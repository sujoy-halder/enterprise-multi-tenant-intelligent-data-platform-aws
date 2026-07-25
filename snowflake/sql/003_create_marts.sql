use role DATA_PLATFORM_ADMIN;
use database ENTERPRISE_ANALYTICS;

create schema if not exists MARTS_FINANCE;
create schema if not exists MARTS_SALES;
create schema if not exists MARTS_SUPPLY_CHAIN;
create schema if not exists MARTS_CUSTOMER_ANALYTICS;
create schema if not exists MARTS_EXECUTIVE;

grant usage on schema MARTS_FINANCE to role ANALYST_ROLE;
grant usage on schema MARTS_SALES to role ANALYST_ROLE;
grant usage on schema MARTS_SUPPLY_CHAIN to role ANALYST_ROLE;
grant usage on schema MARTS_CUSTOMER_ANALYTICS to role ANALYST_ROLE;
grant usage on schema MARTS_EXECUTIVE to role ANALYST_ROLE;

grant select on future tables in schema MARTS_FINANCE to role ANALYST_ROLE;
grant select on future tables in schema MARTS_SALES to role ANALYST_ROLE;
grant select on future tables in schema MARTS_SUPPLY_CHAIN to role ANALYST_ROLE;
grant select on future tables in schema MARTS_CUSTOMER_ANALYTICS to role ANALYST_ROLE;
grant select on future tables in schema MARTS_EXECUTIVE to role ANALYST_ROLE;

create or replace view MARTS_EXECUTIVE.PLATFORM_DATA_PRODUCTS as
select 'finance_revenue_daily' as data_product, 'Finance' as domain, 'finance-data@company.example' as owner
union all select 'sales_daily', 'Retail', 'retail-data@company.example'
union all select 'supply_chain_shipments_daily', 'Logistics', 'logistics-data@company.example'
union all select 'customer_360', 'Customer Analytics', 'customer-data@company.example';
