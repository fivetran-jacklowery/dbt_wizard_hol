with source as (

    select * from {{ ref('orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        cast(order_date as date)                             as order_date,
        lower(status)                                        as status,
        upper(shipping_address_state)                        as shipping_state,
        shipping_address_city                                as shipping_city,
        nullif(promo_code, '')                               as promo_code,
        coalesce(discount_cents, 0)                          as discount_cents

    from source

)

select * from renamed
