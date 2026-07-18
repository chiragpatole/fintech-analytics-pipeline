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

variable "billing_service_agent_email" {
  description = <<-EOT
    Email of the Cloud Billing service agent for your billing account, in the
    form billing-export-bigquery@[PROJECT_NUMBER].iam.gserviceaccount.com
    (shown in the console when you first configure billing export, or
    derivable once export is enabled once manually).
  EOT
  type        = string
}
