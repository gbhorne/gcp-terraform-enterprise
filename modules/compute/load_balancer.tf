# ── Static External IP ────────────────────────────────────────────────────────
resource "google_compute_global_address" "lb_ip" {
  name    = "${var.environment}-lb-ip"
  project = var.project_id
}

# ── Backend Service ───────────────────────────────────────────────────────────
resource "google_compute_backend_service" "web" {
  name                  = "${var.environment}-web-backend"
  project               = var.project_id
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.web.id]

  backend {
    group           = google_compute_region_instance_group_manager.web.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# ── URL Map ───────────────────────────────────────────────────────────────────
resource "google_compute_url_map" "web" {
  name            = "${var.environment}-web-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.web.id
}

# ── HTTP Proxy ────────────────────────────────────────────────────────────────
resource "google_compute_target_http_proxy" "web" {
  name    = "${var.environment}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.web.id
}

# ── Forwarding Rule ───────────────────────────────────────────────────────────
resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.environment}-http-forwarding-rule"
  project               = var.project_id
  ip_address            = google_compute_global_address.lb_ip.address
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.web.id
  load_balancing_scheme = "EXTERNAL"
}