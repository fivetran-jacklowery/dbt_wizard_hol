with source as (

    select * from {{ source('retail', 'RET_ORDERS') }}

),

renamed as (

    select
        id                                                       as order_id,
        customer_id,
        order_date,
        lower(status)                                            as order_status,
        shipping_method,
        shipping_address,
        shipping_city,
        upper(shipping_state)                                    as shipping_state,
        shipping_zip,
        subtotal,
        tax_amount,
        shipping_cost,
        total_amount,
        created_at,
        updated_at,
        _fivetran_deleted                                        as is_deleted,
        _fivetran_synced                                         as fivetran_synced_at

    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
