-- Singular test: all completed orders must have positive line-item revenue.
-- Returns rows that violate this expectation — test passes when 0 rows are returned.

select
    order_id,
    order_status,
    order_revenue
from {{ ref('fct_orders') }}
where order_status = 'completed'
  and order_revenue <= 0
