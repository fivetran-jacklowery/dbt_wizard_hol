with source as (

    select * from {{ source('retail', 'RET_ORDER_ITEMS') }}

),

renamed as (

    select
        id                                                       as order_item_id,
        order_id,
        product_id,
        quantity,
        unit_price,
        discount_pct,
        line_total,
        created_at,
        _fivetran_deleted                                        as is_deleted,
        _fivetran_synced                                         as fivetran_synced_at

    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
