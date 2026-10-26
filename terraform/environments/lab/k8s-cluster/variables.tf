# Cấu hình môi trường lab cho cụm Kubernetes.
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

variable "foundation_state_path" {
  description = "Đường dẫn tới terraform.tfstate của environment foundation (backend local), tính từ thư mục này."
  type        = string
  default     = "../foundation/terraform.tfstate"
}

variable "common_tags" {
  description = "Tag gắn cho mọi tài nguyên do Terraform quản lý."
  type        = list(string)
  default     = ["terraform-managed"]
}

# ---------- Mạng tenant ----------

variable "tenant_network_name" {
  type    = string
  default = "k8s-net"
}

variable "tenant_subnet_name" {
  type    = string
  default = "k8s-subnet"
}

variable "tenant_cidr" {
  type    = string
  default = "10.20.0.0/24"
}

variable "tenant_gateway" {
  type    = string
  default = "10.20.0.1"
}

variable "dns_nameservers" {
  description = "Máy chủ DNS cấp cho các node Kubernetes."
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "router_name" {
  type    = string
  default = "k8s-router"
}

# ---------- Security group ----------

variable "security_group_name" {
  type    = string
  default = "k8s-nodes"
}

variable "ssh_allowed_cidr" {
  description = "Dải mạng được phép SSH vào các node."
  type        = string
  default     = "172.30.0.0/24"
}

variable "icmp_allowed_cidr" {
  description = "Dải mạng được phép ping các node."
  type        = string
  default     = "0.0.0.0/0"
}

variable "traefik_nodeport" {
  description = "NodePort HTTP của Traefik (khớp helm/traefik/values.yaml)."
  type        = number
  default     = 30080
}

variable "traefik_allowed_cidr" {
  description = "Dải mạng được truy cập NodePort của Traefik. Mặc định chỉ cho host OpenStack (gateway của mạng external)."
  type        = string
  default     = "172.30.0.1/32"
}

variable "additional_security_group_rules" {
  description = "Rule bổ sung gộp vào bộ rule cơ bản (cùng cấu trúc với security_group_rules của module)."
  type = map(object({
    direction        = string
    ethertype        = optional(string, "IPv4")
    protocol         = optional(string)
    port_min         = optional(number)
    port_max         = optional(number)
    remote_ip_prefix = optional(string)
  }))
  default = {}
}

# ---------- Node ----------

variable "nodes" {
  description = <<-EOT
    Map tên node => cấu hình. Thêm worker mới chỉ cần thêm một phần tử, ví dụ:
      "k8s-worker-02" = { role = "worker", flavor = "k8s-small", fixed_ip = "10.20.0.13" }
    flavor phải là khóa có trong map flavors của environment foundation.
  EOT
  type = map(object({
    role                    = string
    flavor                  = string
    fixed_ip                = string
    floating_ip             = optional(bool, true)
    floating_ip_description = optional(string)
  }))
  default = {
    "k8s-control-01" = {
      role                    = "control"
      flavor                  = "k8s-control"
      fixed_ip                = "10.20.0.10"
      floating_ip_description = "Floating IP for Kubernetes control plane"
    }
    "k8s-worker-01" = {
      role                    = "worker"
      flavor                  = "k8s-small"
      fixed_ip                = "10.20.0.11"
      floating_ip_description = "Floating IP for Kubernetes worker"
    }
    "k8s-monitoring-01" = {
      role                    = "worker"
      flavor                  = "k8s-monitoring"
      fixed_ip                = "10.20.0.12"
      floating_ip_description = "Floating IP for Kubernetes monitoring worker"
    }
  }
}
