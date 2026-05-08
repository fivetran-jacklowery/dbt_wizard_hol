with source as (

    select * from {{ source('retail', 'RET_CUSTOMERS') }}

),

renamed as (

    select
        id                                                       as customer_id,
        first_name,
        last_name,
        first_name || ' ' || last_name                          as full_name,
        lower(email)                                             as email,
        phone,
        address,
        city,
        upper(state)                                             as state,
        zip,
        region,
        lower(customer_type)                                     as customer_type,
        created_at,
        updated_at,
        _fivetran_deleted                                        as is_deleted,
        _fivetran_synced                                         as fivetran_synced_at

    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
