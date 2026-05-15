{{
    config(
        materialized = 'table'
    )
}}

with orders as (

    select * from {{ ref('int_orders_enriched') }}

),

order_items as (

    select
        order_id,
        sum(line_revenue)                   as order_revenue,
        sum(line_revenue_after_discount)    as order_revenue_after_discount,
        count(*)                            as line_item_count,
        sum(quantity)                       as total_quantity

    from {{ ref('int_order_items_enriched') }}
    group by 1

),

final as (

    select
        -- Keys
        o.order_id,
        o.customer_id,

        -- Dates
        o.order_date,
        o.order_month,
        o.order_year,

        -- Status
        o.order_status,
        o.shipping_method,

        -- Location
        o.shipping_address,
        o.shipping_city,
        o.shipping_state,
        o.shipping_zip,

        -- Financial totals (from order record)
        o.subtotal,
        o.tax_amount,
        o.shipping_cost,
        o.total_amount,

        -- Revenue from line items (may differ from subtotal due to discounts)
        coalesce(oi.order_revenue, 0)                          as order_revenue,
        coalesce(oi.order_revenue_after_discount, 0)           as order_revenue_after_discount,

        -- Line items
        coalesce(oi.line_item_count, 0)                        as line_item_count,
        coalesce(oi.total_quantity, 0)                         as total_quantity,

        -- Flags
        o.is_returned,
        o.is_cancelled,
        o.is_completed

    from orders o
    left join order_items oi
        on o.order_id = oi.order_id

)

select * from final
