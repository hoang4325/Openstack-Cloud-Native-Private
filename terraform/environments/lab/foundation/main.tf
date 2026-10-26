# Môi trường lab: gọi module foundation với cấu hình của lab.
module "foundation" {
  source = "../../../modules/foundation"

  image = {
    name        = var.ubuntu_image_name
    source_url  = var.ubuntu_image_url
    min_disk_gb = var.image_min_disk_gb
    tags        = var.image_tags
  }

  flavors = var.flavors

  keypair = {
    name       = var.keypair_name
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  external_network = {
    name                  = var.external_network_name
    subnet_name           = var.external_subnet_name
    physical_network      = var.external_physical_network
    cidr                  = var.external_cidr
    gateway_ip            = var.external_gateway
    allocation_pool_start = var.floating_ip_start
    allocation_pool_end   = var.floating_ip_end
  }

  common_tags = var.common_tags
}
