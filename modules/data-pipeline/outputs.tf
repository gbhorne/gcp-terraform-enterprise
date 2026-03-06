output "landing_bucket_name" {
  value = google_storage_bucket.landing.name
}

output "curated_bucket_name" {
  value = google_storage_bucket.curated.name
}

output "pubsub_topic_name" {
  value = google_pubsub_topic.file_uploaded.name
}

output "bigquery_dataset_id" {
  value = google_bigquery_dataset.pipeline.dataset_id
}

output "bigquery_table_id" {
  value = google_bigquery_table.raw_events.table_id
}

output "function_name" {
  value = google_cloudfunctions2_function.etl_processor.name
}
