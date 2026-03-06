resource "google_monitoring_notification_channel" "email" {
  display_name = "${var.environment} Alert Email"
  type         = "email"
  project      = var.project_id

  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "${var.environment} - High CPU Utilization"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "CPU > 80%"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "cloud_run_errors" {
  display_name = "${var.environment} - Cloud Run Errors"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run error rate > 5%"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class=\"5xx\""
      duration        = "120s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_dashboard" "main" {
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "${var.environment} Infrastructure Dashboard"
    gridLayout = {
      widgets = [
        {
          title = "GCE CPU Utilization"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
                  aggregation = {
                    alignmentPeriod    = "60s"
                    perSeriesAligner   = "ALIGN_MEAN"
                  }
                }
              }
            }]
          }
        },
        {
          title = "Cloud Run Request Count"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\""
                  aggregation = {
                    alignmentPeriod    = "60s"
                    perSeriesAligner   = "ALIGN_RATE"
                  }
                }
              }
            }]
          }
        }
      ]
    }
  })
}
