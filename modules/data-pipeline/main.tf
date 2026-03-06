locals {
  bucket_prefix = "${var.project_id}-${var.environment}"
}

resource "google_storage_bucket" "landing" {
  name                        = "${local.bucket_prefix}-landing"
  project                     = var.project_id
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = true

  lifecycle_rule {
    condition { age = 30 }
    action    { type = "Delete" }
  }

  labels = {
    environment = var.environment
    tier        = "landing"
  }
}

resource "google_storage_bucket" "curated" {
  name                        = "${local.bucket_prefix}-curated"
  project                     = var.project_id
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }

  labels = {
    environment = var.environment
    tier        = "curated"
  }
}

resource "google_storage_bucket" "function_source" {
  name                        = "${local.bucket_prefix}-function-source"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

data "archive_file" "function_zip" {
  type        = "zip"
  output_path = "/tmp/etl-function.zip"
  source_dir  = "${path.module}/function_source"
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "etl-function-${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_zip.output_path
}

resource "google_pubsub_topic" "file_uploaded" {
  name    = "${var.environment}-file-uploaded"
  project = var.project_id

  message_retention_duration = "86600s"

  labels = {
    environment = var.environment
  }
}

resource "google_pubsub_topic" "dead_letter" {
  name    = "${var.environment}-etl-dead-letter"
  project = var.project_id
}

resource "google_pubsub_subscription" "etl_trigger" {
  name    = "${var.environment}-etl-trigger-sub"
  project = var.project_id
  topic   = google_pubsub_topic.file_uploaded.name

  ack_deadline_seconds = 60

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }
}

data "google_storage_project_service_account" "gcs_sa" {
  project = var.project_id
}

resource "google_pubsub_topic_iam_member" "gcs_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.file_uploaded.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_sa.email_address}"
}

resource "google_storage_notification" "landing_upload" {
  bucket         = google_storage_bucket.landing.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.file_uploaded.id
  event_types    = ["OBJECT_FINALIZE"]

  depends_on = [google_pubsub_topic_iam_member.gcs_publisher]
}

resource "google_bigquery_dataset" "pipeline" {
  dataset_id                 = "${replace(var.environment, "-", "_")}_pipeline"
  project                    = var.project_id
  location                   = "US"
  description                = "Data pipeline dataset for ${var.environment}"
  delete_contents_on_destroy = true

  labels = {
    environment = var.environment
  }
}

resource "google_bigquery_table" "raw_events" {
  dataset_id          = google_bigquery_dataset.pipeline.dataset_id
  table_id            = "raw_events"
  project             = var.project_id
  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "event_timestamp"
  }

  schema = jsonencode([
    { name = "event_id",        type = "STRING",    mode = "REQUIRED" },
    { name = "event_type",      type = "STRING",    mode = "REQUIRED" },
    { name = "event_timestamp", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "source_file",     type = "STRING",    mode = "NULLABLE" },
    { name = "payload",         type = "JSON",      mode = "NULLABLE" },
    { name = "processed_at",    type = "TIMESTAMP", mode = "NULLABLE" },
  ])
}

resource "google_cloudfunctions2_function" "etl_processor" {
  name     = "${var.environment}-etl-processor"
  project  = var.project_id
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "process_file"

    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    max_instance_count    = 3
    min_instance_count    = 0
    available_memory      = "256M"
    timeout_seconds       = 300
    service_account_email = var.data_pipeline_sa_email

    environment_variables = {
      PROJECT_ID     = var.project_id
      ENVIRONMENT    = var.environment
      CURATED_BUCKET = google_storage_bucket.curated.name
      BQ_DATASET     = google_bigquery_dataset.pipeline.dataset_id
      BQ_TABLE       = google_bigquery_table.raw_events.table_id
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.file_uploaded.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}
