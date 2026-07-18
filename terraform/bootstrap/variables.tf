variable "project_id" {
  description = "GCP project ID (create this in the console first — Terraform doesn't create projects here)"
  type        = string
}

variable "region" {
  description = "Primary region for the state bucket"
  type        = string
  default     = "europe-west3"
}
