# Đăng ký public key SSH để truy cập các máy ảo.
resource "openstack_compute_keypair_v2" "lab" {
  name       = var.keypair_name
  public_key = file(pathexpand(var.ssh_public_key_path))
}
