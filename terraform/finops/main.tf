terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "REPLACE_WITH_YOUR_TF_STATE_BUCKET" # created once, manually or via bootstrap/
    prefix = "finops/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "billing_export" {
  source = "../modules/billing-export"

  project_id                  = var.project_id
  dataset_id                  = "billing_export"
  location                    = var.bq_location
  billing_service_agent_email = var.billing_service_agent_email
}

module "budget_alert" {
  source = "../modules/budget-alert"

  billing_account_id = var.billing_account_id
  project_number      = var.project_number
  alert_email         = var.alert_email
  budget_amount       = var.budget_amount
}
