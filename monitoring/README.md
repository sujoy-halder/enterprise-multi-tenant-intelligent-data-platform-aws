# Monitoring

This folder contains Prometheus alert rules and Grafana dashboard provisioning.

Core signals:

- Pipeline latency and freshness.
- Kafka consumer lag and Kinesis iterator age.
- Airflow DAG failures.
- dbt test failures.
- Spark job failures and executor pressure.
- EKS CPU, memory, and pod health.
- Snowflake credits and warehouse queueing through an exporter or scheduled metrics job.
