from __future__ import annotations

from metadata.datahub.emit_metadata import build_metadata_events


def test_metadata_events_include_ownership_and_tags() -> None:
    events = build_metadata_events("dev")
    aspect_names = {event["aspectName"] for event in events}
    assert {"ownership", "globalTags"} <= aspect_names
    assert any("FACT_ORDERS" in event["entityUrn"] for event in events)
