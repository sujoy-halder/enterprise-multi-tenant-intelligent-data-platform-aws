select
    date_trunc('day', payment_ts) as revenue_date,
    payment_status,
    payment_method,
    count(*) as payment_count,
    sum(amount) as revenue_amount
from {{ ref('fact_payments') }}
group by 1, 2, 3
