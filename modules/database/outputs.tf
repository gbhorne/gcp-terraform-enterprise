output "instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.main.name
}

output "connection_name" {
  description = "Cloud SQL connection name for Cloud SQL proxy"
  value       = google_sql_database_instance.main.connection_name
}

output "private_ip" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.main.private_ip_address
}

output "database_name" {
  description = "Name of the created database"
  value       = google_sql_database.app_db.name
}

output "db_password_secret_id" {
  description = "Secret Manager secret ID for the DB password"
  value       = google_secret_manager_secret.db_password.secret_id
}