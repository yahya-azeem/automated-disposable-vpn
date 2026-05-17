output "active_region" {
  description = "The currently active AWS region."
  value       = var.active_region
}

output "instance_id" {
  description = "The EC2 instance ID of the active VPN node."
  value = var.active_region == "us-east-1" ? module.vpn_us_east_1[0].instance_id : (
    var.active_region == "eu-central-1" ? module.vpn_eu_central_1[0].instance_id : module.vpn_ap_northeast_1[0].instance_id
  )
}

output "public_ip" {
  description = "The public IP address of the active VPN node."
  value = var.active_region == "us-east-1" ? module.vpn_us_east_1[0].public_ip : (
    var.active_region == "eu-central-1" ? module.vpn_eu_central_1[0].public_ip : module.vpn_ap_northeast_1[0].public_ip
  )
}

output "vpc_id" {
  description = "The VPC ID of the active VPN node."
  value = var.active_region == "us-east-1" ? module.vpn_us_east_1[0].vpc_id : (
    var.active_region == "eu-central-1" ? module.vpn_eu_central_1[0].vpc_id : module.vpn_ap_northeast_1[0].vpc_id
  )
}
