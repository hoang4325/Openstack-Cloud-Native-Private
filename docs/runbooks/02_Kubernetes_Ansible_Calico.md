# RUNBOOK 02 — Ansible, Kubernetes 4 node & Calico

**Trạng thái:** Hoàn thành triển khai lab; 4 node Kubernetes `Ready` đã được xác nhận trước đó. Các lệnh dựng mới dưới đây là tài liệu tham chiếu, **không chạy trên cluster hiện tại**.

## 1. Topology

| Node | Fixed IP | Vai trò |
|---|---|---|
| `k8s-control-01` | `10.20.0.10` | control-plane, quản lý cluster |
| `k8s-worker-01` | `10.20.0.11` | worker, Traefik và workload |
| `k8s-monitoring-01` | `10.20.0.12` | Prometheus/Grafana/Alertmanager |
| `k8s-deploy-01` | `10.20.0.13` | Student app + backup Job; Tailscale `100.77.144.40` |

Kubernetes v1.36.5, Ubuntu 24.04, containerd, Calico VXLAN; Pod CIDR `192.168.0.0/16`, Service CIDR `10.96.0.0/12` theo repo và kết quả lab.

## 2. Đường dẫn source

- `ansible/inventories/lab/terraform_inventory.py` — dynamic inventory từ `terraform output -json nodes`; đọc state, không apply.
- `ansible/inventories/lab/group_vars/` — các biến cluster.
- `ansible/playbooks/verify.yml` — read-only verification.
- `ansible/playbooks/bootstrap.yml` — cấu hình node mới (**mutating**, có guard `bootstrap_allow_changes`).
- `ansible/playbooks/add-workers.yml` — thêm worker mới, yêu cầu `--limit` đúng node và xác nhận riêng.
- `ansible/playbooks/deploy-platform.yml` — Argo CD/Traefik; mặc định verify.
- `ansible/playbooks/manage-cinder-csi.yml` — mặc định verify.

## 3. Lệnh kiểm tra định kỳ — chạy trên `k8s-control-01`

```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl -n kube-system get pods -o wide
kubectl get csidriver
kubectl get storageclass
kubectl get --raw='/readyz?verbose'
```

Trên môi trường có Ansible và Terraform state:

```bash
python3 ansible/inventories/lab/terraform_inventory.py --list
ansible-inventory -i ansible/inventories/lab/terraform_inventory.py --graph
ansible-playbook -i ansible/inventories/lab/terraform_inventory.py ansible/playbooks/verify.yml
```

Chạy `verify.yml` cần môi trường control node, SSH và `KUBECONFIG` đúng; nếu không có state hoặc mạng không thông, đây là giới hạn môi trường, không tự động kết luận cluster lỗi.

## 4. Các kết quả đã xác nhận

- 4 node `Ready`, kube-system/Calico hoạt động, Pod giao tiếp qua cluster network.
- Traefik và các ứng dụng chạy trên worker; MongoDB, Student API và Monitoring thu thập được metrics.
- Ansible source hỗ trợ read-only verify và thao tác bootstrap có điều kiện chấp thuận rõ ràng.

## 5. Khi Pod `Pending` / `NotReady`

```bash
kubectl describe node <NODE>
kubectl -n <NAMESPACE> describe pod <POD>
kubectl -n <NAMESPACE> get events --sort-by=.lastTimestamp | tail -40
kubectl -n kube-system get pods -o wide
kubectl -n <NAMESPACE> logs <POD> --all-containers --tail=100
```

Xác định lỗi thuộc scheduler/nodeSelector, CNI, resource, image pull hay PVC. **Không `drain`, `reset`, `delete node`, reboot toàn cụm** nếu chưa có kế hoạch và kiểm tra khả năng chịu lỗi; lab single control-plane.

## 6. Tái dựng lab mới — không dùng cho cluster hiện tại

```bash
# CHỈ DÀNH CHO CỤM HOÀN TOÀN MỚI, SAU KHI ĐỐI CHIẾU HOST / INVENTORY.
ansible-playbook -i ansible/inventories/lab/terraform_inventory.py \
  ansible/playbooks/bootstrap.yml -e bootstrap_allow_changes=true
```

Thêm node mới dùng `ansible/playbooks/add-workers.yml --limit <NEW_WORKER>`; không chạy hàng loạt lên worker đang hoạt động. Các biến mặc định được định nghĩa trong `ansible/inventories/lab/group_vars/all.yml` và ưu tiên các thao tác `verify`.

## 7. Checklist nghiệm thu

- [x] 4 node Ready (đã quan sát từ kết quả thực tế trước đây)
- [x] Calico và workload chạy
- [x] Argo CD, Traefik và CSI có workload hoạt động
- [ ] Kiểm thử HA/mất control-plane (ngoài phạm vi; hệ thống không HA)

**Source:** `ansible/`, `terraform/environments/lab/k8s-cluster/`.
