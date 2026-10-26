output "image_id" {
  description = "ID của image Ubuntu đã đăng ký."
  value       = openstack_images_image_v2.this.id
}

output "image_name" {
  description = "Tên của image Ubuntu đã đăng ký."
  value       = openstack_images_image_v2.this.name
}

output "flavor_ids" {
  description = "Map tên flavor => ID flavor."
  value       = { for name, flavor in openstack_compute_flavor_v2.this : name => flavor.id }
}

output "keypair_name" {
  description = "Tên keypair SSH."
  value       = openstack_compute_keypair_v2.this.name
}

output "external_network_id" {
  description = "ID của mạng external."
  value       = openstack_networking_network_v2.external.id
}

output "external_network_name" {
  description = "Tên của mạng external."
  value       = openstack_networking_network_v2.external.name
}

output "external_subnet_id" {
  description = "ID của subnet external."
  value       = openstack_networking_subnet_v2.external.id
}
