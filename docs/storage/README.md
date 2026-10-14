# OpenStack Cinder CSI — PVC / GitOps

## Đối chiếu với hệ thống đã chạy

- Kubernetes `v1.36.5`, 3 VMs: `k8s-control-01`, `k8s-worker-01`, `k8s-monitoring-01`.
- Kolla-Ansible Cinder LVM backend `cinder-volumes` (loopback 30GiB chỉ dùng cho lab).
- Helm release đang hoạt động: `cinder-csi` trong namespace `kube-system`, chart `openstack-cinder-csi` phiên bản `2.36.2`.
- Secret **đã tồn tại**: `kube-system/cinder-csi-cloud-config` chứa key `cloud.conf`.
- CSI driver: `cinder.csi.openstack.org`.
- StorageClass **đã tồn tại**: `cinder-lvm`, type `__DEFAULT__`, `Retain`, `WaitForFirstConsumer`.
- PVC `default/cinder-test-pvc` trước đó đã Bound, volume `in-use` ở VM `k8s-worker-01`, đọc/ghi `/data/test.txt` thành công.
- Chưa tự động chỉnh sửa các PVC/volume đang chạy, đặc biệt volume thử nghiệm đang gắn `k8s-monitoring-01`.

## Source tree

- `helm/storage/cinder-csi-values.yaml`: version-controlled Helm values, **không chứa credentials**.
- `helm/storage/cloud.conf.example`: template cấu hình, chỉ thay giá trị trên máy cục bộ; KHÔNG commit file `cloud.conf` thật.
- `kubernetes/storage/storageclass/cinder-lvm.yaml`: StorageClass của môi trường.
- `gitops/applications/storageclass.yaml`: Argo CD Application, đồng bộ **thủ công lần đầu**.
- `gitops/examples/cinder-csi-application.yaml`: mẫu chuyển CSI từ Helm sang Argo CD; **không apply lúc này**.
- `kubernetes/storage/tests/cinder-smoke.yaml`: smoke test tạo PVC mới trong namespace riêng; không auto-sync.
- `helm/monitoring/persistence.values.example.yaml`: overlay bật PVC monitoring **chưa kích hoạt**.

## Kiểm tra trước khi thay đổi

Trên control plane:

```bash
kubectl get nodes -o wide
kubectl get csidrivers
kubectl get csinodes
kubectl get sc cinder-lvm -o yaml
kubectl -n kube-system get secret cinder-csi-cloud-config
helm get values cinder-csi -n kube-system -o yaml
```

Không paste nội dung Secret hoặc `cloud.conf` thật vào log/PR. Giá trị `helm get values` ở trên không nên chứa mật khẩu vì secret được quản lý riêng.

Trên host OpenStack:

```bash
openstack volume service list
openstack volume list
sudo vgs cinder-volumes
systemctl is-enabled cinder-loop-activate.service
```

Không chạy lại `pvcreate`/`vgcreate`: backend LVM này đã chứa dữ liệu. Không cấu hình `enable_haproxy: true` khi các API hiện bind trực tiếp trên `10.250.0.10`.

## Bootstrap (cluster mới) và trạng thái cluster hiện tại

Với cluster **hiện tại**, CSI và StorageClass đã được tạo thủ công. Đừng cài một bản CSI thứ hai.

Trên **cluster mới**, phải tạo Secret từ credentials bên ngoài Git trước:

```bash
umask 077
cp helm/storage/cloud.conf.example /tmp/cloud.conf
# Sửa /tmp/cloud.conf (dữ liệu thật KHÔNG commit)
chmod 600 /tmp/cloud.conf
kubectl -n kube-system create secret generic cinder-csi-cloud-config   --from-file=cloud.conf=/tmp/cloud.conf
helm repo add cpo https://kubernetes.github.io/cloud-provider-openstack
helm repo update
helm upgrade --install cinder-csi cpo/openstack-cinder-csi   -n kube-system --version 2.36.2   -f helm/storage/cinder-csi-values.yaml   --wait --timeout 10m
kubectl apply -f kubernetes/storage/storageclass/cinder-lvm.yaml
```

Chỉ dùng lệnh bootstrap này trên cluster mới hoặc khi có kế hoạch phục hồi CSI. Không commit file cấu hình chứa password. Luôn xác minh Keystone, Nova, Cinder API và OpenStack instance metadata/config-drive trên các node trước khi cài.

## Quản lý StorageClass với Argo CD

```bash
kubectl diff -f kubernetes/storage/storageclass/cinder-lvm.yaml
kubectl apply -f gitops/applications/storageclass.yaml
kubectl -n argocd get application storageclass-cinder
```

Argo CD Application được tạo ở chế độ *manual sync*. Sau khi kiểm tra live StorageClass khớp manifest, Sync `storageclass-cinder` một lần qua Argo CD UI. Khi xác minh thành công, mới cân nhắc thêm `syncPolicy.automated` với `prune: false` và `selfHeal: true`.

## Smoke test PVC mới — không động chạm test cũ

```bash
kubectl apply -f kubernetes/storage/tests/cinder-smoke.yaml
kubectl -n storage-smoke wait --for=condition=Ready pod/cinder-smoke-pod --timeout=180s
kubectl -n storage-smoke get pod,pvc
kubectl get pv
kubectl get volumeattachments
kubectl -n storage-smoke exec cinder-smoke-pod -- sh -c 'echo storage-persistent > /data/probe.txt'
kubectl -n storage-smoke exec cinder-smoke-pod -- cat /data/probe.txt
```

Chỉ xóa Pod (không xóa PVC) để kiểm chứng persistence:

```bash
kubectl -n storage-smoke delete pod cinder-smoke-pod
kubectl apply -f kubernetes/storage/tests/cinder-smoke.yaml
kubectl -n storage-smoke wait --for=condition=Ready pod/cinder-smoke-pod --timeout=180s
kubectl -n storage-smoke exec cinder-smoke-pod -- cat /data/probe.txt
```

Dữ liệu kỳ vọng là `storage-persistent`. Nếu PVC `Bound` và pod `Running` nhưng chưa thấy dữ liệu, kiểm tra `/data` mount và VolumeAttachment.

**Lưu ý Retain:** Khi xóa PVC hoặc namespace `storage-smoke`, PV và volume Cinder có thể vẫn tồn tại ở trạng thái `Released`. Không dọn dẹp tự động: cần xác nhận không còn dữ liệu cần giữ, detach đúng quy trình và xử lý PV/volume thủ công. Không xóa Cinder volume đang `in-use`.

## Quy trình GitOps cho CSI hiện hữu

`cinder-csi` đang do Helm quản lý trực tiếp. File `gitops/examples/cinder-csi-application.yaml` là **bản thiết kế cho lần chuyển quyền quản lý**, không được `kubectl apply` vào cluster hiện tại rồi Sync ngay. Việc đó có thể gây cạnh tranh owner labels/annotations giữa Helm và Argo CD. Hãy chuẩn bị một maintenance window, lưu `helm get manifest`/`helm get values`, kiểm tra manifest render từ Argo CD, đánh giá quyền sở hữu và tiến hành cutover có kiểm soát. Không `helm uninstall cinder-csi` khi vẫn còn PVC đang sử dụng chỉ để chuyển ownership.

## Chuyển monitoring từ ephemeral sang PVC (để sau)

Source hiện tại ở `helm/monitoring/values.yaml` có:
- Prometheus `storageSpec: {}` và `retention: 3d`, `retentionSize: 3GiB`.
- Grafana `persistence.enabled: false`.
- Alertmanager `storage: {}`.

Overlay đề xuất ở `helm/monitoring/persistence.values.example.yaml` cấp 10Gi + 3Gi + 2Gi (15Gi trước khi tính hai volume test đã có). **Overlay này chưa được Argo CD sử dụng**, nên chỉ commit file không làm đổi workload hiện tại.

Chỉ khi backup Grafana dashboards, Prometheus data/retention và Alertmanager silences, đồng thời chấp nhận Pod/StatefulSet có thể restart/recreate, mới sửa `gitops/applications/monitoring.yaml` để thêm file thứ hai trong `helm.valueFiles`:

```yaml
valueFiles:
  - $values/helm/monitoring/values.yaml
  - $values/helm/monitoring/persistence.values.example.yaml
```

Đổi tên overlay `.example.yaml` thành file triển khai ổn định nếu cần. Vì Application `monitoring` đang auto-sync và self-heal, việc commit thay đổi `valueFiles` trên `master` có thể lập tức kích hoạt rollout. Dữ liệu `emptyDir` sẽ KHÔNG tự di chuyển sang PVC. Quá trình chuyển `volumeClaimTemplate` của StatefulSet có thể đòi hỏi thao tác migration riêng, không nên xóa StatefulSet hoặc PVC một cách mù quáng.

## Kiểm tra sau commit

```bash
git status --short
git diff --check
kubectl apply --dry-run=client -f kubernetes/storage/storageclass/cinder-lvm.yaml
kubectl apply --dry-run=client -f kubernetes/storage/tests/cinder-smoke.yaml
```

Trên máy có `helm`:

```bash
helm template cinder-csi cpo/openstack-cinder-csi --version 2.36.2   -n kube-system -f helm/storage/cinder-csi-values.yaml > /tmp/cinder-csi-rendered.yaml
```

**Dữ liệu bền vững không đồng nghĩa backup/HA**. Loopback LVM trên một máy AIO vẫn có single point of failure. Thiết kế backup, snapshot, kiểm thử restore trước khi sử dụng nghiêm túc.
