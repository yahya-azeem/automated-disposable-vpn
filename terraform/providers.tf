terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
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

# Default provider (used for global resources if any)
provider "google" {
  project = var.gcp_project_id
  region  = var.active_region
}

# Provider for us-east1
provider "google" {
  alias   = "us_east1"
  project = var.gcp_project_id
  region  = "us-east1"
}

# Provider for us-central1
provider "google" {
  alias   = "us_central1"
  project = var.gcp_project_id
  region  = "us-central1"
}

# Provider for us-west1
provider "google" {
  alias   = "us_west1"
  project = var.gcp_project_id
  region  = "us-west1"
}
