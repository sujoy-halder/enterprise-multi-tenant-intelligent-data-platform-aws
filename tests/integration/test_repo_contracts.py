from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_core_directories_exist() -> None:
    expected = [
        "terraform",
        "kubernetes",
        "airflow",
        "spark",
        "dbt",
        "snowflake",
        "quality",
        "monitoring",
        "metadata",
        "security",
        "docker",
    ]
    for directory in expected:
        assert (ROOT / directory).is_dir()


def test_grafana_dashboard_is_valid_json() -> None:
    dashboard = ROOT / "monitoring/grafana/dashboards/enterprise-data-platform-overview.json"
    payload = json.loads(dashboard.read_text(encoding="utf-8"))
    assert payload["title"] == "Enterprise Data Platform Overview"
