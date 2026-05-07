{{
    config(
        materialized = 'table'
    )
}}

-- Grain: one row per order line item
-- Includes all enriched product, category, and margin data

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

    from {{ ref('int_orders_with_payments') }}

),

final as (

    select
        -- Keys
        oi.order_item_id,
        oi.order_id,
        oi.product_id,
        oi.category_id,
        o.customer_id,

        -- Dates (denormalized from order)
        o.order_date,
        o.order_month,
        o.order_status,

        -- Product info
        oi.product_name,
        oi.sku,
        oi.category_name,
        oi.department,
        oi.product_is_active,

        -- Quantity & pricing
        oi.quantity,
        oi.unit_price_cents,
        oi.unit_price_dollars,
        oi.unit_cost_cents,
        oi.unit_cost_dollars,

        -- Line totals
        oi.line_total_cents,
        oi.line_total_dollars,
        oi.line_cost_cents,
        oi.line_cost_dollars,
        oi.line_margin_cents,
        oi.line_margin_dollars,
        oi.line_margin_pct

    from order_items oi
    inner join orders o
        on oi.order_id = o.order_id

)

select * from final
