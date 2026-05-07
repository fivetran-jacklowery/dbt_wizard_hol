with source as (

    select * from {{ source('raw', 'products') }}

),

renamed as (

    select
        product_id,
        product_name,
        category_id,
        sku,
        unit_cost_cents,
        unit_price_cents,
        {{ cents_to_dollars('unit_cost_cents') }}            as unit_cost_dollars,
        {{ cents_to_dollars('unit_price_cents') }}           as unit_price_dollars,
        unit_price_cents - unit_cost_cents                   as unit_margin_cents,
        {{ cents_to_dollars('unit_price_cents - unit_cost_cents') }} as unit_margin_dollars,
        {{ safe_divide('unit_price_cents - unit_cost_cents', 'unit_price_cents') }} as margin_pct,
        cast(is_active as boolean)                           as is_active

    from source

)

select * from renamed
