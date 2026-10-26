locals {
  # Chỉ các node có floating_ip = true mới được cấp floating IP.
  floating_ip_nodes = { for name, node in var.nodes : name => node if node.floating_ip }
}

# Cổng mạng với IP cố định cho từng node.
resource "openstack_networking_port_v2" "node" {
  for_each = var.nodes

  name               = "${each.key}-port"
  network_id         = openstack_networking_network_v2.this.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.nodes.id]

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.this.id
    ip_address = each.value.fixed_ip
  }

}

# Máy ảo cho từng node.
resource "openstack_compute_instance_v2" "node" {
  for_each = var.nodes

  name      = each.key
  image_id  = var.image_id
  flavor_id = var.flavor_ids[each.value.flavor]
  key_pair  = var.keypair_name

  network {
    port = openstack_networking_port_v2.node[each.key].id
  }

  depends_on = [openstack_networking_router_interface_v2.this]

  lifecycle {
    precondition {
      condition     = contains(keys(var.flavor_ids), each.value.flavor)
      error_message = "Node ${each.key} dùng flavor ${each.value.flavor} nhưng flavor này không có trong flavor_ids."
    }
  }
}

# Floating IP gắn vào cổng mạng của node.
resource "openstack_networking_floatingip_v2" "node" {
  for_each = local.floating_ip_nodes

  pool        = var.external.network_name
  subnet_id   = var.external.subnet_id
  port_id     = openstack_networking_port_v2.node[each.key].id
  description = coalesce(each.value.floating_ip_description, "Floating IP for ${each.key}")

  depends_on = [openstack_networking_router_interface_v2.this]
}
