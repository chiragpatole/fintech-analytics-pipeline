variable "project_id" {
  description = "GCP project ID that will host the billing export dataset"
  type        = string
}

variable "dataset_id" {
  description = "BigQuery dataset ID to receive the billing export (e.g. billing_export)"
  type        = string
  default     = "billing_export"
}

variable "location" {
  description = "BigQuery dataset location (must match your other datasets for cross-dataset dbt joins)"
  type        = string
  default     = "EU"
}
