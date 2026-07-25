# Snowflake

Run the SQL files in order with an account administrator or a controlled deployment role.

The scripts create:

- Databases, schemas, warehouses, roles, and grants.
- External stages for S3 medallion data.
- Business marts and secure role boundaries.
- Resource monitors for cost control.

Replace placeholder ARNs and S3 bucket names with Terraform outputs before applying in production.
