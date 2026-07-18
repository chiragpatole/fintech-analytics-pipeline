# Fintech Analytics Pipeline

An end-to-end analytics engineering pipeline on GCP: synthetic fintech
transaction data, transformed with dbt, provisioned entirely via Terraform,
deployed through CI/CD, with a FinOps cost-governance track layered on top.

## Architecture

```
Python/Faker generator ──▶ GCS (raw-landing) ──▶ BigQuery (raw)
                                                       │
                                                       ▼
                                    dbt: staging ─▶ intermediate ─▶ marts
                                                       │
                        ┌──────────────────────────────┴───────────────────┐
                        ▼                                                  ▼
        fct_daily_transaction_volume                          fraud_summary_by_category
        dim_customer_rfm

GCP Billing Export ──▶ BigQuery (billing_export) ──▶ dbt: FinOps marts
                                                       (cost_by_project_service,
                                                        budget_vs_actual)

GitHub Actions:
  PR      → sqlfluff lint, terraform plan, dbt build (Slim CI)
  main    → terraform apply, dbt build --target prod, publish docs
```

## Stack

| Layer | Tool |
|---|---|
| Infrastructure as Code | Terraform (GCS state, BigQuery datasets, IAM, Workload Identity Federation) |
| Data warehouse | BigQuery |
| Transformation | dbt-core (dbt-bigquery adapter) |
| CI/CD | GitHub Actions — keyless auth via Workload Identity Federation, no static service account keys |
| Cost governance | GCP Billing Export + Terraform-managed budget alerts |
| Data generation | Python (Faker) — synthetic transactions, no real PII |

## Repo structure

```
terraform/
  bootstrap/    one-time: state bucket, API enablement
  core/         BigQuery datasets, GCS landing bucket, CI service account + WIF
  finops/       billing export dataset, budget + alert
  modules/      reusable billing-export and budget-alert modules
data_generator/ synthetic transaction generator + BigQuery loader
dbt_project/    staging → intermediate → marts models, tests, docs
.github/workflows/  CI (PR checks) and CD (deploy) pipelines
```

Each subfolder has its own README with exact setup/run steps.

## Key design decisions worth noting

- **Keyless CI/CD**: GitHub Actions authenticates to GCP via Workload
  Identity Federation, not a downloadable JSON service account key —
  eliminates a common credential-leak vector.
- **Slim CI**: PR builds only re-run dbt models affected by the change
  (`dbt build --select state:modified+`), using a prod manifest published
  to GCS after every deploy — keeps CI fast and query costs near zero.
- **Synthetic data only**: avoids any real PII/regulatory concern while
  still exercising realistic fraud-detection and customer-segmentation
  logic.
- **Cost-bounded by design**: partitioned queries, batch (not streaming)
  loads, and a Terraform-managed €5 budget alert keep this project running
  on GCP's free tier.

## Status

Phases 1-3 complete and verified end-to-end (Terraform applied, 100k
synthetic transactions loaded, 6 dbt models / 20 tests passing). CI/CD
(Phase 4) and FinOps dbt models (Phase 5) in progress.
