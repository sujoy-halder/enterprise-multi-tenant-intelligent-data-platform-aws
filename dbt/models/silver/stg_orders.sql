with source as (
    select * from {{ source('silver', 'orders') }}
),

renamed as (
    select
        cast(order_id as varchar) as order_id,
        cast(customer_id as varchar) as customer_id,
        cast(store_id as varchar) as store_id,
        cast(product_id as varchar) as product_id,
        cast(order_status as varchar) as order_status,
        cast(order_amount as number(18, 2)) as order_amount,
        cast(event_ts as timestamp_ntz) as order_ts,
        cast(updated_at as timestamp_ntz) as updated_at
    from source
)

select * from renamed
