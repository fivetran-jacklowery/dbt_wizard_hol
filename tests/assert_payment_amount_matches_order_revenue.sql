-- Singular test: for successful, non-discounted completed orders,
-- the payment amount should be within 5% of the order revenue.
-- Minor rounding differences in seed data are expected; anything beyond 5%
-- indicates a genuine payment reconciliation issue.
-- Returns violating rows — the test passes when 0 rows are returned.

select
    o.order_id,
    o.order_revenue_dollars,
    p.amount_dollars                                         as payment_amount_dollars,
    abs(o.order_revenue_dollars - p.amount_dollars)
        / nullif(o.order_revenue_dollars, 0)                 as pct_discrepancy

from {{ ref('fct_orders') }} o
inner join {{ ref('fct_payments') }} p
    on o.order_id = p.order_id

where o.order_status = 'completed'
  and p.payment_status = 'success'
  and o.has_promo = false
  and abs(o.order_revenue_dollars - p.amount_dollars)
        / nullif(o.order_revenue_dollars, 0) > 0.05
