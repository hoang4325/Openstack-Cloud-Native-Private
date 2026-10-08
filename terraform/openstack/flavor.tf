# Tạo flavor OpenStack cho các máy ảo Kubernetes.
resource "openstack_compute_flavor_v2" "k8s_small" {
  name      = var.flavor_name
  ram       = var.flavor_ram_mb
  vcpus     = var.flavor_vcpus
  disk      = var.flavor_disk_gb
  is_public = true
}
