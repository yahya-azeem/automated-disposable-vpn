# Root main configuration enforcing a single active regional VPN node.
# Changing var.active_region automatically destroys the previous region's resources and creates the new ones.

module "vpn_us_east1" {
  source = "./modules/vpn_node"
  providers = {
    google = google.us_east1
  }
  count                   = (!var.local_mode && var.active_region == "us-east1") ? 1 : 0
  project                 = var.gcp_project_id
  region                  = "us-east1"
  zone                    = "us-east1-b"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
  container_image         = var.container_image
}

module "vpn_us_central1" {
  source = "./modules/vpn_node"
  providers = {
    google = google.us_central1
  }
  count                   = (!var.local_mode && var.active_region == "us-central1") ? 1 : 0
  project                 = var.gcp_project_id
  region                  = "us-central1"
  zone                    = "us-central1-a"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
  container_image         = var.container_image
}

module "vpn_us_west1" {
  source = "./modules/vpn_node"
  providers = {
    google = google.us_west1
  }
  count                   = (!var.local_mode && var.active_region == "us-west1") ? 1 : 0
  project                 = var.gcp_project_id
  region                  = "us-west1"
  zone                    = "us-west1-a"
  instance_type           = var.instance_type
  allowed_client_ip_range = var.allowed_client_ip_range
  endpoint_port           = var.endpoint_port
  ssh_public_key          = var.ssh_public_key
  tags                    = var.tags
  local_mode              = var.local_mode
  container_image         = var.container_image
}

resource "docker_container" "vpn_local" {
  count = var.local_mode ? 1 : 0
  name  = "trusttunnel-node-local"
  image = var.container_image
  env   = [
    "SSH_PUBLIC_KEY=${var.ssh_public_key}",
    "PORT=22"
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
