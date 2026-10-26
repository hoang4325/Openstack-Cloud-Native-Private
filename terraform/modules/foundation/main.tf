locals {
  external_tags = concat(["external"], var.common_tags)
}

# Tải và đăng ký image Ubuntu dùng cho các máy ảo.
resource "openstack_images_image_v2" "this" {
  name             = var.image.name
  image_source_url = var.image.source_url
  container_format = var.image.container_format
  disk_format      = var.image.disk_format
  visibility       = var.image.visibility
  min_disk_gb      = var.image.min_disk_gb
  tags             = concat(var.image.tags, var.common_tags)
}

# Tạo flavor cho từng phần tử của var.flavors.
resource "openstack_compute_flavor_v2" "this" {
  for_each = var.flavors

  name      = each.key
  ram       = each.value.ram_mb
  vcpus     = each.value.vcpus
  disk      = each.value.disk_gb
  is_public = each.value.is_public
}

# Đăng ký public key SSH để truy cập các máy ảo.
resource "openstack_compute_keypair_v2" "this" {
  name       = var.keypair.name
  public_key = var.keypair.public_key
}

# Mạng external ánh xạ vào physical network của Neutron.
resource "openstack_networking_network_v2" "external" {
  name           = var.external_network.name
  admin_state_up = true
  external       = true
  shared         = var.external_network.shared

  segments {
    network_type     = var.external_network.network_type
    physical_network = var.external_network.physical_network
  }

  tags = local.external_tags
}

# Subnet public và dải IP dùng để cấp floating IP.
resource "openstack_networking_subnet_v2" "external" {
  name        = var.external_network.subnet_name
  network_id  = openstack_networking_network_v2.external.id
  cidr        = var.external_network.cidr
  ip_version  = 4
  gateway_ip  = var.external_network.gateway_ip
  enable_dhcp = var.external_network.enable_dhcp

  allocation_pool {
    start = var.external_network.allocation_pool_start
    end   = var.external_network.allocation_pool_end
  }

  tags = local.external_tags
}
