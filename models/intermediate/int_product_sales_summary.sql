-- Rolls up order item data to the product level for completed orders.
-- Produces per-product sales volume and revenue metrics.

with order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

orders as (

    select order_id, order_status, order_date
    from {{ ref('int_orders_enriched') }}

),

products as (

    select product_id, price_tier
    from {{ ref('int_products_enriched') }}

),

product_sales as (

    select
        oi.product_id,
        oi.product_name,
        oi.sku,
        oi.brand,
        oi.subcategory_id,
        oi.subcategory_name,
        oi.category_id,
        oi.category_name,
        oi.product_is_active,
        p.price_tier,

        -- Volume
        count(distinct oi.order_id)                             as orders_containing_product,
        sum(oi.quantity)                                         as total_units_sold,

        -- Revenue
        sum(oi.line_revenue)                                     as total_revenue,
        sum(oi.line_revenue_after_discount)                      as total_revenue_after_discount,

        -- Review context (populated in downstream dim)
        -- Recency
        max(o.order_date)                                        as last_sold_date

    from order_items oi
    inner join orders o
        on oi.order_id = o.order_id
    left join products p
        on oi.product_id = p.product_id
    where o.order_status = 'completed'
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

)

select * from product_sales
