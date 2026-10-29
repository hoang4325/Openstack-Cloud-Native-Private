# RUNBOOK 05 — Monitoring & Telegram Alerting

**Trạng thái:** `COMPLETED` cho metrics và tuyến alert E2E lab; Grafana dashboard tùy biến/GitOps JSON chưa được chứng minh hoàn tất trong bộ log này.

## 1. Thành phần

- `kube-prometheus-stack` Helm chart **92.14.1** theo `gitops/applications/monitoring.yaml`: Prometheus, Grafana, Alertmanager, kube-state-metrics, node-exporter, Prometheus Operator.
- Node monitoring: `k8s-monitoring-01`; PVC Cinder cho Prometheus/Grafana/Alertmanager.
- MongoDB exporter `percona/mongodb_exporter:0.39` + `ServiceMonitor/mongodb-exporter` trong `student`.
- Spring Boot Actuator/Micrometer: `/actuator/prometheus`, `ServiceMonitor/student-api` với label `release: monitoring`.
- Alert Rules: `mongodb-alerts` (MongoDBDown, ExporterDown, PodRestarting, PVCUsageHigh, BackupJobFailed, BackupStale) và `student-api-alerts` (StudentAPIDown, StudentAPIHigh5xx).
- `AlertmanagerConfig/mongodb-telegram` trong namespace `student`, tham chiếu Secret `alertmanager-telegram-bot`; token **không lưu trong repo**. Alertmanager chọn config theo labels/namespace.

## 2. Bằng chứng nghiệm thu đã ghi nhận

| Hạng mục | Kết quả thực tế |
|---|---|
| Node monitoring | `count(kube_node_status_condition{condition="Ready",status="true"} == 1)` → 4 |
| MongoDB exporter | `mongodb_up=1` và `up{namespace="student",service="mongodb-exporter"}=1` |
| Spring Boot metrics | `/actuator/prometheus` HTTP 200, JVM/HTTP metrics; API scrape `up=1` qua Grafana |
| Student API rules | `StudentAPIDown`, `StudentAPIHigh5xx`: `inactive`, `health=ok` |
| MongoDB backup rules | `MongoDBBackupJobFailed`, `MongoDBBackupStale`: `inactive`, `health=ok` |
| Telegram | Synthetic E2E test tới Telegram; Backup Job Failed drill và Stale drill cũng gửi thông báo |
| Backup success metric | `kube_cronjob_status_last_successful_time = 1793239208` lúc 09:00:08 29/10/2026 (lần kiểm thử lịch 09:00) |
| GitOps status cuối | Cả ba Applications `Synced/Healthy` |

`health=ok` = rule đánh giá không lỗi, **không tự động chứng minh chuỗi alert đã firing**. Bài test Telegram đã bổ sung bằng chứng E2E. Stale drill là mô phỏng thời gian trong PromQL, không phải production thực sự bỏ lỡ lịch.

## 3. Lệnh quan sát (read-only)

```bash
kubectl -n monitoring get pods,svc,pvc -o wide
kubectl -n student get servicemonitors,prometheusrules,alertmanagerconfigs
kubectl -n argocd get applications
```

Port-forward Prometheus ở terminal 1:

```bash
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
```

Terminal 2:

```bash
curl -fsS http://127.0.0.1:9090/-/ready
curl -fsSG http://127.0.0.1:9090/api/v1/query --data-urlencode 'query=mongodb_up{namespace="student"}'
curl -fsSG http://127.0.0.1:9090/api/v1/query --data-urlencode 'query=up{namespace="student",service="api"}'
curl -fsS 'http://127.0.0.1:9090/api/v1/rules?type=alert' | jq -r '.data.groups[].rules[] | select(.name | startswith("MongoDB") or startswith("StudentAPI")) | "\(.name) | \(.state) | \(.health)"'
```

**Lưu ý:** Nếu `curl: (7) Failed to connect ... 9090`, kiểm tra **port-forward terminal** trước; không suy ra Prometheus đã down.

## 4. PromQL tham khảo

```promql
up{namespace="student",service="api"}
mongodb_up{namespace="student"}
sum(jvm_memory_used_bytes{application="student-app-api",area="heap"}) / 1024 / 1024
sum(rate(http_server_requests_seconds_count{application="student-app-api",uri!~"/actuator/.*"}[5m]))
count(kube_node_status_condition{condition="Ready",status="true"} == 1)
kube_cronjob_status_last_successful_time{namespace="student",cronjob="mongodb-daily-backup"}
```

Nếu HTTP histogram `_bucket` chưa được cấu hình trong Micrometer, chưa thể tự động tính P95/P99 với `histogram_quantile`.

## 5. Quy trình xử lý alert

1. Xác định `alertname`, `severity`, `namespace`, thời điểm firing, mô tả từ Telegram.
2. Mở Prometheus/Grafana để xác thực metric/target; loại trừ thiếu metric và port-forward hết hạn.
3. Xem `kubectl -n student get pods,job,cronjob`, `kubectl describe` và `kubectl logs` liên quan.
4. Thao tác khắc phục phải theo runbook ứng dụng/storage/backup; không xóa dữ liệu hay restart toàn cụm khi chưa có root cause.
5. Kiểm tra trạng thái `resolved`, ghi nhận incident timeline và bằng chứng.

## 6. Test E2E và an toàn

**Đã kiểm chứng:** Student API smoke alert, MongoDBBackupJobFailed (Job cố ý exit 1), MongoDBBackupStaleDrill (rule PromQL tạm); người vận hành xác nhận nhận Telegram. Các resource thử nghiệm đã được hướng dẫn dọn sau test. Không lặp lại trên production nếu không có lịch diễn tập.

**Tránh:** commit bot token, thay Secret Grafana tùy tiện, xoá monitoring PVC, Sync Argo CD với Prune/Force/Replace không kiểm soát.

**Source:** `gitops/applications/monitoring.yaml`, `kubernetes/databases/student-mongodb/mongodb-{exporter,alerts,telegram-alertmanagerconfig}.yaml`, `kubernetes/apps/student-management/backend-{servicemonitor,alerts}.yaml`.
