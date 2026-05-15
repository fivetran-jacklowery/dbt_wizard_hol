{{
    config(
        materialized = 'table'
    )
}}

-- Grain: one row per inventory transaction
-- Denormalized with product and warehouse context for inventory analytics

with transactions as (

    select * from {{ ref('stg_inventory_transactions') }}

),

products as (

    select product_id, product_name, sku, brand
    from {{ ref('stg_products') }}

),

warehouses as (

    select warehouse_id, warehouse_name, city, state
    from {{ ref('stg_warehouses') }}

),

final as (

    select
        -- Keys
        t.transaction_id,
        t.product_id,
        t.warehouse_id,

        -- Transaction details
        t.transaction_type,
        t.quantity,
        t.reference_id,
        t.notes,
        t.created_at                                            as transaction_date,

        -- Product context
        p.product_name,
        p.sku,
        p.brand,

        -- Warehouse context
        w.warehouse_name,
        w.city                                                  as warehouse_city,
        w.state                                                 as warehouse_state,

        -- Derived: inbound vs outbound movement
        case
            when t.transaction_type in ('receipt', 'return', 'adjustment_in') then t.quantity
            else 0
        end                                                     as quantity_in,

        case
            when t.transaction_type in ('sale', 'adjustment_out', 'transfer_out') then t.quantity
            else 0
        end                                                     as quantity_out

    from transactions t
    left join products p
        on t.product_id = p.product_id
    left join warehouses w
        on t.warehouse_id = w.warehouse_id

)

select * from final
