# ── Provider ──────────────────────────────────────────────────────────────────
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ── VPC Network ───────────────────────────────────────────────────────────────
resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "Custom VPC for ${var.environment} environment"
}

# ── Subnets ───────────────────────────────────────────────────────────────────
resource "google_compute_subnetwork" "public" {
  name                     = "${var.environment}-public-subnet"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = var.public_subnet_cidr
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private" {
  name                     = "${var.environment}-private-subnet"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = var.private_subnet_cidr
  private_ip_google_access = true
}

# ── Cloud Router ──────────────────────────────────────────────────────────────
resource "google_compute_router" "router" {
  name    = "${var.environment}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
}

# ── Cloud NAT ─────────────────────────────────────────────────────────────────
resource "google_compute_router_nat" "nat" {
  name                               = "${var.environment}-nat"
  project                            = var.project_id
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ── Firewall Rules ────────────────────────────────────────────────────────────
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.environment}-allow-http-https"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
  direction     = "INGRESS"
  priority      = 1000
  description   = "Allow HTTP/HTTPS from internet to web servers"
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.environment}-allow-iap-ssh"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-ssh"]
  direction     = "INGRESS"
  priority      = 1000
  description   = "Allow SSH only via IAP tunnel"
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.environment}-allow-internal"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.public_subnet_cidr, var.private_subnet_cidr]
  direction     = "INGRESS"
  priority      = 1000
  description   = "Allow all traffic within the VPC"
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.environment}-allow-health-checks"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["web-server"]
  direction     = "INGRESS"
  priority      = 1000
  description   = "Allow health checks from Google Load Balancer"
}

# ── Private Service Access (for Cloud SQL private IP) ─────────────────────────
resource "google_compute_global_address" "private_ip_range" {
  name          = "${var.environment}-private-ip-range"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}
