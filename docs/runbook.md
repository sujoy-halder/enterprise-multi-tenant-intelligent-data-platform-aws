# Operations Runbook

## Pipeline Latency Is High

1. Check Kinesis iterator age and Kafka consumer lag.
2. Inspect Spark executor allocation and failed tasks.
3. Validate downstream Snowflake warehouse queueing.
4. Scale the consumer deployment or Spark executor count.
5. If the issue is source-side throttling, contact the owning domain team.

## Airflow DAG Failure

1. Open the DAG run and identify the failed task.
2. Check task logs in Airflow and CloudWatch.
3. Confirm upstream S3 partitions exist for the target date.
4. Re-run only failed tasks where idempotent.
5. Escalate if dbt tests or Great Expectations checks fail repeatedly.

## Data Quality Failure

1. Identify the suite and expectation from Great Expectations output.
2. Compare row counts and schema with the previous successful partition.
3. Quarantine invalid records under `s3://<lake>/quarantine/<domain>/`.
4. Notify the domain owner listed in `metadata/openmetadata/ownership.yml`.
5. Backfill after the source system or transformation is fixed.

## Snowflake Credit Spike

1. Check active warehouses and query history.
2. Suspend noncritical warehouses.
3. Review dbt model materializations and clustering changes.
4. Confirm no accidental full-refresh is running.
5. Use resource monitors to prevent runaway spend.

## EKS Node Pressure

1. Check pending pods and node allocatable resources.
2. Review HPA and Cluster Autoscaler/Karpenter events.
3. Move bursty Spark jobs onto spot-backed node pools.
4. Raise requests only when metrics prove sustained demand.
5. Rebalance workloads across namespaces if noisy-neighbor issues appear.
