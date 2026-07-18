# Phase 3 — dbt Project

Transforms `raw.transactions` (loaded in Phase 2) into staging, intermediate,
and mart-layer models.

```
models/
├── staging/        stg_transactions — cleaned, typed, one row per transaction
├── intermediate/   int_customer_activity, int_fraud_signals — reusable logic
└── marts/          fct_daily_transaction_volume, dim_customer_rfm,
                     fraud_summary_by_category — business-facing tables
```

## Setup

```bash
cd dbt_project
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

mkdir -p ~/.dbt
cp profiles.yml.example ~/.dbt/profiles.yml
```

Uses your existing `gcloud auth application-default login` credentials from
Phase 1 — no extra auth setup needed locally.

## Run it

```bash
dbt debug          # confirms connection to BigQuery works
dbt run            # builds all models into the analytics_dev dataset
dbt test           # runs the uniqueness/not-null/accepted-values tests
dbt docs generate  # builds the documentation site
dbt docs serve     # opens it locally at http://localhost:8080
```

`dbt run` builds against `analytics_dev` by default (see `profiles.yml`'s
`target: dev`). To build against prod: `dbt run --target prod`.

## What to check after `dbt run`

In the BigQuery console, under `analytics_dev`, you should see:
- `stg_transactions` (view)
- `int_customer_activity`, `int_fraud_signals` (views)
- `fct_daily_transaction_volume`, `dim_customer_rfm`, `fraud_summary_by_category` (tables)

Query `dim_customer_rfm` and check the `customer_segment` column has a mix
of champion/loyal/at_risk_high_value/churned/developing — if everything
lands in one segment, the RFM `ntile()` windowing isn't seeing enough
variation (shouldn't happen with 100k rows across 2,000 customers, but
worth a glance).

## Cost check

`dbt run` on 100k rows scans well under 1 GB per model — negligible against
BigQuery's 1 TiB/month free query allowance.

## Next: Phase 4

CI/CD — GitHub Actions running `sqlfluff` lint, `dbt build` (Slim CI) on
pull requests, and `terraform apply` + `dbt run --target prod` on merge to
main.
