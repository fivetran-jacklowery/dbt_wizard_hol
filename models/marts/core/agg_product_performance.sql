{{
    config(
        materialized = 'table'
    )
}}

-- Product performance aggregation — ranks products by revenue, volume, and reviews.

with product_sales as (

    select * from {{ ref('int_product_sales_summary') }}

),

reviews as (

    select * from {{ ref('int_product_reviews_summary') }}

),

ranked as (

    select
        ps.product_id,
        ps.product_name,
        ps.sku,
        ps.brand,
        ps.subcategory_id,
        ps.subcategory_name,
        ps.category_id,
        ps.category_name,
        ps.product_is_active,
        ps.price_tier,

        ps.orders_containing_product,
        ps.total_units_sold,
        ps.total_revenue,
        ps.total_revenue_after_discount,
        ps.last_sold_date,

        -- Review metrics
        coalesce(r.total_reviews, 0)                            as total_reviews,
        r.avg_rating,
        coalesce(r.positive_review_rate, 0)                     as positive_review_rate,

        -- Rankings within the full catalog
        rank() over (order by ps.total_revenue desc)            as revenue_rank,
        rank() over (order by ps.total_units_sold desc)         as volume_rank,
        rank() over (order by coalesce(r.avg_rating, 0) desc)   as rating_rank,

        -- Rankings within category
        rank() over (
            partition by ps.category_id
            order by ps.total_revenue desc
        )                                                       as revenue_rank_in_category,

        -- Revenue share
        {{ safe_divide(
            'ps.total_revenue',
            'sum(ps.total_revenue) over ()'
        ) }}                                                    as pct_of_total_revenue

    from product_sales ps
    left join reviews r
        on ps.product_id = r.product_id

)

select * from ranked
order by revenue_rank
