import base64
import json
import os
import csv
import io
import uuid
from datetime import datetime, timezone

from google.cloud import storage, bigquery

PROJECT_ID     = os.environ.get("PROJECT_ID")
ENVIRONMENT    = os.environ.get("ENVIRONMENT", "dev")
CURATED_BUCKET = os.environ.get("CURATED_BUCKET")
BQ_DATASET     = os.environ.get("BQ_DATASET")
BQ_TABLE       = os.environ.get("BQ_TABLE")

storage_client = storage.Client(project=PROJECT_ID)
bq_client      = bigquery.Client(project=PROJECT_ID)


def process_file(event, context):
    print(f"[{ENVIRONMENT}] ETL function triggered")

    try:
        message_data = base64.b64decode(event["data"]).decode("utf-8")
        gcs_event = json.loads(message_data)
    except Exception as e:
        print(f"ERROR: Failed to decode message: {e}")
        return

    bucket_name = gcs_event.get("bucket")
    object_name = gcs_event.get("name")

    if not bucket_name or not object_name:
        print("ERROR: Missing bucket or object name")
        return

    print(f"Processing: gs://{bucket_name}/{object_name}")

    if not object_name.endswith(".csv"):
        print(f"Skipping non-CSV file: {object_name}")
        return

    try:
        rows         = read_csv(bucket_name, object_name)
        record_count = write_to_bigquery(rows, object_name)
        move_to_curated(bucket_name, object_name)
        print(f"SUCCESS: Processed {record_count} records")
    except Exception as e:
        print(f"ERROR: {e}")
        raise


def read_csv(bucket_name, object_name):
    bucket  = storage_client.bucket(bucket_name)
    blob    = bucket.blob(object_name)
    content = blob.download_as_text()
    return list(csv.DictReader(io.StringIO(content)))


def write_to_bigquery(rows, source_file):
    table_ref = f"{PROJECT_ID}.{BQ_DATASET}.{BQ_TABLE}"
    now       = datetime.now(timezone.utc).isoformat()

    bq_rows = [
        {
            "event_id":        str(uuid.uuid4()),
            "event_type":      "file_ingestion",
            "event_timestamp": now,
            "source_file":     source_file,
            "payload":         json.dumps(row),
            "processed_at":    now,
        }
        for row in rows
    ]

    errors = bq_client.insert_rows_json(table_ref, bq_rows)
    if errors:
        raise RuntimeError(f"BigQuery insert errors: {errors}")

    return len(bq_rows)


def move_to_curated(source_bucket_name, object_name):
    source_bucket = storage_client.bucket(source_bucket_name)
    dest_bucket   = storage_client.bucket(CURATED_BUCKET)
    source_blob   = source_bucket.blob(object_name)
    dest_name     = f"processed/{datetime.now().strftime('%Y/%m/%d')}/{object_name}"
    source_bucket.copy_blob(source_blob, dest_bucket, dest_name)
    print(f"Moved to curated: {dest_name}")
