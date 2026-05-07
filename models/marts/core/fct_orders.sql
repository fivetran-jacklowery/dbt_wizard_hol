{{
    config(
        materialized = 'table'
    )
}}

with orders as (

    select * from {{ ref('int_orders_with_payments') }}

),

order_items as (

    select
        order_id,
        sum(line_total_cents)   as order_revenue_cents,
        sum(line_cost_cents)    as order_cost_cents,
        sum(line_margin_cents)  as order_margin_cents,
        count(*)                as line_item_count,
        sum(quantity)           as total_quantity

    from {{ ref('int_order_items_enriched') }}
    group by 1

),

final as (

    select
        -- Keys
        o.order_id,
        o.customer_id,
        o.payment_id,

        -- Dates
        o.order_date,
        o.order_month,
        o.order_year,
        o.payment_date,

        -- Status
        o.order_status,
        o.payment_status,

        -- Location
        o.shipping_state,
        o.shipping_city,

        -- Promo
        o.promo_code,
        o.has_promo,
        o.discount_cents,
        o.discount_dollars,

        -- Payment
        o.payment_method,
        o.payment_amount_cents,
        o.payment_amount_dollars,

        -- Revenue & margin (from line items)
        coalesce(oi.order_revenue_cents, 0)                 as order_revenue_cents,
        {{ cents_to_dollars('coalesce(oi.order_revenue_cents, 0)') }} as order_revenue_dollars,
        coalesce(oi.order_cost_cents, 0)                    as order_cost_cents,
        coalesce(oi.order_margin_cents, 0)                  as order_margin_cents,
        {{ cents_to_dollars('coalesce(oi.order_margin_cents, 0)') }} as order_margin_dollars,
        {{ safe_divide(
            'coalesce(oi.order_margin_cents, 0)',
            'coalesce(oi.order_revenue_cents, 1)'
        ) }}                                                as order_margin_pct,

        -- Line items
        coalesce(oi.line_item_count, 0)                     as line_item_count,
        coalesce(oi.total_quantity, 0)                      as total_quantity,

        -- Flags
        o.is_returned,
        o.is_refunded

    from orders o
    left join order_items oi
        on o.order_id = oi.order_id

)

select * from final
