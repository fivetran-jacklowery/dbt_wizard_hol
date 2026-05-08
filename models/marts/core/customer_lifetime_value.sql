{{
    config(
        materialized = 'table'
    )
}}

-- Customer Lifetime Value (CLV) model.
-- Combines actual spend history with a simple linear 12-month projection.

with dim_customers as (

    select * from {{ ref('dim_customers') }}

),

clv as (

    select
        customer_id,
        full_name,
        email,
        state,
        region,
        customer_type,
        customer_tier,
        is_active,

        -- Actuals
        total_orders,
        first_order_date,
        last_order_date,
        customer_tenure_days,
        lifetime_revenue,
        avg_order_value,

        -- Velocity: orders per month
        {{ safe_divide(
            'total_orders',
            'greatest(customer_tenure_days, 1) / 30.0'
        ) }}                                                    as orders_per_month,

        -- Simple 12-month projected revenue (avg order value × monthly velocity × 12)
        round(
            avg_order_value
            * {{ safe_divide(
                    'total_orders',
                    'greatest(customer_tenure_days, 1) / 30.0'
                ) }}
            * 12,
            2
        )                                                       as projected_12mo_revenue,

        -- Support profile
        total_support_tickets,
        open_tickets,
        avg_resolution_hours,

        return_rate

    from dim_customers
    where has_ever_ordered

)

select * from clv
order by lifetime_revenue desc
