with source as (

    select * from {{ source('retail', 'RET_PRODUCT_REVIEWS') }}

),

renamed as (

    select
        id                                                       as review_id,
        product_id,
        customer_id,
        rating,
        review_title,
        review_text,
        is_verified_purchase,
        created_at,
        _fivetran_deleted                                        as is_deleted,
        _fivetran_synced                                         as fivetran_synced_at

    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
