{{
    config(
        materialized = 'table'
    )
}}

-- Daily revenue summary — primary reporting grain for time-series dashboards.

select
    order_date,
    order_month,
    order_count,
    unique_customers,
    daily_revenue_cents,
    daily_revenue_dollars,
    daily_cost_cents,
    daily_margin_cents,
    daily_margin_dollars,
    daily_margin_pct,
    promo_order_count,
    total_discount_cents,
    {{ cents_to_dollars('total_discount_cents') }}           as total_discount_dollars,

    -- Rolling 7-day revenue average
    avg(daily_revenue_dollars) over (
        order by order_date
        rows between 6 preceding and current row
    )                                                        as revenue_7d_avg,

    -- Running cumulative revenue
    sum(daily_revenue_dollars) over (
        order by order_date
        rows between unbounded preceding and current row
    )                                                        as cumulative_revenue_dollars

from {{ ref('int_daily_revenue') }}
order by order_date
