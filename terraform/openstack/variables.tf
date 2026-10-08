# Tên cloud OpenStack được cấu hình trong clouds.yaml.
variable "cloud_name" {
  type    = string
  default = "kolla-admin"
}

# Tên region OpenStack sẽ triển khai tài nguyên.
variable "region" {
  type    = string
  default = "RegionOne"
}

# Tên image Ubuntu dùng cho máy ảo.
variable "ubuntu_image_name" {
  type    = string
  default = "ubuntu-24.04-noble"
}

# URL tải image Ubuntu cloud image.
variable "ubuntu_image_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

# Tên flavor OpenStack dành cho Kubernetes.
variable "flavor_name" {
  type    = string
  default = "k8s-small"
}

# Dung lượng RAM của flavor, tính bằng MB.
variable "flavor_ram_mb" {
  type    = number
  default = 2048
}

# Số lượng vCPU của flavor.
variable "flavor_vcpus" {
  type    = number
  default = 2
}

# Dung lượng đĩa của flavor, tính bằng GB.
variable "flavor_disk_gb" {
  type    = number
  default = 20
}

# Tên keypair SSH dùng cho các máy ảo.
variable "keypair_name" {
  type    = string
  default = "openstack-lab-key"
}

# Đường dẫn đến file public key SSH trên máy triển khai.
variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

# Tên mạng OpenStack bên ngoài.
variable "external_network_name" {
  type    = string
  default = "public-veth"
}

# Tên subnet của mạng bên ngoài.
variable "external_subnet_name" {
  type    = string
  default = "public-veth-subnet"
}

# Tên physical network ánh xạ vào mạng bên ngoài.
variable "external_physical_network" {
  type    = string
  default = "physnet1"
}

# Dải CIDR IPv4 của mạng bên ngoài.
variable "external_cidr" {
  type    = string
  default = "172.30.0.0/24"
}

# Địa chỉ gateway của mạng bên ngoài.
variable "external_gateway" {
  type    = string
  default = "172.30.0.1"
}

# Địa chỉ bắt đầu của allocation pool dành cho floating IP.
variable "floating_ip_start" {
  type    = string
  default = "172.30.0.100"
}

# Địa chỉ kết thúc của allocation pool dành cho floating IP.
variable "floating_ip_end" {
  type    = string
  default = "172.30.0.200"
}
