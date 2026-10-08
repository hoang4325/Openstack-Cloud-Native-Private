# Khai báo provider OpenStack và thông tin cloud/region sử dụng.
provider "openstack" {
  cloud  = var.cloud_name
  region = var.region
}
