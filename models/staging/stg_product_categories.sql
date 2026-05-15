with source as (

    select * from {{ source('retail', 'RET_PRODUCT_CATEGORIES') }}

),

renamed as (

    select
        id                                                       as category_id,
        name                                                     as category_name,
        description                                              as category_description,
        created_at,
        updated_at,
        _fivetran_deleted                                        as is_deleted,
        _fivetran_synced                                         as fivetran_synced_at

    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
