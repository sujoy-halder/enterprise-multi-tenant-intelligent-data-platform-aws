{{ config(unique_key='customer_key') }}

select
    {{ platform_surrogate_key(['customer_id']) }} as customer_key,
    customer_id,
    customer_segment,
    country_code,
    email_hash,
    created_at,
    updated_at
from {{ ref('stg_customers') }}

{% if is_incremental() %}
where updated_at > (select coalesce(max(updated_at), '1900-01-01') from {{ this }})
{% endif %}
