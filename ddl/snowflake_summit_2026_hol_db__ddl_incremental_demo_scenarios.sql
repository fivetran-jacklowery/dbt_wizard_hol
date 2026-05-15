-- =============================================================================
-- Incremental DDL + DML for SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL
-- Extends the base schema to support three demo scenarios:
--   A — Locating misallocated inventory
--   B — Identifying faulty items
--   C — Customer segmentation for targeted outreach
--
-- All changes are additive. Demo data is tagged with
--   DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS'
-- for identification and rollback.
--
-- Date range extended to 2026-06-01.
-- DO NOT EXECUTE without review — output only.
-- =============================================================================

USE DATABASE SNOWFLAKE_SUMMIT_2026_HOL_DB;
USE SCHEMA SF_HOL_2026_RETAIL;

-- #############################################################################
-- PHASE 3: CONSOLIDATED DDL
-- #############################################################################

-- -----------------------------------------------------------------------------
-- 1. NEW TABLES
-- -----------------------------------------------------------------------------

-- [Scenario B] Vendors/suppliers entity
CREATE TABLE RET_VENDORS (
    CTID_FIVETRAN_ID  VARCHAR(16) NOT NULL,
    ID                NUMBER(38,0),
    NAME              VARCHAR(200),
    CONTACT_EMAIL     VARCHAR(300),
    CITY              VARCHAR(100),
    STATE             VARCHAR(2),
    CREATED_AT        TIMESTAMP_NTZ(9),
    _FIVETRAN_DELETED BOOLEAN DEFAULT FALSE,
    _FIVETRAN_SYNCED  TIMESTAMP_TZ(9),
    DEMO_BATCH_ID     VARCHAR(50),
    PRIMARY KEY (CTID_FIVETRAN_ID)
);

-- [Scenario B] Line-level returns with reason
CREATE TABLE RET_RETURNS (
    CTID_FIVETRAN_ID  VARCHAR(16) NOT NULL,
    ID                NUMBER(38,0),
    ORDER_ID          NUMBER(38,0),       -- FK -> RET_ORDERS.ID
    ORDER_ITEM_ID     NUMBER(38,0),       -- FK -> RET_ORDER_ITEMS.ID
    PRODUCT_ID        NUMBER(38,0),       -- FK -> RET_PRODUCTS.ID
    CUSTOMER_ID       NUMBER(38,0),       -- FK -> RET_CUSTOMERS.ID
    RETURN_DATE       DATE,
    QUANTITY          NUMBER(10,0),
    RETURN_REASON     VARCHAR(50),        -- Values: Defective, Wrong Size, Changed Mind, Damaged in Transit
    NOTES             VARCHAR(500),
    CREATED_AT        TIMESTAMP_NTZ(9),
    _FIVETRAN_DELETED BOOLEAN DEFAULT FALSE,
    _FIVETRAN_SYNCED  TIMESTAMP_TZ(9),
    DEMO_BATCH_ID     VARCHAR(50),
    PRIMARY KEY (CTID_FIVETRAN_ID)
);

-- [Scenario A] Shipment header (distribution events to locations)
CREATE TABLE RET_SHIPMENTS (
    CTID_FIVETRAN_ID         VARCHAR(16) NOT NULL,
    ID                       NUMBER(38,0),
    DESTINATION_WAREHOUSE_ID NUMBER(38,0),  -- FK -> RET_WAREHOUSES.ID
    ORIGIN_WAREHOUSE_ID      NUMBER(38,0),  -- FK -> RET_WAREHOUSES.ID (nullable for external supply)
    SHIPMENT_DATE            DATE,
    STATUS                   VARCHAR(20),   -- Values: planned, in_transit, delivered
    NOTES                    VARCHAR(500),
    CREATED_AT               TIMESTAMP_NTZ(9),
    _FIVETRAN_DELETED        BOOLEAN DEFAULT FALSE,
    _FIVETRAN_SYNCED         TIMESTAMP_TZ(9),
    DEMO_BATCH_ID            VARCHAR(50),
    PRIMARY KEY (CTID_FIVETRAN_ID)
);

-- [Scenario A] Shipment line items (what was shipped)
CREATE TABLE RET_SHIPMENT_LINES (
    CTID_FIVETRAN_ID  VARCHAR(16) NOT NULL,
    ID                NUMBER(38,0),
    SHIPMENT_ID       NUMBER(38,0),       -- FK -> RET_SHIPMENTS.ID
    PRODUCT_ID        NUMBER(38,0),       -- FK -> RET_PRODUCTS.ID
    QUANTITY          NUMBER(10,0),
    CREATED_AT        TIMESTAMP_NTZ(9),
    _FIVETRAN_DELETED BOOLEAN DEFAULT FALSE,
    _FIVETRAN_SYNCED  TIMESTAMP_TZ(9),
    DEMO_BATCH_ID     VARCHAR(50),
    PRIMARY KEY (CTID_FIVETRAN_ID)
);

-- -----------------------------------------------------------------------------
-- 2. NEW COLUMNS ON EXISTING TABLES
-- -----------------------------------------------------------------------------

-- [Scenario B] Link products to vendors
ALTER TABLE RET_PRODUCTS ADD COLUMN VENDOR_ID NUMBER(38,0);

-- [Scenario C] Fulfillment location on orders
ALTER TABLE RET_ORDERS ADD COLUMN WAREHOUSE_ID NUMBER(38,0);

-- [Rollback support] Demo batch marker on existing tables receiving demo DML
ALTER TABLE RET_INVENTORY ADD COLUMN DEMO_BATCH_ID VARCHAR(50);
ALTER TABLE RET_ORDERS ADD COLUMN DEMO_BATCH_ID VARCHAR(50);
ALTER TABLE RET_PRODUCTS ADD COLUMN DEMO_BATCH_ID VARCHAR(50);
ALTER TABLE RET_ORDER_ITEMS ADD COLUMN DEMO_BATCH_ID VARCHAR(50);

-- -----------------------------------------------------------------------------
-- 3. CONSTRAINTS (informational — Snowflake does not enforce FKs but they
--    document intent and are used by dbt relationship tests)
-- -----------------------------------------------------------------------------

-- [Scenario B]
ALTER TABLE RET_PRODUCTS ADD CONSTRAINT FK_PRODUCTS_VENDOR
    FOREIGN KEY (VENDOR_ID) REFERENCES RET_VENDORS(ID) NOT ENFORCED;

-- [Scenario C]
ALTER TABLE RET_ORDERS ADD CONSTRAINT FK_ORDERS_WAREHOUSE
    FOREIGN KEY (WAREHOUSE_ID) REFERENCES RET_WAREHOUSES(ID) NOT ENFORCED;

-- [Scenario A]
ALTER TABLE RET_SHIPMENTS ADD CONSTRAINT FK_SHIPMENTS_DEST_WAREHOUSE
    FOREIGN KEY (DESTINATION_WAREHOUSE_ID) REFERENCES RET_WAREHOUSES(ID) NOT ENFORCED;

ALTER TABLE RET_SHIPMENT_LINES ADD CONSTRAINT FK_SHIPMENT_LINES_SHIPMENT
    FOREIGN KEY (SHIPMENT_ID) REFERENCES RET_SHIPMENTS(ID) NOT ENFORCED;

ALTER TABLE RET_SHIPMENT_LINES ADD CONSTRAINT FK_SHIPMENT_LINES_PRODUCT
    FOREIGN KEY (PRODUCT_ID) REFERENCES RET_PRODUCTS(ID) NOT ENFORCED;

-- [Scenario B]
ALTER TABLE RET_RETURNS ADD CONSTRAINT FK_RETURNS_ORDER
    FOREIGN KEY (ORDER_ID) REFERENCES RET_ORDERS(ID) NOT ENFORCED;

ALTER TABLE RET_RETURNS ADD CONSTRAINT FK_RETURNS_ORDER_ITEM
    FOREIGN KEY (ORDER_ITEM_ID) REFERENCES RET_ORDER_ITEMS(ID) NOT ENFORCED;

ALTER TABLE RET_RETURNS ADD CONSTRAINT FK_RETURNS_PRODUCT
    FOREIGN KEY (PRODUCT_ID) REFERENCES RET_PRODUCTS(ID) NOT ENFORCED;

ALTER TABLE RET_RETURNS ADD CONSTRAINT FK_RETURNS_CUSTOMER
    FOREIGN KEY (CUSTOMER_ID) REFERENCES RET_CUSTOMERS(ID) NOT ENFORCED;


-- #############################################################################
-- PHASE 4: CONSOLIDATED DML
-- All demo rows tagged with DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS'
-- IDs start at 90000+ to avoid collision with existing data (max existing ~50000)
-- #############################################################################

-- =============================================================================
-- SCENARIO A: Inventory Misallocation Demo Data
-- Focal item: Product ID 42
-- Allocation: 200 units to each of 5 warehouses on 2026-03-15
-- =============================================================================

-- A.1: Shipment headers (one per destination warehouse)
INSERT INTO RET_SHIPMENTS (CTID_FIVETRAN_ID, ID, DESTINATION_WAREHOUSE_ID, ORIGIN_WAREHOUSE_ID, SHIPMENT_DATE, STATUS, NOTES, CREATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, DEMO_BATCH_ID)
VALUES
  ('DEMO_SH000001', 90001, 1, NULL, '2026-03-15', 'delivered', 'Bulk allocation - Product 42', '2026-03-15 08:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS'),
  ('DEMO_SH000002', 90002, 2, NULL, '2026-03-15', 'delivered', 'Bulk allocation - Product 42', '2026-03-15 08:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS'),
  ('DEMO_SH000003', 90003, 3, NULL, '2026-03-15', 'delivered', 'Bulk allocation - Product 42', '2026-03-15 08:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS'),
  ('DEMO_SH000004', 90004, 4, NULL, '2026-03-15', 'delivered', 'Bulk allocation - Product 42', '2026-03-15 08:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS'),
  ('DEMO_SH000005', 90005, 5, NULL, '2026-03-15', 'delivered', 'Bulk allocation - Product 42', '2026-03-15 08:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS');

-- A.2: Shipment lines (200 units of product 42 to each location)
INSERT INTO RET_SHIPMENT_LINES (CTID_FIVETRAN_ID, ID, SHIPMENT_ID, PRODUCT_ID, QUANTITY, CREATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, DEMO_BATCH_ID)
VALUES
  ('DEMO_SL000001', 90001, 90001, 42, 200, '2026-03-15 08:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS'),
  ('DEMO_SL000002', 90002, 90002, 42, 200, '2026-03-15 08:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS'),
  ('DEMO_SL000003', 90003, 90003, 42, 200, '2026-03-15 08:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS'),
  ('DEMO_SL000004', 90004, 90004, 42, 200, '2026-03-15 08:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS'),
  ('DEMO_SL000005', 90005, 90005, 42, 200, '2026-03-15 08:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS');

-- A.3: Adjust on-hand inventory for product 42 across all 5 warehouses
--   WH 1: 200 (exact match)
--   WH 2:  95 (clearly short, -105)
--   WH 3: 255 (clearly over, +55)
--   WH 4: 248 (clearly over, +48)
--   WH 5: 203 (near-miss, +3)
MERGE INTO RET_INVENTORY tgt
USING (
    SELECT column1 AS product_id, column2 AS warehouse_id, column3 AS quantity_on_hand
    FROM VALUES
      (42, 1, 200),
      (42, 2, 95),
      (42, 3, 255),
      (42, 4, 248),
      (42, 5, 203)
) src ON tgt.PRODUCT_ID = src.product_id AND tgt.WAREHOUSE_ID = src.warehouse_id AND tgt._FIVETRAN_DELETED = FALSE
WHEN MATCHED THEN UPDATE SET
    tgt.QUANTITY_ON_HAND = src.quantity_on_hand,
    tgt.UPDATED_AT       = '2026-05-10 12:00:00',
    tgt.DEMO_BATCH_ID    = 'DEMO_2026_SCENARIOS'
WHEN NOT MATCHED THEN INSERT (CTID_FIVETRAN_ID, ID, PRODUCT_ID, WAREHOUSE_ID, QUANTITY_ON_HAND, REORDER_POINT, REORDER_QUANTITY, LAST_RESTOCKED_AT, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, DEMO_BATCH_ID)
    VALUES ('DEMO_INV_' || src.warehouse_id, 90000 + src.warehouse_id, src.product_id, src.warehouse_id, src.quantity_on_hand, 50, 100, '2026-03-15', '2026-05-10 12:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS');


-- =============================================================================
-- SCENARIO B: Faulty Items Demo Data
-- 3 vendors, 8 focal products, 475 sales, returns with 4 reason categories
--
-- Target defect rates (units):
--   Product 101: 18/60  = 30%  (high defect, Vendor Alpha)
--   Product 102: 16/55  = 29%  (high defect, Vendor Alpha)
--   Product 103: 15/50  = 30%  (high defect, Vendor Beta)
--   Product 104: 10/55  = 18%  (near-miss,   Vendor Beta)
--   Product 105: 11/60  = 18%  (near-miss,   Vendor Gamma)
--   Product 106:  3/70  =  4%  (clean,        Vendor Alpha)
--   Product 107:  0/65  =  0%  (clean,        Vendor Beta)
--   Product 108:  2/60  =  3%  (clean,        Vendor Gamma)
-- =============================================================================

-- B.1: Insert vendors
INSERT INTO RET_VENDORS (CTID_FIVETRAN_ID, ID, NAME, CONTACT_EMAIL, CITY, STATE, CREATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, DEMO_BATCH_ID)
VALUES
  ('DEMO_VN000001', 1, 'Vendor Alpha', 'contact@vendor-alpha.example', 'Chicago',  'IL', '2023-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS'),
  ('DEMO_VN000002', 2, 'Vendor Beta',  'contact@vendor-beta.example',  'Dallas',   'TX', '2023-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS'),
  ('DEMO_VN000003', 3, 'Vendor Gamma', 'contact@vendor-gamma.example', 'Denver',   'CO', '2023-01-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS');

-- B.2: Assign VENDOR_ID to focal products (existing products 101-108)
UPDATE RET_PRODUCTS SET VENDOR_ID = 1, DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS' WHERE ID IN (101, 102, 106);
UPDATE RET_PRODUCTS SET VENDOR_ID = 2, DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS' WHERE ID IN (103, 104, 107);
UPDATE RET_PRODUCTS SET VENDOR_ID = 3, DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS' WHERE ID IN (105, 108);

-- B.3: Insert 475 sales orders spread across trailing 365 days (2025-06-02 to 2026-06-01)
--      Each order has status='delivered', one line item for a focal product.
INSERT INTO RET_ORDERS (CTID_FIVETRAN_ID, ID, CUSTOMER_ID, ORDER_DATE, STATUS, SHIPPING_METHOD, SHIPPING_ADDRESS, SHIPPING_CITY, SHIPPING_STATE, SHIPPING_ZIP, SUBTOTAL, TAX_AMOUNT, SHIPPING_COST, TOTAL_AMOUNT, CREATED_AT, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, WAREHOUSE_ID, DEMO_BATCH_ID)
SELECT
    'DEMO_OR' || LPAD(ROW_NUMBER() OVER (ORDER BY seq4())::VARCHAR, 6, '0'),
    90000 + ROW_NUMBER() OVER (ORDER BY seq4()),
    MOD(seq4(), 470) + 1,
    DATEADD('day', MOD(seq4(), 365), '2025-06-02')::TIMESTAMP_NTZ,
    'delivered',
    'standard',
    '123 Demo St',
    'Anytown',
    'CA',
    '90001',
    49.99,
    4.50,
    5.99,
    60.48,
    DATEADD('day', MOD(seq4(), 365), '2025-06-02')::TIMESTAMP_NTZ,
    DATEADD('day', MOD(seq4(), 365), '2025-06-02')::TIMESTAMP_NTZ,
    FALSE,
    CURRENT_TIMESTAMP(),
    MOD(seq4(), 5) + 1,
    'DEMO_2026_SCENARIOS'
FROM TABLE(GENERATOR(ROWCOUNT => 475));

-- B.4: Insert order items — one per order, mapped to focal products by row position
--      First 60 -> product 101, next 55 -> 102, etc.
INSERT INTO RET_ORDER_ITEMS (CTID_FIVETRAN_ID, ID, ORDER_ID, PRODUCT_ID, QUANTITY, UNIT_PRICE, DISCOUNT_PCT, LINE_TOTAL, CREATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, DEMO_BATCH_ID)
WITH ordered_orders AS (
    SELECT ID AS order_id,
           ROW_NUMBER() OVER (ORDER BY ID) AS rn,
           ORDER_DATE AS created_at
    FROM RET_ORDERS
    WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS'
      AND ID BETWEEN 90001 AND 90475
),
product_map AS (
    SELECT rn, order_id, created_at,
        CASE
            WHEN rn <= 60  THEN 101
            WHEN rn <= 115 THEN 102
            WHEN rn <= 165 THEN 103
            WHEN rn <= 220 THEN 104
            WHEN rn <= 280 THEN 105
            WHEN rn <= 350 THEN 106
            WHEN rn <= 415 THEN 107
            ELSE 108
        END AS product_id
    FROM ordered_orders
)
SELECT
    'DEMO_OI' || LPAD(rn::VARCHAR, 6, '0'),
    90000 + rn,
    order_id,
    product_id,
    1,
    49.99,
    0.00,
    49.99,
    created_at,
    FALSE,
    CURRENT_TIMESTAMP(),
    'DEMO_2026_SCENARIOS'
FROM product_map;

-- B.5: Insert returns — defective + other reasons per product
INSERT INTO RET_RETURNS (CTID_FIVETRAN_ID, ID, ORDER_ID, ORDER_ITEM_ID, PRODUCT_ID, CUSTOMER_ID, RETURN_DATE, QUANTITY, RETURN_REASON, NOTES, CREATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, DEMO_BATCH_ID)
WITH return_source AS (
    SELECT
        oi.ID AS order_item_id,
        o.ID  AS order_id,
        oi.PRODUCT_ID,
        o.CUSTOMER_ID,
        o.ORDER_DATE::DATE AS order_date,
        ROW_NUMBER() OVER (PARTITION BY oi.PRODUCT_ID ORDER BY o.ORDER_DATE) AS item_rn
    FROM RET_ORDER_ITEMS oi
    JOIN RET_ORDERS o ON oi.ORDER_ID = o.ID
    WHERE oi.DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS'
      AND o.DEMO_BATCH_ID  = 'DEMO_2026_SCENARIOS'
),
returns_to_create AS (
    SELECT *,
        CASE
            -- Product 101: 18 defective / 60 sales = 30%, plus 4 other-reason
            WHEN PRODUCT_ID = 101 AND item_rn <= 18 THEN 'Defective'
            WHEN PRODUCT_ID = 101 AND item_rn BETWEEN 19 AND 20 THEN 'Wrong Size'
            WHEN PRODUCT_ID = 101 AND item_rn BETWEEN 21 AND 22 THEN 'Changed Mind'
            -- Product 102: 16 defective / 55 sales = 29%, plus 3 other-reason
            WHEN PRODUCT_ID = 102 AND item_rn <= 16 THEN 'Defective'
            WHEN PRODUCT_ID = 102 AND item_rn BETWEEN 17 AND 18 THEN 'Damaged in Transit'
            WHEN PRODUCT_ID = 102 AND item_rn = 19 THEN 'Changed Mind'
            -- Product 103: 15 defective / 50 sales = 30%, plus 3 other-reason
            WHEN PRODUCT_ID = 103 AND item_rn <= 15 THEN 'Defective'
            WHEN PRODUCT_ID = 103 AND item_rn BETWEEN 16 AND 17 THEN 'Wrong Size'
            WHEN PRODUCT_ID = 103 AND item_rn = 18 THEN 'Damaged in Transit'
            -- Product 104: 10 defective / 55 sales = 18% (near-miss), plus 5 other
            WHEN PRODUCT_ID = 104 AND item_rn <= 10 THEN 'Defective'
            WHEN PRODUCT_ID = 104 AND item_rn BETWEEN 11 AND 13 THEN 'Changed Mind'
            WHEN PRODUCT_ID = 104 AND item_rn BETWEEN 14 AND 15 THEN 'Wrong Size'
            -- Product 105: 11 defective / 60 sales = 18% (near-miss), plus 4 other
            WHEN PRODUCT_ID = 105 AND item_rn <= 11 THEN 'Defective'
            WHEN PRODUCT_ID = 105 AND item_rn BETWEEN 12 AND 13 THEN 'Damaged in Transit'
            WHEN PRODUCT_ID = 105 AND item_rn BETWEEN 14 AND 15 THEN 'Changed Mind'
            -- Product 106: 3 defective / 70 sales = 4%, plus 2 other
            WHEN PRODUCT_ID = 106 AND item_rn <= 3 THEN 'Defective'
            WHEN PRODUCT_ID = 106 AND item_rn BETWEEN 4 AND 5 THEN 'Changed Mind'
            -- Product 107: 0 defective, 2 other-reason only
            WHEN PRODUCT_ID = 107 AND item_rn <= 2 THEN 'Wrong Size'
            -- Product 108: 2 defective / 60 sales = 3%, plus 1 other
            WHEN PRODUCT_ID = 108 AND item_rn <= 2 THEN 'Defective'
            WHEN PRODUCT_ID = 108 AND item_rn = 3 THEN 'Damaged in Transit'
            ELSE NULL
        END AS return_reason
    FROM return_source
)
SELECT
    'DEMO_RT' || LPAD(ROW_NUMBER() OVER (ORDER BY order_id)::VARCHAR, 6, '0'),
    90000 + ROW_NUMBER() OVER (ORDER BY order_id),
    order_id,
    order_item_id,
    PRODUCT_ID,
    CUSTOMER_ID,
    DATEADD('day', 14, order_date),
    1,
    return_reason,
    'Demo return',
    DATEADD('day', 14, order_date)::TIMESTAMP_NTZ,
    FALSE,
    CURRENT_TIMESTAMP(),
    'DEMO_2026_SCENARIOS'
FROM returns_to_create
WHERE return_reason IS NOT NULL;

-- B.6: Returns OUTSIDE the trailing 365-day window (before 2025-06-02)
--      These should be excluded by date filters in validation.
INSERT INTO RET_RETURNS (CTID_FIVETRAN_ID, ID, ORDER_ID, ORDER_ITEM_ID, PRODUCT_ID, CUSTOMER_ID, RETURN_DATE, QUANTITY, RETURN_REASON, NOTES, CREATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, DEMO_BATCH_ID)
VALUES
  ('DEMO_RT_OLD01', 99901, 100, 500,  101, 10, '2025-04-01', 1, 'Defective', 'Old return - outside window', '2025-04-01 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS'),
  ('DEMO_RT_OLD02', 99902, 200, 1000, 101, 20, '2025-05-15', 1, 'Defective', 'Old return - outside window', '2025-05-15 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS'),
  ('DEMO_RT_OLD03', 99903, 300, 1500, 103, 30, '2025-03-20', 1, 'Defective', 'Old return - outside window', '2025-03-20 00:00:00', FALSE, CURRENT_TIMESTAMP(), 'DEMO_2026_SCENARIOS');


-- =============================================================================
-- SCENARIO C: Customer Segmentation Demo Data
-- 15 customers across 3 locations (warehouses 1, 2, 3)
-- 180-day window: 2025-12-04 to 2026-06-01
--
-- Segments:
--   VIP:            avg txn > $100 AND >= 3 transactions
--   Big Spender:    >= 1 transaction > $300
--   Category-Loyal: >= 10 transactions of items in same category
--
-- Customer distribution:
--   401-403: VIP only
--   404-405: Big Spender only
--   406-408: Category-Loyal only
--   409:     VIP + Big Spender + Category-Loyal
--   410:     VIP + Big Spender
--   411-413: Excluded (fail all thresholds)
--   414:     Excluded (outside 180-day window)
--   415:     Excluded (boundary: avg=$100 exactly, only 2 txns)
-- =============================================================================

-- C.1: Orders for VIP, Big Spender, multi-segment, excluded, and boundary customers
INSERT INTO RET_ORDERS (CTID_FIVETRAN_ID, ID, CUSTOMER_ID, ORDER_DATE, STATUS, SHIPPING_METHOD, SHIPPING_ADDRESS, SHIPPING_CITY, SHIPPING_STATE, SHIPPING_ZIP, SUBTOTAL, TAX_AMOUNT, SHIPPING_COST, TOTAL_AMOUNT, CREATED_AT, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, WAREHOUSE_ID, DEMO_BATCH_ID)
VALUES
  -- Customer 401: VIP only (5 txns, avg ~$170, warehouse 1)
  ('DEMO_OC000001', 91001, 401, '2026-01-10 10:00:00', 'delivered', 'standard', '1 VIP St',       'Edison',       'NJ', '08817', 140.00,  12.60, 7.00, 159.60, '2026-01-10 10:00:00', '2026-01-10 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000002', 91002, 401, '2026-02-05 10:00:00', 'delivered', 'standard', '1 VIP St',       'Edison',       'NJ', '08817', 160.00,  14.40, 7.00, 181.40, '2026-02-05 10:00:00', '2026-02-05 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000003', 91003, 401, '2026-03-12 10:00:00', 'delivered', 'standard', '1 VIP St',       'Edison',       'NJ', '08817', 145.00,  13.05, 7.00, 165.05, '2026-03-12 10:00:00', '2026-03-12 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000004', 91004, 401, '2026-04-18 10:00:00', 'delivered', 'standard', '1 VIP St',       'Edison',       'NJ', '08817', 155.00,  13.95, 7.00, 175.95, '2026-04-18 10:00:00', '2026-04-18 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000005', 91005, 401, '2026-05-20 10:00:00', 'delivered', 'standard', '1 VIP St',       'Edison',       'NJ', '08817', 150.00,  13.50, 7.00, 170.50, '2026-05-20 10:00:00', '2026-05-20 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),

  -- Customer 402: VIP only (3 txns, avg ~$138, warehouse 1)
  ('DEMO_OC000006', 91006, 402, '2026-01-20 10:00:00', 'delivered', 'standard', '2 VIP St',       'Edison',       'NJ', '08817', 110.00,   9.90, 7.00, 126.90, '2026-01-20 10:00:00', '2026-01-20 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000007', 91007, 402, '2026-03-15 10:00:00', 'delivered', 'standard', '2 VIP St',       'Edison',       'NJ', '08817', 125.00,  11.25, 7.00, 143.25, '2026-03-15 10:00:00', '2026-03-15 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000008', 91008, 402, '2026-05-01 10:00:00', 'delivered', 'standard', '2 VIP St',       'Edison',       'NJ', '08817', 125.00,  11.25, 7.00, 143.25, '2026-05-01 10:00:00', '2026-05-01 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),

  -- Customer 403: VIP only (4 txns, avg ~$149, warehouse 2)
  ('DEMO_OC000009', 91009, 403, '2026-01-05 10:00:00', 'delivered', 'standard', '3 VIP Ave',      'Atlanta',      'GA', '30301', 120.00,  10.80, 7.00, 137.80, '2026-01-05 10:00:00', '2026-01-05 10:00:00', FALSE, CURRENT_TIMESTAMP(), 2, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000010', 91010, 403, '2026-02-14 10:00:00', 'delivered', 'standard', '3 VIP Ave',      'Atlanta',      'GA', '30301', 135.00,  12.15, 7.00, 154.15, '2026-02-14 10:00:00', '2026-02-14 10:00:00', FALSE, CURRENT_TIMESTAMP(), 2, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000011', 91011, 403, '2026-03-30 10:00:00', 'delivered', 'standard', '3 VIP Ave',      'Atlanta',      'GA', '30301', 140.00,  12.60, 7.00, 159.60, '2026-03-30 10:00:00', '2026-03-30 10:00:00', FALSE, CURRENT_TIMESTAMP(), 2, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000012', 91012, 403, '2026-05-10 10:00:00', 'delivered', 'standard', '3 VIP Ave',      'Atlanta',      'GA', '30301', 125.00,  11.25, 7.00, 143.25, '2026-05-10 10:00:00', '2026-05-10 10:00:00', FALSE, CURRENT_TIMESTAMP(), 2, 'DEMO_2026_SCENARIOS'),

  -- Customer 404: Big Spender only (2 txns: $367 and $83, warehouse 2)
  ('DEMO_OC000013', 91013, 404, '2026-02-10 10:00:00', 'delivered', 'standard', '4 Spend Ln',     'Atlanta',      'GA', '30301', 330.00,  29.70, 7.00, 366.70, '2026-02-10 10:00:00', '2026-02-10 10:00:00', FALSE, CURRENT_TIMESTAMP(), 2, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000014', 91014, 404, '2026-04-05 10:00:00', 'delivered', 'standard', '4 Spend Ln',     'Atlanta',      'GA', '30301',  70.00,   6.30, 7.00,  83.30, '2026-04-05 10:00:00', '2026-04-05 10:00:00', FALSE, CURRENT_TIMESTAMP(), 2, 'DEMO_2026_SCENARIOS'),

  -- Customer 405: Big Spender only (1 txn: $465, warehouse 3)
  ('DEMO_OC000015', 91015, 405, '2026-03-22 10:00:00', 'delivered', 'standard', '5 Spend Dr',     'Indianapolis', 'IN', '46201', 420.00,  37.80, 7.00, 464.80, '2026-03-22 10:00:00', '2026-03-22 10:00:00', FALSE, CURRENT_TIMESTAMP(), 3, 'DEMO_2026_SCENARIOS'),

  -- Customer 409: VIP + Big Spender + Category-Loyal (10 txns, avg ~$136, max $367, all cat 1, warehouse 1)
  ('DEMO_OC000026', 91026, 409, '2026-01-08 10:00:00', 'delivered', 'standard', '9 Multi St',     'Edison',       'NJ', '08817', 150.00,  13.50, 7.00, 170.50, '2026-01-08 10:00:00', '2026-01-08 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000027', 91027, 409, '2026-02-02 10:00:00', 'delivered', 'standard', '9 Multi St',     'Edison',       'NJ', '08817', 160.00,  14.40, 7.00, 181.40, '2026-02-02 10:00:00', '2026-02-02 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000028', 91028, 409, '2026-02-28 10:00:00', 'delivered', 'standard', '9 Multi St',     'Edison',       'NJ', '08817', 170.00,  15.30, 7.00, 192.30, '2026-02-28 10:00:00', '2026-02-28 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000029', 91029, 409, '2026-03-20 10:00:00', 'delivered', 'standard', '9 Multi St',     'Edison',       'NJ', '08817', 330.00,  29.70, 7.00, 366.70, '2026-03-20 10:00:00', '2026-03-20 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000030', 91030, 409, '2026-04-15 10:00:00', 'delivered', 'standard', '9 Multi St',     'Edison',       'NJ', '08817', 140.00,  12.60, 7.00, 159.60, '2026-04-15 10:00:00', '2026-04-15 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000031', 91031, 409, '2026-04-20 10:00:00', 'delivered', 'standard', '9 Multi St',     'Edison',       'NJ', '08817',  45.00,   4.05, 7.00,  56.05, '2026-04-20 10:00:00', '2026-04-20 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000032', 91032, 409, '2026-04-25 10:00:00', 'delivered', 'standard', '9 Multi St',     'Edison',       'NJ', '08817',  50.00,   4.50, 7.00,  61.50, '2026-04-25 10:00:00', '2026-04-25 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000033', 91033, 409, '2026-05-01 10:00:00', 'delivered', 'standard', '9 Multi St',     'Edison',       'NJ', '08817',  40.00,   3.60, 7.00,  50.60, '2026-05-01 10:00:00', '2026-05-01 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000034', 91034, 409, '2026-05-10 10:00:00', 'delivered', 'standard', '9 Multi St',     'Edison',       'NJ', '08817',  55.00,   4.95, 7.00,  66.95, '2026-05-10 10:00:00', '2026-05-10 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000035', 91035, 409, '2026-05-20 10:00:00', 'delivered', 'standard', '9 Multi St',     'Edison',       'NJ', '08817',  48.00,   4.32, 7.00,  59.32, '2026-05-20 10:00:00', '2026-05-20 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),

  -- Customer 410: VIP + Big Spender (4 txns, avg ~$356, max $378, warehouse 2)
  ('DEMO_OC000036', 91036, 410, '2026-01-15 10:00:00', 'delivered', 'standard', '10 Multi Ave',   'Atlanta',      'GA', '30301', 300.00,  27.00, 7.00, 334.00, '2026-01-15 10:00:00', '2026-01-15 10:00:00', FALSE, CURRENT_TIMESTAMP(), 2, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000037', 91037, 410, '2026-02-20 10:00:00', 'delivered', 'standard', '10 Multi Ave',   'Atlanta',      'GA', '30301', 330.00,  29.70, 7.00, 366.70, '2026-02-20 10:00:00', '2026-02-20 10:00:00', FALSE, CURRENT_TIMESTAMP(), 2, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000038', 91038, 410, '2026-03-25 10:00:00', 'delivered', 'standard', '10 Multi Ave',   'Atlanta',      'GA', '30301', 310.00,  27.90, 7.00, 344.90, '2026-03-25 10:00:00', '2026-03-25 10:00:00', FALSE, CURRENT_TIMESTAMP(), 2, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000039', 91039, 410, '2026-04-28 10:00:00', 'delivered', 'standard', '10 Multi Ave',   'Atlanta',      'GA', '30301', 340.00,  30.60, 7.00, 377.60, '2026-04-28 10:00:00', '2026-04-28 10:00:00', FALSE, CURRENT_TIMESTAMP(), 2, 'DEMO_2026_SCENARIOS'),

  -- Customer 411: Excluded (2 low-value txns, warehouse 3)
  ('DEMO_OC000040', 91040, 411, '2026-03-10 10:00:00', 'delivered', 'standard', '11 Low St',      'Indianapolis', 'IN', '46201',  40.00,   3.60, 7.00,  50.60, '2026-03-10 10:00:00', '2026-03-10 10:00:00', FALSE, CURRENT_TIMESTAMP(), 3, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000041', 91041, 411, '2026-04-22 10:00:00', 'delivered', 'standard', '11 Low St',      'Indianapolis', 'IN', '46201',  55.00,   4.95, 7.00,  66.95, '2026-04-22 10:00:00', '2026-04-22 10:00:00', FALSE, CURRENT_TIMESTAMP(), 3, 'DEMO_2026_SCENARIOS'),

  -- Customer 412: Excluded (1 low-value txn, warehouse 1)
  ('DEMO_OC000042', 91042, 412, '2026-05-05 10:00:00', 'delivered', 'standard', '12 Low Ave',     'Edison',       'NJ', '08817',  25.00,   2.25, 7.00,  34.25, '2026-05-05 10:00:00', '2026-05-05 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),

  -- Customer 413: Excluded (2 txns, avg ~$91, scattered categories, warehouse 2)
  ('DEMO_OC000043', 91043, 413, '2026-02-28 10:00:00', 'delivered', 'standard', '13 Scatter Dr',  'Atlanta',      'GA', '30301',  70.00,   6.30, 7.00,  83.30, '2026-02-28 10:00:00', '2026-02-28 10:00:00', FALSE, CURRENT_TIMESTAMP(), 2, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000044', 91044, 413, '2026-04-10 10:00:00', 'delivered', 'standard', '13 Scatter Dr',  'Atlanta',      'GA', '30301',  85.00,   7.65, 7.00,  99.65, '2026-04-10 10:00:00', '2026-04-10 10:00:00', FALSE, CURRENT_TIMESTAMP(), 2, 'DEMO_2026_SCENARIOS'),

  -- Customer 414: Outside 180-day window (all activity before 2025-12-04, warehouse 3)
  ('DEMO_OC000045', 91045, 414, '2025-08-10 10:00:00', 'delivered', 'standard', '14 Old Rd',      'Indianapolis', 'IN', '46201', 200.00,  18.00, 7.00, 225.00, '2025-08-10 10:00:00', '2025-08-10 10:00:00', FALSE, CURRENT_TIMESTAMP(), 3, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000046', 91046, 414, '2025-09-15 10:00:00', 'delivered', 'standard', '14 Old Rd',      'Indianapolis', 'IN', '46201', 180.00,  16.20, 7.00, 203.20, '2025-09-15 10:00:00', '2025-09-15 10:00:00', FALSE, CURRENT_TIMESTAMP(), 3, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000047', 91047, 414, '2025-10-20 10:00:00', 'delivered', 'standard', '14 Old Rd',      'Indianapolis', 'IN', '46201', 190.00,  17.10, 7.00, 214.10, '2025-10-20 10:00:00', '2025-10-20 10:00:00', FALSE, CURRENT_TIMESTAMP(), 3, 'DEMO_2026_SCENARIOS'),

  -- Customer 415: Boundary (2 txns x $100.00 exactly — avg=$100, only 2 txns, warehouse 1)
  ('DEMO_OC000048', 91048, 415, '2026-03-01 10:00:00', 'delivered', 'standard', '15 Edge St',     'Edison',       'NJ', '08817',  86.96,   7.83, 5.21, 100.00, '2026-03-01 10:00:00', '2026-03-01 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS'),
  ('DEMO_OC000049', 91049, 415, '2026-04-15 10:00:00', 'delivered', 'standard', '15 Edge St',     'Edison',       'NJ', '08817',  86.96,   7.83, 5.21, 100.00, '2026-04-15 10:00:00', '2026-04-15 10:00:00', FALSE, CURRENT_TIMESTAMP(), 1, 'DEMO_2026_SCENARIOS');

-- C.2: Orders for Category-Loyal customers (generator-based)

-- Customer 406: 12 txns, all category 1, avg $43.15, warehouse 1
INSERT INTO RET_ORDERS (CTID_FIVETRAN_ID, ID, CUSTOMER_ID, ORDER_DATE, STATUS, SHIPPING_METHOD, SHIPPING_ADDRESS, SHIPPING_CITY, SHIPPING_STATE, SHIPPING_ZIP, SUBTOTAL, TAX_AMOUNT, SHIPPING_COST, TOTAL_AMOUNT, CREATED_AT, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, WAREHOUSE_ID, DEMO_BATCH_ID)
SELECT
    'DEMO_OC_406_' || LPAD(seq4()::VARCHAR, 2, '0'),
    91100 + seq4(),
    406,
    DATEADD('day', seq4() * 14, '2026-01-05')::TIMESTAMP_NTZ,
    'delivered',
    'standard',
    '6 Loyal St',
    'Edison',
    'NJ',
    '08817',
    35.00,
    3.15,
    5.00,
    43.15,
    DATEADD('day', seq4() * 14, '2026-01-05')::TIMESTAMP_NTZ,
    DATEADD('day', seq4() * 14, '2026-01-05')::TIMESTAMP_NTZ,
    FALSE,
    CURRENT_TIMESTAMP(),
    1,
    'DEMO_2026_SCENARIOS'
FROM TABLE(GENERATOR(ROWCOUNT => 12));

-- Customer 407: 11 txns, all category 5, avg $37.70, warehouse 2
INSERT INTO RET_ORDERS (CTID_FIVETRAN_ID, ID, CUSTOMER_ID, ORDER_DATE, STATUS, SHIPPING_METHOD, SHIPPING_ADDRESS, SHIPPING_CITY, SHIPPING_STATE, SHIPPING_ZIP, SUBTOTAL, TAX_AMOUNT, SHIPPING_COST, TOTAL_AMOUNT, CREATED_AT, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, WAREHOUSE_ID, DEMO_BATCH_ID)
SELECT
    'DEMO_OC_407_' || LPAD(seq4()::VARCHAR, 2, '0'),
    91200 + seq4(),
    407,
    DATEADD('day', seq4() * 14, '2026-01-10')::TIMESTAMP_NTZ,
    'delivered',
    'standard',
    '7 Loyal Ave',
    'Atlanta',
    'GA',
    '30301',
    30.00,
    2.70,
    5.00,
    37.70,
    DATEADD('day', seq4() * 14, '2026-01-10')::TIMESTAMP_NTZ,
    DATEADD('day', seq4() * 14, '2026-01-10')::TIMESTAMP_NTZ,
    FALSE,
    CURRENT_TIMESTAMP(),
    2,
    'DEMO_2026_SCENARIOS'
FROM TABLE(GENERATOR(ROWCOUNT => 11));

-- Customer 408: 10 txns, all category 9, avg $48.60, warehouse 3
INSERT INTO RET_ORDERS (CTID_FIVETRAN_ID, ID, CUSTOMER_ID, ORDER_DATE, STATUS, SHIPPING_METHOD, SHIPPING_ADDRESS, SHIPPING_CITY, SHIPPING_STATE, SHIPPING_ZIP, SUBTOTAL, TAX_AMOUNT, SHIPPING_COST, TOTAL_AMOUNT, CREATED_AT, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, WAREHOUSE_ID, DEMO_BATCH_ID)
SELECT
    'DEMO_OC_408_' || LPAD(seq4()::VARCHAR, 2, '0'),
    91300 + seq4(),
    408,
    DATEADD('day', seq4() * 15, '2026-01-08')::TIMESTAMP_NTZ,
    'delivered',
    'standard',
    '8 Loyal Dr',
    'Indianapolis',
    'IN',
    '46201',
    40.00,
    3.60,
    5.00,
    48.60,
    DATEADD('day', seq4() * 15, '2026-01-08')::TIMESTAMP_NTZ,
    DATEADD('day', seq4() * 15, '2026-01-08')::TIMESTAMP_NTZ,
    FALSE,
    CURRENT_TIMESTAMP(),
    3,
    'DEMO_2026_SCENARIOS'
FROM TABLE(GENERATOR(ROWCOUNT => 10));

-- C.3: Order items for all Scenario C orders
--      Category-loyal customers get items from a single category.
--      Others get mixed products.
INSERT INTO RET_ORDER_ITEMS (CTID_FIVETRAN_ID, ID, ORDER_ID, PRODUCT_ID, QUANTITY, UNIT_PRICE, DISCOUNT_PCT, LINE_TOTAL, CREATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, DEMO_BATCH_ID)
SELECT
    'DEMO_OIC_' || LPAD(ROW_NUMBER() OVER (ORDER BY o.ID)::VARCHAR, 6, '0'),
    91000 + ROW_NUMBER() OVER (ORDER BY o.ID),
    o.ID,
    CASE
        WHEN o.CUSTOMER_ID = 406 THEN 10    -- Category 1 (Power Tools)
        WHEN o.CUSTOMER_ID = 407 THEN 210   -- Category 5 (Paint & Stain)
        WHEN o.CUSTOMER_ID = 408 THEN 410   -- Category 9 (Outdoor & Garden)
        WHEN o.CUSTOMER_ID = 409 THEN 10    -- Category 1 (for loyalty qualification)
        WHEN o.CUSTOMER_ID = 413 AND MOD(o.ID, 2) = 0 THEN 210  -- scattered categories
        WHEN o.CUSTOMER_ID = 413 AND MOD(o.ID, 2) = 1 THEN 410  -- scattered categories
        ELSE 50  -- arbitrary product for non-loyalty customers
    END,
    1,
    o.SUBTOTAL,
    0.00,
    o.SUBTOTAL,
    o.ORDER_DATE,
    FALSE,
    CURRENT_TIMESTAMP(),
    'DEMO_2026_SCENARIOS'
FROM RET_ORDERS o
WHERE o.DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS'
  AND o.ID BETWEEN 91001 AND 91399;


-- #############################################################################
-- PHASE 5: VALIDATION QUERIES
-- #############################################################################

-- =============================================================================
-- VALIDATION A: Inventory Misallocation
-- Expected: 5 rows. WH2 SHORT (-105), WH3 OVER (+55), WH4 OVER (+48),
--           WH5 Within tolerance (+3), WH1 Within tolerance (0).
-- =============================================================================
/*
SELECT
    w.ID                          AS warehouse_id,
    w.NAME                        AS warehouse_name,
    w.CITY,
    sl.QUANTITY                   AS shipped_quantity,
    inv.QUANTITY_ON_HAND          AS actual_on_hand,
    inv.QUANTITY_ON_HAND - sl.QUANTITY AS delta,
    CASE
        WHEN ABS(inv.QUANTITY_ON_HAND - sl.QUANTITY) <= 5 THEN 'Within tolerance'
        WHEN inv.QUANTITY_ON_HAND - sl.QUANTITY < -5       THEN 'SHORT'
        WHEN inv.QUANTITY_ON_HAND - sl.QUANTITY > 5        THEN 'OVER'
    END AS status
FROM RET_SHIPMENTS s
JOIN RET_SHIPMENT_LINES sl ON s.ID = sl.SHIPMENT_ID
JOIN RET_WAREHOUSES w      ON s.DESTINATION_WAREHOUSE_ID = w.ID
JOIN RET_INVENTORY inv     ON inv.PRODUCT_ID = sl.PRODUCT_ID
                           AND inv.WAREHOUSE_ID = w.ID
                           AND inv._FIVETRAN_DELETED = FALSE
WHERE sl.PRODUCT_ID = 42
  AND s.DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS'
ORDER BY w.ID;
*/

-- =============================================================================
-- VALIDATION B: Faulty Items (>20% defective return rate, trailing 365 days)
-- Expected: 3 items above 20% (products 101, 102, 103).
--           2 near-misses at ~18% (products 104, 105).
--           3 clean negatives at 0-4% (products 106, 107, 108).
-- =============================================================================
/*
WITH sales AS (
    SELECT
        oi.PRODUCT_ID,
        COUNT(*) AS units_sold
    FROM RET_ORDER_ITEMS oi
    JOIN RET_ORDERS o ON oi.ORDER_ID = o.ID
    WHERE o.STATUS = 'delivered'
      AND o.ORDER_DATE >= DATEADD('day', -365, '2026-06-01')
      AND o._FIVETRAN_DELETED  = FALSE
      AND oi._FIVETRAN_DELETED = FALSE
      AND oi.DEMO_BATCH_ID    = 'DEMO_2026_SCENARIOS'
    GROUP BY oi.PRODUCT_ID
),
defective_returns AS (
    SELECT
        r.PRODUCT_ID,
        COUNT(*) AS defective_units
    FROM RET_RETURNS r
    WHERE r.RETURN_REASON = 'Defective'
      AND r.RETURN_DATE >= DATEADD('day', -365, '2026-06-01')
      AND r._FIVETRAN_DELETED = FALSE
      AND r.DEMO_BATCH_ID    = 'DEMO_2026_SCENARIOS'
    GROUP BY r.PRODUCT_ID
)
SELECT
    s.PRODUCT_ID,
    p.NAME                                             AS product_name,
    v.NAME                                             AS vendor_name,
    s.units_sold,
    COALESCE(d.defective_units, 0)                     AS defective_returns,
    ROUND(COALESCE(d.defective_units, 0) * 100.0 / s.units_sold, 1) AS defect_rate_pct
FROM sales s
JOIN RET_PRODUCTS p     ON s.PRODUCT_ID = p.ID
LEFT JOIN RET_VENDORS v ON p.VENDOR_ID  = v.ID
LEFT JOIN defective_returns d ON s.PRODUCT_ID = d.PRODUCT_ID
ORDER BY defect_rate_pct DESC;
*/

-- =============================================================================
-- VALIDATION C: Customer Segmentation (180-day rolling window ending 2026-06-01)
-- Expected: 7 customers qualify for >= 1 segment.
--   401-403: VIP only.  404-405: Big Spender only.  406-408: Category-Loyal only.
--   409: VIP+Big Spender+Category-Loyal.  410: VIP+Big Spender.
--   411-415: fail all thresholds or outside window.
-- =============================================================================
/*
WITH order_level AS (
    SELECT
        CUSTOMER_ID,
        WAREHOUSE_ID,
        COUNT(*)           AS txn_count,
        AVG(TOTAL_AMOUNT)  AS avg_val,
        MAX(TOTAL_AMOUNT)  AS max_val
    FROM RET_ORDERS
    WHERE STATUS = 'delivered'
      AND ORDER_DATE >= DATEADD('day', -180, '2026-06-01')
      AND _FIVETRAN_DELETED = FALSE
      AND DEMO_BATCH_ID    = 'DEMO_2026_SCENARIOS'
      AND ID BETWEEN 91001 AND 91399
    GROUP BY CUSTOMER_ID, WAREHOUSE_ID
),
category_loyalty AS (
    SELECT
        o.CUSTOMER_ID,
        sc.CATEGORY_ID,
        COUNT(*) AS cat_txn_count
    FROM RET_ORDERS o
    JOIN RET_ORDER_ITEMS oi            ON o.ID = oi.ORDER_ID
    JOIN RET_PRODUCTS p                ON oi.PRODUCT_ID = p.ID
    JOIN RET_PRODUCT_SUBCATEGORIES sc  ON p.SUBCATEGORY_ID = sc.ID
    WHERE o.STATUS = 'delivered'
      AND o.ORDER_DATE >= DATEADD('day', -180, '2026-06-01')
      AND o._FIVETRAN_DELETED  = FALSE
      AND oi._FIVETRAN_DELETED = FALSE
      AND o.DEMO_BATCH_ID     = 'DEMO_2026_SCENARIOS'
      AND o.ID BETWEEN 91001 AND 91399
    GROUP BY o.CUSTOMER_ID, sc.CATEGORY_ID
    HAVING COUNT(*) >= 10
)
SELECT
    ol.CUSTOMER_ID,
    ol.WAREHOUSE_ID,
    ol.txn_count,
    ROUND(ol.avg_val, 2)                                          AS avg_txn_value,
    ol.max_val                                                    AS max_txn_value,
    CASE WHEN ol.avg_val > 100 AND ol.txn_count >= 3 THEN 'Y' ELSE 'N' END AS is_vip,
    CASE WHEN ol.max_val > 300                        THEN 'Y' ELSE 'N' END AS is_big_spender,
    CASE WHEN cl.CUSTOMER_ID IS NOT NULL              THEN 'Y' ELSE 'N' END AS is_category_loyal
FROM order_level ol
LEFT JOIN category_loyalty cl ON ol.CUSTOMER_ID = cl.CUSTOMER_ID
ORDER BY ol.CUSTOMER_ID;
*/


-- #############################################################################
-- ROLLBACK: Identify and remove all demo data
-- #############################################################################
/*
-- Count demo rows per table
SELECT 'RET_SHIPMENTS'             AS tbl, COUNT(*) FROM RET_SHIPMENTS             WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS'
UNION ALL SELECT 'RET_SHIPMENT_LINES',      COUNT(*) FROM RET_SHIPMENT_LINES      WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS'
UNION ALL SELECT 'RET_VENDORS',             COUNT(*) FROM RET_VENDORS             WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS'
UNION ALL SELECT 'RET_RETURNS',             COUNT(*) FROM RET_RETURNS             WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS'
UNION ALL SELECT 'RET_ORDERS',              COUNT(*) FROM RET_ORDERS              WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS'
UNION ALL SELECT 'RET_ORDER_ITEMS',         COUNT(*) FROM RET_ORDER_ITEMS         WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS'
UNION ALL SELECT 'RET_INVENTORY',           COUNT(*) FROM RET_INVENTORY           WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS'
UNION ALL SELECT 'RET_PRODUCTS',            COUNT(*) FROM RET_PRODUCTS            WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS';

-- Delete demo rows (run in dependency order: children first)
DELETE FROM RET_RETURNS             WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS';
DELETE FROM RET_SHIPMENT_LINES      WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS';
DELETE FROM RET_SHIPMENTS           WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS';
DELETE FROM RET_ORDER_ITEMS         WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS';
DELETE FROM RET_ORDERS              WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS';
DELETE FROM RET_VENDORS             WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS';
UPDATE RET_PRODUCTS   SET VENDOR_ID = NULL, DEMO_BATCH_ID = NULL WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS';
UPDATE RET_INVENTORY  SET DEMO_BATCH_ID = NULL WHERE DEMO_BATCH_ID = 'DEMO_2026_SCENARIOS';

-- Full DDL revert (drop added columns and new tables)
ALTER TABLE RET_PRODUCTS    DROP COLUMN VENDOR_ID;
ALTER TABLE RET_ORDERS      DROP COLUMN WAREHOUSE_ID;
ALTER TABLE RET_INVENTORY   DROP COLUMN DEMO_BATCH_ID;
ALTER TABLE RET_ORDERS      DROP COLUMN DEMO_BATCH_ID;
ALTER TABLE RET_PRODUCTS    DROP COLUMN DEMO_BATCH_ID;
ALTER TABLE RET_ORDER_ITEMS DROP COLUMN DEMO_BATCH_ID;
DROP TABLE RET_RETURNS;
DROP TABLE RET_SHIPMENT_LINES;
DROP TABLE RET_SHIPMENTS;
DROP TABLE RET_VENDORS;
*/
