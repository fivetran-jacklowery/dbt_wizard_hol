{{
    config(
        materialized = 'table'
    )
}}

-- Operations view of outbound inventory movements that explain where stock went.
-- Grain: one row per sale or transfer inventory transaction.
-- Preserves unmatched product/order references because those are investigation signals.

with inventory_transactions as (

    select
        transaction_id,
        product_id,
        warehouse_id,
        transaction_type,
        quantity,
        reference_id,
        notes,
        created_at as transaction_date
    from {{ ref('stg_inventory_transactions') }}

),

products as (

    select product_id, product_name, sku, brand
    from {{ ref('stg_products') }}

),

warehouses as (

    select warehouse_id, warehouse_name, city, state, is_active
    from {{ ref('stg_warehouses') }}

),

orders as (

    select
        order_id,
        customer_id,
        order_date,
        order_status,
        shipping_method,
        shipping_city,
        shipping_state,
        shipping_zip,
        is_cancelled,
        is_returned,
        is_completed
    from {{ ref('int_orders_enriched') }}

),

current_inventory as (

    select
        inventory_id,
        product_id,
        warehouse_id,
        quantity_on_hand,
        reorder_point,
        reorder_quantity,
        updated_at,
        row_number() over (
            partition by product_id, warehouse_id
            order by updated_at desc, inventory_id desc
        ) as inventory_recency_rank
    from {{ ref('stg_inventory') }}

),

latest_inventory as (

    select *
    from current_inventory
    where inventory_recency_rank = 1

),

outbound_movements as (

    select
        transaction_id,
        product_id,
        warehouse_id,
        transaction_type,
        quantity,
        abs(quantity)                                             as missing_inventory_units,
        reference_id,
        notes,
        transaction_date
    from inventory_transactions
    where transaction_type in ('sale', 'transfer')
        and quantity < 0

),

final as (

    select
        -- Transaction grain
        om.transaction_id,
        om.transaction_date,
        om.transaction_type,
        om.reference_id,
        om.notes,

        -- Product context
        om.product_id,
        p.sku,
        p.product_name,
        p.brand,

        -- Source warehouse context
        om.warehouse_id,
        w.warehouse_name,
        w.city                                                   as warehouse_city,
        w.state                                                  as warehouse_state,
        w.is_active                                              as warehouse_is_active,

        -- Inventory impact
        om.quantity,
        om.missing_inventory_units,
        li.quantity_on_hand,
        li.reorder_point,
        li.reorder_quantity,
        case
            when li.quantity_on_hand is null then null
            when li.quantity_on_hand <= li.reorder_point then true
            else false
        end                                                      as is_at_or_below_reorder_point,

        -- Sale/order context. Sale transaction reference_id maps most closely to order_id.
        o.order_id,
        o.customer_id,
        o.order_date,
        o.order_status,
        o.shipping_method,
        o.shipping_city,
        o.shipping_state,
        o.shipping_zip,
        o.is_cancelled,
        o.is_returned,
        o.is_completed,

        -- Operational routing
        case
            when om.transaction_type = 'sale' and o.order_id is not null
                then 'customer shipment'
            when om.transaction_type = 'sale' and o.order_id is null
                then 'unmatched sale reference'
            when om.transaction_type = 'transfer'
                then 'inter-warehouse transfer'
            else 'unknown outbound movement'
        end                                                      as likely_inventory_destination,

        case
            when p.product_id is null then 'missing product reference'
            when w.warehouse_id is null then 'missing warehouse reference'
            when om.transaction_type = 'sale' and o.order_id is null then 'sale reference does not match active order'
            when om.transaction_type = 'transfer' then 'confirm receiving warehouse or transfer documentation'
            when o.order_status in ('processing', 'shipped') then 'review shipment before customer delivery'
            when o.order_status in ('cancelled', 'returned') then 'verify stock was returned to inventory'
            when coalesce(li.quantity_on_hand, 0) <= coalesce(li.reorder_point, 0) then 'replenish or reallocate stock before sale'
            else 'no immediate exception detected'
        end                                                      as recommended_action,

        case
            when p.product_id is null
                or w.warehouse_id is null
                or (om.transaction_type = 'sale' and o.order_id is null)
                then 'critical'
            when coalesce(li.quantity_on_hand, 0) <= coalesce(li.reorder_point, 0)
                and om.missing_inventory_units >= coalesce(li.quantity_on_hand, 0)
                then 'high'
            when om.transaction_type = 'transfer'
                or o.order_status in ('processing', 'shipped')
                or coalesce(li.quantity_on_hand, 0) <= coalesce(li.reorder_point, 0)
                then 'medium'
            else 'low'
        end                                                      as investigation_priority,

        case
            when p.product_id is null
                or w.warehouse_id is null
                or (om.transaction_type = 'sale' and o.order_id is null)
                or om.transaction_type = 'transfer'
                or o.order_status in ('processing', 'shipped')
                or coalesce(li.quantity_on_hand, 0) <= coalesce(li.reorder_point, 0)
                then true
            else false
        end                                                      as requires_ops_review

    from outbound_movements om
    left join products p
        on om.product_id = p.product_id
    left join warehouses w
        on om.warehouse_id = w.warehouse_id
    left join orders o
        on om.transaction_type = 'sale'
        and om.reference_id = o.order_id
    left join latest_inventory li
        on om.product_id = li.product_id
        and om.warehouse_id = li.warehouse_id

)

select * from final
