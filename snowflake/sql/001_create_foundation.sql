use role accountadmin;

create role if not exists DATA_PLATFORM_ADMIN;
create role if not exists LOADER_ROLE;
create role if not exists TRANSFORMER_ROLE;
create role if not exists ANALYST_ROLE;

grant role DATA_PLATFORM_ADMIN to role SYSADMIN;
grant role LOADER_ROLE to role DATA_PLATFORM_ADMIN;
grant role TRANSFORMER_ROLE to role DATA_PLATFORM_ADMIN;
grant role ANALYST_ROLE to role DATA_PLATFORM_ADMIN;

create warehouse if not exists LOADING_WH
  warehouse_size = 'SMALL'
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true;

create warehouse if not exists TRANSFORMING_WH
  warehouse_size = 'MEDIUM'
  auto_suspend = 120
  auto_resume = true
  initially_suspended = true;

create warehouse if not exists BI_WH
  warehouse_size = 'SMALL'
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true;

create database if not exists ENTERPRISE_ANALYTICS;

create schema if not exists ENTERPRISE_ANALYTICS.BRONZE;
create schema if not exists ENTERPRISE_ANALYTICS.SILVER;
create schema if not exists ENTERPRISE_ANALYTICS.GOLD;
create schema if not exists ENTERPRISE_ANALYTICS.MARTS;
create schema if not exists ENTERPRISE_ANALYTICS.GOVERNANCE;

grant usage on database ENTERPRISE_ANALYTICS to role LOADER_ROLE;
grant usage on database ENTERPRISE_ANALYTICS to role TRANSFORMER_ROLE;
grant usage on database ENTERPRISE_ANALYTICS to role ANALYST_ROLE;

grant usage on schema ENTERPRISE_ANALYTICS.BRONZE to role LOADER_ROLE;
grant usage on schema ENTERPRISE_ANALYTICS.SILVER to role TRANSFORMER_ROLE;
grant usage on schema ENTERPRISE_ANALYTICS.GOLD to role TRANSFORMER_ROLE;
grant usage on schema ENTERPRISE_ANALYTICS.MARTS to role ANALYST_ROLE;

grant all privileges on schema ENTERPRISE_ANALYTICS.BRONZE to role LOADER_ROLE;
grant all privileges on schema ENTERPRISE_ANALYTICS.SILVER to role TRANSFORMER_ROLE;
grant all privileges on schema ENTERPRISE_ANALYTICS.GOLD to role TRANSFORMER_ROLE;
grant all privileges on schema ENTERPRISE_ANALYTICS.MARTS to role TRANSFORMER_ROLE;

grant usage on warehouse LOADING_WH to role LOADER_ROLE;
grant usage on warehouse TRANSFORMING_WH to role TRANSFORMER_ROLE;
grant usage on warehouse BI_WH to role ANALYST_ROLE;

create resource monitor if not exists DATA_PLATFORM_MONTHLY_MONITOR
  with credit_quota = 1000
  frequency = monthly
  start_timestamp = immediately
  triggers
    on 75 percent do notify
    on 90 percent do notify
    on 100 percent do suspend;

alter warehouse LOADING_WH set resource_monitor = DATA_PLATFORM_MONTHLY_MONITOR;
alter warehouse TRANSFORMING_WH set resource_monitor = DATA_PLATFORM_MONTHLY_MONITOR;
alter warehouse BI_WH set resource_monitor = DATA_PLATFORM_MONTHLY_MONITOR;
