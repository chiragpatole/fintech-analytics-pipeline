# Phase 2 — Synthetic Transaction Generator

Generates fake bank transactions and loads them into BigQuery `raw.transactions`.

## Setup

```bash
cd data_generator
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Auth: uses your gcloud Application Default Credentials from Phase 1's
# `gcloud auth application-default login` — nothing extra needed locally.
```

## 1. Historical backfill (~100k rows across last 90 days)

```bash
python generate_transactions.py --mode backfill --rows 100000 --days 90
```

This writes a local Parquet file to `./output/` and uploads it to
`gs://fintech-analytics-pipeline-raw-landing/transactions/backfill/`.

Want to test the generator without touching GCP yet? Add `--no-upload`.

## 2. Load the backfill into BigQuery

```bash
python load_to_bigquery.py \
  --source "gs://fintech-analytics-pipeline-raw-landing/transactions/backfill/*.parquet"
```

Creates `raw.transactions` on first run (schema auto-detected from Parquet),
appends on subsequent runs.

## 3. Daily incremental batch (simulates ongoing data arrival)

```bash
python generate_transactions.py --mode daily --rows 1500
python load_to_bigquery.py \
  --source "gs://fintech-analytics-pipeline-raw-landing/transactions/daily/$(date +%Y-%m-%d)/*.parquet"
```

Run this once and you have real historical data for dbt staging models
to build incremental logic against — this is what Phase 6's GitHub
Actions cron job will run automatically once we get there.

## Schema (auto-detected in BigQuery)

| column | type | notes |
|---|---|---|
| transaction_id | STRING | UUID |
| customer_id | STRING | one of 2,000 synthetic customers, repeats across rows |
| account_id | STRING | one per customer |
| timestamp | STRING (ISO 8601) | dbt casts to TIMESTAMP in staging |
| amount | FLOAT | fraud rows have inflated amounts |
| currency | STRING | EUR / USD / GBP |
| merchant_name | STRING | Faker company names |
| merchant_category | STRING | groceries, dining, travel, etc. |
| transaction_type | STRING | purchase, refund, transfer, withdrawal, deposit |
| transaction_country | STRING | ISO country code; mismatched vs. customer home country on ~fraud rows |
| is_fraud | BOOLEAN | ~1.5% of rows |

## Cost check

100k rows of this schema is roughly 5-8 MB as Parquet — nowhere near the
10 GB free BigQuery storage tier or the 5 GB free GCS tier. The load job
itself is free (loading, not querying, is free in BigQuery).

## Next: Phase 3

With real data sitting in `raw.transactions`, we build the dbt project:
staging model (cleans/casts raw columns) → intermediate (fraud flags,
customer aggregates) → marts (RFM segmentation, fraud summary, daily
volume) with tests on each layer.
