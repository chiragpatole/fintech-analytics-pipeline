variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_number" {
  description = "GCP numeric project number (find via: gcloud projects describe PROJECT_ID)"
  type        = string
}

variable "region" {
  description = "Default GCP region for provider"
  type        = string
  default     = "europe-west3" # Frankfurt -- keep data in the EU
}

variable "bq_location" {
  description = "BigQuery dataset location"
  type        = string
  default     = "EU"
}

variable "billing_account_id" {
  description = "Billing account ID (format XXXXXX-XXXXXX-XXXXXX)"
  type        = string
}

variable "alert_email" {
  description = "Where budget threshold alerts get sent"
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget cap in EUR (tripwire, not an expected spend)"
  type        = number
  default     = 5
}
