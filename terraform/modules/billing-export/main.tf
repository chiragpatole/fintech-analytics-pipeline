# ---------------------------------------------------------------------------
# Billing Export Module
#
# Creates the BigQuery dataset that GCP's "Detailed billing export" writes to.
#
# IMPORTANT: Terraform cannot enable the billing export link itself — Google
# does not expose a public API/resource for that step. After this module
# runs, you must do this ONE manual step in the console:
#
#   Billing > Billing export > Detailed usage cost > Edit settings
#   -> select the project + dataset this module creates
#
# Everything else (dataset, location, retention, IAM so the billing service
# agent can write to it) is handled here.
# ---------------------------------------------------------------------------

resource "google_bigquery_dataset" "billing_export" {
  project                     = var.project_id
  dataset_id                  = var.dataset_id
  friendly_name               = "GCP Billing Export"
  description                 = "Detailed billing export target for FinOps cost-analytics dbt models"
  location                    = var.location
  default_table_expiration_ms = null # billing export tables are partitioned by day; keep indefinitely

  labels = {
    purpose = "finops"
    managed_by = "terraform"
  }
}

# The Cloud Billing service agent needs BigQuery Data Editor on this dataset
# to stream cost records into it. This grant is required even though the
# export *link* itself must be enabled manually in the console.
resource "google_bigquery_dataset_iam_member" "billing_service_agent_writer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.billing_export.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.billing_service_agent_email}"
}
