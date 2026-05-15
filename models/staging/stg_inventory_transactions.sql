with source as (

    select * from {{ source('retail', 'RET_INVENTORY_TRANSACTIONS') }}

),

renamed as (

    select
        id                                                       as transaction_id,
        product_id,
        warehouse_id,
        lower(transaction_type)                                  as transaction_type,
        quantity,
        reference_id,
        notes,
        created_at,
        _fivetran_deleted                                        as is_deleted,
        _fivetran_synced                                         as fivetran_synced_at

    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
