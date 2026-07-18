"""
generate_transactions.py

Generates synthetic bank transaction data for the fintech-analytics-pipeline
portfolio project. Two modes:

  backfill  — generates a large historical batch (default ~100k rows) spread
              across the last N days, for the initial load into `raw`.
  daily     — generates a single day's incremental batch (default ~1.5k rows),
              meant to be run once a day (locally, or later via GitHub
              Actions cron in Phase 6) to feed a dbt incremental model.

Output: Parquet file written locally, then uploaded to the GCS raw-landing
bucket created in Phase 1.

Usage:
    python generate_transactions.py --mode backfill --rows 100000 --days 90
    python generate_transactions.py --mode daily --rows 1500

Requires: faker, pandas, pyarrow, google-cloud-storage
    pip install -r requirements.txt
"""

import argparse
import random
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pandas as pd
from faker import Faker

fake = Faker()
Faker.seed(42)  # reproducible synthetic data — useful for demo consistency
random.seed(42)

MERCHANT_CATEGORIES = [
    "groceries", "dining", "travel", "electronics", "utilities",
    "entertainment", "healthcare", "clothing", "fuel", "subscriptions",
    "insurance", "rent", "transfer",
]

TRANSACTION_TYPES = ["purchase", "refund", "transfer", "withdrawal", "deposit"]

CURRENCIES = ["EUR", "USD", "GBP"]

COUNTRIES = ["DE", "FR", "NL", "ES", "IT", "US", "GB", "PL"]

# Fixed pool of synthetic customers/accounts so aggregations (RFM, per-account
# behavior) actually have repeat activity to analyze, instead of every row
# being a unique one-off entity.
NUM_CUSTOMERS = 2000


def _customer_pool(n=NUM_CUSTOMERS):
    return [
        {
            "customer_id": str(uuid.uuid4()),
            "account_id": str(uuid.uuid4()),
            "home_country": random.choice(COUNTRIES),
        }
        for _ in range(n)
    ]


def _generate_amount(txn_type: str) -> float:
    if txn_type == "rent" or txn_type == "transfer":
        return round(random.uniform(200, 2500), 2)
    if txn_type == "withdrawal":
        return round(random.uniform(20, 500), 2)
    return round(random.uniform(2, 800), 2)


def generate_transactions(n_rows: int, start_date: datetime, end_date: datetime,
                           customers: list) -> pd.DataFrame:
    rows = []
    span_seconds = int((end_date - start_date).total_seconds())

    for _ in range(n_rows):
        customer = random.choice(customers)
        txn_type = random.choice(TRANSACTION_TYPES)
        category = random.choice(MERCHANT_CATEGORIES)
        timestamp = start_date + timedelta(seconds=random.randint(0, max(span_seconds, 1)))

        # ~1.5% fraud rate, skewed toward higher amounts and foreign country
        # mismatches — gives the fraud mart something real to detect.
        is_fraud = random.random() < 0.015
        amount = _generate_amount(txn_type)
        if is_fraud:
            amount = round(amount * random.uniform(2, 6), 2)

        rows.append({
            "transaction_id": str(uuid.uuid4()),
            "customer_id": customer["customer_id"],
            "account_id": customer["account_id"],
            "timestamp": timestamp.isoformat(),
            "amount": amount,
            "currency": random.choice(CURRENCIES),
            "merchant_name": fake.company(),
            "merchant_category": category,
            "transaction_type": txn_type,
            "transaction_country": customer["home_country"] if not is_fraud else random.choice(COUNTRIES),
            "is_fraud": is_fraud,
        })

    return pd.DataFrame(rows)


def upload_to_gcs(local_path: Path, bucket_name: str, blob_name: str):
    from google.cloud import storage

    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.upload_from_filename(str(local_path))
    print(f"Uploaded to gs://{bucket_name}/{blob_name}")


def main():
    parser = argparse.ArgumentParser(description="Generate synthetic fintech transactions")
    parser.add_argument("--mode", choices=["backfill", "daily"], required=True)
    parser.add_argument("--rows", type=int, default=None,
                         help="Row count. Default: 100000 for backfill, 1500 for daily")
    parser.add_argument("--days", type=int, default=90,
                         help="Backfill window in days (backfill mode only)")
    parser.add_argument("--bucket", type=str, default="fintech-analytics-pipeline-raw-landing")
    parser.add_argument("--no-upload", action="store_true",
                         help="Write locally only, skip GCS upload (useful for a first dry run)")
    parser.add_argument("--out-dir", type=str, default="./output")
    args = parser.parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    customers = _customer_pool()
    now = datetime.now(timezone.utc)

    if args.mode == "backfill":
        rows = args.rows or 100_000
        start_date = now - timedelta(days=args.days)
        end_date = now
        blob_prefix = "transactions/backfill"
    else:
        rows = args.rows or 1_500
        start_date = now - timedelta(days=1)
        end_date = now
        blob_prefix = f"transactions/daily/{now.strftime('%Y-%m-%d')}"

    print(f"Generating {rows:,} synthetic transactions ({args.mode} mode)...")
    df = generate_transactions(rows, start_date, end_date, customers)

    filename = f"{args.mode}_{now.strftime('%Y%m%d_%H%M%S')}.parquet"
    local_path = out_dir / filename
    df.to_parquet(local_path, index=False)
    print(f"Wrote {len(df):,} rows to {local_path} ({local_path.stat().st_size / 1024:.0f} KB)")
    print(f"Fraud rate in this batch: {df['is_fraud'].mean() * 100:.2f}%")

    if not args.no_upload:
        upload_to_gcs(local_path, args.bucket, f"{blob_prefix}/{filename}")
    else:
        print("Skipped GCS upload (--no-upload set)")


if __name__ == "__main__":
    main()
