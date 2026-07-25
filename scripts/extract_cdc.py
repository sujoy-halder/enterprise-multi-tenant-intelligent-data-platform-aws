from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime

import boto3


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--engine", choices=["postgresql", "mysql"], required=True)
    parser.add_argument("--table", required=True)
    parser.add_argument("--target-bucket", required=True)
    parser.add_argument("--secret-id", required=True)
    args = parser.parse_args()

    secrets = boto3.client("secretsmanager")
    s3 = boto3.client("s3")
    secret = secrets.get_secret_value(SecretId=args.secret_id)
    connection = json.loads(secret["SecretString"])

    marker = {
        "engine": args.engine,
        "table": args.table,
        "extracted_at": datetime.now(UTC).isoformat(),
        "connection_host": connection.get("host", "configured"),
        "note": "Replace marker extraction with Debezium, DMS, or source-specific CDC connector.",
    }

    key = (
        f"bronze/domain=cdc/source={args.engine}/table={args.table}/"
        f"run_date={datetime.now(UTC):%Y-%m-%d}/_SUCCESS.json"
    )
    s3.put_object(
        Bucket=args.target_bucket,
        Key=key,
        Body=json.dumps(marker, indent=2).encode("utf-8"),
        ContentType="application/json",
        ServerSideEncryption="aws:kms",
    )
    print(f"wrote cdc marker s3://{args.target_bucket}/{key}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
