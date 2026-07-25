from __future__ import annotations

import argparse
import json
import os
from datetime import UTC, datetime

import requests


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--checkpoint", required=True)
    parser.add_argument("--environment", default="dev")
    args = parser.parse_args()

    webhook_url = os.getenv("SLACK_WEBHOOK_URL")
    summary = {
        "text": (
            f"Data quality checkpoint `{args.checkpoint}` completed for `{args.environment}` "
            f"at {datetime.now(UTC).isoformat()}."
        )
    }

    if not webhook_url:
        print(json.dumps(summary))
        return 0

    response = requests.post(webhook_url, json=summary, timeout=10)
    response.raise_for_status()
    print("quality summary published")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
