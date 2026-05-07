-- Singular test: all completed orders must have positive revenue.
-- Returns rows that violate this expectation — the test passes when 0 rows are returned.

select
    order_id,
    order_status,
    order_revenue_dollars
from {{ ref('fct_orders') }}
where order_status = 'completed'
  and order_revenue_dollars <= 0
