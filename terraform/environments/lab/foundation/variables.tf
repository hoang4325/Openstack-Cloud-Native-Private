# Cấu hình môi trường lab cho lớp foundation.
# Giá trị mặc định ở đây khớp với lab đang chạy; ghi đè bằng terraform.tfvars (không commit) khi cần.

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

# ---------- Image ----------

variable "ubuntu_image_name" {
  description = "Tên image Ubuntu trong Glance."
  type        = string
  default     = "ubuntu-24.04-noble"
}

variable "ubuntu_image_url" {
  description = "URL tải Ubuntu cloud image."
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "image_min_disk_gb" {
  description = "Dung lượng đĩa tối thiểu (GB) mà image yêu cầu."
  type        = number
  default     = 20
}

variable "image_tags" {
  description = "Tag mô tả image (tag common_tags được nối thêm tự động)."
  type        = list(string)
  default     = ["ubuntu", "24.04", "noble"]
}

# ---------- Flavor ----------

variable "flavors" {
  description = "Map tên flavor => cấu hình. Thêm flavor mới chỉ cần thêm một phần tử."
  type = map(object({
    ram_mb    = number
    vcpus     = number
    disk_gb   = number
    is_public = optional(bool, true)
  }))
  default = {
    "k8s-small"      = { ram_mb = 2048, vcpus = 2, disk_gb = 20 }
    "k8s-control"    = { ram_mb = 4096, vcpus = 2, disk_gb = 20 }
    "k8s-monitoring" = { ram_mb = 4096, vcpus = 4, disk_gb = 40 }
    "k8s-deploy"     = { ram_mb = 4096, vcpus = 2, disk_gb = 50 }
  }
}

# ---------- Keypair ----------

variable "keypair_name" {
  description = "Tên keypair SSH dùng cho các máy ảo."
  type        = string
  default     = "openstack-lab-key"
}

variable "ssh_public_key_path" {
  description = "Đường dẫn file public key SSH trên máy chạy Terraform."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

# ---------- Mạng external ----------

variable "external_network_name" {
  type    = string
  default = "public-veth"
}

variable "external_subnet_name" {
  type    = string
  default = "public-veth-subnet"
}

variable "external_physical_network" {
  description = "Tên physical network của Neutron ánh xạ vào mạng external."
  type        = string
  default     = "physnet1"
}

variable "external_cidr" {
  type    = string
  default = "172.30.0.0/24"
}

variable "external_gateway" {
  type    = string
  default = "172.30.0.1"
}

variable "floating_ip_start" {
  description = "Địa chỉ đầu của allocation pool cấp floating IP."
  type        = string
  default     = "172.30.0.100"
}

variable "floating_ip_end" {
  description = "Địa chỉ cuối của allocation pool cấp floating IP."
  type        = string
  default     = "172.30.0.200"
}

variable "common_tags" {
  description = "Tag gắn cho mọi tài nguyên do Terraform quản lý."
  type        = list(string)
  default     = ["terraform-managed"]
}
