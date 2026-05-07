-- Aggregates completed order revenue and margin by day.
-- Feeds into agg_daily_revenue and agg_monthly_revenue mart models.

with orders as (

    select * from {{ ref('int_orders_with_payments') }}

),

order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

order_totals as (

    select
        order_id,
        sum(line_total_cents)  as order_revenue_cents,
        sum(line_cost_cents)   as order_cost_cents,
        sum(line_margin_cents) as order_margin_cents

    from order_items
    group by 1

),

daily as (

    select
        o.order_date,
        date_trunc('month', o.order_date)                   as order_month,
        count(distinct o.order_id)                          as order_count,
        count(distinct o.customer_id)                       as unique_customers,
        sum(ot.order_revenue_cents)                         as daily_revenue_cents,
        {{ cents_to_dollars('sum(ot.order_revenue_cents)') }} as daily_revenue_dollars,
        sum(ot.order_cost_cents)                            as daily_cost_cents,
        sum(ot.order_margin_cents)                          as daily_margin_cents,
        {{ cents_to_dollars('sum(ot.order_margin_cents)') }}  as daily_margin_dollars,
        {{ safe_divide(
            'sum(ot.order_margin_cents)',
            'sum(ot.order_revenue_cents)'
        ) }}                                                as daily_margin_pct,
        sum(case when o.has_promo then 1 else 0 end)        as promo_order_count,
        sum(o.discount_cents)                               as total_discount_cents

    from orders o
    left join order_totals ot
        on o.order_id = ot.order_id
    where o.order_status = 'completed'
    group by 1, 2

)

select * from daily
