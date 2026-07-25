FROM bitnami/spark:3.5.6

USER root

RUN python -m pip install --no-cache-dir --upgrade pip setuptools wheel \
    && python -m pip install --no-cache-dir "boto3>=1.34.0" "pyyaml>=6.0.1" "great-expectations>=0.18.0" \
    && python -m pip uninstall -y pip setuptools wheel

WORKDIR /app

COPY spark ./spark
COPY quality ./quality

RUN chown -R 1001:1001 /app
USER 1001

ENV PYTHONPATH=/app

CMD ["/opt/bitnami/spark/bin/spark-submit", "/app/spark/jobs/bronze_to_silver.py", "--domain", "all"]
