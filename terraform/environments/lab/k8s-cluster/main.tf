# Đọc các tài nguyên nền tảng từ state của environment foundation (backend local).
# Đường dẫn là biến để không phụ thuộc vị trí thư mục.
data "terraform_remote_state" "foundation" {
  backend = "local"
  config  = { path = var.foundation_state_path }
}

locals {
  foundation = data.terraform_remote_state.foundation.outputs

  # Bộ rule cơ bản của lab, dựng từ các biến; rule bổ sung gộp thêm ở cuối.
  security_group_rules = merge(
    {
      egress_ipv4 = {
        direction = "egress"
      }
      ssh = {
        direction        = "ingress"
        protocol         = "tcp"
        port_min         = 22
        port_max         = 22
        remote_ip_prefix = var.ssh_allowed_cidr
      }
      icmp = {
        direction        = "ingress"
        protocol         = "icmp"
        remote_ip_prefix = var.icmp_allowed_cidr
      }
      cluster_internal = {
        direction        = "ingress"
        remote_ip_prefix = var.tenant_cidr
      }
      traefik_http_nodeport = {
        direction        = "ingress"
        protocol         = "tcp"
        port_min         = var.traefik_nodeport
        port_max         = var.traefik_nodeport
        remote_ip_prefix = var.traefik_allowed_cidr
      }
    },
    var.additional_security_group_rules,
  )
}

module "k8s_cluster" {
  source = "../../../modules/k8s-cluster"

  image_id     = local.foundation.image_id
  flavor_ids   = local.foundation.flavor_ids
  keypair_name = local.foundation.keypair_name

  external = {
    network_id   = local.foundation.external_network_id
    network_name = local.foundation.external_network_name
    subnet_id    = local.foundation.external_subnet_id
  }

  network = {
    name            = var.tenant_network_name
    subnet_name     = var.tenant_subnet_name
    router_name     = var.router_name
    cidr            = var.tenant_cidr
    gateway_ip      = var.tenant_gateway
    dns_nameservers = var.dns_nameservers
  }

  security_group = {
    name = var.security_group_name
  }

  security_group_rules = local.security_group_rules
  nodes                = var.nodes
  common_tags          = var.common_tags
}
