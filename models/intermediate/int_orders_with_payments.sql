-- Joins orders to their payment record and enriches with computed flags.
-- Each order has at most one payment in this dataset.

with orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('stg_payments') }}

),

joined as (

    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.status                                             as order_status,
        o.shipping_state,
        o.shipping_city,
        o.promo_code,
        o.discount_cents,
        {{ cents_to_dollars('o.discount_cents') }}           as discount_dollars,

        p.payment_id,
        p.payment_method,
        p.amount_cents                                       as payment_amount_cents,
        {{ cents_to_dollars('p.amount_cents') }}             as payment_amount_dollars,
        p.payment_date,
        p.payment_status,

        -- Derived flags
        case when o.promo_code is not null then true else false end as has_promo,
        case when o.status = 'returned' then true else false end    as is_returned,
        case when p.payment_status = 'refunded' then true else false end as is_refunded,

        -- Date parts for reporting
        date_trunc('month', o.order_date)                   as order_month,
        date_trunc('year', o.order_date)                    as order_year,
        dayofweek(o.order_date)                              as order_day_of_week

    from orders o
    left join payments p
        on o.order_id = p.order_id

)

select * from joined
