# RUNBOOK — Kubernetes `ErrImagePull` / `ImagePullBackOff`

> **Áp dụng:** Kubernetes workloads dùng container images từ registry  
> **Đối tượng:** SRE / DevOps / Platform Engineer  
> **Ví dụ đã điều tra:** [INC-001 — `inc01-obj01`](../incidents/INC-001-imagepullbackoff.md)  
> **Phạm vi lệnh thay đổi:** Chỉ trong namespace và tài nguyên được ủy quyền. Không inject/sửa lỗi trong production khi chưa có phê duyệt.

## 1. Mục tiêu và điều kiện kích hoạt

Runbook này hướng dẫn **phát hiện → điều tra → xác minh nguyên nhân → khôi phục → kiểm chứng** khi Pod xuất hiện `ErrImagePull`, `ImagePullBackOff` hoặc Events liên quan đến việc tải container image.

`ImagePullBackOff` cho biết kubelet tải image thất bại và đang trì hoãn lần thử lại. Đây **không phải nguyên nhân gốc**; phải đọc message cụ thể của kubelet/runtime/registry.

## 2. Chuẩn bị và giới hạn an toàn

1. Xác định đúng cluster/context, namespace, Pod và sự cố/ticket.
2. Kiểm tra phạm vi ảnh hưởng, thông tin change/deploy gần nhất và mức độ ưu tiên.
3. Thu thập evidence trước khi thay đổi tài nguyên.
4. Phân biệt **Pod độc lập**, **Deployment/StatefulSet/DaemonSet** và workload do **Argo CD/GitOps** quản lý.
5. Không dùng `kubectl delete pods --all`, không xóa cả namespace, không tắt kubelet/node để xử lý một Pod lỗi.

Đặt biến phù hợp với sự cố (các giá trị dưới đây chỉ dành cho **lab INC-001**):

```bash
NS=troubleshooting-lab
POD=inc01-obj01
kubectl config current-context
kubectl cluster-info
```

## 3. Triage nhanh — read-only

```bash
kubectl -n "$NS" get pod "$POD" -o wide
kubectl -n "$NS" describe pod "$POD"
kubectl -n "$NS" get pod "$POD" \
  -o jsonpath='{range .spec.containers[*]}{.name}{" -> "}{.image}{"\n"}{end}'
kubectl -n "$NS" get pod "$POD" \
  -o jsonpath='{.metadata.ownerReferences}'; echo
kubectl -n "$NS" get events \
  --field-selector involvedObject.kind=Pod,involvedObject.name="$POD" \
  --sort-by=.lastTimestamp
```

Ghi lại:

| Thông tin | Mục đích |
|---|---|
| Pod Ready, `Waiting.Reason` | Chứng minh triệu chứng |
| Image full name + tag/digest | Kiểm tra artifact |
| Node của Pod | Xác định nơi phát sinh thao tác pull |
| `ownerReferences` | Xác định nơi phải sửa cấu hình lâu dài |
| `Events: Failed / BackOff` | Tìm lỗi gốc (manifest/auth/DNS/network/TLS/rate limit) |
| Thời điểm / bản phát hành gần nhất | Xác định trigger |

Nếu thấy `CrashLoopBackOff`, `CreateContainerConfigError` hoặc `Pending` do scheduler thay vì image pull, chuyển sang runbook tương ứng; không ép mọi lỗi vào ImagePullBackOff.

## 4. Lưu evidence

```bash
CASE_ID=INC-001
EVIDENCE_DIR="$HOME/rca-evidence/$CASE_ID"
mkdir -p "$EVIDENCE_DIR"
date -u +'%Y-%m-%dT%H:%M:%SZ' > "$EVIDENCE_DIR/collected-at.txt"
kubectl -n "$NS" get pod "$POD" -o yaml > "$EVIDENCE_DIR/pod-before.yaml"
kubectl -n "$NS" describe pod "$POD" > "$EVIDENCE_DIR/describe-before.txt"
kubectl -n "$NS" get events \
  --field-selector involvedObject.kind=Pod,involvedObject.name="$POD" \
  -o yaml > "$EVIDENCE_DIR/events-before.yaml"
```

Không commit nguyên trạng kubeconfig, token, credentials hoặc các YAML/logs nhạy cảm. Events có TTL nên cần thu thập sớm.

## 5. Decision Tree — xác định nguyên nhân

| Message / quan sát | Nhánh điều tra | Hành động khôi phục phù hợp |
|---|---|---|
| `manifest unknown`, `not found` | Sai repository/tag hoặc artifact chưa được push | Đối chiếu registry và pipeline, tham chiếu tag/digest hợp lệ |
| `unauthorized`, `denied` | Sai registry credential, quyền truy cập hoặc `imagePullSecrets` | Kiểm tra service account/secret và registry permissions, sửa qua Secret management |
| `no such host` | DNS node không resolve được registry | Kiểm tra DNS trên node và resolver/upstream |
| `i/o timeout`, `connection refused` | Registry/network/proxy/firewall | Kiểm tra kết nối từ node, proxy, routing, security group |
| `x509: certificate...` | CA/certification/TLS | Kiểm tra trust chain, CA bundle, certificate expiry; không tắt TLS verification tùy tiện |
| `429 Too Many Requests`, rate limit | Giới hạn pull từ registry | Dùng authenticated pull, mirror/cache hoặc điều chỉnh tần suất rollout |
| `no space left on device` | Disk pressure/image storage | Xác minh dung lượng, dọn image/cache có kiểm soát và chính sách GC |
| Chỉ `BackOff` / `ImagePullBackOff` | Chưa đủ bằng chứng | Lấy sự kiện lỗi gốc, runtime/kubelet logs và kiểm tra registry từ node |

Luôn kiểm chứng giả thuyết, không suy đoán `ImagePullBackOff` đồng nghĩa image tag chắc chắn không tồn tại.

### 5.1. Thu thập phản hồi pull từ node (nếu có quyền)

Sau khi xác nhận node từ `kubectl get pod -o wide`, SSH vào **đúng node đó** và thử với image thực tế (lệnh thử có thể tải image và sử dụng disk/network):

```bash
sudo crictl pull docker.io/library/nginx:tag-does-not-exist-troubleshooting
```

Ví dụ này chỉ dùng cho INC-001. Không đặt thông tin xác thực registry vào command history hoặc evidence công khai. Lưu nguyên văn lỗi có timestamp và che thông tin nhạy cảm.

## 6. Recovery — chọn đúng mô hình quản lý

### A. Pod độc lập trong troubleshooting lab

**Chỉ sử dụng trong namespace thực hành sau khi đã lưu bằng chứng và kiểm tra ownerReferences.**

```bash
kubectl -n troubleshooting-lab patch pod inc01-obj01 \
  --type=strategic \
  -p '{"spec":{"containers":[{"name":"web","image":"nginx:stable"}]}}'
```

Image `nginx:stable` là ví dụ phục hồi cho lab, không phải khuyến nghị dùng tag mutable trong production. Giữ nguyên manifest lỗi trong `operator-fault-injector/manifests/01.yaml` để bài lab còn tái hiện được.

Nếu patch không được API chấp nhận, hãy đọc thông báo lỗi và kiểm tra đối tượng/field; không xóa Pod bừa bãi. Đối với Pod độc lập, một phương án khác là viết manifest sửa riêng rồi thay Pod có kiểm soát, sau khi đã lưu bằng chứng và xác minh không ảnh hưởng workload khác.

### B. Deployment hoặc controller tương đương

Sửa **Pod template của controller** (bằng manifest hoặc change có kiểm soát), không chỉ xóa Pod lỗi. Khi cần mitigation thủ công trong môi trường không do GitOps quản lý và được phép thao tác, ví dụ:

```bash
# Thay DEPLOYMENT, CONTAINER, IMAGE bằng các giá trị đã xác minh.
kubectl -n "$NS" set image deployment/DEPLOYMENT CONTAINER=IMAGE
kubectl -n "$NS" rollout status deployment/DEPLOYMENT --timeout=180s
```

Ghi lại change, xác minh bản triển khai và sau đó cập nhật cấu hình gốc trong Git để tránh sai lệch.

### C. Workload do Argo CD / GitOps quản lý

1. Tìm Application và manifest/Helm values nguồn.
2. Sửa image tag/digest trong Git, tạo PR/review/merge theo mức độ khẩn cấp.
3. Theo dõi Argo CD Sync/Health và rollout.
4. Nếu buộc phải mitigation trực tiếp trong incident nghiêm trọng, phối hợp người chịu trách nhiệm GitOps và **đưa Git về đúng trạng thái ngay sau đó**; `selfHeal` có thể ghi đè sửa đổi thủ công.
5. Không chỉnh sửa manifest fault injector của các lab khi làm permanent fix cho ứng dụng production.

## 7. Verification sau recovery

### 7.1. Kubernetes health

```bash
kubectl -n "$NS" wait --for=condition=Ready "pod/$POD" --timeout=180s
kubectl -n "$NS" get pod "$POD" -o wide
kubectl -n "$NS" describe pod "$POD"
kubectl -n "$NS" logs "$POD" --tail=30
```

Quan sát Pod `1/1` (hoặc đúng số containers), không còn image pull failure mới, và đúng image tag/digest sau sửa.

### 7.2. Functional check (INC-001 có Nginx)

Terminal 1 (trên host có kubectl):

```bash
kubectl -n troubleshooting-lab port-forward pod/inc01-obj01 18080:80
```

Terminal 2 (cùng host):

```bash
curl -i --max-time 10 http://127.0.0.1:18080/
```

Yêu cầu phản hồi HTTP thành công, ví dụ `HTTP/1.1 200 OK`, và ghi output thật. Port-forward chỉ chứng minh ứng dụng trả lời qua tunnel, không chứng minh đường Service/Ingress nếu workload có lớp networking đó.

### 7.3. Lưu kết quả sau sửa

```bash
kubectl -n "$NS" get pod "$POD" -o yaml > "$EVIDENCE_DIR/pod-after.yaml"
kubectl -n "$NS" describe pod "$POD" > "$EVIDENCE_DIR/describe-after.txt"
date -u +'%Y-%m-%dT%H:%M:%SZ' > "$EVIDENCE_DIR/recovery-check-at.txt"
```

Chỉ đánh dấu `Resolved` khi **đã xác minh kết quả**. Nếu chưa thể kiểm thử HTTP hoặc lỗi lặp lại, giữ incident ở `Mitigating`/`Monitoring` hoặc `Investigating` tương ứng.

## 8. Escalation & rollback

- **Registry auth / Secret**: chuyển cho Platform/Registry owner; không copy secret raw ra ticket.
- **DNS/network/TLS từ node**: phối hợp Network/Platform Engineer; đối chiếu nhiều node và security rules.
- **Image không được build/push**: phối hợp CI/CD owner; có thể rollback về artifact hợp lệ trước đó nếu kế hoạch cho phép.
- **GitOps tự ghi đè**: phối hợp Argo CD owner và đồng bộ Git source of truth.
- **Lỗi sau recovery / tái diễn**: ghi timeline mới, quay lại bước triage; không xóa bằng chứng cũ.

## 9. Điều kiện đóng incident và ghi RCA

RCA của từng incident (không viết kết quả giả) phải có:

- Impact và nguồn phát hiện, timestamp UTC.
- Ít nhất hai giả thuyết cạnh tranh cùng bằng chứng chấp nhận/loại trừ.
- Root cause đã xác minh và các giới hạn bằng chứng.
- Thay đổi thực tế (command/PR/commit) và tác dụng phụ/rủi ro.
- Recovery verification (health và functional check).
- Corrective/preventive actions có owner, deadline hoặc lý do chưa lên lịch.
- Chỉ số MTTD/MTTR nếu có dữ liệu timestamp đáng tin cậy.

## 10. Dọn và tái hiện bài lab INC-001 (không dành cho production)

Chỉ sau khi lưu đủ evidence, tại thư mục Operator Pack trên control plane:

```bash
./operator.sh stop 01      # Chỉ xóa tài nguyên khai báo cho INC-01
./operator.sh start 01     # Chủ động tạo lại fault INC-01 nếu muốn luyện tập tiếp
```

Không dùng `./operator.sh reset` khi các case khác đang chạy: lệnh đó xóa toàn bộ namespace `troubleshooting-lab`.

## 11. Tài liệu liên quan

- [Incident INC-001](../incidents/INC-001-imagepullbackoff.md)
- [Ticket bài tập INC-01](../../labs/kubernetes/troubleshooting/student-blind-labs/tickets/01.md)
- [Kubernetes: Debug Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)
- [Kubernetes: Images](https://kubernetes.io/docs/concepts/containers/images/)
