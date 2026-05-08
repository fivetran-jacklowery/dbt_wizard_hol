with source as (

    select * from {{ source('retail', 'RET_INVENTORY') }}

),

renamed as (

    select
        id                                                       as inventory_id,
        product_id,
        warehouse_id,
        quantity_on_hand,
        reorder_point,
        reorder_quantity,
        last_restocked_at,
        updated_at,
        _fivetran_deleted                                        as is_deleted,
        _fivetran_synced                                         as fivetran_synced_at

    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
