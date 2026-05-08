with source as (

    select * from {{ source('retail', 'RET_WAREHOUSES') }}

),

renamed as (

    select
        id                                                       as warehouse_id,
        name                                                     as warehouse_name,
        address,
        city,
        upper(state)                                             as state,
        zip,
        capacity_sqft,
        is_active,
        created_at,
        _fivetran_deleted                                        as is_deleted,
        _fivetran_synced                                         as fivetran_synced_at

    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
