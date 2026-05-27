terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

# Fetch the latest Container-Optimized OS image
data "google_compute_image" "cos" {
  family  = "cos-stable"
  project = "cos-cloud"
}

# Minimal VPC dedicated to the disposable VPN node
resource "google_compute_network" "vpn" {
  name                    = "trusttunnel-vpc-${var.region}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name          = "trusttunnel-subnet-${var.region}"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpn.id
}

# Firewall allowing TrustTunnel endpoint port and SSH
resource "google_compute_firewall" "vpn" {
  name    = "trusttunnel-fw-${var.region}"
  network = google_compute_network.vpn.name

  allow {
    protocol = "tcp"
    ports    = [tostring(var.endpoint_port), "22"]
  }

  allow {
    protocol = "udp"
    ports    = [tostring(var.endpoint_port)]
  }

  source_ranges = [var.allowed_client_ip_range]
  target_tags   = ["trusttunnel-node"]
}

# Allow GCP IAP for SSH (optional but good practice)
resource "google_compute_firewall" "iap" {
  name    = "trusttunnel-iap-${var.region}"
  network = google_compute_network.vpn.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["trusttunnel-node"]
}

locals {
  # The container declaration runs the prebuilt image and configures runtime settings via env variables.
  container_declaration = yamlencode({
    spec = {
      containers = [
        {
          name  = "trusttunnel-node"
          image = var.container_image
          env = [
            {
              name  = "SSH_PUBLIC_KEY"
              value = var.ssh_public_key
            },
            {
              name  = "PORT"
              value = tostring(var.endpoint_port)
            }
          ]
          securityContext = {
            privileged = true
          }
          stdin = false
          tty   = false
        }
      ]
      restartPolicy = "Always"
    }
  })
}

# The single micro Compute Engine instance for the active VPN node using Container-Optimized OS
resource "google_compute_instance" "vpn" {
  name         = "trusttunnel-node-${var.region}"
  machine_type = var.instance_type
  zone         = var.zone
  project      = var.project

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos.self_link
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.id
    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    gce-container-declaration = local.container_declaration
    google-logging-enabled    = "true"
  }

  tags = ["trusttunnel-node"]

  labels = var.tags
}
