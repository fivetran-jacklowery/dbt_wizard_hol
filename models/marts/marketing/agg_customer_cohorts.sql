{{
    config(
        materialized = 'table',
        schema = 'marketing'
    )
}}

-- Customer cohort analysis — groups customers by their acquisition month
-- and tracks aggregate revenue and retention metrics per cohort.

with cohorts as (

    select * from {{ ref('int_customer_cohorts') }}

),

cohort_summary as (

    select
        cohort_month,
        referral_source,

        count(distinct customer_id)                         as cohort_size,
        count(distinct case when first_order_date is not null then customer_id end) as customers_with_orders,
        count(distinct case when is_active_customer then customer_id end) as active_customers,

        {{ safe_divide(
            'count(distinct case when first_order_date is not null then customer_id end)',
            'count(distinct customer_id)'
        ) }}                                                as purchase_conversion_rate,

        {{ safe_divide(
            'count(distinct case when is_active_customer then customer_id end)',
            'count(distinct case when first_order_date is not null then customer_id end)'
        ) }}                                                as retention_rate,

        sum(coalesce(lifetime_revenue_dollars, 0))          as cohort_total_revenue,
        avg(coalesce(lifetime_revenue_dollars, 0))          as cohort_avg_revenue_per_customer,
        avg(coalesce(avg_order_value_dollars, 0))           as cohort_avg_order_value,
        avg(coalesce(days_to_first_order, 0))               as avg_days_to_first_order

    from cohorts
    where cohort_month is not null  -- exclude customers who have never ordered
    group by 1, 2

)

select * from cohort_summary
order by cohort_month, referral_source
