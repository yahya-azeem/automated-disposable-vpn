# Root main configuration enforcing a single active regional VPN node.
# Changing var.active_region automatically destroys the previous region's resources and creates the new ones.

module "vpn_us_east_1" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.us_east_1
  }
  count                   = var.active_region == "us-east-1" ? 1 : 0
  region                  = "us-east-1"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
}

module "vpn_eu_central_1" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.eu_central_1
  }
  count                   = var.active_region == "eu-central-1" ? 1 : 0
  region                  = "eu-central-1"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
}

module "vpn_ap_northeast_1" {
  source = "./modules/vpn_node"
  providers = {
    aws = aws.ap_northeast_1
  }
  count                   = var.active_region == "ap-northeast-1" ? 1 : 0
  region                  = "ap-northeast-1"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
}
