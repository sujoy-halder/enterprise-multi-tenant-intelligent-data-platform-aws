from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator

from include.defaults import DEFAULT_ARGS


with DAG(
    dag_id="enterprise_data_quality_daily",
    description="Daily Great Expectations validation for business-ready data products.",
    default_args=DEFAULT_ARGS,
    start_date=datetime(2026, 1, 1),
    schedule="45 6 * * *",
    catchup=False,
    tags=["enterprise-data-platform", "quality"],
) as dag:
    run_gold_checkpoint = BashOperator(
        task_id="run_gold_checkpoint",
        bash_command=(
            "great_expectations checkpoint run enterprise_gold_checkpoint "
            "--directory /app/quality/great_expectations"
        ),
    )

    publish_quality_summary = BashOperator(
        task_id="publish_quality_summary",
        bash_command=(
            "python /app/scripts/publish_quality_summary.py "
            "--checkpoint enterprise_gold_checkpoint "
            "--environment ${ENVIRONMENT:-dev}"
        ),
    )

    run_gold_checkpoint >> publish_quality_summary
