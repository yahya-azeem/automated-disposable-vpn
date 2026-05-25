# Root main configuration enforcing a single active regional VPN node.
# Changing var.active_region automatically destroys the previous region's resources and creates the new ones.

module "vpn_us_east_1" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.us_east_1
  }
  count                   = (!var.local_mode && var.active_region == "us-east-1") ? 1 : 0
  region                  = "us-east-1"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

module "vpn_eu_central_1" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.eu_central_1
  }
  count                   = (!var.local_mode && var.active_region == "eu-central-1") ? 1 : 0
  region                  = "eu-central-1"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

module "vpn_ap_northeast_1" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.ap_northeast_1
  }
  count                   = (!var.local_mode && var.active_region == "ap-northeast-1") ? 1 : 0
  region                  = "ap-northeast-1"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

resource "docker_image" "alpine_sshd" {
  count = var.local_mode ? 1 : 0
  name  = "alpine:latest"
}

resource "docker_container" "vpn_local" {
  count = var.local_mode ? 1 : 0
  name  = "trusttunnel-node-local"
  image = docker_image.alpine_sshd[0].image_id
  command = [
    "sh",
    "-c",
    "apk add --no-cache openssh python3 && ssh-keygen -A && mkdir -p /root/.ssh && echo '${var.ssh_public_key}' > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && /usr/sbin/sshd -D"
  ]
  ports {
    internal = 22
    external = 2223
  }
  ports {
    internal = 443
    external = 8443
    protocol = "tcp"
  }
  capabilities {
    add = ["NET_ADMIN", "SYS_MODULE"]
  }
  rm = true
}
