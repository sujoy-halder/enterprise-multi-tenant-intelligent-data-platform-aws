from __future__ import annotations

import argparse
import os

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, current_timestamp, expr, from_json
from pyspark.sql.types import MapType, StringType, StructField, StructType

from spark.jobs.common import load_config, load_domain_specs, resolve_domains


EVENT_SCHEMA = StructType(
    [
        StructField("event_id", StringType(), False),
        StructField("event_time", StringType(), False),
        StructField("event_type", StringType(), False),
        StructField("domain", StringType(), False),
        StructField("source", StringType(), True),
        StructField("payload", MapType(StringType(), StringType()), True),
    ]
)


def stream_domain(spark: SparkSession, domain: str, bucket: str, stream_prefix: str, bronze_prefix: str) -> None:
    stream_name = f"{stream_prefix}-{domain}-events"
    output_path = f"s3a://{bucket}/{bronze_prefix}/domain={domain}"
    checkpoint_path = f"s3a://{bucket}/_checkpoints/kinesis/domain={domain}"

    raw = (
        spark.readStream.format("kinesis")
        .option("streamName", stream_name)
        .option("region", os.getenv("AWS_REGION", "us-east-1"))
        .option("initialPosition", "latest")
        .load()
    )

    parsed = (
        raw.select(from_json(col("data").cast("string"), EVENT_SCHEMA).alias("event"))
        .select("event.*")
        .withColumn("bronze_written_at", current_timestamp())
        .withColumn("year", expr("year(to_timestamp(event_time))"))
        .withColumn("month", expr("month(to_timestamp(event_time))"))
        .withColumn("day", expr("day(to_timestamp(event_time))"))
        .withColumn("hour", expr("hour(to_timestamp(event_time))"))
    )

    (
        parsed.writeStream.format("json")
        .option("path", output_path)
        .option("checkpointLocation", checkpoint_path)
        .partitionBy("event_type", "year", "month", "day", "hour")
        .outputMode("append")
        .start()
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--domain", default="all")
    parser.add_argument("--bucket", default=os.environ["DATA_LAKE_BUCKET"])
    parser.add_argument("--stream-prefix", default=os.environ["KINESIS_STREAM_PREFIX"])
    parser.add_argument("--config", default=None)
    args = parser.parse_args()

    config = load_config(args.config)
    specs = load_domain_specs(args.config)
    domains = resolve_domains(args.domain, tuple(specs.keys()))

    spark = SparkSession.builder.appName("enterprise-kinesis-to-bronze").getOrCreate()
    for domain in domains:
        stream_domain(spark, domain, args.bucket, args.stream_prefix, config["lake"]["bronze_prefix"])

    spark.streams.awaitAnyTermination()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
