terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "npipe:////./pipe/docker_engine"
}

# Floci Local Emulator shared configuration
locals {
  floci_endpoint = "http://localhost:4566"
}

# Default provider (used for global resources like IAM, Budgets)
provider "aws" {
  region                      = var.active_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = local.floci_endpoint
    iam = local.floci_endpoint
  }
}

# Explicit regional provider aliases for dynamic region switching and clean teardown
provider "aws" {
  alias                       = "us_east_1"
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = local.floci_endpoint
    iam = local.floci_endpoint
  }
}

provider "aws" {
  alias                       = "eu_central_1"
  region                      = "eu-central-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = local.floci_endpoint
    iam = local.floci_endpoint
  }
}

provider "aws" {
  alias                       = "ap_northeast_1"
  region                      = "ap-northeast-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = local.floci_endpoint
    iam = local.floci_endpoint
  }
}
