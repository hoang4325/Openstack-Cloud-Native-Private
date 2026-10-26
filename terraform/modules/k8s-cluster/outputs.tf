output "nodes" {
  description = "Thông tin từng node: role, IP cố định, floating IP và lệnh SSH."
  value = {
    for name, node in var.nodes : name => {
      role        = node.role
      fixed_ip    = node.fixed_ip
      floating_ip = try(openstack_networking_floatingip_v2.node[name].address, null)
      ssh         = try("ssh ${var.ssh_user}@${openstack_networking_floatingip_v2.node[name].address}", null)
    }
  }
}

output "floating_ips" {
  description = "Map tên node => floating IP (chỉ gồm node có floating IP)."
  value       = { for name, fip in openstack_networking_floatingip_v2.node : name => fip.address }
}

output "network_id" {
  description = "ID mạng tenant của cụm."
  value       = openstack_networking_network_v2.this.id
}

output "router_id" {
  description = "ID router của cụm."
  value       = openstack_networking_router_v2.this.id
}

output "security_group_id" {
  description = "ID security group của các node."
  value       = openstack_networking_secgroup_v2.nodes.id
}
