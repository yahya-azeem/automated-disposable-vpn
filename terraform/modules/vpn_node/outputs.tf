output "instance_id" {
  description = "The Compute Engine instance ID."
  value       = google_compute_instance.vpn.id
}

output "public_ip" {
  description = "The public IP address."
  value       = google_compute_instance.vpn.network_interface[0].access_config[0].nat_ip
}

output "network_id" {
  description = "The Network ID."
  value       = google_compute_network.vpn.id
}
