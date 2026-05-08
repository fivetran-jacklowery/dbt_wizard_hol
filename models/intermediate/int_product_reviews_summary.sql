-- Aggregates product review data per product.
-- Produces average rating, review count, and verified purchase rate.

with reviews as (

    select * from {{ ref('stg_product_reviews') }}

),

summary as (

    select
        product_id,

        count(*)                                                as total_reviews,
        count(case when is_verified_purchase then 1 end)        as verified_reviews,
        avg(rating)                                             as avg_rating,
        min(rating)                                             as min_rating,
        max(rating)                                             as max_rating,
        count(case when rating >= 4 then 1 end)                 as positive_reviews,
        count(case when rating <= 2 then 1 end)                 as negative_reviews,

        {{ safe_divide(
            'count(case when is_verified_purchase then 1 end)',
            'count(*)'
        ) }}                                                    as verified_purchase_rate,

        {{ safe_divide(
            'count(case when rating >= 4 then 1 end)',
            'count(*)'
        ) }}                                                    as positive_review_rate,

        min(created_at)                                         as first_review_date,
        max(created_at)                                         as last_review_date

    from reviews
    group by 1

)

select * from summary
