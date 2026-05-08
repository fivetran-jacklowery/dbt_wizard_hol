{{
    config(
        materialized = 'table'
    )
}}

-- Grain: one row per support ticket
-- Denormalized with customer and order context for support analytics

with tickets as (

    select * from {{ ref('stg_tickets') }}

),

customers as (

    select customer_id, full_name, customer_type, region, state
    from {{ ref('stg_customers') }}

),

orders as (

    select order_id, order_date, order_status, total_amount
    from {{ ref('stg_orders') }}

),

final as (

    select
        -- Keys
        t.ticket_id,
        t.customer_id,
        t.order_id,

        -- Ticket details
        t.issue_type,
        t.priority,
        t.ticket_status,
        t.ticket_description,

        -- Timing
        t.created_at                                            as ticket_created_at,
        t.resolved_at,
        t.resolution_hours,

        -- Customer context
        c.full_name                                             as customer_name,
        c.customer_type,
        c.region,
        c.state,

        -- Order context (nullable — not all tickets are order-linked)
        o.order_date,
        o.order_status,
        o.total_amount                                          as order_total_amount,

        -- Derived
        case when t.resolved_at is not null then true else false end as is_resolved,
        case when t.priority = 'high' then true else false end      as is_high_priority

    from tickets t
    left join customers c
        on t.customer_id = c.customer_id
    left join orders o
        on t.order_id = o.order_id

)

select * from final
