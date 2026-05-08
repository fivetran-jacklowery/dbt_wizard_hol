-- Joins products to their full taxonomy (subcategory → category)
-- and assigns a price tier bucket.

with products as (

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
        p.product_id,
        p.sku,
        p.product_name,
        p.product_description,
        p.brand,
        p.unit_price,
        p.weight_lbs,
        p.is_active,

        sc.subcategory_id,
        sc.subcategory_name,
        c.category_id,
        c.category_name,

        -- Price tier bucketing (native dollars)
        case
            when p.unit_price >= 100 then 'premium'
            when p.unit_price >= 50  then 'mid-range'
            else 'budget'
        end                                                     as price_tier

    from products p
    left join subcategories sc
        on p.subcategory_id = sc.subcategory_id
    left join categories c
        on sc.category_id = c.category_id

)

select * from joined
