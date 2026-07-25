FROM python:3.11-alpine3.24

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DBT_PROFILES_DIR=/app/dbt \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apk add --no-cache ca-certificates libstdc++

RUN python -m pip install --upgrade pip setuptools wheel \
    && python -m pip install "dbt-core>=1.8.0" "dbt-snowflake>=1.8.0" "great-expectations>=0.18.0" \
    && python -m pip uninstall -y pip setuptools wheel

COPY dbt ./dbt
COPY quality ./quality

RUN adduser -D -u 10001 appuser
USER 10001

WORKDIR /app/dbt

CMD ["dbt", "build", "--profiles-dir", "/app/dbt", "--target", "dev"]
