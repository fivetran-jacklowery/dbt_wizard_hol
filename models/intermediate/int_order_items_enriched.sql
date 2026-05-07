-- Enriches order line items with product and category details.
-- Adds cost, margin, and category context to every line item.

with order_items as (

    select * from {{ ref('stg_order_items') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

categories as (

    select * from {{ ref('stg_product_categories') }}

),

joined as (

    select
        oi.order_item_id,
        oi.order_id,
        oi.product_id,
        oi.quantity,

        -- Price & revenue
        oi.unit_price_cents,
        oi.unit_price_dollars,
        oi.line_total_cents,
        oi.line_total_dollars,

        -- Cost & margin (from product master)
        p.unit_cost_cents,
        p.unit_cost_dollars,
        oi.quantity * p.unit_cost_cents                     as line_cost_cents,
        {{ cents_to_dollars('oi.quantity * p.unit_cost_cents') }} as line_cost_dollars,
        oi.line_total_cents - (oi.quantity * p.unit_cost_cents) as line_margin_cents,
        {{ cents_to_dollars('oi.line_total_cents - (oi.quantity * p.unit_cost_cents)') }} as line_margin_dollars,
        {{ safe_divide(
            'oi.line_total_cents - (oi.quantity * p.unit_cost_cents)',
            'oi.line_total_cents'
        ) }}                                                as line_margin_pct,

        -- Product context
        p.product_name,
        p.sku,
        p.is_active                                         as product_is_active,
        p.margin_pct                                        as product_margin_pct,

        -- Category context
        c.category_id,
        c.category_name,
        c.department

    from order_items oi
    left join products p
        on oi.product_id = p.product_id
    left join categories c
        on p.category_id = c.category_id

)

select * from joined
