locals {
  cluster_tags = concat(["kubernetes"], var.common_tags)
}

# Mạng riêng dành cho các node Kubernetes.
resource "openstack_networking_network_v2" "this" {
  name           = var.network.name
  admin_state_up = true
  tags           = local.cluster_tags
}

# Subnet IPv4 của mạng Kubernetes.
resource "openstack_networking_subnet_v2" "this" {
  name            = var.network.subnet_name
  network_id      = openstack_networking_network_v2.this.id
  cidr            = var.network.cidr
  ip_version      = 4
  gateway_ip      = var.network.gateway_ip
  enable_dhcp     = var.network.enable_dhcp
  dns_nameservers = var.network.dns_nameservers
  tags            = local.cluster_tags
}

# Router nối mạng Kubernetes với mạng external.
resource "openstack_networking_router_v2" "this" {
  name                = var.network.router_name
  admin_state_up      = true
  external_network_id = var.external.network_id
  enable_snat         = var.network.enable_snat
  tags                = local.cluster_tags
}

# Gắn subnet Kubernetes vào router.
resource "openstack_networking_router_interface_v2" "this" {
  router_id = openstack_networking_router_v2.this.id
  subnet_id = openstack_networking_subnet_v2.this.id
}
