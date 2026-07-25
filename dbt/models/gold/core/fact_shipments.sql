{{ config(unique_key='shipment_id') }}

select
    shipment_id,
    order_id,
    carrier,
    origin_location_id,
    destination_location_id,
    shipment_status,
    shipment_ts,
    updated_at
from {{ ref('stg_shipments') }}

{% if is_incremental() %}
where updated_at > (select coalesce(max(updated_at), '1900-01-01') from {{ this }})
{% endif %}
