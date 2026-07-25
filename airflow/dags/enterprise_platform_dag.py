from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.bash import BashOperator
from airflow.utils.task_group import TaskGroup

from include.defaults import BUSINESS_DOMAINS, DEFAULT_ARGS


with DAG(
    dag_id="enterprise_platform_hourly",
    description="Hourly medallion processing and quality checks for all business domains.",
    default_args=DEFAULT_ARGS,
    start_date=datetime(2026, 1, 1),
    schedule="0 * * * *",
    catchup=False,
    max_active_runs=1,
    tags=["enterprise-data-platform", "medallion", "hourly"],
) as dag:
    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end")

    with TaskGroup("bronze_to_silver") as bronze_to_silver:
        for domain in BUSINESS_DOMAINS:
            BashOperator(
                task_id=f"{domain}_bronze_to_silver",
                bash_command=(
                    "spark-submit /app/spark/jobs/bronze_to_silver.py "
                    f"--domain {domain} --bucket $DATA_LAKE_BUCKET"
                ),
            )

    with TaskGroup("silver_to_gold") as silver_to_gold:
        for domain in BUSINESS_DOMAINS:
            BashOperator(
                task_id=f"{domain}_silver_to_gold",
                bash_command=(
                    "spark-submit /app/spark/jobs/silver_to_gold.py "
                    f"--domain {domain} --bucket $DATA_LAKE_BUCKET"
                ),
            )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command="cd /app/dbt && dbt build --profiles-dir /app/dbt --target ${ENVIRONMENT:-dev}",
    )

    quality_checkpoint = BashOperator(
        task_id="great_expectations_checkpoint",
        bash_command=(
            "great_expectations checkpoint run enterprise_gold_checkpoint "
            "--directory /app/quality/great_expectations"
        ),
    )

    start >> bronze_to_silver >> silver_to_gold >> dbt_build >> quality_checkpoint >> end
