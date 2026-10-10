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

# Tên mạng riêng dành cho cụm Kubernetes.
variable "tenant_network_name" {
  type    = string
  default = "k8s-net"
}

# Tên subnet riêng dành cho cụm Kubernetes.
variable "tenant_subnet_name" {
  type    = string
  default = "k8s-subnet"
}

# Dải CIDR IPv4 của subnet Kubernetes.
variable "tenant_cidr" {
  type    = string
  default = "10.20.0.0/24"
}

# Địa chỉ gateway của subnet Kubernetes.
variable "tenant_gateway" {
  type    = string
  default = "10.20.0.1"
}

# Danh sách máy chủ DNS cấp cho các node Kubernetes.
variable "dns_nameservers" {
  type    = list(string)
  default = ["1.1.1.1", "8.8.8.8"]
}

# Tên router kết nối mạng Kubernetes với mạng bên ngoài.
variable "router_name" {
  type    = string
  default = "k8s-router"
}

# Tên security group áp dụng cho các node Kubernetes.
variable "security_group_name" {
  type    = string
  default = "k8s-nodes"
}

# Dải mạng được phép kết nối SSH vào các node.
variable "ssh_allowed_cidr" {
  type    = string
  default = "172.30.0.0/24"
}

# Tên máy ảo control plane.
variable "control_name" {
  type    = string
  default = "k8s-control-01"
}

# Địa chỉ IP cố định của node control plane.
variable "control_fixed_ip" {
  type    = string
  default = "10.20.0.10"
}

# Tên máy ảo worker.
variable "worker_name" {
  type    = string
  default = "k8s-worker-01"
}

# Địa chỉ IP cố định của node worker.
variable "worker_fixed_ip" {
  type    = string
  default = "10.20.0.11"
}

variable "monitoring_name" {
  type    = string
  default = "k8s-monitoring-01"
}

variable "monitoring_fixed_ip" {
  type    = string
  default = "10.20.0.12"
}