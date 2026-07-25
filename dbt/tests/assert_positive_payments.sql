select *
from {{ ref('fact_payments') }}
where amount < 0
