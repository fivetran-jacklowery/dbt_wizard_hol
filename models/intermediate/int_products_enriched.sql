-- Joins products with their category and computes sales performance metrics.

with products as (

    select * from {{ ref('stg_products') }}

),

categories as (

    select * from {{ ref('stg_product_categories') }}

),

joined as (

    select
        p.product_id,
        p.product_name,
        p.sku,
        p.is_active,
        p.unit_cost_cents,
        p.unit_cost_dollars,
        p.unit_price_cents,
        p.unit_price_dollars,
        p.unit_margin_cents,
        p.unit_margin_dollars,
        p.margin_pct,

        c.category_id,
        c.category_name,
        c.department,

        -- Price tier bucketing
        case
            when p.unit_price_cents >= 10000 then 'premium'
            when p.unit_price_cents >= 5000  then 'mid-range'
            else 'budget'
        end as price_tier

    from products p
    left join categories c
        on p.category_id = c.category_id

)

select * from joined
