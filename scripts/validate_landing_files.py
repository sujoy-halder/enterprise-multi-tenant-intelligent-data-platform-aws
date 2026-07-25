from __future__ import annotations

import argparse

import boto3


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bucket", required=True)
    parser.add_argument("--prefix", default="bronze/")
    args = parser.parse_args()

    s3 = boto3.client("s3")
    response = s3.list_objects_v2(Bucket=args.bucket, Prefix=args.prefix, MaxKeys=10)
    count = response.get("KeyCount", 0)
    if count == 0:
        raise SystemExit(f"No landing files found under s3://{args.bucket}/{args.prefix}")

    print(f"found {count} landing objects under s3://{args.bucket}/{args.prefix}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
