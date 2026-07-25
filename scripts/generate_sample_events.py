from __future__ import annotations

import json
from datetime import UTC, datetime
from random import randint, random
from uuid import uuid4

DOMAINS = {
    "retail": "orders.created",
    "healthcare": "patient.monitoring",
    "finance": "payments.authorized",
    "logistics": "gps.location",
}


def main() -> int:
    for domain, event_type in DOMAINS.items():
        event = {
            "event_id": str(uuid4()),
            "event_time": datetime.now(UTC).isoformat(),
            "event_type": event_type,
            "domain": domain,
            "source": "sample-generator",
            "payload": {
                "customer_id": f"C{randint(1000, 9999)}",
                "amount": round(random() * 500, 2),
                "status": "created",
            },
        }
        print(json.dumps(event))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
