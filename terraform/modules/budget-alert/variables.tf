variable "project_id" {
  description = "GCP project ID that hosts the email notification channel"
  type        = string
}

variable "billing_account_id" {
  description = "Your GCP billing account ID (format XXXXXX-XXXXXX-XXXXXX)"
  type        = string
}

variable "project_number" {
  description = "Numeric GCP project number (not the project ID) that the budget scopes to"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive budget threshold alerts"
  type        = string
}

variable "budget_display_name" {
  description = "Display name for the budget in the console"
  type        = string
  default     = "fintech-analytics-pipeline-budget"
}

variable "budget_amount" {
  description = "Monthly budget cap in EUR — set low (e.g. 5) for a solo portfolio project as a tripwire, not a real spend expectation"
  type        = number
  default     = 5
}
