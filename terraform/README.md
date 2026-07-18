# Phase 1 — Terraform Foundation

Two steps, in order. Bootstrap has no remote backend (chicken-and-egg problem
— can't store state in a bucket that doesn't exist), core does.

## Prerequisites (do these once, manually)
1. Create a GCP project in the console (or `gcloud projects create`), note the
   **project ID**.
2. Link a billing account to it.
3. `gcloud auth application-default login` locally so Terraform can authenticate.

## 1. Bootstrap

```bash
cd terraform/bootstrap
terraform init
terraform apply -var="project_id=YOUR_PROJECT_ID"
```

Note the `state_bucket_name` output — you need it next.

## 2. Core

```bash
cd ../core
# Edit main.tf: set the backend "gcs" bucket to the bootstrap output
terraform init
terraform apply \
  -var="project_id=YOUR_PROJECT_ID" \
  -var="github_repo=YOUR_GH_USERNAME/fintech-analytics-pipeline"
```

This creates: `raw`, `analytics_dev`, `analytics_prod` BigQuery datasets, a
GCS landing bucket, and the GitHub Actions CI service account with Workload
Identity Federation (no static JSON keys — resource name to use as a GitHub
secret is in the `workload_identity_provider` output).

## After this phase

You'll have real values to wire into:
- **GitHub repo secrets**: `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT_EMAIL`
  (from the `ci_service_account_email` output)
- **dbt `profiles.yml`**: `dataset: analytics_dev` / `analytics_prod` per target
- **Data generator config**: `raw_landing_bucket` output as the GCS destination

## Cost check

All resources here are free-tier: datasets and buckets cost nothing until
they hold real data volume, and IAM/WIF resources have no charge.

## Next: Phase 2

Once `terraform apply` succeeds on both, we build the synthetic transaction
generator and the load-to-BigQuery step.
