from __future__ import annotations

from spark.jobs.common import load_domain_specs, resolve_domains


def test_load_domain_specs_contains_all_business_domains() -> None:
    specs = load_domain_specs()
    assert sorted(specs) == ["finance", "healthcare", "logistics", "retail"]
    assert "orders.created" in specs["retail"].event_types
    assert "patient_id" in specs["healthcare"].pii_fields


def test_resolve_domains_supports_all() -> None:
    assert resolve_domains("all", ("retail", "finance")) == ["finance", "retail"]


def test_resolve_domains_rejects_unknown_domain() -> None:
    try:
        resolve_domains("unknown", ("retail",))
    except ValueError as exc:
        assert "Unsupported domain" in str(exc)
    else:
        raise AssertionError("Expected ValueError")
