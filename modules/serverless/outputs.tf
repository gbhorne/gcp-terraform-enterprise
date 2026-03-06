output "cloud_run_url" {
  value = google_cloud_run_v2_service.api.uri
}

output "api_repository" {
  value = google_artifact_registry_repository.api.name
}

output "api_key_secret_id" {
  value = google_secret_manager_secret.api_key.secret_id
}
