select
    date_trunc('day', shipment_ts) as shipment_date,
    carrier,
    shipment_status,
    count(*) as shipment_count
from {{ ref('fact_shipments') }}
group by 1, 2, 3
