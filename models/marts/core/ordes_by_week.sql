{{
    config(
        materialized = 'table'
    )
}}

-- Weekly order rollup — one row per calendar week.

with orders as (

    select * from {{ ref('fct_orders') }}

),

weekly_orders as (

    select
        date_trunc('week', order_date)     as order_week,
        count(*)                           as order_count,
        sum(order_revenue)                 as gross_revenue,
        count(distinct customer_id)        as distinct_customers

    from orders
    group by 1

)

select * from weekly_orders
order by order_week
