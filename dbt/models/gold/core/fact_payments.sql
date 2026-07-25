{{ config(unique_key='payment_id') }}

select
    payments.payment_id,
    payments.order_id,
    {{ platform_surrogate_key(['payments.customer_id']) }} as customer_key,
    payments.payment_status,
    payments.payment_method,
    payments.amount,
    payments.payment_ts,
    payments.updated_at
from {{ ref('stg_payments') }} payments

{% if is_incremental() %}
where payments.updated_at > (select coalesce(max(updated_at), '1900-01-01') from {{ this }})
{% endif %}
