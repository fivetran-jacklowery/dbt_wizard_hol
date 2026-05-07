{{
    config(
        materialized = 'table'
    )
}}

-- Order-level margin analysis — flags high and low margin orders.
-- Useful for pricing review and promotional effectiveness analysis.

with orders as (

    select * from {{ ref('fct_orders') }}

),

final as (

    select
        order_id,
        customer_id,
        order_date,
        order_month,
        order_status,
        payment_method,

        -- Revenue & margin
        order_revenue_dollars,
        order_cost_cents,
        order_margin_dollars,
        order_margin_pct,

        -- Discount impact
        has_promo,
        promo_code,
        discount_dollars,
        {{ safe_divide('discount_dollars', 'order_revenue_dollars') }} as discount_pct,

        -- Margin classification
        case
            when order_margin_pct >= 0.50 then 'high'
            when order_margin_pct >= 0.30 then 'medium'
            when order_margin_pct >= 0    then 'low'
            else 'negative'
        end                                                  as margin_band,

        line_item_count,
        total_quantity,
        is_returned,
        is_refunded,

        -- Net margin after discount
        order_margin_dollars - discount_dollars              as net_margin_after_discount,
        {{ safe_divide(
            'order_margin_dollars - discount_dollars',
            'order_revenue_dollars'
        ) }}                                                as net_margin_pct_after_discount

    from orders
    where order_status != 'pending'

)

select * from final
order by order_date, order_id
