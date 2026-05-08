-- Assigns each customer to an acquisition cohort (first order month)
-- and flags active customers based on recency.

with customers as (

    select * from {{ ref('stg_customers') }}

),

customer_summary as (

    select * from {{ ref('int_customer_order_summary') }}

),

cohorts as (

    select
        c.customer_id,
        c.full_name,
        c.email,
        c.customer_type,
        c.state,
        c.region,
        c.created_at                                            as signup_date,

        cos.first_order_date,
        cos.last_order_date,
        cos.total_orders,
        cos.lifetime_revenue,
        cos.avg_order_value,

        -- Cohort key: month of first order
        date_trunc('month', cos.first_order_date)               as cohort_month,

        -- Days from account creation to first purchase
        datediff('day', c.created_at, cos.first_order_date)     as days_to_first_order,

        -- Active in last N days (driven by project variable)
        case
            when datediff('day', cos.last_order_date, current_date) <= {{ var('active_customer_days') }}
            then true else false
        end                                                     as is_active_customer

    from customers c
    left join customer_summary cos
        on c.customer_id = cos.customer_id

)

select * from cohorts
