with source as (

    select * from {{ source('raw', 'customers') }}

),

renamed as (

    select
        customer_id,
        first_name,
        last_name,
        first_name || ' ' || last_name                      as full_name,
        lower(email)                                         as email,
        phone,
        upper(country)                                       as country,
        upper(state)                                         as state,
        city,
        cast(signup_date as date)                            as signup_date,
        lower(referral_source)                               as referral_source

    from source

)

select * from renamed
