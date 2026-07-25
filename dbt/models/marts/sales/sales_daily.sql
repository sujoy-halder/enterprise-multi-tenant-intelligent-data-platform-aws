select
    date_trunc('day', orders.order_ts) as sales_date,
    stores.region,
    products.category,
    count(*) as order_count,
    sum(orders.order_amount) as gross_sales
from {{ ref('fact_orders') }} orders
left join {{ ref('dim_store') }} stores
    on orders.store_key = stores.store_key
left join {{ ref('dim_product') }} products
    on orders.product_key = products.product_key
group by 1, 2, 3
