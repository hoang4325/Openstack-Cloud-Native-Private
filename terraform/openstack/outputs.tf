# Xuất ID của image Ubuntu đã đăng ký.
output "image_id" { value = openstack_images_image_v2.ubuntu_noble.id }
# Xuất tên của image Ubuntu đã đăng ký.
output "image_name" { value = openstack_images_image_v2.ubuntu_noble.name }
# Xuất ID của flavor dành cho Kubernetes.
output "flavor_id" { value = openstack_compute_flavor_v2.k8s_small.id }
# Xuất tên của flavor dành cho Kubernetes.
output "flavor_name" { value = openstack_compute_flavor_v2.k8s_small.name }
# Xuất tên keypair SSH đã đăng ký.
output "keypair_name" { value = openstack_compute_keypair_v2.lab.name }
# Xuất ID của mạng bên ngoài.
output "external_network_id" { value = openstack_networking_network_v2.external.id }
# Xuất tên của mạng bên ngoài.
output "external_network_name" { value = openstack_networking_network_v2.external.name }
# Xuất ID của subnet bên ngoài.
output "external_subnet_id" { value = openstack_networking_subnet_v2.external.id }
output "monitoring_flavor_id" {
  value = openstack_compute_flavor_v2.k8s_monitoring.id
}