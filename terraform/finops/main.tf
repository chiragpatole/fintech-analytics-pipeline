terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "fintech-analytics-pipeline-tf-state"
    prefix = "finops/state"
  }
}

provider "google" {
  project                = var.project_id
  region                  = var.region
  user_project_override  = true
  billing_project         = var.project_id
}

module "billing_export" {
  source = "../modules/billing-export"

  project_id = var.project_id
  dataset_id = "billing_export"
  location   = var.bq_location
}

module "budget_alert" {
  source = "../modules/budget-alert"

  project_id          = var.project_id
  billing_account_id  = var.billing_account_id
  project_number      = var.project_number
  alert_email         = var.alert_email
  budget_amount       = var.budget_amount
}

# The CI service account (created in terraform/core) needs read access to
# this dataset for dbt to build the finops models against it -- it only
# got access to raw/analytics_dev/analytics_prod in Phase 1.
resource "google_bigquery_dataset_iam_member" "ci_billing_export_viewer" {
  project    = var.project_id
  dataset_id = module.billing_export.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:github-actions-ci@${var.project_id}.iam.gserviceaccount.com"
}
