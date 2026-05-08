-- Enriches order line items with product, subcategory, and category details.
-- Discount-adjusted revenue is computed here for accurate margin analysis.

with order_items as (

    select * from {{ ref('stg_order_items') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

subcategories as (

    select * from {{ ref('stg_product_subcategories') }}

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

        -- Price & revenue (native dollars)
        oi.unit_price,
        oi.discount_pct,
        oi.line_total                                           as line_revenue,

        -- Discount-adjusted revenue
        oi.line_total * (1 - coalesce(oi.discount_pct, 0) / 100.0) as line_revenue_after_discount,

        -- Product context
        p.sku,
        p.product_name,
        p.brand,
        p.unit_price                                            as product_unit_price,
        p.is_active                                             as product_is_active,

        -- Taxonomy context
        sc.subcategory_id,
        sc.subcategory_name,
        c.category_id,
        c.category_name

    from order_items oi
    left join products p
        on oi.product_id = p.product_id
    left join subcategories sc
        on p.subcategory_id = sc.subcategory_id
    left join categories c
        on sc.category_id = c.category_id

)

select * from joined
