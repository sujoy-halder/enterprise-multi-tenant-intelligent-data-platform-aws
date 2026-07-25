with source as (
    select * from {{ source('silver', 'customers') }}
)

select
    cast(customer_id as varchar) as customer_id,
    cast(customer_segment as varchar) as customer_segment,
    cast(country_code as varchar) as country_code,
    cast(created_at as timestamp_ntz) as created_at,
    cast(updated_at as timestamp_ntz) as updated_at,
    sha2(coalesce(cast(email as varchar), ''), 256) as email_hash
from source
