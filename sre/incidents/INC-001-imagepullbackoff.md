# INC-001 — Kubernetes ImagePullBackOff (`inc01-obj01`)

> **Loại:** Incident Report / Root Cause Analysis (RCA)  
> **Môi trường:** OpenStack Private Cloud — Kubernetes Troubleshooting Lab  
> **Runbook:** [ImagePullBackOff](../runbooks/imagepullbackoff.md)  
> **Ticket thực hành:** [INC-01](../../labs/kubernetes/troubleshooting/student-blind-labs/tickets/01.md)

## 1. Incident metadata

| Thuộc tính | Giá trị |
|---|---|
| Incident ID | `INC-001` (ticket lab: `INC-01`) |
| Incident title | Pod không khởi chạy do image tag không tồn tại |
| Ngày | `2026-10-12` |
| Namespace | `troubleshooting-lab` |
| Pod / container | `inc01-obj01` / `web` |
| Node chạy Pod | `k8s-monitoring-01` (`10.20.0.12`) |
| Mức độ | SEV-4 (đề xuất riêng cho môi trường lab) |
| Pod start time của **lần tái hiện này** | `2026-10-12 15:59:43 UTC` |
| Thời điểm HTTP kiểm thử thành công | `2026-10-12 16:03:05 UTC` |
| Incident status | **RESOLVED — Technical recovery verified** |
| RCA status | **Root cause confirmed; preventive actions proposed** |
| Incident owner | `[Bổ sung người thực hiện]` |

**Phân biệt các lần tái hiện:** Log cũ của `inc01-obj01` ghi thời điểm tạo `13:18:13 UTC`, Pod IP `192.168.80.98`. Báo cáo này sử dụng **lần tái hiện mới**, Pod được tạo `15:59:43 UTC`, Pod IP `192.168.80.99`; không cộng thời lượng hai lần thành một incident.

## 2. Executive summary

Ngày 12/10/2026, Pod `inc01-obj01` trong namespace `troubleshooting-lab` được schedule thành công tới node `k8s-monitoring-01`, nhưng container `web` không khởi động. Pod ở trạng thái `Pending`, container `Waiting (ImagePullBackOff)`, `Ready=False`.

Pod tham chiếu image `nginx:tag-does-not-exist-troubleshooting`. Sự kiện kubelet ghi nhận lỗi `NotFound` khi phân giải image trên Docker Hub; một lệnh `crictl pull` chạy bổ sung **trên `k8s-control-01`** cũng trả về `NotFound`. Manifest trong Operator Pack xác nhận image tag lỗi này được khai báo có chủ đích để tạo incident thực hành.

Kỹ sư đã sửa trường `spec.containers[].image` của **Pod độc lập** bằng `kubectl patch`, chuyển sang `nginx:stable`. Pod đạt `1/1 Running`, Nginx khởi động thành công; yêu cầu HTTP tới `127.0.0.1:18080` trả `200 OK`. Kết quả cho thấy sự cố khởi động container đã được khôi phục. Không có bằng chứng về sự cố production.

## 3. Impact assessment

- **Technical impact:** Một Pod lab không thể chạy container và chưa đạt Ready; trạng thái `0/1 ImagePullBackOff`, `Restart Count=0` trước recovery.
- **Phạm vi:** Tài nguyên `inc01-obj01` trong `troubleshooting-lab`; manifest incident không tạo Service/Ingress riêng.
- **Node & scheduling:** `PodScheduled=True`; node `k8s-monitoring-01` đã được gán thành công. Không phải lỗi Pending vì thiếu tài nguyên/scheduling.
- **Business/user impact:** Không ghi nhận ảnh hưởng đến người dùng production.
- **Duration:** Từ Pod creation (`15:59:43`) đến HTTP 200 (`16:03:05`) là **3 phút 22 giây**. Đây là khoảng thời gian quan sát được từ hai mốc xác định, **không phải** MTTR production hay thời điểm bắt đầu ảnh hưởng người dùng.
- **MTTD:** Chưa đo; không có timestamp chính xác khi người vận hành lần đầu phát hiện lỗi.

## 4. Evidence trước recovery

### E01 — Pod/container state

Lệnh:

```bash
kubectl describe pod inc01-obj01 -n troubleshooting-lab
```

Các trường quan trọng:

```text
Name:             inc01-obj01
Namespace:        troubleshooting-lab
Node:             k8s-monitoring-01/10.20.0.12
Start Time:       Mon, 12 Oct 2026 15:59:43 +0000
Status:           Pending
IP:               192.168.80.99
Containers:
  web:
    Image:          nginx:tag-does-not-exist-troubleshooting
    State:          Waiting
      Reason:       ImagePullBackOff
    Ready:          False
    Restart Count:  0
Conditions:
  Initialized:             True
  Ready:                   False
  ContainersReady:         False
  PodScheduled:            True
```

**Ý nghĩa:** Pod đã được schedule, nhưng container chưa tải được image để khởi chạy.

### E02 — Kubelet Events xác nhận `NotFound`

Trích `kubectl describe pod`:

```text
Warning  Failed  47s (x4 over 2m20s)  kubelet
Failed to pull image "nginx:tag-does-not-exist-troubleshooting":
rpc error: code = NotFound desc = failed to pull and unpack image
"docker.io/library/nginx:tag-does-not-exist-troubleshooting":
failed to resolve image: docker.io/library/nginx:tag-does-not-exist-troubleshooting: not found

Warning  Failed  47s (x4 over 2m20s)  kubelet  Error: ErrImagePull
Normal   BackOff 10s (x8 over 2m19s)  kubelet  Back-off pulling image
Warning  Failed  10s (x8 over 2m19s)  kubelet  Error: ImagePullBackOff
```

**Ý nghĩa:** Kubelet nhận được lỗi không tìm thấy image/tag; các lần thử lại tạo trạng thái backoff. Số lần lặp Events không phải số request chính xác tới registry.

### E03 — Kiểm chứng bổ sung bằng container runtime

Chạy trên shell `ubuntu@k8s-control-01` (không phải trên node chứa Pod):

```bash
sudo crictl pull docker.io/library/nginx:tag-does-not-exist-troubleshooting
```

Trích lỗi:

```text
E1012 16:02:13.317019 ... PullImage from image service failed
rpc error: code = NotFound desc = failed to pull and unpack image
"docker.io/library/nginx:tag-does-not-exist-troubleshooting":
failed to resolve image: docker.io/library/nginx:tag-does-not-exist-troubleshooting: not found
FATA[0001] pulling image: rpc error: code = NotFound
```

**Ý nghĩa:** Phép kiểm tra độc lập trên control plane củng cố kết luận tag không tồn tại; kubelet Event của node `k8s-monitoring-01` là bằng chứng trực tiếp tại nơi Pod chạy.

### E04 — Cấu hình lỗi trong source manifest

Nguồn: [`labs/kubernetes/troubleshooting/operator-fault-injector/manifests/01.yaml`](../../labs/kubernetes/troubleshooting/operator-fault-injector/manifests/01.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: inc01-obj01
  namespace: troubleshooting-lab
  labels:
    troubleshooting-case: l01
spec:
  containers:
    - name: web
      image: nginx:tag-does-not-exist-troubleshooting
```

Đây là *Pod độc lập được tạo qua Fault Injection*, không phải một Deployment do Argo CD quản lý.

## 5. Hypotheses & diagnosis

| Giả thuyết | Bằng chứng kiểm tra | Kết luận |
|---|---|---|
| H1: Tag image không tồn tại | Kubelet `NotFound`; `crictl pull` `NotFound`; manifest trỏ đúng tag đó | **Confirmed** |
| H2: Registry credentials thiếu hoặc sai | Không quan sát `unauthorized` / `denied`; registry trả `NotFound` cho image/tag cụ thể | **Không phải nguyên nhân phù hợp nhất với evidence này** |
| H3: DNS / network / TLS tới registry hỏng | Runtime nhận phản hồi `NotFound`, không phải `no such host`, `timeout` hay `x509` | **Không phải nguyên nhân của lần xảy ra này theo evidence** |

## 6. Root cause analysis

**Symptom:** Pod `0/1`, container `Waiting (ImagePullBackOff)`.

**Immediate cause:** Kubelet không thể tải image được khai báo vì Docker Hub không tìm thấy `docker.io/library/nginx:tag-does-not-exist-troubleshooting`.

**Root cause ở cấp cấu hình:** File fault injector `manifests/01.yaml` khai báo tag không tồn tại. Điều này được tạo có chủ đích để luyện tập điều tra và khôi phục Kubernetes workload.

**Recovery mechanism:** Cập nhật image của container `web` sang `nginx:stable`; sau đó container được khởi chạy thành công.

**Contributing factors:** Không có đủ dữ liệu để kết luận lỗi quy trình CI/CD production hoặc thiếu policy validation; đây là bài lab fault injection.

### Chuỗi 5 Whys rút gọn

1. **Vì sao Pod không Ready?** Container `web` chưa khởi chạy.
2. **Vì sao container chưa khởi chạy?** Kubelet pull image thất bại.
3. **Vì sao image pull thất bại?** Registry trả `NotFound` cho tag được khai báo.
4. **Vì sao tag sai được khai báo?** Manifest `01.yaml` chứa `nginx:tag-does-not-exist-troubleshooting`.
5. **Vì sao manifest có tag đó?** Bài lab chủ đích inject lỗi để thực hành SRE.

## 7. Timeline (UTC)

| Mốc thời gian | Sự kiện | Nguồn |
|---|---|---|
| 2026-10-12 15:59:43 | Pod của lần tái hiện mới được tạo | `kubectl describe pod` |
| Khoảng 15:59–16:02 | Kubelet thử pull, ghi `NotFound`, `ErrImagePull`, `ImagePullBackOff` | Events (không có tuyệt đối từng mốc) |
| 2026-10-12 16:02:13 | Kiểm tra `crictl pull` trên control plane nhận `NotFound` | `crictl` log |
| Giữa 16:02:13 và 16:02:19 | Thực hiện `kubectl patch`, image chuyển sang `nginx:stable` | Thứ tự lệnh và kết quả; không có timestamp chính xác |
| 2026-10-12 16:02:19 | Nginx bắt đầu khởi chạy worker processes | Container logs |
| Sau khi patch, trước HTTP test | Pod được quan sát `1/1 Running`, `RESTARTS=0` | `kubectl get pod -w`, `kubectl get pod -o wide` |
| 2026-10-12 16:03:05 | HTTP `200 OK` nhận tại localhost:18080 | Response `Date` header |

## 8. Recovery & validation

### 8.1. Thao tác khôi phục thực tế

```bash
kubectl patch pod inc01-obj01 \
  -n troubleshooting-lab \
  --type=strategic \
  -p '{"spec":{"containers":[{"name":"web","image":"nginx:stable"}]}}'
```

Kết quả:

```text
pod/inc01-obj01 patched
```

Kiểm tra image sau khi patch:

```bash
kubectl get pod inc01-obj01 -n troubleshooting-lab \
  -o jsonpath='{.spec.containers[0].image}'
# nginx:stable
```

### 8.2. Pod state sau recovery

```text
NAME          READY   STATUS    RESTARTS   AGE    IP              NODE
inc01-obj01   1/1     Running   0          3m6s   192.168.80.99   k8s-monitoring-01
```

### 8.3. Container logs

Trích `kubectl logs inc01-obj01 -n troubleshooting-lab -c web --tail=30`:

```text
/docker-entrypoint.sh: Configuration complete; ready for start up
2026/10/12 16:02:19 [notice] 1#1: nginx/1.30.5
2026/10/12 16:02:19 [notice] 1#1: start worker processes
```

### 8.4. HTTP functional test

```bash
curl -i --max-time 10 http://127.0.0.1:18080/
```

Response:

```http
HTTP/1.1 200 OK
Server: nginx/1.30.5
Date: Mon, 12 Oct 2026 16:03:05 GMT
Content-Type: text/html
```

HTML body trả về trang **Welcome to nginx!**. HTTP request đã thành công tại endpoint local. Lệnh khởi tạo `kubectl port-forward` không nằm trong transcript hiện có nên chưa thể independently audit kết nối cụ thể từ local port 18080 đến Pod `inc01-obj01`; trạng thái Pod Ready và logs Nginx đã xác nhận khôi phục container. Khi lưu evidence chính thức, ghi thêm output/command `port-forward`.

### 8.5. Verification summary

| Tiêu chí | Kết quả |
|---|---|
| Image tag lỗi được chứng minh | **PASS** — `NotFound` |
| Image sau sửa | **PASS** — `nginx:stable` |
| Pod Ready | **PASS** — `1/1 Running` |
| Container khởi động | **PASS** — Nginx logs |
| HTTP endpoint local | **PASS** — `200 OK` |
| Service/Ingress (không có trong manifest INC-01) | **Not applicable** |
| Audit port-forward tới đúng Pod | **Bổ sung nếu lưu evidence có thể tái kiểm tra** |

**Incident state:** `RESOLVED` đối với lỗi image pull của Pod lab; phần CAPA dài hạn vẫn theo dõi riêng.

## 9. Corrective & preventive actions

| ID | Hành động | Loại | Trạng thái | Tiêu chí hoàn thành |
|---|---|---|---|---|
| CA-01 | Patch Pod để khôi phục image | Recovery | **Done** | Pod `1/1 Running`; Nginx started |
| CA-02 | Xác minh HTTP local endpoint | Validation | **Done** | `HTTP 200` |
| PA-01 | Áp dụng kiểm tra image/tag tồn tại ở pipeline release production | Prevention (đề xuất) | **Proposed** | Pipeline chặn tag không tìm thấy |
| PA-02 | Viết/duy trì Runbook ImagePullBackOff | Documentation | **Existing draft; review pending** | Runbook được thực hành và review |
| PA-03 | Thiết lập và thử nghiệm alert image pull failure | Detection (đề xuất) | **Proposed** | Alert thực sự kích hoạt trong test |

Owner, deadline, ticket liên quan: `[Bổ sung khi triển khai action]`.

## 10. Lessons learned & closure

- `ImagePullBackOff` là triệu chứng; root cause chỉ được xác nhận khi có bằng chứng chi tiết từ Events hoặc registry.
- Lỗi này **không** xuất phát từ việc Pod không được schedule: `PodScheduled=True`.
- Patch image có thể khôi phục nhanh **Pod độc lập**. Không nên sửa manifest cố ý tạo lỗi trong Operator Pack nếu muốn tái hiện bài lab.
- Với Deployment/Argo CD, thay đổi lâu dài phải được cập nhật ở Git/manifest nguồn để tránh drift.
- Ghi rõ lần tái hiện sự cố và thời điểm UTC; không gộp Pod age của lần trước với recovery của lần sau.
- Recovery được xác minh tách biệt khỏi hoàn thành các biện pháp phòng ngừa (CAPA).

**Kết luận cuối:** INC-001 được khôi phục thành công trong môi trường lab. **Confirmed root cause:** nonexistent image tag `nginx:tag-does-not-exist-troubleshooting`. **Observed recovery:** `nginx:stable` → Pod `1/1 Running`, Nginx khởi động, local HTTP `200 OK`. Không có bằng chứng ảnh hưởng production.

### Bước dọn lab (chỉ chạy khi đã lưu bằng chứng)

```bash
# Chạy trong operator-fault-injector, sau khi kiểm tra namespace/context
./operator.sh stop 01
```

Không chạy `operator.sh reset` để tránh xóa cả namespace chứa các bài lab khác.
