# Data Governance

## Ownership Model

Every domain has a data owner, technical owner, and escalation channel:

- Retail: sales and customer behavior data.
- Healthcare: patient monitoring and operational metrics.
- Finance: payments, fraud, invoices, and accounting data.
- Logistics: GPS, shipment, warehouse, and supplier data.

Ownership metadata is stored in `metadata/openmetadata/ownership.yml` and emitted to DataHub by
`metadata/datahub/emit_metadata.py`.

## Classification

Default classifications:

- `PII`: direct identifiers such as name, email, phone, address, national ID.
- `PHI`: healthcare observations and patient monitoring data.
- `PCI`: payment card or tokenized payment fields.
- `Confidential`: finance and supplier contract data.
- `Internal`: operational data that can be shared inside the company.

## Lineage

Lineage is represented through:

- dbt model dependencies and exposures.
- Airflow DAG task dependencies.
- DataHub metadata change events.
- Snowflake query history and grants.

## Data Contracts

Each source must define:

- Schema and owner.
- Freshness SLA.
- Allowed nullability.
- Primary or natural keys.
- PII/PHI/PCI classification.
- Backfill and replay policy.
