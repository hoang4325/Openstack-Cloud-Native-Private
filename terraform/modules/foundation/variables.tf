# Module foundation: tài nguyên nền tảng dùng chung cho mọi cụm (image, flavor, keypair, external network).
# Module không chứa giá trị mặc định đặc thù môi trường; mọi giá trị đó do environment truyền vào.

# Image hệ điều hành dùng cho các máy ảo.
variable "image" {
  description = "Ubuntu cloud image đăng ký vào Glance."
  type = object({
    name             = string
    source_url       = string
    min_disk_gb      = number
    container_format = optional(string, "bare")
    disk_format      = optional(string, "qcow2")
    visibility       = optional(string, "public")
    tags             = optional(list(string), [])
  })
}

# Danh sách flavor, khóa của map chính là tên flavor trong OpenStack.
variable "flavors" {
  description = "Map tên flavor => cấu hình. Thêm hoặc bớt flavor chỉ cần sửa map này."
  type = map(object({
    ram_mb    = number
    vcpus     = number
    disk_gb   = number
    is_public = optional(bool, true)
  }))

  validation {
    condition     = length(var.flavors) > 0
    error_message = "Phải khai báo ít nhất một flavor."
  }

  validation {
    condition = alltrue([
      for f in values(var.flavors) : f.ram_mb > 0 && f.vcpus > 0 && f.disk_gb >= 0
    ])
    error_message = "ram_mb và vcpus phải lớn hơn 0, disk_gb không được âm."
  }
}

# Keypair SSH. Module nhận nội dung public key, không đọc file, để logic không phụ thuộc máy chạy Terraform.
variable "keypair" {
  description = "Tên keypair và nội dung public key SSH."
  type = object({
    name       = string
    public_key = string
  })
}

# Mạng external (provider network) dùng cấp floating IP.
variable "external_network" {
  description = "Mạng external và subnet cấp floating IP."
  type = object({
    name                  = string
    subnet_name           = string
    physical_network      = string
    cidr                  = string
    gateway_ip            = string
    allocation_pool_start = string
    allocation_pool_end   = string
    network_type          = optional(string, "flat")
    shared                = optional(bool, true)
    enable_dhcp           = optional(bool, false)
  })

  validation {
    condition     = can(cidrhost(var.external_network.cidr, 0))
    error_message = "external_network.cidr phải là CIDR IPv4 hợp lệ."
  }
}

# Tag chung gắn vào các tài nguyên hỗ trợ tag, giúp nhận diện tài nguyên do Terraform quản lý.
variable "common_tags" {
  description = "Tag gắn cho mọi tài nguyên do module tạo."
  type        = list(string)
  default     = ["terraform-managed"]
}
