output "state_bucket_name" {
  value       = google_storage_bucket.tf_state.name
  description = "Put this in terraform/core/main.tf and terraform/finops/main.tf backend blocks"
}
