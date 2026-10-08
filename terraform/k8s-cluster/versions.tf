# Khai báo phiên bản Terraform và phiên bản provider OpenStack bắt buộc.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "= 3.4.0"
    }
  }
}
