{{ config(unique_key='product_key') }}

select
    {{ platform_surrogate_key(['product_id']) }} as product_key,
    product_id,
    sku,
    product_name,
    category,
    unit_price,
    updated_at
from {{ ref('stg_products') }}

{% if is_incremental() %}
where updated_at > (select coalesce(max(updated_at), '1900-01-01') from {{ this }})
{% endif %}
