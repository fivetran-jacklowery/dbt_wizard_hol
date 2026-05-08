{{
    config(
        materialized = 'table'
    )
}}

-- Monthly revenue rollup — includes MoM growth rate calculations.

with daily as (

    select * from {{ ref('int_daily_revenue') }}

),

monthly as (

    select
        order_month,
        sum(order_count)                                        as order_count,
        sum(unique_customers)                                   as total_customer_days,
        count(distinct order_date)                              as active_days,
        sum(daily_revenue)                                      as monthly_revenue,
        sum(daily_revenue_after_discount)                       as monthly_revenue_after_discount,
        sum(daily_total_billed)                                 as monthly_total_billed,
        {{ safe_divide(
            'sum(daily_revenue)',
            'count(distinct order_date)'
        ) }}                                                    as avg_daily_revenue

    from daily
    group by 1

),

with_growth as (

    select
        *,
        lag(monthly_revenue) over (order by order_month)        as prev_month_revenue,
        {{ safe_divide(
            'monthly_revenue - lag(monthly_revenue) over (order by order_month)',
            'lag(monthly_revenue) over (order by order_month)'
        ) }}                                                    as mom_revenue_growth_pct

    from monthly

)

select * from with_growth
order by order_month
