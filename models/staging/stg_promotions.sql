with source as (

    select * from {{ source('retail', 'RET_PROMOTIONS') }}

),

renamed as (

    select
        id                                                       as promotion_id,
        name                                                     as promotion_name,
        description                                              as promotion_description,
        lower(discount_type)                                     as discount_type,
        discount_value,
        min_order_amount,
        applicable_category_id,
        start_date,
        end_date,
        is_active,
        created_at,
        _fivetran_deleted                                        as is_deleted,
        _fivetran_synced                                         as fivetran_synced_at

    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
