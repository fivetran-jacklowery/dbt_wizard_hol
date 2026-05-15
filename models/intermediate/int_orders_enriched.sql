-- Enriches orders with derived flags and date parts.
-- No payment table in this schema; totals are on the order record directly.

with orders as (

    select * from {{ ref('stg_orders') }}

),

enriched as (

    select
        order_id,
        customer_id,
        order_date,
        order_status,
        shipping_method,
        shipping_address,
        shipping_city,
        shipping_state,
        shipping_zip,
        subtotal,
        tax_amount,
        shipping_cost,
        total_amount,
        created_at,
        updated_at,

        -- Derived flags
        case when order_status = 'returned'   then true else false end  as is_returned,
        case when order_status = 'cancelled'  then true else false end  as is_cancelled,
        case when order_status = 'completed'  then true else false end  as is_completed,

        -- Date parts for reporting
        date_trunc('month', order_date)                                 as order_month,
        date_trunc('year', order_date)                                  as order_year,
        dayofweek(order_date)                                           as order_day_of_week

    from orders

)

select * from enriched
