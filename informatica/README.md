# Informatica

This folder documents enterprise ETL mappings for teams that use Informatica Cloud or PowerCenter
alongside the shared platform.

Expected pattern:

1. Source systems land files or CDC extracts into the bronze S3 prefix.
2. Informatica mappings standardize legacy ERP, supplier, and finance data.
3. Outputs are written to silver S3 prefixes or Snowflake staging tables.
4. Airflow triggers downstream dbt and quality checks.
