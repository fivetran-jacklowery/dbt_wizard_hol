with source as (

    select * from {{ ref('product_categories') }}

),

renamed as (

    select
        category_id,
        category_name,
        lower(department)                                    as department

    from source

)

select * from renamed
