FROM python:3.11-alpine3.24

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apk add --no-cache ca-certificates librdkafka

COPY requirements.txt .
RUN apk add --no-cache --virtual .build-deps build-base librdkafka-dev \
    && python -m pip install --upgrade pip setuptools wheel \
    && python -m pip install -r requirements.txt \
    && python -m pip uninstall -y pip setuptools wheel \
    && apk del .build-deps

COPY app ./app

RUN adduser -D -u 10001 appuser
USER 10001

CMD ["python", "-m", "app.main"]
