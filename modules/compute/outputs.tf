output "instance_group" {
  description = "Self-link of the managed instance group"
  value       = google_compute_region_instance_group_manager.web.instance_group
}

output "mig_name" {
  description = "Name of the managed instance group manager"
  value       = google_compute_region_instance_group_manager.web.name
}

output "health_check_self_link" {
  description = "Self-link of the health check"
  value       = google_compute_health_check.web.self_link
}

output "instance_template_id" {
  description = "ID of the instance template"
  value       = google_compute_instance_template.web.id
}

output "lb_ip_address" {
  description = "External IP address of the load balancer"
  value       = google_compute_global_address.lb_ip.address
}