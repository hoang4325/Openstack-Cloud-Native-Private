# Tạo cổng mạng và gán IP cố định cho node control plane.
resource "openstack_networking_port_v2" "control" {
  name               = "${var.control_name}-port"
  network_id         = openstack_networking_network_v2.k8s.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.k8s_nodes.id]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s.id
    ip_address = var.control_fixed_ip
  }
}

# Tạo cổng mạng và gán IP cố định cho node worker.
resource "openstack_networking_port_v2" "worker" {
  name               = "${var.worker_name}-port"
  network_id         = openstack_networking_network_v2.k8s.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.k8s_nodes.id]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s.id
    ip_address = var.worker_fixed_ip
  }
}

resource "openstack_networking_port_v2" "monitoring" {
  name           = "${var.monitoring_name}-port"
  network_id     = openstack_networking_network_v2.k8s.id
  admin_state_up = true

  security_group_ids = [
    openstack_networking_secgroup_v2.k8s_nodes.id
  ]

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.k8s.id
    ip_address = var.monitoring_fixed_ip
  }
}