output "web_app_sa_email" {
  description = "Email of the web app service account"
  value       = google_service_account.web_app.email
}

output "data_pipeline_sa_email" {
  description = "Email of the data pipeline service account"
  value       = google_service_account.data_pipeline.email
}

output "api_service_sa_email" {
  description = "Email of the API service account"
  value       = google_service_account.api_service.email
}

output "cloud_build_sa_email" {
  description = "Email of the Cloud Build service account"
  value       = google_service_account.cloud_build.email
}