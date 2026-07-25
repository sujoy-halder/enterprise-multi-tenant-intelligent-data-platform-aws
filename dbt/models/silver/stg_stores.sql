with source as (
    select * from {{ source('silver', 'stores') }}
)

select
    cast(store_id as varchar) as store_id,
    cast(store_name as varchar) as store_name,
    cast(region as varchar) as region,
    cast(country_code as varchar) as country_code,
    cast(opened_at as date) as opened_at
from source
