-- Aggregates completed order revenue by day.
-- Feeds into agg_daily_revenue and agg_monthly_revenue mart models.

with orders as (

    select * from {{ ref('int_orders_enriched') }}

),

order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

order_totals as (

    select
        order_id,
        sum(line_revenue)                                       as order_revenue,
        sum(line_revenue_after_discount)                        as order_revenue_after_discount

    from order_items
    group by 1

),

daily as (

    select
        o.order_date,
        date_trunc('month', o.order_date)                       as order_month,
        count(distinct o.order_id)                              as order_count,
        count(distinct o.customer_id)                           as unique_customers,

        sum(ot.order_revenue)                                   as daily_revenue,
        sum(ot.order_revenue_after_discount)                    as daily_revenue_after_discount,
        sum(o.total_amount)                                     as daily_total_billed,

        {{ safe_divide(
            'sum(ot.order_revenue_after_discount)',
            'sum(ot.order_revenue)'
        ) }}                                                    as avg_discount_factor,

        count(distinct o.shipping_state)                        as distinct_states

    from orders o
    left join order_totals ot
        on o.order_id = ot.order_id
    where o.order_status = 'completed'
    group by 1, 2

)

select * from daily
