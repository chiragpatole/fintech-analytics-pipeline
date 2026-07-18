# ---------------------------------------------------------------------------
# Bootstrap — run this ONCE, with local state (no backend block here on
# purpose: you can't store state in a bucket that doesn't exist yet).
#
#   cd terraform/bootstrap
#   terraform init
#   terraform apply
#
# After this succeeds, note the state bucket name in the output and put it
# in terraform/core/main.tf's backend block.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "required" {
  for_each = toset([
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudbilling.googleapis.com",
    "billingbudgets.googleapis.com",
    "monitoring.googleapis.com",
    "sts.googleapis.com", # needed for Workload Identity Federation
    "cloudresourcemanager.googleapis.com", # needed for project-level IAM member resources
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_storage_bucket" "tf_state" {
  name                        = "${var.project_id}-tf-state"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.required]
}
