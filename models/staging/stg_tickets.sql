with source as (

    select * from {{ source('retail', 'RET_TICKETS') }}

),

renamed as (

    select
        id                                                       as ticket_id,
        customer_id,
        order_id,
        lower(issue_type)                                        as issue_type,
        lower(priority)                                          as priority,
        lower(status)                                            as ticket_status,
        description                                              as ticket_description,
        created_at,
        resolved_at,
        case
            when resolved_at is not null
            then datediff('hour', created_at, resolved_at)
        end                                                      as resolution_hours,
        _fivetran_deleted                                        as is_deleted,
        _fivetran_synced                                         as fivetran_synced_at

    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
