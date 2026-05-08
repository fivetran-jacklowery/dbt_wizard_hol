{{
    config(
        materialized = 'table'
    )
}}

with customers as (

    select * from {{ ref('stg_customers') }}

),

customer_summary as (

    select * from {{ ref('int_customer_order_summary') }}

),

support_summary as (

    select * from {{ ref('int_customer_support_summary') }}

),

final as (

    select
        -- Keys
        c.customer_id,

        -- Identity
        c.full_name,
        c.first_name,
        c.last_name,
        c.email,
        c.phone,

        -- Location
        c.address,
        c.city,
        c.state,
        c.zip,
        c.region,

        -- Segmentation
        c.customer_type,

        -- Timestamps
        c.created_at                                            as signup_date,

        -- Order history
        coalesce(cos.total_orders, 0)                          as total_orders,
        cos.first_order_date,
        cos.last_order_date,
        coalesce(cos.customer_tenure_days, 0)                  as customer_tenure_days,
        coalesce(cos.lifetime_revenue, 0)                      as lifetime_revenue,
        coalesce(cos.avg_order_value, 0)                       as avg_order_value,
        coalesce(cos.total_items_purchased, 0)                 as total_items_purchased,
        coalesce(cos.returned_order_count, 0)                  as returned_order_count,
        coalesce(cos.return_rate, 0)                           as return_rate,

        -- Support history
        coalesce(ss.total_tickets, 0)                          as total_support_tickets,
        coalesce(ss.open_tickets, 0)                           as open_tickets,
        coalesce(ss.resolved_tickets, 0)                       as resolved_tickets,
        ss.avg_resolution_hours,
        ss.most_common_issue_type,

        -- Computed segments
        {{ classify_customer_tier('coalesce(cos.lifetime_revenue, 0)') }} as customer_tier,
        case when cos.customer_id is null then false else true end as has_ever_ordered,
        case
            when datediff('day', cos.last_order_date, current_date) <= {{ var('active_customer_days') }}
            then true else false
        end                                                    as is_active

    from customers c
    left join customer_summary cos
        on c.customer_id = cos.customer_id
    left join support_summary ss
        on c.customer_id = ss.customer_id

)

select * from final
