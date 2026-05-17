output "instance_id" {
  description = "The EC2 instance ID."
  value       = aws_instance.vpn.id
}

output "public_ip" {
  description = "The public IP address."
  value       = aws_instance.vpn.public_ip
}

output "vpc_id" {
  description = "The VPC ID."
  value       = aws_vpc.vpn.id
}
