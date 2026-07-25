{{ config(unique_key='order_id') }}

select
    orders.order_id,
    {{ platform_surrogate_key(['orders.customer_id']) }} as customer_key,
    {{ platform_surrogate_key(['orders.store_id']) }} as store_key,
    {{ platform_surrogate_key(['orders.product_id']) }} as product_key,
    orders.order_status,
    orders.order_amount,
    orders.order_ts,
    orders.updated_at
from {{ ref('stg_orders') }} orders

{% if is_incremental() %}
where orders.updated_at > (select coalesce(max(updated_at), '1900-01-01') from {{ this }})
{% endif %}
