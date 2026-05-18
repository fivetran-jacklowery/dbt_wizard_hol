# Scenario 4 - Instructor Setup

Scenario 4 demonstrates dbt Wizard fixing a product model that's broken by an upstream column rename. For the attendee to see a real failure, the rename must be applied to the source table **before they run `dbt run`**.

This scenario uses the product-source rename: `retail.RET_PRODUCTS.brand` is renamed to `brand_name`.

## Apply the product rename

Run as a role with ALTER on the retail source schema (e.g. `LAB_INSTRUCTOR_ROLE`):

```sql
ALTER TABLE SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL.RET_PRODUCTS
  RENAME COLUMN BRAND TO BRAND_NAME;
```

This breaks `stg_products`, which still selects `brand`. The intended fix is to update the staging model to select `brand_name as brand`, preserving the public dbt contract for downstream models.

## Post-lab cleanup

Reverse the rename after the cohort completes:

```sql
ALTER TABLE SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL.RET_PRODUCTS
  RENAME COLUMN BRAND_NAME TO BRAND;
```

## Multi-tenant note

If multiple cohorts run concurrently against the same source schema, do not rename the shared `SF_HOL_2026_RETAIL` table. Instead, clone the source into a per-cohort schema and apply the rename there, pointing each attendee's `profiles.yml` at the cohort-specific schema.
