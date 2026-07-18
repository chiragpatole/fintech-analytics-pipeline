output "dataset_id" {
  description = "The BigQuery dataset ID created for billing export"
  value       = google_bigquery_dataset.billing_export.dataset_id
}

output "dataset_self_link" {
  value = google_bigquery_dataset.billing_export.self_link
}
