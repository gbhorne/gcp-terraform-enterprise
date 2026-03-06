# ── Service Accounts ──────────────────────────────────────────────────────────
resource "google_service_account" "web_app" {
  account_id   = "${var.environment}-web-app-sa"
  display_name = "${var.environment} Web Application"
  description  = "Service account for web app GCE instances"
  project      = var.project_id
}

resource "google_service_account" "data_pipeline" {
  account_id   = "${var.environment}-data-pipeline-sa"
  display_name = "${var.environment} Data Pipeline"
  description  = "Service account for ETL pipeline"
  project      = var.project_id
}

resource "google_service_account" "api_service" {
  account_id   = "${var.environment}-api-service-sa"
  display_name = "${var.environment} API Microservice"
  description  = "Service account for Cloud Run API"
  project      = var.project_id
}

resource "google_service_account" "cloud_build" {
  account_id   = "${var.environment}-cloud-build-sa"
  display_name = "${var.environment} Cloud Build"
  description  = "Service account for Cloud Build pipelines"
  project      = var.project_id
}

# ── IAM Bindings ──────────────────────────────────────────────────────────────
resource "google_project_iam_member" "web_app_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.web_app.email}"
}

resource "google_project_iam_member" "web_app_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.web_app.email}"
}

resource "google_project_iam_member" "data_pipeline_bq_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.data_pipeline.email}"
}

resource "google_project_iam_member" "data_pipeline_storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.data_pipeline.email}"
}

resource "google_project_iam_member" "data_pipeline_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.editor"
  member  = "serviceAccount:${google_service_account.data_pipeline.email}"
}

resource "google_project_iam_member" "api_service_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.api_service.email}"
}

resource "google_project_iam_member" "api_service_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.api_service.email}"
}

resource "google_project_iam_member" "cloud_build_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}

resource "google_project_iam_member" "cloud_build_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}