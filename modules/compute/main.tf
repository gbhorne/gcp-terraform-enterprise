# ── Startup Script ────────────────────────────────────────────────────────────
locals {
  startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx

    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head><title>${var.environment} Web App</title></head>
    <body>
      <h1>Enterprise Terraform Demo</h1>
      <p>Environment: ${var.environment}</p>
      <p>Instance: $(hostname)</p>
    </body>
    </html>
    HTML

    echo "OK" > /var/www/html/health
  EOT
}

# ── Instance Template ─────────────────────────────────────────────────────────
resource "google_compute_instance_template" "web" {
  name_prefix  = "${var.environment}-web-template-"
  project      = var.project_id
  machine_type = var.machine_type
  region       = var.region

  tags = ["web-server", "allow-ssh"]

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
    disk_type    = "pd-standard"
    disk_size_gb = 20
  }

  network_interface {
    network    = var.vpc_name
    subnetwork = var.subnet_name
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    startup-script  = local.startup_script
    enable-oslogin  = "TRUE"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── Health Check ──────────────────────────────────────────────────────────────
resource "google_compute_health_check" "web" {
  name                = "${var.environment}-web-health-check"
  project             = var.project_id
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 80
    request_path = "/health"
  }
}

# ── Managed Instance Group ────────────────────────────────────────────────────
resource "google_compute_region_instance_group_manager" "web" {
  name               = "${var.environment}-web-mig"
  project            = var.project_id
  region             = var.region
  base_instance_name = "${var.environment}-web"

  version {
    name              = "primary"
    instance_template = google_compute_instance_template.web.id
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.web.id
    initial_delay_sec = 300
  }

  lifecycle {
    ignore_changes = [target_size]
  }
}

# ── Autoscaler ────────────────────────────────────────────────────────────────
resource "google_compute_region_autoscaler" "web" {
  name    = "${var.environment}-web-autoscaler"
  project = var.project_id
  region  = var.region
  target  = google_compute_region_instance_group_manager.web.id

  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = 60

    cpu_utilization {
      target = 0.70
    }
  }
}