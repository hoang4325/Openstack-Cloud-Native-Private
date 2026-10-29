# RUNBOOK 01 — OpenStack AIO & Terraform Infrastructure

**Dự án:** `hoang4325/Openstack-Cloud-Native-Private`  
**Phạm vi:** Private Cloud Lab, OpenStack Kolla-Ansible AIO, Terraform foundation + k8s-cluster  
**Trạng thái:** Đã triển khai và từng kiểm tra OpenStack/Kubernetes VM; tài liệu này là runbook **vận hành**, không phải lệnh tái tạo trên hệ thống đang chạy.

## 1. Kiến trúc và nguồn cấu hình

OpenStack AIO gồm Keystone, Nova, Neutron, Glance và Cinder LVM. Terraform chia thành hai root module:

- `terraform/environments/lab/foundation`: Ubuntu image, flavors, SSH keypair, external network/subnet.
- `terraform/environments/lab/k8s-cluster`: tenant network `10.20.0.0/24`, router, security group, fixed-IP ports, VM, floating IP; đọc state `../foundation/terraform.tfstate`.
- Module dùng chung: `terraform/modules/foundation/`, `terraform/modules/k8s-cluster/`.
- Cloud profile: `kolla-admin`; region: `RegionOne` (theo cấu hình repository).

Cụm đang được vận hành có 4 VM (xác nhận trước đó qua `kubectl get nodes`): `k8s-control-01` (`10.20.0.10`), `k8s-worker-01` (`.11`), `k8s-monitoring-01` (`.12`), `k8s-deploy-01` (`.13`). **Chú ý:** `terraform.tfvars.example` của cluster chỉ có 3 node, nhưng `variables.tf` có default cho 4 node; xem *live Terraform state* trước khi kết luận VM nào đang do Terraform quản lý.

## 2. Kiểm tra vận hành (read-only)

Thực hiện trên host cài `openstack` CLI và có quyền đọc cấu hình cloud:

```bash
export OS_CLOUD=kolla-admin
openstack token issue
openstack service list
openstack compute service list
openstack network agent list
openstack server list --long
openstack network list
openstack subnet list
openstack router list
openstack volume service list
openstack volume list
```

Kiểm tra Terraform state (không sửa tài nguyên):

```bash
terraform -chdir=terraform/environments/lab/foundation output
terraform -chdir=terraform/environments/lab/k8s-cluster output -json nodes
terraform -chdir=terraform/environments/lab/k8s-cluster state list
```

Chỉ xem `terraform plan` sau khi kiểm tra đúng cloud, variables, backend/state; `plan` có thể gọi API và không phải bằng chứng tài nguyên đã được triển khai. **Không chạy `terraform apply` hoặc `terraform destroy` trên lab đang hoạt động để làm lại bài test.**

## 3. Kiểm chứng và bằng chứng lịch sử

- OpenStack AIO đã cung cấp VM, networks và block storage cho Kubernetes 4 node.
- Cinder volume từng tạo được qua CSI; xem `03_Cinder_CSI_Storage.md`.
- Sự cố OpenStack API từng được xử lý bằng kiểm tra địa chỉ VIP/API, khôi phục truy cập Keystone/Nova và kiểm chứng CLI; xem `08_Incident_OpenStack_API.md`.
- Terraform configuration hiện tại có tài nguyên và outputs đã version-control. **Không có log `terraform apply` gốc trong bộ chứng cứ hiện cung cấp**, nên không đánh dấu mọi resource Terraform là đã kiểm thử tái tạo từ đầu.

## 4. Checklist khi mất API/VM

1. Phân biệt *API không phản hồi* với *VM không chạy*: `openstack token issue`, `openstack server list`; xem Kolla containers trên AIO.
2. Kiểm tra VIP/API endpoint, route và network interface trên host: `ip -br addr`, `ip route`, `ss -lntp`.
3. Kiểm tra Nova compute, Neutron agents và VM/hypervisor; không xóa ports hoặc VM để thử.
4. Kiểm tra Cinder backend (`openstack volume service list`, `openstack volume list`) trước khi thao tác storage.
5. Ghi nhận thời điểm, lỗi CLI, thay đổi cấu hình, và evidence sau phục hồi.

## 5. Quy tắc an toàn

- Không thay đổi `clouds.yaml`, Kolla config, API VIP hoặc Terraform state dựa trên phỏng đoán.
- Không commit credentials, `*.tfstate`, `terraform.tfvars`, private key hay Kolla secrets.
- Không tạo lại VG/LVM/Cinder backend trên volume đã chứa dữ liệu.
- Floating IP có thể đổi; dùng `terraform output`, không hard-code FIP từ môi trường lịch sử.

## 6. Tiêu chí kiểm tra định kỳ

- Token issue thành công; Keystone/Nova/Neutron/Cinder không trả lỗi.
- Các VM thuộc cluster `ACTIVE`; node K8s `Ready`.
- State Terraform đọc được, cloud/region đúng, chưa có thao tác quản lý hạ tầng ngoài kế hoạch.

**Source:** `terraform/environments/lab/**`, `terraform/modules/**`; [repository](https://github.com/hoang4325/Openstack-Cloud-Native-Private).
