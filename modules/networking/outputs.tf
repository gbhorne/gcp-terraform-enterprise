output "vpc_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = google_compute_subnetwork.public.name
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = google_compute_subnetwork.private.name
}

output "private_vpc_connection" {
  description = "Private VPC connection ID for Cloud SQL dependency"
  value       = google_service_networking_connection.private_vpc_connection.id
}
