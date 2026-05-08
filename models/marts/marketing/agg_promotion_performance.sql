{{
    config(
        materialized = 'table',
        schema = 'marketing'
    )
}}

-- Promotion performance analysis.
-- Joins active promotions to order item revenue within the promotion period
-- for the applicable product category.

with promotions as (

    select * from {{ ref('stg_promotions') }}

),

order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

orders as (

    select order_id, order_date, order_status
    from {{ ref('int_orders_enriched') }}

),

-- Match order items to promotions by category and order date within window
promo_matches as (

    select
        p.promotion_id,
        p.promotion_name,
        p.discount_type,
        p.discount_value,
        p.min_order_amount,
        p.applicable_category_id,
        p.start_date,
        p.end_date,
        p.is_active,

        count(distinct oi.order_id)                             as orders_in_promo_window,
        count(distinct oi.order_item_id)                        as line_items_in_promo_window,
        sum(oi.line_revenue)                                     as gross_revenue_in_window,
        sum(oi.line_revenue_after_discount)                      as net_revenue_in_window,
        sum(oi.quantity)                                         as units_sold_in_window

    from promotions p
    left join order_items oi
        on oi.category_id = p.applicable_category_id
    left join orders o
        on oi.order_id = o.order_id
        and o.order_date between p.start_date and p.end_date
        and o.order_status = 'completed'
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9

)

select * from promo_matches
order by start_date desc
