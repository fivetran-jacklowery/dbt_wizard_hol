-- Singular test: no product/warehouse combination should have negative inventory.
-- Returns rows that violate this expectation — test passes when 0 rows are returned.

select
    inventory_id,
    product_id,
    warehouse_id,
    product_name,
    warehouse_name,
    quantity_on_hand

from {{ ref('int_inventory_status') }}
where quantity_on_hand < 0
