-- Assigns each customer to an acquisition cohort (first order month)
-- and computes their revenue contribution within that cohort.

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
        c.referral_source,
        c.state,
        c.signup_date,

        cos.first_order_date,
        cos.last_order_date,
        cos.total_orders,
        cos.lifetime_revenue_cents,
        cos.lifetime_revenue_dollars,
        cos.avg_order_value_dollars,

        -- Cohort key: month of first order
        date_trunc('month', cos.first_order_date)           as cohort_month,

        -- Days from signup to first purchase
        datediff('day', c.signup_date, cos.first_order_date) as days_to_first_order,

        -- Active in last N days (driven by project variable)
        case
            when datediff('day', cos.last_order_date, current_date) <= {{ var('active_customer_days') }}
            then true else false
        end                                                  as is_active_customer

    from customers c
    left join customer_summary cos
        on c.customer_id = cos.customer_id

)

select * from cohorts
