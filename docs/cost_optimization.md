# Cost Optimization

## AWS

- Use S3 lifecycle policies to transition bronze data to infrequent access and archive old raw data.
- Use Kinesis on-demand only for unpredictable workloads; switch to provisioned shards for stable traffic.
- Run stateless consumers and Spark executor pools on spot instances where retry semantics are safe.
- Keep Glue crawler schedules targeted by partition instead of crawling full buckets.
- Use CloudWatch log retention policies and OpenSearch index lifecycle management.

## Snowflake

- Separate ingestion, transformation, and BI warehouses.
- Enable auto-suspend and auto-resume.
- Use small warehouses for scheduled dbt jobs unless query history proves they need larger sizes.
- Configure resource monitors for each business domain.
- Avoid full-refresh dbt jobs in production except during controlled migrations.

## Kubernetes

- Set resource requests and limits for every workload.
- Use HPA for APIs and consumers.
- Use PodDisruptionBudgets for critical services.
- Use separate node groups for system, platform, and Spark workloads.
- Prefer scheduled batch windows over always-on high-capacity compute.
