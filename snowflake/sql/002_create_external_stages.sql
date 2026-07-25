use role accountadmin;
use database ENTERPRISE_ANALYTICS;

create storage integration if not exists AWS_DATA_LAKE_INTEGRATION
  type = external_stage
  storage_provider = s3
  enabled = true
  storage_aws_role_arn = 'arn:aws:iam::000000000000:role/enterprise-data-platform-dev-snowflake'
  storage_allowed_locations = (
    's3://enterprise-data-platform-dev-lake-000000000000/bronze/',
    's3://enterprise-data-platform-dev-lake-000000000000/silver/',
    's3://enterprise-data-platform-dev-lake-000000000000/gold/'
  );

describe integration AWS_DATA_LAKE_INTEGRATION;

create file format if not exists BRONZE.JSON_FORMAT
  type = json
  strip_outer_array = false;

create file format if not exists SILVER.PARQUET_FORMAT
  type = parquet;

create stage if not exists BRONZE.BRONZE_STAGE
  url = 's3://enterprise-data-platform-dev-lake-000000000000/bronze/'
  storage_integration = AWS_DATA_LAKE_INTEGRATION
  file_format = BRONZE.JSON_FORMAT;

create stage if not exists SILVER.SILVER_STAGE
  url = 's3://enterprise-data-platform-dev-lake-000000000000/silver/'
  storage_integration = AWS_DATA_LAKE_INTEGRATION
  file_format = SILVER.PARQUET_FORMAT;

create stage if not exists GOLD.GOLD_STAGE
  url = 's3://enterprise-data-platform-dev-lake-000000000000/gold/'
  storage_integration = AWS_DATA_LAKE_INTEGRATION
  file_format = SILVER.PARQUET_FORMAT;

grant usage on integration AWS_DATA_LAKE_INTEGRATION to role LOADER_ROLE;
grant usage on stage BRONZE.BRONZE_STAGE to role LOADER_ROLE;
grant usage on stage SILVER.SILVER_STAGE to role TRANSFORMER_ROLE;
grant usage on stage GOLD.GOLD_STAGE to role TRANSFORMER_ROLE;
