from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml


@dataclass(frozen=True)
class DomainSpec:
    name: str
    owner: str
    event_types: tuple[str, ...]
    pii_fields: tuple[str, ...]
    freshness_minutes: int


def default_config_path() -> Path:
    return Path(__file__).resolve().parents[1] / "conf" / "domain_config.yaml"


def load_config(path: str | os.PathLike[str] | None = None) -> dict[str, Any]:
    config_path = Path(path) if path else default_config_path()
    with config_path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def load_domain_specs(path: str | os.PathLike[str] | None = None) -> dict[str, DomainSpec]:
    config = load_config(path)
    domains = config.get("domains", {})
    return {
        name: DomainSpec(
            name=name,
            owner=spec["owner"],
            event_types=tuple(spec.get("event_types", [])),
            pii_fields=tuple(spec.get("pii_fields", [])),
            freshness_minutes=int(spec.get("freshness_minutes", 60)),
        )
        for name, spec in domains.items()
    }


def resolve_domains(requested_domain: str, available_domains: list[str] | tuple[str, ...]) -> list[str]:
    if requested_domain == "all":
        return sorted(available_domains)
    if requested_domain not in available_domains:
        raise ValueError(f"Unsupported domain {requested_domain!r}. Expected one of {available_domains}.")
    return [requested_domain]


def lake_uri(bucket: str, prefix: str, domain: str) -> str:
    return f"s3a://{bucket}/{prefix}/domain={domain}"
