-- Aggregates support ticket history per customer.
-- Produces ticket counts, resolution metrics, and issue type breakdown.

with tickets as (

    select * from {{ ref('stg_tickets') }}

),

summary as (

    select
        customer_id,

        count(*)                                                as total_tickets,
        count(case when ticket_status = 'open'       then 1 end) as open_tickets,
        count(case when ticket_status = 'resolved'   then 1 end) as resolved_tickets,
        count(case when ticket_status = 'closed'     then 1 end) as closed_tickets,
        count(case when priority = 'high'            then 1 end) as high_priority_tickets,

        avg(case when resolution_hours is not null
            then resolution_hours end)                          as avg_resolution_hours,

        min(created_at)                                         as first_ticket_date,
        max(created_at)                                         as last_ticket_date,

        -- Most common issue type
        mode(issue_type)                                        as most_common_issue_type

    from tickets
    group by 1

)

select * from summary
