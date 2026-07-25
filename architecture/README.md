# Architecture

`platform.mmd` contains the high-level platform architecture in Mermaid format.

The design follows these principles:

- Shared platform, domain-owned data products.
- Medallion lakehouse with immutable bronze data.
- Kubernetes for stateless services and scheduled runners.
- Snowflake for governed business marts.
- Metadata and quality checks as release gates.
- Observability and cost controls from day one.
