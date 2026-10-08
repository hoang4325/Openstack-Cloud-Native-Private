# Cấp floating IP cho node control plane và gắn IP vào cổng mạng tương ứng.
resource "openstack_networking_floatingip_v2" "control" {
  pool        = data.terraform_remote_state.foundation.outputs.external_network_name
  subnet_id   = data.terraform_remote_state.foundation.outputs.external_subnet_id
  port_id     = openstack_networking_port_v2.control.id
  description = "Floating IP for Kubernetes control plane"
  depends_on = [
    openstack_networking_router_interface_v2.k8s
  ]
}

# Cấp floating IP cho node worker và gắn IP vào cổng mạng tương ứng.
resource "openstack_networking_floatingip_v2" "worker" {
  pool        = data.terraform_remote_state.foundation.outputs.external_network_name
  subnet_id   = data.terraform_remote_state.foundation.outputs.external_subnet_id
  port_id     = openstack_networking_port_v2.worker.id
  description = "Floating IP for Kubernetes worker"
  depends_on = [
    openstack_networking_router_interface_v2.k8s
  ]
}