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

# Provider for us-east-1
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

# Provider for us-east-2
provider "aws" {
  alias                       = "us_east_2"
  region                      = "us-east-2"
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

# Provider for us-west-1
provider "aws" {
  alias                       = "us_west_1"
  region                      = "us-west-1"
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

# Provider for us-west-2
provider "aws" {
  alias                       = "us_west_2"
  region                      = "us-west-2"
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

# Provider for ca-central-1
provider "aws" {
  alias                       = "ca_central_1"
  region                      = "ca-central-1"
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

# Provider for eu-central-1
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

# Provider for eu-west-1
provider "aws" {
  alias                       = "eu_west_1"
  region                      = "eu-west-1"
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

# Provider for eu-west-2
provider "aws" {
  alias                       = "eu_west_2"
  region                      = "eu-west-2"
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

# Provider for eu-west-3
provider "aws" {
  alias                       = "eu_west_3"
  region                      = "eu-west-3"
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

# Provider for eu-north-1
provider "aws" {
  alias                       = "eu_north_1"
  region                      = "eu-north-1"
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

# Provider for ap-south-1
provider "aws" {
  alias                       = "ap_south_1"
  region                      = "ap-south-1"
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

# Provider for ap-northeast-1
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

# Provider for ap-northeast-2
provider "aws" {
  alias                       = "ap_northeast_2"
  region                      = "ap-northeast-2"
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

# Provider for ap-northeast-3
provider "aws" {
  alias                       = "ap_northeast_3"
  region                      = "ap-northeast-3"
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

# Provider for ap-southeast-1
provider "aws" {
  alias                       = "ap_southeast_1"
  region                      = "ap-southeast-1"
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

# Provider for ap-southeast-2
provider "aws" {
  alias                       = "ap_southeast_2"
  region                      = "ap-southeast-2"
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

# Provider for sa-east-1
provider "aws" {
  alias                       = "sa_east_1"
  region                      = "sa-east-1"
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
