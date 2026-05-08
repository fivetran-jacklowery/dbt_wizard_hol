{{
    config(
        materialized = 'table'
    )
}}

-- Order-level discount and revenue analysis.
-- Since we have no cost data in this schema, margin banding uses discount depth.

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
        shipping_method,

        -- Revenue
        order_revenue,
        order_revenue_after_discount,
        total_amount,
        tax_amount,
        shipping_cost,

        -- Discount impact
        order_revenue - order_revenue_after_discount            as total_discount_amount,
        {{ safe_divide(
            'order_revenue - order_revenue_after_discount',
            'order_revenue'
        ) }}                                                    as discount_pct,

        -- Discount depth banding
        case
            when {{ safe_divide(
                    'order_revenue - order_revenue_after_discount',
                    'order_revenue'
                ) }} = 0                                        then 'no discount'
            when {{ safe_divide(
                    'order_revenue - order_revenue_after_discount',
                    'order_revenue'
                ) }} < 0.1                                      then 'light (<10%)'
            when {{ safe_divide(
                    'order_revenue - order_revenue_after_discount',
                    'order_revenue'
                ) }} < 0.2                                      then 'moderate (10–20%)'
            else                                                     'heavy (20%+)'
        end                                                     as discount_band,

        line_item_count,
        total_quantity,
        is_returned,
        is_cancelled

    from orders
    where order_status not in ('pending', 'cancelled')

)

select * from final
order by order_date, order_id
