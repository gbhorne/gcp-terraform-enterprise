output "lb_ip_address" {
  description = "External Load Balancer IP"
  value       = module.compute.lb_ip_address
}

output "vpc_name" {
  description = "VPC name"
  value       = module.networking.vpc_name
}

output "db_instance_name" {
  description = "Cloud SQL instance name"
  value       = module.database.instance_name
}

output "db_private_ip" {
  description = "Cloud SQL private IP"
  value       = module.database.private_ip
}

output "db_password_secret" {
  description = "Secret Manager secret ID for DB password"
  value       = module.database.db_password_secret_id
}

output "landing_bucket" {
  value = module.data_pipeline.landing_bucket_name
}

output "bigquery_dataset" {
  value = module.data_pipeline.bigquery_dataset_id
}

output "etl_function_name" {
  value = module.data_pipeline.function_name
}
output "cloud_run_url" {
  value = module.serverless.cloud_run_url
}

output "api_key_secret" {
  value = module.serverless.api_key_secret_id
}
