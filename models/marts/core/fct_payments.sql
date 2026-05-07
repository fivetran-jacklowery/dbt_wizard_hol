{{
    config(
        materialized = 'table'
    )
}}

with payments as (

    select * from {{ ref('stg_payments') }}

),

orders as (

    select
        order_id,
        customer_id,
        order_date,
        status as order_status,
        shipping_state

    from {{ ref('stg_orders') }}

),

final as (

    select
        -- Keys
        p.payment_id,
        p.order_id,
        o.customer_id,

        -- Dates
        p.payment_date,
        o.order_date,
        datediff('day', o.order_date, p.payment_date)       as days_to_payment,

        -- Payment details
        p.payment_method,
        p.payment_status,
        p.amount_cents,
        p.amount_dollars,

        -- Order context
        o.order_status,
        o.shipping_state

    from payments p
    left join orders o
        on p.order_id = o.order_id

)

select * from final
