# Tải và đăng ký image Ubuntu 24.04 dùng cho các máy ảo.
resource "openstack_images_image_v2" "ubuntu_noble" {
  name             = var.ubuntu_image_name
  image_source_url = var.ubuntu_image_url
  container_format = "bare"
  disk_format      = "qcow2"
  visibility       = "public"
  min_disk_gb      = var.flavor_disk_gb
  tags             = ["ubuntu", "24.04", "noble", "terraform-managed"]
}
