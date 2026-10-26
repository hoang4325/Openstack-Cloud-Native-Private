output "nodes" {
  description = "Thông tin từng node: role, IP cố định, floating IP và lệnh SSH."
  value       = module.k8s_cluster.nodes
}

output "floating_ips" {
  description = "Map tên node => floating IP. Dùng giá trị này để điền ansible/inventory/hosts.ini."
  value       = module.k8s_cluster.floating_ips
}
