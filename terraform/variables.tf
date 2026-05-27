variable "local_mode" {
  type        = bool
  description = "If true, skip GCP and deploy a local Docker container for testing"
  default     = false
}

variable "gcp_project_id" {
  type        = string
  description = "The GCP Project ID."
  default     = "trusttunnel-vpn-project"
}

variable "active_region" {
  type        = string
  description = "The currently active GCP region for the single VPN node. Allowed values (free tier): us-east1, us-central1, us-west1."
  default     = "us-east1"
  validation {
    condition     = contains(["us-east1", "us-central1", "us-west1"], var.active_region)
    error_message = "The active_region must be one of: us-east1, us-central1, us-west1."
  }
}

variable "instance_type" {
  type        = string
  description = "The Compute Engine instance type. Must be Free Tier eligible (e2-micro)."
  default     = "e2-micro"
}

variable "allowed_client_ip_range" {
  type        = string
  description = "CIDR block allowed to connect to the TrustTunnel endpoint port."
  default     = "0.0.0.0/0"
}

variable "endpoint_port" {
  type        = number
  description = "The listening port for the TrustTunnel VPN endpoint."
  default     = 443
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key to deploy to the container. The container will run an SSH daemon with this key."
  default     = ""
}

variable "budget_amount" {
  type        = number
  description = "Monthly budget limit in USD for GCP billing alerts."
  default     = 1.0
}

variable "tags" {
  type        = map(string)
  description = "Common labels applied to all GCP resources."
  default = {
    project     = "trusttunnel-vpn"
    environment = "production-disposable"
    managed-by  = "terraform-automated"
  }
}

variable "container_image" {
  type        = string
  description = "The Docker/container image to run. Defaults to the local build target."
  default     = "trusttunnel-node:latest"
}

