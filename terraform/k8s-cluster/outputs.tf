# Xuất địa chỉ IP cố định của node control plane.
output "control_fixed_ip" { value = var.control_fixed_ip }
# Xuất địa chỉ IP nổi của node control plane.
output "control_floating_ip" { value = openstack_networking_floatingip_v2.control.address }
# Xuất địa chỉ IP cố định của node worker.
output "worker_fixed_ip" { value = var.worker_fixed_ip }
# Xuất địa chỉ IP nổi của node worker.
output "worker_floating_ip" { value = openstack_networking_floatingip_v2.worker.address }
# Xuất các lệnh SSH dùng để truy cập hai node Kubernetes.
output "ssh_commands" {
  value = {
    control = "ssh ubuntu@${openstack_networking_floatingip_v2.control.address}"
    worker  = "ssh ubuntu@${openstack_networking_floatingip_v2.worker.address}"
  }
}

output "monitoring_fixed_ip" {
  value = var.monitoring_fixed_ip
}

output "monitoring_floating_ip" {
  value = openstack_networking_floatingip_v2.monitoring.address
}
