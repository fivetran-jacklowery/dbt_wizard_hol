with source as (

    select * from {{ source('retail', 'RET_PRODUCT_SUBCATEGORIES') }}

),

renamed as (

    select
        id                                                       as subcategory_id,
        category_id,
        name                                                     as subcategory_name,
        description                                              as subcategory_description,
        created_at,
        updated_at,
        _fivetran_deleted                                        as is_deleted,
        _fivetran_synced                                         as fivetran_synced_at

    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
