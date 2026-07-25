with source as (
    select * from {{ source('silver', 'shipments') }}
)

select
    cast(shipment_id as varchar) as shipment_id,
    cast(order_id as varchar) as order_id,
    cast(carrier as varchar) as carrier,
    cast(origin_location_id as varchar) as origin_location_id,
    cast(destination_location_id as varchar) as destination_location_id,
    cast(shipment_status as varchar) as shipment_status,
    cast(event_ts as timestamp_ntz) as shipment_ts,
    cast(updated_at as timestamp_ntz) as updated_at
from source
