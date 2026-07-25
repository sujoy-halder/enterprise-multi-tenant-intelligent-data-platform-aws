from __future__ import annotations

import json
import os
from datetime import UTC, datetime
from typing import Any
from uuid import uuid4

import boto3
import structlog
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

log = structlog.get_logger()

PROJECT_NAME = os.getenv("PROJECT_NAME", "enterprise-data-platform")
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
DOMAINS = {domain.strip() for domain in os.getenv("DOMAINS", "").split(",") if domain.strip()}
KINESIS_STREAM_PREFIX = os.getenv("KINESIS_STREAM_PREFIX", f"{PROJECT_NAME}-{ENVIRONMENT}")
DRY_RUN = os.getenv("DRY_RUN", "false").lower() == "true"

kinesis = boto3.client("kinesis", region_name=AWS_REGION)

app = FastAPI(
    title="Enterprise Data Platform Ingestion API",
    version="0.1.0",
    docs_url="/docs",
    redoc_url=None,
)


class EventIn(BaseModel):
    domain: str = Field(..., examples=["retail"])
    event_type: str = Field(..., examples=["orders.created"])
    event_id: str | None = None
    event_time: datetime | None = None
    source: str = Field(default="api")
    payload: dict[str, Any]


class EventAccepted(BaseModel):
    status: str
    domain: str
    event_id: str
    stream_name: str
    dry_run: bool


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "healthy"}


@app.get("/readyz")
def readyz() -> dict[str, Any]:
    return {
        "status": "ready",
        "environment": ENVIRONMENT,
        "domains": sorted(DOMAINS),
    }


@app.get("/domains")
def domains() -> dict[str, list[str]]:
    return {"domains": sorted(DOMAINS)}


@app.post("/events", response_model=EventAccepted, status_code=202)
def accept_event(event: EventIn) -> EventAccepted:
    if DOMAINS and event.domain not in DOMAINS:
        raise HTTPException(status_code=400, detail=f"Unsupported domain: {event.domain}")

    event_id = event.event_id or str(uuid4())
    event_time = event.event_time or datetime.now(UTC)
    stream_name = f"{KINESIS_STREAM_PREFIX}-{event.domain}-events"

    envelope = {
        "event_id": event_id,
        "event_time": event_time.isoformat(),
        "event_type": event.event_type,
        "domain": event.domain,
        "source": event.source,
        "payload": event.payload,
        "ingested_at": datetime.now(UTC).isoformat(),
    }

    if not DRY_RUN:
        try:
            kinesis.put_record(
                StreamName=stream_name,
                PartitionKey=event_id,
                Data=json.dumps(envelope, default=str).encode("utf-8"),
            )
        except Exception as exc:  # boto3 exceptions are broad and service-specific.
            log.exception("failed_to_publish_event", stream_name=stream_name, event_id=event_id)
            raise HTTPException(status_code=502, detail="Failed to publish event") from exc

    log.info("event_accepted", stream_name=stream_name, event_id=event_id, dry_run=DRY_RUN)
    return EventAccepted(
        status="accepted",
        domain=event.domain,
        event_id=event_id,
        stream_name=stream_name,
        dry_run=DRY_RUN,
    )
