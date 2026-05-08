-- Singular test: for completed orders, the sum of line item revenue should
-- equal the order subtotal within 1% (rounding / discount differences expected).
-- Returns violating rows — test passes when 0 rows are returned.

with order_line_totals as (

    select
        order_id,
        sum(line_revenue) as line_revenue_total

    from {{ ref('fct_order_items') }}
    group by 1

),

orders as (

    select
        order_id,
        subtotal,
        order_status

    from {{ ref('fct_orders') }}
    where order_status = 'completed'

)

select
    o.order_id,
    o.subtotal,
    olt.line_revenue_total,
    abs(o.subtotal - olt.line_revenue_total)
        / nullif(o.subtotal, 0)                                 as pct_discrepancy

from orders o
inner join order_line_totals olt
    on o.order_id = olt.order_id

where abs(o.subtotal - olt.line_revenue_total)
        / nullif(o.subtotal, 0) > 0.01
