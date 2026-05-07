-- Rolls up order item data to the product level.
-- Produces per-product sales volume, revenue, and margin metrics.

with order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

orders as (

    select order_id, order_status, order_date
    from {{ ref('int_orders_with_payments') }}

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
        oi.category_id,
        oi.category_name,
        oi.department,
        oi.product_is_active,
        p.price_tier                                         as product_price_tier,

        -- Volume
        count(distinct oi.order_id)                         as orders_containing_product,
        sum(oi.quantity)                                     as total_units_sold,

        -- Revenue
        sum(oi.line_total_cents)                            as total_revenue_cents,
        {{ cents_to_dollars('sum(oi.line_total_cents)') }}  as total_revenue_dollars,

        -- Cost & margin
        sum(oi.line_cost_cents)                             as total_cost_cents,
        sum(oi.line_margin_cents)                           as total_margin_cents,
        {{ cents_to_dollars('sum(oi.line_margin_cents)') }} as total_margin_dollars,
        {{ safe_divide(
            'sum(oi.line_margin_cents)',
            'sum(oi.line_total_cents)'
        ) }}                                                as blended_margin_pct,

        -- Recency
        max(o.order_date)                                   as last_sold_date

    from order_items oi
    inner join orders o
        on oi.order_id = o.order_id
    left join products p
        on oi.product_id = p.product_id
    where o.order_status = 'completed'
    group by 1, 2, 3, 4, 5, 6, 7, 8

)

select * from product_sales
