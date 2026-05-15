-- Aggregates completed order history per customer to produce lifetime metrics.
-- Used downstream in dim_customers and customer_lifetime_value.

with orders as (

    select * from {{ ref('int_orders_enriched') }}

),

order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

-- Roll up revenue to the order level first
order_totals as (

    select
        order_id,
        sum(line_revenue)                                       as order_revenue,
        sum(line_revenue_after_discount)                        as order_revenue_after_discount,
        count(*)                                                as item_count

    from order_items
    group by 1

),

-- Join order metadata then aggregate to customer
customer_orders as (

    select
        o.customer_id,
        count(distinct o.order_id)                              as total_orders,
        min(o.order_date)                                       as first_order_date,
        max(o.order_date)                                       as last_order_date,
        datediff('day', min(o.order_date), max(o.order_date))   as customer_tenure_days,

        sum(ot.order_revenue)                                   as lifetime_revenue,
        sum(ot.order_revenue_after_discount)                    as lifetime_revenue_after_discount,
        avg(ot.order_revenue)                                   as avg_order_value,
        sum(ot.item_count)                                      as total_items_purchased,

        count(distinct case when o.is_returned then o.order_id end) as returned_order_count,
        {{ safe_divide(
            'count(distinct case when o.is_returned then o.order_id end)',
            'count(distinct o.order_id)'
        ) }}                                                    as return_rate

    from orders o
    left join order_totals ot
        on o.order_id = ot.order_id
    where o.order_status not in ('pending', 'cancelled')
    group by 1

)

select * from customer_orders
