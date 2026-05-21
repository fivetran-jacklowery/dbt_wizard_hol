with source as (

    select * from {{ source('retail', 'RET_PRODUCTS') }}

),

renamed as (

    select
        id                                                       as product_id,
        sku,
        name                                                     as product_name,
        description                                              as product_description,
        subcategory_id,
        brand_name                                               as brand,
        unit_price,
        weight_lbs,
        is_active,
        created_at,
        updated_at,
        _fivetran_deleted                                        as is_deleted,
        _fivetran_synced                                         as fivetran_synced_at

    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
