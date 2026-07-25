from __future__ import annotations

import os
import sys


def main() -> int:
    required = ["DATA_LAKE_BUCKET", "DOMAINS"]
    missing = [name for name in required if not os.getenv(name)]
    if missing:
        print(f"missing configuration: {','.join(missing)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
