{{
    config(
        materialized = 'table'
    )
}}

-- Product performance aggregation — ranks products by revenue, volume, and margin.

with product_sales as (

    select * from {{ ref('int_product_sales_summary') }}

),

ranked as (

    select
        product_id,
        product_name,
        sku,
        category_id,
        category_name,
        department,
        product_is_active,
        product_price_tier,

        orders_containing_product,
        total_units_sold,
        total_revenue_dollars,
        total_margin_dollars,
        blended_margin_pct,
        last_sold_date,

        -- Rankings within the full catalog
        rank() over (order by total_revenue_dollars desc)   as revenue_rank,
        rank() over (order by total_units_sold desc)        as volume_rank,
        rank() over (order by blended_margin_pct desc)      as margin_rank,

        -- Rankings within department
        rank() over (
            partition by department
            order by total_revenue_dollars desc
        )                                                    as revenue_rank_in_dept,

        -- Revenue share
        {{ safe_divide(
            'total_revenue_dollars',
            'sum(total_revenue_dollars) over ()'
        ) }}                                                as pct_of_total_revenue

    from product_sales

)

select * from ranked
order by revenue_rank
