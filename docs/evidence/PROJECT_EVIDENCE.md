# Project Evidence

Repository: `sujoy-halder/enterprise-multi-tenant-intelligent-data-platform-aws`
Audit date: 2026-09-02
Primary platform: AWS
Portfolio role: Enterprise multi-tenant intelligent data platform with streaming, CDC, medallion lakehouse, Spark/Databricks, Snowflake, dbt, Airflow, EKS, Terraform, Great Expectations, governance, observability, security, and CI/CD.

## Cloud Proof Boundary

- This repository is a production-style engineering portfolio project with executable infrastructure, pipeline, CI, and documentation assets.
- Local evidence means repository files, tests, static checks, CI configuration, and validation commands that can run without cloud credentials.
- Authenticated AWS, Databricks, Snowflake, or other cloud deployment proof must include real run logs, resource IDs, workspace URLs, screenshots, or exported command output.
- No live cloud deployment is claimed by this file unless those authenticated artifacts are committed under `docs/evidence/`.

## Proof Inventory

- `README.md` explains the project purpose and reviewer path.
- `.github/workflows/evidence-check.yml` validates the core evidence files on push and pull request.
- Existing project docs, tests, Terraform, and workflow files are part of the reviewable proof surface.
- Future deployment evidence should be added as timestamped files under `docs/evidence/`.

## Reviewer Validation Commands

```bash
git clone https://github.com/sujoy-halder/enterprise-multi-tenant-intelligent-data-platform-aws.git
cd enterprise-multi-tenant-intelligent-data-platform-aws
test -f README.md
test -f docs/evidence/PROJECT_EVIDENCE.md
test -f LICENSE || test -f LICENSE.md
find . -maxdepth 3 -type f | sort | sed -n '1,120p'
```

## Evidence To Add After Authenticated Deployment

- AWS `terraform plan` or `terraform apply` output with sensitive values removed.
- EKS, streaming, CDC, Airflow, or S3/lakehouse validation screenshots or JSON exports.
- Databricks/Snowflake/dbt validation outputs where applicable.
- CI run URL proving the validation workflow passed on GitHub-hosted runners.
