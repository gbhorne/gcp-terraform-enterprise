output "notification_channel_id" {
  value = google_monitoring_notification_channel.email.id
}

output "dashboard_name" {
  value = google_monitoring_dashboard.main.id
}
