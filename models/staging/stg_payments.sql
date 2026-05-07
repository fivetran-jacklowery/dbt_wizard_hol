with source as (

    select * from {{ ref('payments') }}

),

renamed as (

    select
        payment_id,
        order_id,
        lower(payment_method)                                as payment_method,
        amount_cents,
        {{ cents_to_dollars('amount_cents') }}               as amount_dollars,
        cast(payment_date as date)                           as payment_date,
        lower(status)                                        as payment_status

    from source

)

select * from renamed
