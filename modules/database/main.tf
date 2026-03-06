# ── Random password for the database user ─────────────────────────────────────
resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}?"
}

# ── Store password in Secret Manager ──────────────────────────────────────────
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.environment}-db-password"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# ── Random suffix for instance name ───────────────────────────────────────────
resource "random_id" "db_suffix" {
  byte_length = 4
}

# ── Cloud SQL PostgreSQL Instance ─────────────────────────────────────────────
resource "google_sql_database_instance" "main" {
  name             = "${var.environment}-postgres-${random_id.db_suffix.hex}"
  project          = var.project_id
  database_version = "POSTGRES_15"
  region           = var.region

  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = "ZONAL"
    disk_type         = "PD_SSD"
    disk_size         = var.disk_size
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "02:00"

      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_id
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }
  }

  depends_on = [var.private_vpc_connection]

  lifecycle {
    prevent_destroy = false
  }
}

# ── Database and User ─────────────────────────────────────────────────────────
resource "google_sql_database" "app_db" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
  project  = var.project_id
}

resource "google_sql_user" "app_user" {
  name     = var.database_user
  instance = google_sql_database_instance.main.name
  project  = var.project_id
  password = random_password.db_password.result
}