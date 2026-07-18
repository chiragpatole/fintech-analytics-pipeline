# FinOps track — Terraform

Provisions the cost-governance side of the project: a BigQuery dataset to
receive GCP's billing export, and a budget with threshold-based email alerts.

## What Terraform does vs. what you do manually

Terraform-managed:
- BigQuery dataset for billing export (`modules/billing-export`)
- IAM grant so the billing service agent can write to it
- Billing budget + email notification channel (`modules/budget-alert`)

Manual, one-time, console-only (Google doesn't expose an API for this step):
1. **Billing > Billing export > Detailed usage cost > Edit settings** — point
   it at the project + dataset this module creates.
2. Grab the **billing service agent email** shown on that same screen (format
   `billing-export-bigquery@<PROJECT_NUMBER>.iam.gserviceaccount.com`) and put
   it in `terraform.tfvars` as `billing_service_agent_email` *before* you
   apply — the IAM grant needs it.

## Setup order

```bash
# 1. Find your project number
gcloud projects describe YOUR_PROJECT_ID --format="value(projectNumber)"

# 2. Copy and fill in tfvars
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with real values

# 3. Point the backend at your state bucket (created once, e.g. via a
#    bootstrap/ directory with local state, or manually with gsutil mb)
# edit the backend "gcs" block in main.tf

terraform init
terraform plan
terraform apply
```

Then go do the manual console step above, using the dataset name Terraform
just created (`billing_export` by default).

## Required IAM roles for the Terraform service account

The identity running `terraform apply` (your user or a CI service account
via Workload Identity Federation) needs:
- `roles/bigquery.admin` (create dataset, manage IAM on it)
- `roles/billing.budgetsEditor` on the billing account
- `roles/monitoring.notificationChannelEditor`

## Cost of this module itself

€0. The dataset and budget resources have no charge; you only pay for
querying the billing-export data later in dbt, which falls under BigQuery's
1 TiB/month free tier for a project this size.

## Where this feeds into dbt

Once billing export is flowing, the `dbt_project/models/finops/` staging
model reads `billing_export.gcp_billing_export_v1_<BILLING_ACCOUNT_ID>` and
builds marts for:
- `cost_by_project_service` — daily spend broken down by project + SKU/service
- `cost_by_label` — spend grouped by resource labels (useful once you tag
  resources by environment/team)
- `budget_vs_actual` — compares cumulative spend against the Terraform-defined
  budget amount, flagging days where burn rate would exceed it
