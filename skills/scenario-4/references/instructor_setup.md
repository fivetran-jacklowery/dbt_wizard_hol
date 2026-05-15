# Scenario 4 — Instructor Setup

Scenario 4 demonstrates dbt Wizard fixing a model that's broken by an upstream column rename. For the attendee to see a real failure, the rename must be applied to the source table **before they run `dbt run`**.

Each path (A, B, C) corresponds to one column rename. Pick one path per cohort, or pre-stage all three across separate dev schemas so attendees can choose.

## Path A — Products (`brand` → `brand_name`)

Run as a role with ALTER on the retail source schema (e.g. `LAB_INSTRUCTOR_ROLE`):

```sql
ALTER TABLE SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL.RET_PRODUCTS
  RENAME COLUMN BRAND TO BRAND_NAME;
```

## Path B — Orders (`status` → `order_status`)

The DDL baseline has this column as `STATUS`. The `stg_orders` model selects `status AS order_status`. Renaming the source column to `ORDER_STATUS` (the alias name) makes the staging model's `select status as order_status` clause invalid — `status` no longer exists, even though `order_status` now does. The break is "the source column you used to read got renamed to something else."

```sql
ALTER TABLE SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL.RET_ORDERS
  RENAME COLUMN STATUS TO ORDER_STATUS;
```

## Path C — Customers (`customer_type` → `segment`)

```sql
ALTER TABLE SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL.RET_CUSTOMERS
  RENAME COLUMN CUSTOMER_TYPE TO SEGMENT;
```

## Post-lab cleanup

Reverse each rename after the cohort completes:

```sql
-- Path A
ALTER TABLE SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL.RET_PRODUCTS
  RENAME COLUMN BRAND_NAME TO BRAND;

-- Path B
ALTER TABLE SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL.RET_ORDERS
  RENAME COLUMN ORDER_STATUS TO STATUS;

-- Path C
ALTER TABLE SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL.RET_CUSTOMERS
  RENAME COLUMN SEGMENT TO CUSTOMER_TYPE;
```

## Multi-tenant note

If multiple cohorts run concurrently against the same source schema, do not rename the shared `SF_HOL_2026_RETAIL` table — instead clone the source into a per-cohort schema and apply the rename there, pointing each attendee's `profiles.yml` at the cohort-specific schema.
