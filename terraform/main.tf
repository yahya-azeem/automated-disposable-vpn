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

module "vpn_us_east_2" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.us_east_2
  }
  count                   = (!var.local_mode && var.active_region == "us-east-2") ? 1 : 0
  region                  = "us-east-2"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

module "vpn_us_west_1" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.us_west_1
  }
  count                   = (!var.local_mode && var.active_region == "us-west-1") ? 1 : 0
  region                  = "us-west-1"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

module "vpn_us_west_2" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.us_west_2
  }
  count                   = (!var.local_mode && var.active_region == "us-west-2") ? 1 : 0
  region                  = "us-west-2"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

module "vpn_ca_central_1" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.ca_central_1
  }
  count                   = (!var.local_mode && var.active_region == "ca-central-1") ? 1 : 0
  region                  = "ca-central-1"
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

module "vpn_eu_west_1" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.eu_west_1
  }
  count                   = (!var.local_mode && var.active_region == "eu-west-1") ? 1 : 0
  region                  = "eu-west-1"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

module "vpn_eu_west_2" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.eu_west_2
  }
  count                   = (!var.local_mode && var.active_region == "eu-west-2") ? 1 : 0
  region                  = "eu-west-2"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

module "vpn_eu_west_3" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.eu_west_3
  }
  count                   = (!var.local_mode && var.active_region == "eu-west-3") ? 1 : 0
  region                  = "eu-west-3"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

module "vpn_eu_north_1" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.eu_north_1
  }
  count                   = (!var.local_mode && var.active_region == "eu-north-1") ? 1 : 0
  region                  = "eu-north-1"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

module "vpn_ap_south_1" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.ap_south_1
  }
  count                   = (!var.local_mode && var.active_region == "ap-south-1") ? 1 : 0
  region                  = "ap-south-1"
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

module "vpn_ap_northeast_2" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.ap_northeast_2
  }
  count                   = (!var.local_mode && var.active_region == "ap-northeast-2") ? 1 : 0
  region                  = "ap-northeast-2"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

module "vpn_ap_northeast_3" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.ap_northeast_3
  }
  count                   = (!var.local_mode && var.active_region == "ap-northeast-3") ? 1 : 0
  region                  = "ap-northeast-3"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

module "vpn_ap_southeast_1" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.ap_southeast_1
  }
  count                   = (!var.local_mode && var.active_region == "ap-southeast-1") ? 1 : 0
  region                  = "ap-southeast-1"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

module "vpn_ap_southeast_2" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.ap_southeast_2
  }
  count                   = (!var.local_mode && var.active_region == "ap-southeast-2") ? 1 : 0
  region                  = "ap-southeast-2"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
}

module "vpn_sa_east_1" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.sa_east_1
  }
  count                   = (!var.local_mode && var.active_region == "sa-east-1") ? 1 : 0
  region                  = "sa-east-1"
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
