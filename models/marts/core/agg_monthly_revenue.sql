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
        sum(order_count)                                     as order_count,
        sum(unique_customers)                                as customer_days, -- days × unique customers
        count(distinct order_date)                           as active_days,
        sum(daily_revenue_cents)                             as monthly_revenue_cents,
        sum(daily_revenue_dollars)                           as monthly_revenue_dollars,
        sum(daily_margin_cents)                              as monthly_margin_cents,
        sum(daily_margin_dollars)                            as monthly_margin_dollars,
        {{ safe_divide(
            'sum(daily_margin_cents)',
            'sum(daily_revenue_cents)'
        ) }}                                                as monthly_margin_pct,
        sum(promo_order_count)                              as promo_order_count,
        sum(total_discount_cents)                           as total_discount_cents,
        {{ cents_to_dollars('sum(total_discount_cents)') }} as total_discount_dollars,
        {{ safe_divide(
            'sum(daily_revenue_dollars)',
            'count(distinct order_date)'
        ) }}                                                as avg_daily_revenue_dollars

    from daily
    group by 1

),

with_growth as (

    select
        *,
        lag(monthly_revenue_dollars) over (order by order_month) as prev_month_revenue_dollars,
        {{ safe_divide(
            'monthly_revenue_dollars - lag(monthly_revenue_dollars) over (order by order_month)',
            'lag(monthly_revenue_dollars) over (order by order_month)'
        ) }}                                                as mom_revenue_growth_pct

    from monthly

)

select * from with_growth
order by order_month
