variable "local_mode" {
  type        = bool
  description = "If true, bypass AWS and deploy a local Docker container for testing"
  default     = false
}

variable "region" {
  type        = string
  description = "The AWS region for this specific module instance."
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type."
}

variable "allowed_client_ip_range" {
  type        = string
  description = "CIDR block allowed to connect to the TrustTunnel endpoint port."
}

variable "endpoint_port" {
  type        = number
  description = "The listening port for the TrustTunnel VPN endpoint."
}

variable "ssh_public_key" {
  type        = string
  description = "Optional SSH public key to deploy."
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all AWS resources."
}
