"""
load_to_bigquery.py

Loads transaction Parquet files from the GCS raw-landing bucket into the
BigQuery `raw` dataset created in Phase 1. Run this after
generate_transactions.py has uploaded a file.

Usage:
    # Load a specific backfill file
    python load_to_bigquery.py --source "gs://fintech-analytics-pipeline-raw-landing/transactions/backfill/*.parquet"

    # Load today's daily batch
    python load_to_bigquery.py --source "gs://fintech-analytics-pipeline-raw-landing/transactions/daily/2026-07-18/*.parquet"

Table is created automatically on first load (schema auto-detected from
Parquet) and set to WRITE_APPEND, so daily incremental loads accumulate
rather than overwrite — dbt's incremental models read from this append-only
raw table.
"""

import argparse

from google.cloud import bigquery


def load(source_uri: str, project_id: str, dataset_id: str, table_id: str):
    client = bigquery.Client(project=project_id)
    table_ref = f"{project_id}.{dataset_id}.{table_id}"

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.PARQUET,
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        # Parquet carries its own schema; autodetect just confirms it on
        # first run, table already exists on subsequent runs.
        autodetect=True,
    )

    load_job = client.load_table_from_uri(source_uri, table_ref, job_config=job_config)
    print(f"Starting load job {load_job.job_id}...")
    load_job.result()  # blocks until done

    table = client.get_table(table_ref)
    print(f"Loaded into {table_ref}. Table now has {table.num_rows:,} rows.")


def main():
    parser = argparse.ArgumentParser(description="Load transaction Parquet files into BigQuery raw dataset")
    parser.add_argument("--source", required=True,
                         help="GCS URI, supports wildcards, e.g. gs://bucket/path/*.parquet")
    parser.add_argument("--project", default="fintech-analytics-pipeline")
    parser.add_argument("--dataset", default="raw")
    parser.add_argument("--table", default="transactions")
    args = parser.parse_args()

    load(args.source, args.project, args.dataset, args.table)


if __name__ == "__main__":
    main()
