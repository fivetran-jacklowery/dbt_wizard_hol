-- Joins inventory levels with product and warehouse details.
-- Flags items that are below their reorder point.

with inventory as (

    select * from {{ ref('stg_inventory') }}

),

products as (

    select product_id, product_name, sku, brand, subcategory_id
    from {{ ref('stg_products') }}

),

warehouses as (

    select warehouse_id, warehouse_name, city, state, is_active
    from {{ ref('stg_warehouses') }}

),

joined as (

    select
        i.inventory_id,
        i.product_id,
        i.warehouse_id,
        i.quantity_on_hand,
        i.reorder_point,
        i.reorder_quantity,
        i.last_restocked_at,
        i.updated_at,

        p.product_name,
        p.sku,
        p.brand,

        w.warehouse_name,
        w.city                                                  as warehouse_city,
        w.state                                                 as warehouse_state,
        w.is_active                                             as warehouse_is_active,

        -- Reorder flag
        case
            when i.quantity_on_hand <= i.reorder_point then true
            else false
        end                                                     as needs_reorder,

        -- Days since last restock
        datediff('day', i.last_restocked_at, current_date)     as days_since_restock

    from inventory i
    left join products p
        on i.product_id = p.product_id
    left join warehouses w
        on i.warehouse_id = w.warehouse_id

)

select * from joined
