# Các output này được environment k8s-cluster đọc qua terraform_remote_state.
output "image_id" {
  value = module.foundation.image_id
}

output "image_name" {
  value = module.foundation.image_name
}

output "flavor_ids" {
  value = module.foundation.flavor_ids
}

output "keypair_name" {
  value = module.foundation.keypair_name
}

output "external_network_id" {
  value = module.foundation.external_network_id
}

output "external_network_name" {
  value = module.foundation.external_network_name
}

output "external_subnet_id" {
  value = module.foundation.external_subnet_id
}
