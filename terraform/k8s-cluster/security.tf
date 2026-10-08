# Tạo security group dành cho các node Kubernetes.
resource "openstack_networking_secgroup_v2" "k8s_nodes" {
  name                 = var.security_group_name
  description          = "Security group for Kubernetes nodes"
  delete_default_rules = true
}

# Cho phép lưu lượng IPv4 đi ra ngoài từ các node Kubernetes.
resource "openstack_networking_secgroup_rule_v2" "egress_ipv4" {
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.k8s_nodes.id
}

# Cho phép kết nối SSH vào các node từ dải mạng được chỉ định.
resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.ssh_allowed_cidr
  security_group_id = openstack_networking_secgroup_v2.k8s_nodes.id
}

# Cho phép lưu lượng ICMP phục vụ kiểm tra kết nối mạng.
resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_nodes.id
}

# Cho phép các node trong subnet Kubernetes giao tiếp nội bộ.
resource "openstack_networking_secgroup_rule_v2" "cluster_internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = var.tenant_cidr
  security_group_id = openstack_networking_secgroup_v2.k8s_nodes.id
}
