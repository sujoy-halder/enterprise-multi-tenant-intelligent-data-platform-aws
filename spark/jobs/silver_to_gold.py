from __future__ import annotations

import argparse
import os

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, current_date, current_timestamp, sum as spark_sum

from spark.jobs.common import lake_uri, load_config, load_domain_specs, resolve_domains


def build_gold_for_domain(spark: SparkSession, bucket: str, domain: str, config: dict[str, object]) -> None:
    silver_path = lake_uri(bucket, config["lake"]["silver_prefix"], domain)
    gold_path = lake_uri(bucket, config["lake"]["gold_prefix"], domain)

    df = spark.read.parquet(silver_path)

    event_summary = (
        df.groupBy("domain", "event_type")
        .agg(count("*").alias("event_count"))
        .withColumn("as_of_date", current_date())
        .withColumn("gold_processed_at", current_timestamp())
    )

    event_summary.write.mode("overwrite").partitionBy("as_of_date").parquet(
        f"{gold_path}/event_summary"
    )

    if domain == "retail":
        orders = df.filter(col("event_type").isin("orders.created", "orders.updated"))
        (
            orders.groupBy("domain")
            .agg(count("*").alias("orders"), spark_sum(col("payload.amount").cast("double")).alias("gross_sales"))
            .withColumn("as_of_date", current_date())
            .write.mode("overwrite")
            .partitionBy("as_of_date")
            .parquet(f"{gold_path}/sales_summary")
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

    spark = SparkSession.builder.appName("enterprise-silver-to-gold").getOrCreate()
    for domain in domains:
        build_gold_for_domain(spark, args.bucket, domain, config)
    spark.stop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
