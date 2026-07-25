with source as (
    select * from {{ source('silver', 'products') }}
)

select
    cast(product_id as varchar) as product_id,
    cast(sku as varchar) as sku,
    cast(product_name as varchar) as product_name,
    cast(category as varchar) as category,
    cast(unit_price as number(18, 2)) as unit_price,
    cast(updated_at as timestamp_ntz) as updated_at
from source
