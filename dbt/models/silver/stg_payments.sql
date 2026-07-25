with source as (
    select * from {{ source('silver', 'payments') }}
)

select
    cast(payment_id as varchar) as payment_id,
    cast(order_id as varchar) as order_id,
    cast(customer_id as varchar) as customer_id,
    cast(payment_status as varchar) as payment_status,
    cast(payment_method as varchar) as payment_method,
    cast(amount as number(18, 2)) as amount,
    cast(event_ts as timestamp_ntz) as payment_ts,
    cast(updated_at as timestamp_ntz) as updated_at
from source
