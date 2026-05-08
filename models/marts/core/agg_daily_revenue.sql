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
    daily_revenue,
    daily_revenue_after_discount,
    daily_total_billed,
    avg_discount_factor,
    distinct_states,

    -- Rolling 7-day revenue average
    avg(daily_revenue) over (
        order by order_date
        rows between 6 preceding and current row
    )                                                           as revenue_7d_avg,

    -- Running cumulative revenue
    sum(daily_revenue) over (
        order by order_date
        rows between unbounded preceding and current row
    )                                                           as cumulative_revenue

from {{ ref('int_daily_revenue') }}
order by order_date
