from __future__ import annotations

import argparse
import os

from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import col, current_timestamp, from_json, sha2, to_json
from pyspark.sql.types import MapType, StringType, StructField, StructType, TimestampType

from spark.jobs.common import lake_uri, load_config, load_domain_specs, resolve_domains


BRONZE_SCHEMA = StructType(
    [
        StructField("event_id", StringType(), False),
        StructField("event_type", StringType(), False),
        StructField("event_time", StringType(), False),
        StructField("domain", StringType(), False),
        StructField("source", StringType(), True),
        StructField("payload", MapType(StringType(), StringType()), True),
        StructField("ingested_at", StringType(), True),
    ]
)


def normalize_bronze(df: DataFrame) -> DataFrame:
    if "value" in df.columns:
        source_df = df.select(from_json(col("value").cast("string"), BRONZE_SCHEMA).alias("record")).select(
            "record.*"
        )
    else:
        source_df = df

    return (
        source_df
        .withColumn("event_ts", col("event_time").cast(TimestampType()))
        .withColumn("ingested_ts", col("ingested_at").cast(TimestampType()))
        .withColumn("record_hash", sha2(to_json(col("payload")), 256))
        .withColumn("silver_processed_at", current_timestamp())
        .dropDuplicates(["event_id"])
    )


def process_domain(spark: SparkSession, bucket: str, domain: str, config: dict[str, object]) -> None:
    bronze_prefix = config["lake"]["bronze_prefix"]
    silver_prefix = config["lake"]["silver_prefix"]
    source_path = lake_uri(bucket, bronze_prefix, domain)
    target_path = lake_uri(bucket, silver_prefix, domain)

    raw_df = spark.read.option("recursiveFileLookup", "true").json(source_path)
    silver_df = normalize_bronze(raw_df)

    (
        silver_df.repartition("event_type")
        .write.mode("append")
        .partitionBy("event_type")
        .parquet(target_path)
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--domain", default="all")
    parser.add_argument("--bucket", default=os.environ["DATA_LAKE_BUCKET"])
    parser.add_argument("--config", default=None)
    args = parser.parse_args()

    config = load_config(args.config)
    specs = load_domain_specs(args.config)
    domains = resolve_domains(args.domain, tuple(specs.keys()))

    spark = (
        SparkSession.builder.appName("enterprise-bronze-to-silver")
        .config("spark.sql.sources.partitionOverwriteMode", "dynamic")
        .getOrCreate()
    )

    for domain in domains:
        process_domain(spark, args.bucket, domain, config)

    spark.stop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
