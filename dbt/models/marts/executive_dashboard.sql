with sales as (
    select
        sales_date as metric_date,
        sum(gross_sales) as gross_sales,
        sum(order_count) as orders
    from {{ ref('sales_daily') }}
    group by 1
),

finance as (
    select
        revenue_date as metric_date,
        sum(revenue_amount) as recognized_revenue
    from {{ ref('finance_revenue_daily') }}
    where payment_status = 'settled'
    group by 1
),

shipments as (
    select
        shipment_date as metric_date,
        sum(shipment_count) as shipments
    from {{ ref('supply_chain_shipments_daily') }}
    group by 1
)

select
    coalesce(sales.metric_date, finance.metric_date, shipments.metric_date) as metric_date,
    coalesce(sales.gross_sales, 0) as gross_sales,
    coalesce(finance.recognized_revenue, 0) as recognized_revenue,
    coalesce(sales.orders, 0) as orders,
    coalesce(shipments.shipments, 0) as shipments
from sales
full outer join finance using (metric_date)
full outer join shipments using (metric_date)
