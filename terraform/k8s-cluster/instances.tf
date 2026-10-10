# Tạo máy ảo control plane cho cụm Kubernetes.
resource "openstack_compute_instance_v2" "control" {
  name      = var.control_name
  image_id  = data.terraform_remote_state.foundation.outputs.image_id
  flavor_id = data.terraform_remote_state.foundation.outputs.control_flavor_id
  key_pair  = data.terraform_remote_state.foundation.outputs.keypair_name
  network {
    port = openstack_networking_port_v2.control.id
  }
  depends_on = [openstack_networking_router_interface_v2.k8s]
}

# Tạo máy ảo worker cho cụm Kubernetes.
resource "openstack_compute_instance_v2" "worker" {
  name      = var.worker_name
  image_id  = data.terraform_remote_state.foundation.outputs.image_id
  flavor_id = data.terraform_remote_state.foundation.outputs.flavor_id
  key_pair  = data.terraform_remote_state.foundation.outputs.keypair_name
  network {
    port = openstack_networking_port_v2.worker.id
  }
  depends_on = [openstack_networking_router_interface_v2.k8s]
}

resource "openstack_compute_instance_v2" "monitoring" {
  name = var.monitoring_name

  image_id = data.terraform_remote_state.foundation.outputs.image_id

  flavor_id = data.terraform_remote_state.foundation.outputs.monitoring_flavor_id

  key_pair = data.terraform_remote_state.foundation.outputs.keypair_name

  network {
    port = openstack_networking_port_v2.monitoring.id
  }

  depends_on = [
    openstack_networking_router_interface_v2.k8s
  ]
}
