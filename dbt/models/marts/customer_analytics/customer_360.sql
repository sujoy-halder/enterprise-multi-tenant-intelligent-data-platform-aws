select
    customers.customer_key,
    customers.customer_segment,
    customers.country_code,
    count(distinct orders.order_id) as lifetime_orders,
    coalesce(sum(orders.order_amount), 0) as lifetime_revenue,
    max(orders.order_ts) as last_order_ts
from {{ ref('dim_customer') }} customers
left join {{ ref('fact_orders') }} orders
    on customers.customer_key = orders.customer_key
group by 1, 2, 3
