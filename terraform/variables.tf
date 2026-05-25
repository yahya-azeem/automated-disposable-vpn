variable "local_mode" {
  type        = bool
  description = "If true, skip AWS EC2 and deploy a local Docker container for testing"
  default     = false
}

variable "active_region" {
  type        = string
  description = "The currently active AWS region for the single VPN node. Allowed values: us-east-1, eu-central-1, ap-northeast-1."
  default     = "us-east-1"
  validation {
    condition     = contains(["us-east-1", "eu-central-1", "ap-northeast-1"], var.active_region)
    error_message = "The active_region must be one of: us-east-1, eu-central-1, ap-northeast-1."
  }
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type. Must be Free Tier eligible (e.g., t4g.micro for arm64 or t3.micro for x86_64)."
  default     = "t3.small"
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
  description = "Optional SSH public key to deploy to the EC2 instance for Ansible provisioning. If empty, a temporary key pair will be generated."
  default     = ""
}

variable "budget_amount" {
  type        = number
  description = "Monthly budget limit in USD for AWS Free Tier guardrail monitoring."
  default     = 1.0
}

variable "budget_subscriber_email" {
  type        = string
  description = "Email address to receive AWS Budget alerts if spending exceeds the threshold."
  default     = "alerts@example.com"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all AWS resources for cost tracking."
  default = {
    Project     = "TrustTunnel-VPN"
    Environment = "Production-Disposable"
    ManagedBy   = "Terraform-Automated"
    CostCenter  = "FreeTier-VPN"
  }
}
