{{
    config(
        materialized = 'table'
    )
}}

with products_enriched as (

    select * from {{ ref('int_products_enriched') }}

),

product_sales as (

    select * from {{ ref('int_product_sales_summary') }}

),

final as (

    select
        -- Keys
        pe.product_id,
        pe.category_id,

        -- Identity
        pe.product_name,
        pe.sku,
        pe.is_active,

        -- Category
        pe.category_name,
        pe.department,

        -- Pricing
        pe.unit_cost_dollars,
        pe.unit_price_dollars,
        pe.unit_margin_dollars,
        pe.margin_pct,
        pe.price_tier,

        -- Sales performance
        coalesce(ps.orders_containing_product, 0)           as orders_containing_product,
        coalesce(ps.total_units_sold, 0)                    as total_units_sold,
        coalesce(ps.total_revenue_dollars, 0)               as total_revenue_dollars,
        coalesce(ps.total_margin_dollars, 0)                as total_margin_dollars,
        coalesce(ps.blended_margin_pct, 0)                  as blended_margin_pct,
        ps.last_sold_date

    from products_enriched pe
    left join product_sales ps
        on pe.product_id = ps.product_id

)

select * from final
