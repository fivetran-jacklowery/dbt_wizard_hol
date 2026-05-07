{{
    config(
        materialized = 'table'
    )
}}

-- Customer Lifetime Value (CLV) model.
-- Combines actual spend history with projected future value (simple linear projection).

with dim_customers as (

    select * from {{ ref('dim_customers') }}

),

clv as (

    select
        customer_id,
        full_name,
        email,
        state,
        referral_source,
        customer_tier,
        is_active,

        -- Actuals
        total_orders,
        first_order_date,
        last_order_date,
        customer_tenure_days,
        lifetime_revenue_dollars,
        lifetime_margin_dollars,
        avg_order_value_dollars,

        -- Velocity: orders per month (avoid div/0 for single-purchase customers)
        {{ safe_divide(
            'total_orders',
            'greatest(customer_tenure_days, 1) / 30.0'
        ) }}                                                as orders_per_month,

        -- Simple 12-month projected revenue
        -- (avg order value × orders per month × 12)
        round(
            avg_order_value_dollars
            * {{ safe_divide(
                    'total_orders',
                    'greatest(customer_tenure_days, 1) / 30.0'
                ) }}
            * 12,
            2
        )                                                    as projected_12mo_revenue,

        -- Margin on projected revenue
        round(
            avg_order_value_dollars
            * {{ safe_divide(
                    'total_orders',
                    'greatest(customer_tenure_days, 1) / 30.0'
                ) }}
            * 12
            * {{ safe_divide('lifetime_margin_dollars', 'greatest(lifetime_revenue_dollars, 1)') }},
            2
        )                                                    as projected_12mo_margin,

        -- Promo usage rate
        {{ safe_divide('promo_order_count', 'greatest(total_orders, 1)') }} as promo_usage_rate,

        return_rate

    from dim_customers
    where has_ever_ordered

)

select * from clv
order by lifetime_revenue_dollars desc
