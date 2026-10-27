# Operator Pack — Chỉ người tạo sự cố sử dụng

Pack này chứa manifest **cố ý bị lỗi**. **Không gửi thư mục `manifests/` cho người học.**
Không có `fixed.yaml`; tất cả giải pháp và RCA phải do người học tự thực hiện.

Đặt pack ở máy có kubeconfig (ví dụ `k8s-control-01`), không nên để chung thư mục với Student Pack nếu muốn bài thực sự blind.

```bash
./operator.sh init          # baseline namespace
./operator.sh list          # xem các số có thể inject
./operator.sh start 01      # tạo sự cố 01, không in YAML
./operator.sh stop 01       # dọn các tài nguyên khai báo trong ticket
./operator.sh reset        # xóa TOÀN namespace troubleshooting-lab, sau khi chắc chắn không còn bài khác
```

**28 ticket có injection.** Ticket 12,34 chỉ truy vấn; 30 ticket khác là giả định/runbook, **không có thể tạo lỗi tự động**.

Giới hạn an toàn: chỉ tài nguyên namespaced trong `troubleshooting-lab`; các case 31,32,33,38,39 có ServiceMonitor/PrometheusRule có thể ảnh hưởng tới trạng thái quan sát toàn cluster. Operator sẽ chặn trừ khi thêm `--allow-monitoring` sau số lab và tự xác minh selector trước.

Một người tự học có thể chạy script mà không xem source, nhưng **blind tuyệt đối không thể đảm bảo nếu họ sở hữu pack operator**. Để blind thật, nhờ người khác làm operator và chỉ dùng Student Pack.
