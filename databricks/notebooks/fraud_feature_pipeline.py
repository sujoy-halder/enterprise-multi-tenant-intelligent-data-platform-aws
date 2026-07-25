# Databricks notebook source
from pyspark.sql.functions import col, count, sum as spark_sum, window

payments = spark.table("ENTERPRISE_ANALYTICS.GOLD.FACT_PAYMENTS")

features = (
    payments.groupBy("customer_key", window("payment_ts", "1 hour"))
    .agg(
        count("*").alias("payments_last_hour"),
        spark_sum(col("amount")).alias("payment_amount_last_hour"),
    )
    .select(
        "customer_key",
        col("window.start").alias("feature_window_start"),
        col("window.end").alias("feature_window_end"),
        "payments_last_hour",
        "payment_amount_last_hour",
    )
)

features.write.mode("overwrite").saveAsTable("ENTERPRISE_ANALYTICS.GOLD.FRAUD_FEATURES_HOURLY")
