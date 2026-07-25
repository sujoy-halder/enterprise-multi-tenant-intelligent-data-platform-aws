# Logging

Use Fluent Bit or your managed EKS log pipeline to ship application, Airflow, Spark, and Kubernetes
logs to OpenSearch.

Recommended index pattern:

```text
data-platform-<environment>-<namespace>-yyyy.MM.dd
```

Keep retention short for verbose Spark executor logs and longer for audit and data quality results.
