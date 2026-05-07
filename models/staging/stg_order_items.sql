with source as (

    select * from {{ source('raw', 'order_items') }}

),

renamed as (

    select
        order_item_id,
        order_id,
        product_id,
        quantity,
        unit_price_cents,
        {{ cents_to_dollars('unit_price_cents') }}           as unit_price_dollars,
        quantity * unit_price_cents                          as line_total_cents,
        {{ cents_to_dollars('quantity * unit_price_cents') }} as line_total_dollars

    from source

)

select * from renamed
