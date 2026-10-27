# Khai báo phiên bản Terraform và phiên bản provider OpenStack bắt buộc.
terraform {
  required_version = ">= 1.8.0" # module dùng cidrcontains()
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "= 3.4.0"
    }
  }
}
