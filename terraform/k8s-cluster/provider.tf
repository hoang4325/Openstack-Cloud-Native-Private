# Khai báo provider OpenStack và thông tin cloud/region sử dụng.
provider "openstack" {
  cloud  = var.cloud_name
  region = var.region
}

# Đọc các tài nguyên nền tảng từ state Terraform cục bộ của module OpenStack.
data "terraform_remote_state" "foundation" {
  backend = "local"
  config  = { path = "../openstack/terraform.tfstate" }
}
