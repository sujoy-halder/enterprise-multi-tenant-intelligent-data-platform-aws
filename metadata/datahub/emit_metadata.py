from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from pathlib import Path

DOMAINS = {
    "retail": "retail-data@company.example",
    "healthcare": "healthcare-data@company.example",
    "finance": "finance-data@company.example",
    "logistics": "logistics-data@company.example",
}

DATA_PRODUCTS = [
    ("snowflake", "ENTERPRISE_ANALYTICS.GOLD.FACT_ORDERS", "retail"),
    ("snowflake", "ENTERPRISE_ANALYTICS.GOLD.FACT_PAYMENTS", "finance"),
    ("snowflake", "ENTERPRISE_ANALYTICS.GOLD.FACT_SHIPMENTS", "logistics"),
    ("snowflake", "ENTERPRISE_ANALYTICS.GOLD.DIM_CUSTOMER", "retail"),
    ("s3", "s3://lake/gold/customer_360", "retail"),
]


def build_metadata_events(environment: str) -> list[dict[str, object]]:
    emitted_at = datetime.now(UTC).isoformat()
    events: list[dict[str, object]] = []
    for platform, name, domain in DATA_PRODUCTS:
        events.append(
            {
                "entityType": "dataset",
                "entityUrn": f"urn:li:dataset:(urn:li:dataPlatform:{platform},{name},{environment})",
                "changeType": "UPSERT",
                "aspectName": "ownership",
                "aspect": {
                    "owners": [
                        {
                            "owner": f"urn:li:corpuser:{DOMAINS[domain]}",
                            "type": "DATAOWNER",
                        }
                    ],
                    "lastModified": {"time": emitted_at},
                },
            }
        )
        events.append(
            {
                "entityType": "dataset",
                "entityUrn": f"urn:li:dataset:(urn:li:dataPlatform:{platform},{name},{environment})",
                "changeType": "UPSERT",
                "aspectName": "globalTags",
                "aspect": {
                    "tags": [
                        {"tag": f"urn:li:tag:{domain}"},
                        {"tag": "urn:li:tag:enterprise-data-platform"},
                    ]
                },
            }
        )
    return events


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--env", default="dev")
    parser.add_argument("--output", default="")
    args = parser.parse_args()

    events = build_metadata_events(args.env)
    payload = json.dumps(events, indent=2)

    if args.output:
        Path(args.output).write_text(payload, encoding="utf-8")
    else:
        print(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
