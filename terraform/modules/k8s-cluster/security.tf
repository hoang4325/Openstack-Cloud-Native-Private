# Security group chung cho các node Kubernetes. Không giữ rule mặc định, mọi rule khai báo qua var.security_group_rules.
resource "openstack_networking_secgroup_v2" "nodes" {
  name                 = var.security_group.name
  description          = var.security_group.description
  delete_default_rules = true
}

# Mỗi phần tử của var.security_group_rules là một rule.
resource "openstack_networking_secgroup_rule_v2" "nodes" {
  for_each = var.security_group_rules

  direction         = each.value.direction
  ethertype         = each.value.ethertype
  protocol          = each.value.protocol
  port_range_min    = each.value.port_min
  port_range_max    = each.value.port_max
  remote_ip_prefix  = each.value.remote_ip_prefix
  security_group_id = openstack_networking_secgroup_v2.nodes.id
}
