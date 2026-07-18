terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "fintech-analytics-pipeline-tf-state" # terraform/bootstrap output: state_bucket_name
    prefix = "core/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# --- BigQuery datasets -------------------------------------------------
# raw: landing zone for loaded transaction data, source-of-truth for dbt sources
# analytics_dev / analytics_prod: dbt build targets (matches profiles.yml dataset per target)

resource "google_bigquery_dataset" "raw" {
  project    = var.project_id
  dataset_id = "raw"
  location   = var.bq_location
  labels     = { purpose = "landing", managed_by = "terraform" }
}

resource "google_bigquery_dataset" "analytics_dev" {
  project    = var.project_id
  dataset_id = "analytics_dev"
  location   = var.bq_location
  labels     = { purpose = "dbt-dev", managed_by = "terraform" }
}

resource "google_bigquery_dataset" "analytics_prod" {
  project    = var.project_id
  dataset_id = "analytics_prod"
  location   = var.bq_location
  labels     = { purpose = "dbt-prod", managed_by = "terraform" }
}

# --- GCS landing bucket for the synthetic data generator ---------------

resource "google_storage_bucket" "raw_landing" {
  name                        = "${var.project_id}-raw-landing"
  project                     = var.project_id
  location                    = var.bq_location
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete" # synthetic data, no reason to keep raw files past 30 days
    }
  }
}

# --- CI service account + Workload Identity Federation -----------------
# GitHub Actions authenticates as this SA without ever holding a JSON key.

resource "google_service_account" "ci" {
  project      = var.project_id
  account_id   = "github-actions-ci"
  display_name = "GitHub Actions CI/CD"
}

resource "google_bigquery_dataset_iam_member" "ci_raw_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.raw.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_bigquery_dataset_iam_member" "ci_dev_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.analytics_dev.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_bigquery_dataset_iam_member" "ci_prod_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.analytics_prod.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_project_iam_member" "ci_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_storage_bucket_iam_member" "ci_landing_admin" {
  bucket = google_storage_bucket.raw_landing.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # Restrict to your repo only — replace with YOUR_GH_USERNAME/fintech-analytics-pipeline
  attribute_condition = "assertion.repository == \"${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.ci.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}
