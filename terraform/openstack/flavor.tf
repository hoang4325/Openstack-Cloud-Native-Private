# Tạo flavor OpenStack cho các máy ảo Kubernetes.
resource "openstack_compute_flavor_v2" "k8s_small" {
  name      = var.flavor_name
  ram       = var.flavor_ram_mb
  vcpus     = var.flavor_vcpus
  disk      = var.flavor_disk_gb
  is_public = true
}
#Tạo flavor Openstack cho máy ảo Kubernetes Monitoring.
resource "openstack_compute_flavor_v2" "k8s_monitoring" {
  name      = "k8s-monitoring"
  ram       = 6144
  vcpus     = 4
  disk      = 40
  is_public = true
}