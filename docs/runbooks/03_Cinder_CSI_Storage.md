# RUNBOOK 03 — Cinder CSI / Persistent Storage

**Trạng thái:** `COMPLETED` cho dynamic provisioning và mount trong Private Cloud Lab.

## 1. Kiến trúc

OpenStack Cinder (backend LVM, lab AIO) → `cinder.csi.openstack.org` → StorageClass `cinder-lvm` → PVC → PV → VolumeAttachment → Pod.

StorageClass thực tế tại `kubernetes/storage/storageclass/cinder-lvm.yaml`:

```yaml
provisioner: cinder.csi.openstack.org
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

`Retain` giữ OpenStack volume sau khi PVC bị xóa, **không có nghĩa khôi phục dữ liệu tự động**. Tránh dọn PV, OpenStack volume, PVC bằng `kubectl delete` trong lab đang chạy.

## 2. Bằng chứng đã kiểm thử

- CSI driver xuất hiện: `kubectl get csidriver cinder.csi.openstack.org`.
- Smoke test với PVC **1Gi** và Pod trên `k8s-worker-01` từng thành công: PVC/PV `Bound`, VolumeAttachment `attached=true`, Pod `Running`.
- MongoDB sử dụng PVC `mongo-data-mongodb-0` dung lượng **5Gi**; Grafana/Prometheus/Alertmanager dùng Cinder PVC.
- NFS backup là tầng khác và nằm **ngoài OpenStack AIO**.

## 3. Lệnh vận hành read-only

```bash
kubectl get storageclass cinder-lvm -o yaml
kubectl get csidriver cinder.csi.openstack.org
kubectl -n kube-system get pods -o wide | grep -i cinder
kubectl get pvc -A
kubectl get pv
kubectl get volumeattachments
kubectl -n student get pvc mongo-data-mongodb-0
kubectl -n monitoring get pvc
```

Trên OpenStack CLI:

```bash
openstack volume service list
openstack volume list
openstack volume type list
```

## 4. Tình huống lỗi và cách khoanh vùng

**PVC Pending:**

```bash
kubectl -n <NAMESPACE> describe pvc <PVC>
kubectl get events -A --sort-by=.lastTimestamp | tail -40
kubectl get storageclass cinder-lvm -o yaml
```

`WaitForFirstConsumer` có thể khiến PVC Pending cho đến khi Pod được scheduling; đừng sửa reclaimPolicy hoặc xóa PVC để 'fix nhanh'.

**Pod ContainerCreating/FailedMount:**

```bash
kubectl -n <NAMESPACE> describe pod <POD>
kubectl get volumeattachments -o wide
kubectl -n kube-system get pods -o wide | grep cinder
```

Phân biệt lỗi provisioning, Nova attach, permission, network/OpenStack API và backend LVM capacity. Với volume đang gắn Pod, không force-detach tùy tiện.

## 5. Smoke test chỉ trên namespace tách biệt

Source: `kubernetes/storage/tests/cinder-smoke.yaml`. Chỉ chạy khi có tài nguyên dư và biết rằng `Retain` có thể để lại volume sau test:

```bash
kubectl apply -f kubernetes/storage/tests/cinder-smoke.yaml
kubectl -n storage-smoke get pvc,pod
kubectl get volumeattachments
```

Không tự xóa namespace/PVC/PV sau test. Nếu muốn dọn, ghi nhận PV và volume ID trước, quyết định xử lý retention có chủ đích.

## 6. Security & secrets

- Cinder CSI cloud credential nằm trong Secret `kube-system/cinder-csi-cloud-config` (file key `cloud.conf`), không in ra terminal/log.
- `ansible/playbooks/manage-cinder-csi.yml` mặc định `verify`, không tự thay Secret/PV/PVC.
- Kiểm tra chart release bằng `helm -n kube-system status cinder-csi` nếu đang dùng đúng release.

## 7. Điểm giới hạn

- Backend Cinder LVM là lab, không HA; data còn phụ thuộc OpenStack AIO host.
- Backup NFS ngoài host là phương án bảo vệ dữ liệu, không phải Cinder PVC persistence.

**Source:** `kubernetes/storage/`, `ansible/roles/cinder_csi/`, `ansible/playbooks/manage-cinder-csi.yml`.
