from __future__ import annotations

import json
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover
    yaml = None

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_PATHS = [
    "terraform/environments/dev/main.tf",
    "terraform/modules/platform/main.tf",
    "kubernetes/base/kustomization.yaml",
    "docker/api/Dockerfile",
    "docker/consumer/Dockerfile",
    "airflow/dags/enterprise_platform_dag.py",
    "spark/jobs/bronze_to_silver.py",
    "dbt/dbt_project.yml",
    "snowflake/sql/001_create_foundation.sql",
    "quality/great_expectations/great_expectations.yml",
    "monitoring/prometheus/rules/data-platform-alerts.yaml",
    "metadata/openmetadata/ownership.yml",
    "security/threat-model.md",
    ".github/workflows/ci-cd.yml",
]


def validate_required_paths() -> list[str]:
    return [path for path in REQUIRED_PATHS if not (ROOT / path).exists()]


def validate_json_files() -> list[str]:
    failures: list[str] = []
    for path in ROOT.rglob("*.json"):
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            failures.append(f"{path.relative_to(ROOT)}: {exc}")
    return failures


def validate_yaml_files() -> list[str]:
    if yaml is None:
        return []

    failures: list[str] = []
    for pattern in ("*.yml", "*.yaml"):
        for path in ROOT.rglob(pattern):
            try:
                list(yaml.safe_load_all(path.read_text(encoding="utf-8")))
            except yaml.YAMLError as exc:
                failures.append(f"{path.relative_to(ROOT)}: {exc}")
    return failures


def main() -> int:
    failures: list[str] = []
    missing = validate_required_paths()
    if missing:
        failures.extend([f"missing required path: {path}" for path in missing])
    failures.extend(validate_json_files())
    failures.extend(validate_yaml_files())

    if failures:
        print("Repository validation failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Repository validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
