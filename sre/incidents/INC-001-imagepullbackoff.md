# INC-001 — Kubernetes ImagePullBackOff

**Incident Report & Root Cause Analysis**

## 1. Incident Information

| Field | Value |
|---|---|
| Incident ID | INC-001 |
| Incident Title | Kubernetes Pod Failed to Pull Container Image |
| Environment | OpenStack Private Cloud — Kubernetes Lab |
| Cluster | Kubernetes Lab Cluster |
| Namespace | `troubleshooting-lab` |
| Affected Resource | `pod/inc01-obj01` |
| Node | `k8s-monitoring-01` (`10.20.0.12`) |
| Severity | SEV-4 — Lab Incident (proposed) |
| Start Time | 2026-10-12 13:18:13 UTC |
| Status | Investigating — Recovery Not Verified |
| Root Cause Status | Suspected — Pending Registry Verification |

## 2. Executive Summary

Ngày 12/10/2026, Pod `inc01-obj01` trong namespace `troubleshooting-lab` không thể khởi chạy container do Kubernetes gặp lỗi khi tải container image.

Tại thời điểm điều tra, Pod đang ở trạng thái `ImagePullBackOff`, container chưa khởi động thành công và chưa đạt điều kiện `Ready`.

Qua kiểm tra Pod specification, container `web` đang sử dụng image:

`nginx:tag-does-not-exist-troubleshooting`

Đây là image tag có dấu hiệu được cố tình cấu hình không hợp lệ để phục vụ Kubernetes Troubleshooting Lab.

Các Kubernetes Events xác nhận kubelet liên tục gặp lỗi image pull và thực hiện backoff. Tuy nhiên, thông báo cụ thể từ container registry chưa được thu thập đầy đủ.

## 3. Impact Assessment

### Technical Impact

- Pod `inc01-obj01` không thể chuyển sang trạng thái `Running`.
- Container `web` chưa được tạo và khởi chạy thành công.
- Trạng thái Pod: `Pending`.
- Trạng thái container: `Waiting — ImagePullBackOff`.
- Readiness: `0/1`.
- Restart count: `0`.
- Pod được lên lịch trên `k8s-monitoring-01`.

Tại thời điểm kiểm tra, Pod đã tồn tại khoảng 109 phút nhưng vẫn không thể khởi chạy container.

### Business Impact

Sự cố nằm trong môi trường Kubernetes Troubleshooting Lab. Chưa có bằng chứng về tác động tới người dùng hoặc dịch vụ production.

Không ghi nhận được ảnh hưởng tới các Pod khác từ những thông tin hiện có.

## 4. Detection & Technical Evidence

### Evidence 01 — Pod Status

Command:

```bash
kubectl get pod inc01-obj01 -n troubleshooting-lab
```

Output:

```text
NAME          READY   STATUS             RESTARTS   AGE
inc01-obj01   0/1     ImagePullBackOff   0          109m
```

**Observation:** Container không đạt trạng thái Ready và Kubernetes báo lỗi `ImagePullBackOff`.

### Evidence 02 — Container Configuration

Command:

```bash
kubectl get pod inc01-obj01 \
  -n troubleshooting-lab \
  -o jsonpath='{.spec.containers[*].image}'
```

Output:

```text
nginx:tag-does-not-exist-troubleshooting
```

**Observation:** Pod tham chiếu một image tag có dấu hiệu không tồn tại trên registry.

### Evidence 03 — Pod Conditions

Từ `kubectl describe pod`:

```text
Status: Pending

Containers:
  web:
    Image: nginx:tag-does-not-exist-troubleshooting
    State: Waiting
      Reason: ImagePullBackOff
    Ready: False
    Restart Count: 0

Conditions:
  PodReadyToStartContainers: True
  Initialized: True
  Ready: False
  ContainersReady: False
  PodScheduled: True
```

**Observation:**

Kubernetes đã schedule Pod thành công. Các điều kiện khởi tạo cần thiết đã đạt, nhưng container chưa khởi chạy do lỗi image pull.

### Evidence 04 — Kubernetes Events

```text
Normal   BackOff  (x458 over 109m)
Back-off pulling image
"nginx:tag-does-not-exist-troubleshooting"

Warning  Failed  (x459 over 109m)
Error: ImagePullBackOff
```

**Observation:**

Kubelet liên tục ghi nhận sự kiện image pull failure và backoff trong khoảng 109 phút.

Số lần lặp Events không nhất thiết bằng chính xác số lần thực hiện yêu cầu pull tới registry.

## 5. Incident Timeline

| Time | Event |
|---|---|
| 13:18:13 UTC | Pod `inc01-obj01` được tạo |
| Sau khi tạo | Kubelet cố tải image được chỉ định |
| Không rõ thời điểm chính xác | Container không khởi chạy và xuất hiện lỗi image pull |
| Trong khoảng 109 phút | Kubernetes tiếp tục ghi nhận `BackOff` và `Failed` |
| Tại thời điểm điều tra | Pod vẫn `0/1`, trạng thái `ImagePullBackOff` |
| Pending | Xác minh image tag trên registry |
| Pending | Thực hiện recovery và kiểm tra kết quả |

Các mốc không có timestamp chính xác được giữ ở trạng thái chưa xác định thay vì gán thời gian giả định.

## 6. Root Cause Analysis

### 6.1. Symptom

Pod `inc01-obj01` không thể khởi động container và liên tục ở trạng thái `ImagePullBackOff`.

### 6.2. Immediate Technical Cause

Kubelet không tải được container image được khai báo trong Pod specification.

Điều này được xác nhận bởi Kubernetes Events.

### 6.3. Suspected Root Cause

Pod đang tham chiếu đến image:

`nginx:tag-does-not-exist-troubleshooting`

**Giả thuyết có độ tin cậy cao:** Image tag không tồn tại trên container registry, khiến kubelet không thể tải image và khởi chạy container.

Để xác nhận nguyên nhân này cần kiểm tra image tag trên registry hoặc thu thập phản hồi cụ thể như `manifest unknown` hoặc `not found`.

### 6.4. Five Whys Analysis

| Question | Analysis |
|---|---|
| Why 1: Pod không Ready? | Container `web` chưa khởi động |
| Why 2: Container chưa khởi động? | Kubernetes không tải được container image |
| Why 3: Image pull thất bại? | Registry không cung cấp được image được yêu cầu; lý do cụ thể cần xác minh |
| Why 4: Tại sao sử dụng image này? | Pod specification tham chiếu tag `tag-does-not-exist-troubleshooting` |
| Why 5: Vì sao tag không hợp lệ có mặt trong manifest? | Nhiều khả năng là fault được chủ động tạo trong bài lab; cần đối chiếu manifest và script injector |

### 6.5. Contributing Factors

Chưa đủ bằng chứng để xác định các nguyên nhân góp phần ở mức quy trình hoặc hệ thống.

Trong môi trường production, có thể cân nhắc kiểm tra quy trình xác minh image, kiểm soát deployment và phát hiện lỗi tự động. Không kết luận các cơ chế này đang thiếu chỉ từ một Pod lỗi.

## 7. Resolution & Recovery

**Status: Not Yet Performed / Not Verified**

### Proposed Recovery Procedure

1. Thu thập đầy đủ Pod YAML và Events trước khi thay đổi.
2. Xác định Pod có được controller quản lý hay không.
3. Xác minh một image tag hợp lệ trên registry.
4. Chỉnh sửa cấu hình nguồn để sử dụng image hợp lệ.
5. Triển khai lại workload.
6. Kiểm tra Pod `Running`, container `Ready` và chức năng ứng dụng.

### Recovery Verification Criteria

- [ ] Image hợp lệ được xác minh tồn tại.
- [ ] Pod được tạo lại hoặc cập nhật thành công.
- [ ] Container đạt trạng thái `Running`.
- [ ] Readiness đạt `1/1`.
- [ ] Không còn image pull failure mới.
- [ ] Workload hoạt động đúng kỳ vọng.

**Recovery Time:** Pending

**Time to Recovery:** Not available

## 8. Corrective and Preventive Actions

| Action | Priority | Status |
|---|---|---|
| Sửa image tag trong cấu hình nguồn | P1 | Pending |
| Xác minh Pod Ready sau recovery | P1 | Pending |
| Kiểm tra image artifact trước deployment trong CI/CD | P2 | Proposed |
| Xây dựng alert phát hiện image pull failure | P2 | Proposed |
| Tạo SRE Runbook cho ImagePullBackOff | P2 | Proposed |

Các action sẽ được gán owner và deadline khi triển khai thành công việc vận hành thực tế.

## 9. Lessons Learned

1. `ImagePullBackOff` là triệu chứng thất bại khi tải container image, không tự nó chứng minh nguyên nhân cụ thể từ registry.
2. Pod có thể được schedule thành công nhưng container vẫn không thể khởi chạy.
3. Kiểm tra `kubectl describe pod` và Kubernetes Events là bước quan trọng khi điều tra image pull failure.
4. Cần kiểm tra image tag, registry access, DNS và network tùy theo thông báo lỗi thực tế.
5. Việc xóa Pod không giải quyết được lỗi nếu workload vẫn tham chiếu tới image không hợp lệ.
6. Thu thập evidence trước recovery giúp báo cáo RCA có thể kiểm chứng.

## 10. Incident Conclusion

Sự cố `INC-001` được xác nhận ở mức Kubernetes không thể tải container image cho Pod `inc01-obj01`.

Image tag không tồn tại là nguyên nhân nghi ngờ chính, phù hợp với cấu hình của Kubernetes Troubleshooting Lab.

Việc xác minh registry và khôi phục Pod vẫn chưa được thực hiện hoặc chưa có bằng chứng xác nhận.

**Final Status: Investigation Completed Partially — Recovery Pending**

**RCA Completion: Pending Root Cause Confirmation & Recovery Evidence**
