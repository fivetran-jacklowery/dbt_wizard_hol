-- Summarizes customer acquisition and revenue by referral source.
-- Used to power the marketing mart.

with customers as (

    select * from {{ ref('stg_customers') }}

),

customer_summary as (

    select * from {{ ref('int_customer_order_summary') }}

),

referral as (

    select
        c.referral_source,

        count(distinct c.customer_id)                       as total_customers_acquired,
        count(distinct case when cos.total_orders > 0 then c.customer_id end) as customers_who_purchased,

        {{ safe_divide(
            'count(distinct case when cos.total_orders > 0 then c.customer_id end)',
            'count(distinct c.customer_id)'
        ) }}                                                as conversion_rate,

        sum(coalesce(cos.total_orders, 0))                  as total_orders,
        sum(coalesce(cos.lifetime_revenue_cents, 0))        as total_revenue_cents,
        {{ cents_to_dollars('sum(coalesce(cos.lifetime_revenue_cents, 0))') }} as total_revenue_dollars,

        {{ safe_divide(
            'sum(coalesce(cos.lifetime_revenue_cents, 0))',
            'count(distinct c.customer_id)'
        ) }}                                                as revenue_per_acquired_customer_cents,

        avg(coalesce(cos.avg_order_value_dollars, 0))       as avg_order_value_dollars

    from customers c
    left join customer_summary cos
        on c.customer_id = cos.customer_id
    group by 1

)

select * from referral
