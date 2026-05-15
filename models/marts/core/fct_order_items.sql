{{
    config(
        materialized = 'table'
    )
}}

-- Grain: one row per order line item
-- Includes product, subcategory/category taxonomy, and discount-adjusted revenue

with order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

orders as (

    select
        order_id,
        customer_id,
        order_date,
        order_status,
        order_month

    from {{ ref('int_orders_enriched') }}

),

final as (

    select
        -- Keys
        oi.order_item_id,
        oi.order_id,
        oi.product_id,
        oi.subcategory_id,
        oi.category_id,
        o.customer_id,

        -- Dates (denormalized from order)
        o.order_date,
        o.order_month,
        o.order_status,

        -- Product info
        oi.product_name,
        oi.sku,
        oi.brand,
        oi.subcategory_name,
        oi.category_name,
        oi.product_is_active,

        -- Quantity & pricing
        oi.quantity,
        oi.unit_price,
        oi.discount_pct,

        -- Line totals
        oi.line_revenue,
        oi.line_revenue_after_discount

    from order_items oi
    inner join orders o
        on oi.order_id = o.order_id

)

select * from final
