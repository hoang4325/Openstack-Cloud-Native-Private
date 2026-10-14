# Blind troubleshooting – Người học

Bộ này **không chứa** `broken.yaml`, `fixed.yaml`, root cause, đáp án, hoặc lệnh sửa cụ thể.

## Quy tắc luyện tập

1. Nhờ người khác chạy **Operator Pack** để kích hoạt ticket, hoặc tự chạy `./operator.sh start NN` mà **không đọc thư mục `manifests/`**. Để thực sự blind thì một người khác phải làm operator: người có quyền xem source của injector có thể tra đáp án gián tiếp.
2. Chỉ nhận thông báo ticket và kiểm tra các tài nguyên trong namespace `troubleshooting-lab`.
3. Điều tra như incident thật: xác định impact → giả thuyết → chứng cứ → sửa **bằng lệnh hoặc YAML do chính bạn viết** → kiểm chứng.
4. Không được gọi công cụ tự động fix; operator chỉ hỗ trợ khởi tạo sự cố và dọn tài nguyên.
5. Với ticket có nhãn `RUNBOOK`, **không có lỗi được tiêm vào cluster**. Đây là sự cố giả định để luyện tư duy và viết kế hoạch điều tra; đừng tuyên bố đã khôi phục trên cluster thật.
6. Với ticket có nhãn `QUERY`, không tiêm lỗi, chỉ thực hành xác minh một giả định bằng lệnh đọc.

## Tài nguyên

- `tickets/NN.md`: đề bài của từng incident, không có giải pháp.
- `INCIDENT_TEMPLATE.md`: mẫu ghi nhận giả thuyết, bằng chứng và RCA.
- `triage.sh`: các lệnh đọc trạng thái, **không sửa cluster**.

## Bắt đầu (trên k8s-control-01 hoặc host có kubeconfig)

```bash
kubectl config current-context
# nhờ operator khởi tạo namespace và kích hoạt case
./triage.sh snapshot
cat tickets/01.md
```

Không sửa namespace `monitoring`, `argocd`, `kube-system`; không tắt node, kubelet, Calico để làm bài. Hãy hoàn thành việc điều tra trước khi tìm lời giải.
