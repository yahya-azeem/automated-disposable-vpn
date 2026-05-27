variable "local_mode" {
  type        = bool
  description = "If true, bypass GCP and deploy a local Docker container for testing"
  default     = false
}

variable "project" {
  type        = string
  description = "The GCP Project ID."
}

variable "region" {
  type        = string
  description = "The GCP region for this specific module instance."
}

variable "zone" {
  type        = string
  description = "The GCP zone for this specific module instance."
}

variable "instance_type" {
  type        = string
  description = "The Compute Engine instance type."
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
  description = "SSH public key to deploy."
}

variable "tags" {
  type        = map(string)
  description = "Common labels applied to all GCP resources."
}

variable "container_image" {
  type        = string
  description = "The Docker/container image to run."
}
