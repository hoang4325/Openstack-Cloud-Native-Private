# Tạo mạng vật lý bên ngoài để cấp kết nối public cho OpenStack.
resource "openstack_networking_network_v2" "external" {
  name           = var.external_network_name
  admin_state_up = true
  external       = true
  shared         = true
  segments {
    network_type     = "flat"
    physical_network = var.external_physical_network
  }
  tags = ["external", "terraform-managed"]
}

# Tạo subnet public và dải IP dùng để cấp floating IP.
resource "openstack_networking_subnet_v2" "external" {
  name        = var.external_subnet_name
  network_id  = openstack_networking_network_v2.external.id
  cidr        = var.external_cidr
  ip_version  = 4
  gateway_ip  = var.external_gateway
  enable_dhcp = false
  allocation_pool {
    start = var.floating_ip_start
    end   = var.floating_ip_end
  }
  tags = ["external", "terraform-managed"]
}
