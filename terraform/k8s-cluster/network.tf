# Tạo mạng riêng dành cho các node Kubernetes.
resource "openstack_networking_network_v2" "k8s" {
  name           = var.tenant_network_name
  admin_state_up = true
  tags           = ["kubernetes", "terraform-managed"]
}

# Tạo subnet IPv4 và bật DHCP cho mạng Kubernetes.
resource "openstack_networking_subnet_v2" "k8s" {
  name            = var.tenant_subnet_name
  network_id      = openstack_networking_network_v2.k8s.id
  cidr            = var.tenant_cidr
  ip_version      = 4
  gateway_ip      = var.tenant_gateway
  enable_dhcp     = true
  dns_nameservers = var.dns_nameservers
  tags            = ["kubernetes", "terraform-managed"]
}

# Tạo router kết nối mạng Kubernetes với mạng bên ngoài.
resource "openstack_networking_router_v2" "k8s" {
  name                = var.router_name
  admin_state_up      = true
  external_network_id = data.terraform_remote_state.foundation.outputs.external_network_id
  enable_snat         = true
  tags                = ["kubernetes", "terraform-managed"]
}

# Kết nối subnet Kubernetes vào router.
resource "openstack_networking_router_interface_v2" "k8s" {
  router_id = openstack_networking_router_v2.k8s.id
  subnet_id = openstack_networking_subnet_v2.k8s.id
}
