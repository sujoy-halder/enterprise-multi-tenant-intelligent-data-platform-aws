from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

from include.defaults import DEFAULT_ARGS

CDC_SOURCES = {
    "postgresql": ["customers", "orders", "payments"],
    "mysql": ["shipments", "inventory", "suppliers"],
}


with DAG(
    dag_id="enterprise_cdc_ingestion",
    description="Nightly CDC ingestion from PostgreSQL and MySQL into the bronze lake.",
    default_args=DEFAULT_ARGS,
    start_date=datetime(2026, 1, 1),
    schedule="30 2 * * *",
    catchup=False,
    tags=["enterprise-data-platform", "cdc", "batch"],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end")

    with TaskGroup("extract_cdc") as extract_cdc:
        for engine, tables in CDC_SOURCES.items():
            for table in tables:
                BashOperator(
                    task_id=f"{engine}_{table}",
                    bash_command=(
                        "python /app/scripts/extract_cdc.py "
                        f"--engine {engine} --table {table} "
                        "--target-bucket $DATA_LAKE_BUCKET "
                        "--secret-id data-platform/${ENVIRONMENT:-dev}/source-databases"
                    ),
                )

    validate_landing = BashOperator(
        task_id="validate_landing_files",
        bash_command="python /app/scripts/validate_landing_files.py --bucket $DATA_LAKE_BUCKET",
    )

    start >> extract_cdc >> validate_landing >> end
