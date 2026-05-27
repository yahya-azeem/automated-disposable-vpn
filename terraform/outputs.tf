output "active_region" {
  description = "The currently active GCP region."
  value       = var.active_region
}

output "instance_id" {
  description = "The Compute Engine instance ID of the active VPN node."
  value = var.local_mode ? docker_container.vpn_local[0].id : (
    var.active_region == "us-east1" ? module.vpn_us_east1[0].instance_id : (
      var.active_region == "us-central1" ? module.vpn_us_central1[0].instance_id : module.vpn_us_west1[0].instance_id
    )
  )
}

output "public_ip" {
  description = "The public IP address of the active VPN node."
  value = var.local_mode ? "127.0.0.1" : (
    var.active_region == "us-east1" ? module.vpn_us_east1[0].public_ip : (
      var.active_region == "us-central1" ? module.vpn_us_central1[0].public_ip : module.vpn_us_west1[0].public_ip
    )
  )
}

output "network_id" {
  description = "The Network ID of the active VPN node."
  value = var.local_mode ? "local-docker-network" : (
    var.active_region == "us-east1" ? module.vpn_us_east1[0].network_id : (
      var.active_region == "us-central1" ? module.vpn_us_central1[0].network_id : module.vpn_us_west1[0].network_id
    )
  )
}
