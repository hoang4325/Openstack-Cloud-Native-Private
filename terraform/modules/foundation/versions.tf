# Module chỉ khai báo provider cần dùng; cấu hình provider (cloud, region) nằm ở environment.
terraform {
  required_version = ">= 1.8.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.4"
    }
  }
}
