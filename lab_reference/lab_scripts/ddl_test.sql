-- =============================================================================
-- DDL: hol_dbx_catalog.test_dbt_wiz_hol_schema_reload
-- =============================================================================
-- Complete schema definition for The Build Depot (TBD) retail demo database.
-- This file is DDL-only: no DML (INSERT/UPDATE/DELETE/MERGE).
--
-- Run this file first on a clean database, then run the DML file to populate data.
--
-- Adapted for Data + AI Summit on Databricks Unity Catalog.
-- =============================================================================

CREATE CATALOG IF NOT EXISTS `hol_dbx_catalog`;
CREATE SCHEMA IF NOT EXISTS `hol_dbx_catalog`.`test_dbt_wiz_hol_schema_reload`;

USE CATALOG `hol_dbx_catalog`;
USE SCHEMA `test_dbt_wiz_hol_schema_reload`;

-- #############################################################################
-- TABLES
-- #############################################################################

-- -----------------------------------------------------------------------------
-- Reference / Lookup Tables
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE RET_WAREHOUSES (
    CTID_FIVETRAN_ID  STRING NOT NULL,
    ID                BIGINT,
    NAME              STRING,
    ADDRESS           STRING,
    CITY              STRING,
    STATE             STRING,
    ZIP               STRING,
    CAPACITY_SQFT     BIGINT,
    IS_ACTIVE         BOOLEAN,
    CREATED_AT        TIMESTAMP,
    _FIVETRAN_DELETED BOOLEAN,
    _FIVETRAN_SYNCED  TIMESTAMP
);

CREATE OR REPLACE TABLE RET_PRODUCT_CATEGORIES (
    CTID_FIVETRAN_ID  STRING NOT NULL,
    ID                BIGINT,
    NAME              STRING,
    DESCRIPTION       STRING,
    CREATED_AT        TIMESTAMP,
    UPDATED_AT        TIMESTAMP,
    _FIVETRAN_DELETED BOOLEAN,
    _FIVETRAN_SYNCED  TIMESTAMP
);

CREATE OR REPLACE TABLE RET_PRODUCT_SUBCATEGORIES (
    CTID_FIVETRAN_ID  STRING NOT NULL,
    ID                BIGINT,
    CATEGORY_ID       BIGINT,
    NAME              STRING,
    DESCRIPTION       STRING,
    CREATED_AT        TIMESTAMP,
    UPDATED_AT        TIMESTAMP,
    _FIVETRAN_DELETED BOOLEAN,
    _FIVETRAN_SYNCED  TIMESTAMP
);

CREATE OR REPLACE TABLE RET_VENDORS (
    CTID_FIVETRAN_ID  STRING NOT NULL,
    ID                BIGINT,
    NAME              STRING,
    CONTACT_EMAIL     STRING,
    CITY              STRING,
    STATE             STRING,
    CREATED_AT        TIMESTAMP,
    _FIVETRAN_DELETED BOOLEAN,
    _FIVETRAN_SYNCED  TIMESTAMP,
    DEMO_BATCH_ID     STRING
);

-- -----------------------------------------------------------------------------
-- Core Entity Tables
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE RET_CUSTOMERS (
    CTID_FIVETRAN_ID  STRING NOT NULL,
    ID                BIGINT,
    FIRST_NAME        STRING,
    LAST_NAME         STRING,
    EMAIL             STRING,
    PHONE             STRING,
    ADDRESS           STRING,
    CITY              STRING,
    STATE             STRING,
    ZIP               STRING,
    REGION            STRING,
    CUSTOMER_TYPE     STRING,
    CREATED_AT        TIMESTAMP,
    UPDATED_AT        TIMESTAMP,
    _FIVETRAN_DELETED BOOLEAN,
    _FIVETRAN_SYNCED  TIMESTAMP
);

CREATE OR REPLACE TABLE RET_PRODUCTS (
    CTID_FIVETRAN_ID  STRING NOT NULL,
    ID                BIGINT,
    SKU               STRING,
    NAME              STRING,
    DESCRIPTION       STRING,
    SUBCATEGORY_ID    BIGINT,
    BRAND             STRING,
    UNIT_PRICE        DECIMAL(10,2),
    WEIGHT_LBS        DECIMAL(8,2),
    IS_ACTIVE         BOOLEAN,
    CREATED_AT        TIMESTAMP,
    UPDATED_AT        TIMESTAMP,
    _FIVETRAN_DELETED BOOLEAN,
    _FIVETRAN_SYNCED  TIMESTAMP,
    DEMO_BATCH_ID     STRING,
    VENDOR_ID         BIGINT
);

-- -----------------------------------------------------------------------------
-- Transaction Tables
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE RET_ORDERS (
    CTID_FIVETRAN_ID  STRING NOT NULL,
    ID                BIGINT,
    CUSTOMER_ID       BIGINT,
    ORDER_DATE        TIMESTAMP,
    STATUS            STRING,
    SHIPPING_METHOD   STRING,
    SHIPPING_ADDRESS  STRING,
    SHIPPING_CITY     STRING,
    SHIPPING_STATE    STRING,
    SHIPPING_ZIP      STRING,
    SUBTOTAL          DECIMAL(10,2),
    TAX_AMOUNT        DECIMAL(10,2),
    SHIPPING_COST     DECIMAL(10,2),
    TOTAL_AMOUNT      DECIMAL(10,2),
    CREATED_AT        TIMESTAMP,
    UPDATED_AT        TIMESTAMP,
    _FIVETRAN_DELETED BOOLEAN,
    _FIVETRAN_SYNCED  TIMESTAMP,
    WAREHOUSE_ID      BIGINT,
    DEMO_BATCH_ID     STRING
);

CREATE OR REPLACE TABLE RET_ORDER_ITEMS (
    CTID_FIVETRAN_ID  STRING NOT NULL,
    ID                BIGINT,
    ORDER_ID          BIGINT,
    PRODUCT_ID        BIGINT,
    QUANTITY          BIGINT,
    UNIT_PRICE        DECIMAL(10,2),
    DISCOUNT_PCT      DECIMAL(5,2),
    LINE_TOTAL        DECIMAL(10,2),
    CREATED_AT        TIMESTAMP,
    _FIVETRAN_DELETED BOOLEAN,
    _FIVETRAN_SYNCED  TIMESTAMP,
    DEMO_BATCH_ID     STRING
);

CREATE OR REPLACE TABLE RET_RETURNS (
    CTID_FIVETRAN_ID  STRING NOT NULL,
    ID                BIGINT,
    ORDER_ID          BIGINT,
    ORDER_ITEM_ID     BIGINT,
    PRODUCT_ID        BIGINT,
    CUSTOMER_ID       BIGINT,
    RETURN_DATE       DATE,
    QUANTITY          BIGINT,
    RETURN_REASON     STRING,
    NOTES             STRING,
    CREATED_AT        TIMESTAMP,
    _FIVETRAN_DELETED BOOLEAN,
    _FIVETRAN_SYNCED  TIMESTAMP,
    DEMO_BATCH_ID     STRING
);

CREATE OR REPLACE TABLE RET_SHIPMENTS (
    CTID_FIVETRAN_ID         STRING NOT NULL,
    ID                       BIGINT,
    DESTINATION_WAREHOUSE_ID BIGINT,
    ORIGIN_WAREHOUSE_ID      BIGINT,
    SHIPMENT_DATE            DATE,
    STATUS                   STRING,
    NOTES                    STRING,
    CREATED_AT               TIMESTAMP,
    _FIVETRAN_DELETED        BOOLEAN,
    _FIVETRAN_SYNCED         TIMESTAMP,
    DEMO_BATCH_ID            STRING
);

CREATE OR REPLACE TABLE RET_SHIPMENT_LINES (
    CTID_FIVETRAN_ID  STRING NOT NULL,
    ID                BIGINT,
    SHIPMENT_ID       BIGINT,
    PRODUCT_ID        BIGINT,
    QUANTITY          BIGINT,
    CREATED_AT        TIMESTAMP,
    _FIVETRAN_DELETED BOOLEAN,
    _FIVETRAN_SYNCED  TIMESTAMP,
    DEMO_BATCH_ID     STRING
);

-- -----------------------------------------------------------------------------
-- Inventory Tables
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE RET_INVENTORY (
    CTID_FIVETRAN_ID  STRING NOT NULL,
    ID                BIGINT,
    PRODUCT_ID        BIGINT,
    WAREHOUSE_ID      BIGINT,
    QUANTITY_ON_HAND  BIGINT,
    REORDER_POINT     BIGINT,
    REORDER_QUANTITY  BIGINT,
    LAST_RESTOCKED_AT TIMESTAMP,
    UPDATED_AT        TIMESTAMP,
    _FIVETRAN_DELETED BOOLEAN,
    _FIVETRAN_SYNCED  TIMESTAMP,
    DEMO_BATCH_ID     STRING
);

CREATE OR REPLACE TABLE RET_INVENTORY_TRANSACTIONS (
    CTID_FIVETRAN_ID  STRING NOT NULL,
    ID                BIGINT,
    PRODUCT_ID        BIGINT,
    WAREHOUSE_ID      BIGINT,
    TRANSACTION_TYPE  STRING,
    QUANTITY          BIGINT,
    REFERENCE_ID      BIGINT,
    NOTES             STRING,
    CREATED_AT        TIMESTAMP,
    _FIVETRAN_DELETED BOOLEAN,
    _FIVETRAN_SYNCED  TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- Engagement Tables
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE RET_PROMOTIONS (
    CTID_FIVETRAN_ID       STRING NOT NULL,
    ID                     BIGINT,
    NAME                   STRING,
    DESCRIPTION            STRING,
    DISCOUNT_TYPE          STRING,
    DISCOUNT_VALUE         DECIMAL(10,2),
    MIN_ORDER_AMOUNT       DECIMAL(10,2),
    APPLICABLE_CATEGORY_ID BIGINT,
    START_DATE             DATE,
    END_DATE               DATE,
    IS_ACTIVE              BOOLEAN,
    CREATED_AT             TIMESTAMP,
    _FIVETRAN_DELETED      BOOLEAN,
    _FIVETRAN_SYNCED       TIMESTAMP
);

CREATE OR REPLACE TABLE RET_TICKETS (
    CTID_FIVETRAN_ID  STRING NOT NULL,
    ID                BIGINT,
    CUSTOMER_ID       BIGINT,
    ORDER_ID          BIGINT,
    ISSUE_TYPE        STRING,
    PRIORITY          STRING,
    STATUS            STRING,
    DESCRIPTION       STRING,
    CREATED_AT        TIMESTAMP,
    RESOLVED_AT       TIMESTAMP,
    _FIVETRAN_DELETED BOOLEAN,
    _FIVETRAN_SYNCED  TIMESTAMP
);

CREATE OR REPLACE TABLE RET_PRODUCT_REVIEWS (
    CTID_FIVETRAN_ID    STRING NOT NULL,
    ID                  BIGINT,
    PRODUCT_ID          BIGINT,
    CUSTOMER_ID         BIGINT,
    RATING              BIGINT,
    REVIEW_TITLE        STRING,
    REVIEW_TEXT         STRING,
    IS_VERIFIED_PURCHASE BOOLEAN,
    CREATED_AT          TIMESTAMP,
    _FIVETRAN_DELETED   BOOLEAN,
    _FIVETRAN_SYNCED    TIMESTAMP
);


-- #############################################################################

-- Foreign key relationships are documented in dbt tests and BI semantics.
-- #############################################################################

-- Products → Subcategories → Categories


-- Products → Vendors

-- Orders → Customers, Warehouses


-- Order Items → Orders, Products


-- Returns → Orders, Order Items, Products, Customers




-- Shipments → Warehouses; Shipment Lines → Shipments, Products



-- Inventory → Products, Warehouses


-- Tickets → Customers, Orders


-- Promotions → Categories

-- Reviews → Products, Customers
