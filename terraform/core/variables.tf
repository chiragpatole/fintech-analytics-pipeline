variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default region"
  type        = string
  default     = "europe-west3"
}

variable "bq_location" {
  description = "BigQuery / GCS location"
  type        = string
  default     = "EU"
}

variable "github_repo" {
  description = "Your GitHub repo in owner/name form, e.g. chirag/fintech-analytics-pipeline — restricts WIF to this repo only"
  type        = string
}
