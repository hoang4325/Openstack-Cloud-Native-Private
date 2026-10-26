# Module k8s-cluster: hạ tầng OpenStack cho một cụm Kubernetes (mạng tenant, router, security group, node).
# Module không chứa giá trị mặc định đặc thù môi trường; mọi giá trị đó do environment truyền vào.

# ---------- Đầu vào lấy từ module foundation ----------

variable "image_id" {
  description = "ID image dùng cho mọi node."
  type        = string
}

variable "flavor_ids" {
  description = "Map tên flavor => ID flavor (output flavor_ids của module foundation)."
  type        = map(string)
}

variable "keypair_name" {
  description = "Tên keypair SSH gắn vào các node."
  type        = string
}

variable "external" {
  description = "Mạng external dùng cho router và floating IP."
  type = object({
    network_id   = string
    network_name = string
    subnet_id    = string
  })
}

# ---------- Mạng tenant ----------

variable "network" {
  description = "Mạng, subnet và router của cụm."
  type = object({
    name            = string
    subnet_name     = string
    router_name     = string
    cidr            = string
    gateway_ip      = string
    dns_nameservers = optional(list(string), [])
    enable_dhcp     = optional(bool, true)
    enable_snat     = optional(bool, true)
  })

  validation {
    condition     = can(cidrhost(var.network.cidr, 0))
    error_message = "network.cidr phải là CIDR IPv4 hợp lệ."
  }
}

# ---------- Security group ----------

variable "security_group" {
  description = "Tên và mô tả security group chung cho các node."
  type = object({
    name        = string
    description = optional(string, "Security group for Kubernetes nodes")
  })
}

variable "security_group_rules" {
  description = "Map tên rule => nội dung rule. Thêm hoặc bớt rule chỉ cần sửa map này."
  type = map(object({
    direction        = string
    ethertype        = optional(string, "IPv4")
    protocol         = optional(string)
    port_min         = optional(number)
    port_max         = optional(number)
    remote_ip_prefix = optional(string)
  }))

  validation {
    condition     = alltrue([for r in values(var.security_group_rules) : contains(["ingress", "egress"], r.direction)])
    error_message = "direction của rule chỉ được là ingress hoặc egress."
  }
}

# ---------- Node ----------

variable "nodes" {
  description = <<-EOT
    Map tên node => cấu hình node. Khóa của map là tên máy ảo.
    - role: control hoặc worker
    - flavor: tên flavor, phải có trong flavor_ids
    - fixed_ip: IP cố định trong network.cidr
    - floating_ip: có cấp floating IP hay không
    - floating_ip_description: mô tả floating IP (mặc định "Floating IP for <tên node>")
  EOT
  type = map(object({
    role                    = string
    flavor                  = string
    fixed_ip                = string
    floating_ip             = optional(bool, true)
    floating_ip_description = optional(string)
  }))

  validation {
    condition     = alltrue([for n in values(var.nodes) : contains(["control", "worker"], n.role)])
    error_message = "role của node chỉ được là control hoặc worker."
  }

  validation {
    condition     = length([for n in values(var.nodes) : n if n.role == "control"]) >= 1
    error_message = "Cụm cần ít nhất một node có role = control."
  }

  validation {
    condition     = length(distinct([for n in values(var.nodes) : n.fixed_ip])) == length(var.nodes)
    error_message = "Mỗi node phải có fixed_ip riêng."
  }
}

variable "ssh_user" {
  description = "User SSH mặc định của image, dùng để sinh lệnh ssh trong output."
  type        = string
  default     = "ubuntu"
}

variable "common_tags" {
  description = "Tag gắn cho mọi tài nguyên do module tạo."
  type        = list(string)
  default     = ["terraform-managed"]
}
