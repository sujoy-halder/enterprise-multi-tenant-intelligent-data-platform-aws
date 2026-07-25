from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass


@dataclass(frozen=True)
class CheckResult:
    name: str
    ok: bool
    detail: str


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, check=False, capture_output=True, text=True)


def cluster_available() -> bool:
    client = run(["kubectl", "version", "--client", "-o", "json"])
    if client.returncode != 0:
        return False
    cluster = run(["kubectl", "cluster-info"])
    return cluster.returncode == 0


def check_deployment(namespace: str, deployment: str) -> CheckResult:
    result = run(["kubectl", "get", "deployment", deployment, "-n", namespace, "-o", "json"])
    if result.returncode != 0:
        return CheckResult(deployment, False, result.stderr.strip())

    payload = json.loads(result.stdout)
    ready = payload.get("status", {}).get("readyReplicas", 0)
    desired = payload.get("spec", {}).get("replicas", 0)
    return CheckResult(deployment, ready >= 1, f"{ready}/{desired} ready")


def check_cronjob(namespace: str, cronjob: str) -> CheckResult:
    result = run(["kubectl", "get", "cronjob", cronjob, "-n", namespace, "-o", "name"])
    return CheckResult(cronjob, result.returncode == 0, result.stdout.strip() or result.stderr.strip())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--namespace", default="data-platform")
    parser.add_argument("--environment", default="dev")
    args = parser.parse_args()

    if not cluster_available():
        print("No reachable Kubernetes cluster; skipping cluster smoke tests.")
        return 0

    checks = [
        check_deployment(args.namespace, "enterprise-api"),
        check_deployment(args.namespace, "kafka-consumer"),
        check_cronjob(args.namespace, "dbt-runner"),
        check_cronjob(args.namespace, "spark-bronze-to-silver"),
    ]

    failed = [check for check in checks if not check.ok]
    for check in checks:
        status = "ok" if check.ok else "failed"
        print(f"{status}: {check.name}: {check.detail}")

    if failed:
        return 1

    print(f"Smoke tests passed for {args.environment}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
