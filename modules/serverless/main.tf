resource "google_artifact_registry_repository" "api" {
  location      = var.region
  repository_id = "${var.environment}-api-repo"
  format        = "DOCKER"
  project       = var.project_id
}

resource "google_secret_manager_secret" "api_key" {
  secret_id = "${var.environment}-api-key"
  project   = var.project_id
  replication {
    auto {}
  }
}

resource "random_password" "api_key" {
  length  = 32
  special = false
}

resource "google_secret_manager_secret_version" "api_key" {
  secret      = google_secret_manager_secret.api_key.id
  secret_data = random_password.api_key.result
}

resource "google_cloud_run_v2_service" "api" {
  name     = "${var.environment}-api-service"
  location = var.region
  project  = var.project_id
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = var.api_service_sa_email

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
