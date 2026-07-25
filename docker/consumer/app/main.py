from __future__ import annotations

import json
import os
import signal
import time
from datetime import UTC, datetime
from uuid import uuid4

import boto3
import structlog
from confluent_kafka import Consumer, KafkaException

log = structlog.get_logger()

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
DATA_LAKE_BUCKET = os.environ["DATA_LAKE_BUCKET"]
BRONZE_PREFIX = os.getenv("BRONZE_PREFIX", "bronze")
DOMAINS = [domain.strip() for domain in os.getenv("DOMAINS", "").split(",") if domain.strip()]
KAFKA_BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "")
KAFKA_TOPIC_PREFIX = os.getenv("KAFKA_TOPIC_PREFIX", "enterprise")
GROUP_ID = os.getenv("KAFKA_GROUP_ID", "enterprise-data-platform-bronze-writer")
DRY_RUN = os.getenv("DRY_RUN", "false").lower() == "true"

s3 = boto3.client("s3", region_name=AWS_REGION)
running = True


def stop(*_args: object) -> None:
    global running
    running = False


def topic_names() -> list[str]:
    return [f"{KAFKA_TOPIC_PREFIX}.{domain}.events" for domain in DOMAINS]


def bronze_key(domain: str, event_type: str, event_time: datetime, event_id: str) -> str:
    return (
        f"{BRONZE_PREFIX}/domain={domain}/event_type={event_type}/"
        f"year={event_time:%Y}/month={event_time:%m}/day={event_time:%d}/hour={event_time:%H}/"
        f"{event_id}.json"
    )


def normalize_message(topic: str, value: bytes) -> tuple[str, dict[str, object]]:
    payload = json.loads(value.decode("utf-8"))
    topic_parts = topic.split(".")
    domain = payload.get("domain") or (topic_parts[1] if len(topic_parts) > 1 else "unknown")
    event_id = str(payload.get("event_id") or uuid4())
    event_type = str(payload.get("event_type") or "unknown")
    event_time = payload.get("event_time") or datetime.now(UTC).isoformat()

    envelope = {
        "event_id": event_id,
        "event_type": event_type,
        "event_time": event_time,
        "domain": domain,
        "payload": payload.get("payload", payload),
        "source_topic": topic,
        "bronze_written_at": datetime.now(UTC).isoformat(),
    }

    parsed_time = datetime.fromisoformat(str(event_time).replace("Z", "+00:00"))
    return bronze_key(str(domain), event_type, parsed_time, event_id), envelope


def write_to_s3(key: str, envelope: dict[str, object]) -> None:
    if DRY_RUN:
        log.info("dry_run_bronze_write", bucket=DATA_LAKE_BUCKET, key=key)
        return

    s3.put_object(
        Bucket=DATA_LAKE_BUCKET,
        Key=key,
        Body=(json.dumps(envelope, default=str) + "\n").encode("utf-8"),
        ContentType="application/json",
        ServerSideEncryption="aws:kms",
    )


def build_consumer() -> Consumer:
    if not KAFKA_BOOTSTRAP_SERVERS:
        raise RuntimeError("KAFKA_BOOTSTRAP_SERVERS is required")

    config = {
        "bootstrap.servers": KAFKA_BOOTSTRAP_SERVERS,
        "group.id": GROUP_ID,
        "auto.offset.reset": "earliest",
        "enable.auto.commit": False,
        "security.protocol": os.getenv("KAFKA_SECURITY_PROTOCOL", "SSL"),
    }

    sasl_mechanism = os.getenv("KAFKA_SASL_MECHANISM")
    sasl_username = os.getenv("KAFKA_SASL_USERNAME")
    sasl_password = os.getenv("KAFKA_SASL_PASSWORD")
    if sasl_mechanism:
        config["sasl.mechanism"] = sasl_mechanism
    if sasl_username:
        config["sasl.username"] = sasl_username
    if sasl_password:
        config["sasl.password"] = sasl_password

    return Consumer(config)


def idle_until_configured() -> int:
    log.warning("kafka_bootstrap_missing_idle_mode")
    while running:
        time.sleep(30)
    return 0


def main() -> int:
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    if not KAFKA_BOOTSTRAP_SERVERS:
        return idle_until_configured()

    topics = topic_names()
    log.info("consumer_starting", topics=topics, bucket=DATA_LAKE_BUCKET, dry_run=DRY_RUN)

    consumer = build_consumer()
    consumer.subscribe(topics)

    try:
        while running:
            message = consumer.poll(1.0)
            if message is None:
                continue
            if message.error():
                raise KafkaException(message.error())

            key, envelope = normalize_message(message.topic(), message.value())
            write_to_s3(key, envelope)
            consumer.commit(message=message, asynchronous=False)
            log.info("message_committed", topic=message.topic(), key=key)
    finally:
        consumer.close()
        time.sleep(1)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
