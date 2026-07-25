{{ config(unique_key='store_key') }}

select
    {{ platform_surrogate_key(['store_id']) }} as store_key,
    store_id,
    store_name,
    region,
    country_code,
    opened_at
from {{ ref('stg_stores') }}
