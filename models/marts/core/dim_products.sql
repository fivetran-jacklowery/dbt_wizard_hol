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

reviews as (

    select * from {{ ref('int_product_reviews_summary') }}

),

final as (

    select
        -- Keys
        pe.product_id,
        pe.subcategory_id,
        pe.category_id,

        -- Identity
        pe.product_name,
        pe.sku,
        pe.brand,
        pe.product_description,
        pe.is_active,

        -- Taxonomy
        pe.subcategory_name,
        pe.category_name,
        pe.price_tier,

        -- Pricing
        pe.unit_price,
        pe.weight_lbs,

        -- Sales performance
        coalesce(ps.orders_containing_product, 0)              as orders_containing_product,
        coalesce(ps.total_units_sold, 0)                       as total_units_sold,
        coalesce(ps.total_revenue, 0)                          as total_revenue,
        coalesce(ps.total_revenue_after_discount, 0)           as total_revenue_after_discount,
        ps.last_sold_date,

        -- Review performance
        coalesce(r.total_reviews, 0)                           as total_reviews,
        coalesce(r.verified_reviews, 0)                        as verified_reviews,
        r.avg_rating,
        coalesce(r.positive_reviews, 0)                        as positive_reviews,
        coalesce(r.negative_reviews, 0)                        as negative_reviews,
        coalesce(r.verified_purchase_rate, 0)                  as verified_purchase_rate,
        coalesce(r.positive_review_rate, 0)                    as positive_review_rate

    from products_enriched pe
    left join product_sales ps
        on pe.product_id = ps.product_id
    left join reviews r
        on pe.product_id = r.product_id

)

select * from final
