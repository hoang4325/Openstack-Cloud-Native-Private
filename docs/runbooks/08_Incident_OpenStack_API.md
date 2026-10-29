# RUNBOOK 08 — OpenStack API/CLI mất kết nối (Incident Record)

**Mục tiêu:** lưu lại sự cố OpenStack API từng gặp và cách khoanh vùng đã có bằng chứng; đây **không phải** hướng dẫn gán IP mới trên host đang chạy nếu thiếu đánh giá.

## 1. Triệu chứng lịch sử

- OpenStack CLI từng không phản hồi hoặc request Keystone/Nova lỗi trong khi host Kolla AIO vẫn chạy.
- Địa chỉ API/VIP `10.10.1.3` bị thiếu binding phù hợp trên host.
- Người vận hành từng kiểm tra endpoint HTTP, issuance Keystone token và `openstack server list` sau khi sửa đường truy cập API.

## 2. Các bước kiểm tra read-only (nfs/cluster không liên quan)

Trên **OpenStack AIO host**:

```bash
ip -br addr
ip route
ss -lntp | grep -E ':(5000|8774|9696|9292)\\b' || true
# Nếu host chạy Kolla bằng Docker:
docker ps --format 'table {{.Names}}\\t{{.Status}}'
```

Trên máy có OpenStack CLI và credentials:

```bash
openstack --os-cloud kolla-admin token issue
openstack --os-cloud kolla-admin endpoint list
openstack --os-cloud kolla-admin server list
```

Nên kiểm tra cấu hình VIP/API và endpoint catalog, phân biệt DNS/routing/tcp timeout với 401/403 do token/role.

## 3. Bằng chứng xử lý trước đây

- Trong phiên lab cũ, phép gán IP API VIP `10.10.1.3/32` trên loopback của host từng khôi phục truy cập HTTP 200, token issue và `openstack server list`.
- Đây là **biện pháp thử tạm thời** đã từng thành công; không khuyến cáo lặp lại lệnh gán IP nếu chưa xác nhận host, VIP ownership, Keepalived/HAProxy và cấu hình mạng hiện tại.
- Ý tưởng khắc phục bền vững khi đó: một dummy interface quản lý API VIP, đối chiếu `api_interface` và chính sách Keepalived của Kolla, nhưng **chưa có bằng chứng hiện tại rằng cấu hình bền vững này đã được áp dụng và nghiệm thu**.

## 4. Khi sự cố tái diễn

1. Ghi thời gian/endpoint lỗi, số VM ảnh hưởng, lỗi CLI/HTTP cụ thể.
2. Kiểm tra interface có chứa VIP không, service proxy API có lắng nghe không.
3. So sánh Kolla globals/config thực tế với tài liệu phiên bản đang chạy.
4. Xây dựng change plan/backup configuration trước khi tác động network trên AIO.
5. Sau khi thay đổi có phê duyệt, kiểm chứng token issuance, endpoint list, server list, workload Kubernetes vẫn `Ready` và PVC vẫn `Bound`.
6. Ghi RCA với trigger/root cause đã chứng minh, corrective action và preventive action.

## 5. Nguyên tắc an toàn

- Không restart toàn bộ Kolla/Docker, không sửa Keepalived và API VIP theo hướng dẫn chung khi chưa xác minh phiên bản/cấu hình.
- Không dùng `kolla-ansible reconfigure` hoặc `terraform apply` như bước chẩn đoán đầu tiên.
- Không ghi OpenStack credentials vào báo cáo/terminal paste.

**Source:** bằng chứng trao đổi về incident API OpenStack ngày 27/10/2026; chưa có file cấu hình Kolla host tương ứng được cung cấp trong repo.
