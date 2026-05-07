-- Aggregates order history per customer to produce lifetime metrics.
-- Used downstream in dim_customers and customer_lifetime_value.

with orders as (

    select * from {{ ref('int_orders_with_payments') }}

),

order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

-- Roll up revenue and margin to the order level first
order_totals as (

    select
        order_id,
        sum(line_total_cents)  as order_revenue_cents,
        sum(line_cost_cents)   as order_cost_cents,
        sum(line_margin_cents) as order_margin_cents,
        count(*)               as item_count

    from order_items
    group by 1

),

-- Join to order metadata then aggregate to customer
customer_orders as (

    select
        o.customer_id,
        count(distinct o.order_id)                          as total_orders,
        min(o.order_date)                                   as first_order_date,
        max(o.order_date)                                   as last_order_date,
        datediff('day', min(o.order_date), max(o.order_date)) as customer_tenure_days,
        sum(ot.order_revenue_cents)                         as lifetime_revenue_cents,
        {{ cents_to_dollars('sum(ot.order_revenue_cents)') }} as lifetime_revenue_dollars,
        sum(ot.order_margin_cents)                          as lifetime_margin_cents,
        {{ cents_to_dollars('sum(ot.order_margin_cents)') }}  as lifetime_margin_dollars,
        avg(ot.order_revenue_cents)                         as avg_order_value_cents,
        {{ cents_to_dollars('avg(ot.order_revenue_cents)') }} as avg_order_value_dollars,
        sum(ot.item_count)                                  as total_items_purchased,
        count(distinct case when o.has_promo then o.order_id end) as promo_order_count,
        count(distinct case when o.is_returned then o.order_id end) as returned_order_count,
        {{ safe_divide(
            'count(distinct case when o.is_returned then o.order_id end)',
            'count(distinct o.order_id)'
        ) }}                                                as return_rate

    from orders o
    left join order_totals ot
        on o.order_id = ot.order_id
    where o.order_status != 'pending'
    group by 1

)

select * from customer_orders
