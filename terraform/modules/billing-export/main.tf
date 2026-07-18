# ---------------------------------------------------------------------------
# Billing Export Module
#
# Creates the BigQuery dataset that GCP's "Detailed billing export" writes to.
#
# IMPORTANT: Terraform cannot enable the billing export link itself -- Google
# does not expose a public API/resource for that step. After this module
# runs, you must do this ONE manual step in the console:
#
#   Billing > Billing export > Detailed usage cost > Edit settings
#   -> select this project + the dataset this module creates
#
# On enabling export, Google automatically grants its own fixed billing
# export service account (billing-export-bigquery@system.gserviceaccount.com)
# owner access on this dataset -- no manual IAM grant needed here. (An
# earlier version of this module tried to grant a per-project-guessed
# service account manually; that was based on an incorrect assumption
# about how the permission model works and has been removed.)
# ---------------------------------------------------------------------------

resource "google_bigquery_dataset" "billing_export" {
  project                     = var.project_id
  dataset_id                  = var.dataset_id
  friendly_name               = "GCP Billing Export"
  description                 = "Detailed billing export target for FinOps cost-analytics dbt models"
  location                    = var.location
  default_table_expiration_ms = null # billing export tables are partitioned by day; keep indefinitely

  labels = {
    purpose    = "finops"
    managed_by = "terraform"
  }
}
