output "raw_dataset_id" {
  value = google_bigquery_dataset.raw.dataset_id
}

output "analytics_dev_dataset_id" {
  value = google_bigquery_dataset.analytics_dev.dataset_id
}

output "analytics_prod_dataset_id" {
  value = google_bigquery_dataset.analytics_prod.dataset_id
}

output "raw_landing_bucket" {
  value = google_storage_bucket.raw_landing.name
}

output "ci_service_account_email" {
  value = google_service_account.ci.email
}

output "workload_identity_provider" {
  description = "Full resource name — use as GCP_WORKLOAD_IDENTITY_PROVIDER secret in GitHub Actions"
  value       = google_iam_workload_identity_pool_provider.github.name
}
