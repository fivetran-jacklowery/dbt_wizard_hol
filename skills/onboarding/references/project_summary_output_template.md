# Project Summary Output Template

Use this template when answering:

```text
Give me a project summary
```

or:

```text
Summarize what this dbt project does. What are the main subject areas and how is the project organized?
```

Populate the bracketed values from `status`, `search`, `dbt_project.yml`, and the model tree. Keep the response concise and factual.

```markdown
## Project summary

`[project_name]` is a [adapter]-backed [business/domain] analytics project. It models the main business domains needed for reporting and analysis:

- **[Domain 1]**: [Short description of what the project models for this domain].
- **[Domain 2]**: [Short description].
- **[Domain 3]**: [Short description].
- **[Domain 4]**: [Short description].
- **[Domain 5]**: [Short description].

## Project shape

Current dbt inventory:

- **[model_count] models**
- **[source_count] sources**
- **[test_count] tests**
- **[doc_coverage]% documented**
- **[test_coverage]% test-covered**
- Last recorded command: `[last_command]` on **[last_run_date]**

## Layering

The repo follows a [layer_count]-layer dbt structure:

### `[staging_path]`
[One-sentence description of staging-layer purpose.]

Examples:
- `[staging_model_1]`
- `[staging_model_2]`
- `[staging_model_3]`

### `[intermediate_path]`
[One-sentence description of intermediate-layer purpose.]

Examples:
- `[intermediate_model_1]`
- `[intermediate_model_2]`
- `[intermediate_model_3]`

### `[mart_path]`
[One-sentence description of mart-layer purpose.]

Examples:
- `[mart_model_1]`
- `[mart_model_2]`
- `[mart_model_3]`

## Main convention to know

- [Convention 1, e.g. staging/intermediate materialization].
- [Convention 2, e.g. mart materialization].
- [Convention 3, e.g. `source()` vs `ref()` usage].
- [Convention 4, e.g. soft-delete filtering].
- [Convention 5, e.g. relevant project vars or macros].
```

For this HOL project, the populated shape should usually resemble:

```markdown
## Project summary

`dbt_wizard_hol` is a Snowflake-backed retail analytics project for The Builder Depot. It models the main business domains needed for reporting and analysis:

- **Customers**: customer dimension, cohorts, lifetime value, support history.
- **Orders**: order facts, order items, revenue aggregates, margin analysis.
- **Products**: product dimension, category taxonomy, sales performance, reviews.
- **Inventory**: inventory status and inventory movement transactions.
- **Promotions**: promotion performance by product category and order revenue.
- **Support**: ticket facts and customer support summaries.

## Project shape

Current dbt inventory:

- **35 models**
- **12 sources**
- **168 tests**
- **100% documented**
- **100% test-covered**
- Last recorded command: `compile` on **2026-05-19**

## Layering

The repo follows a standard three-layer dbt structure:

### `models/staging`
One staging model per raw retail source table. These normalize names/types and filter soft-deleted Fivetran rows.

Examples:
- `stg_customers`
- `stg_orders`
- `stg_order_items`
- `stg_products`
- `stg_inventory`
- `stg_tickets`

### `models/intermediate`
Business logic, enrichment, joins, and reusable aggregates.

Examples:
- `int_orders_enriched`
- `int_order_items_enriched`
- `int_customer_order_summary`
- `int_product_sales_summary`
- `int_inventory_status`

### `models/marts`
Consumer-facing tables for BI and stakeholder analysis.

Core marts include:
- `fct_orders`
- `fct_order_items`
- `dim_customers`
- `dim_products`
- `agg_daily_revenue`
- `agg_monthly_revenue`
- `customer_lifetime_value`

Marketing marts include:
- `agg_customer_cohorts`
- `agg_promotion_performance`

## Main convention to know

- Staging/intermediate models are **views**.
- Mart models are **tables**.
- Staging uses `source('retail', ...)`.
- Downstream layers use `ref()`.
- Customer tier thresholds and active-customer logic are controlled by project vars in `dbt_project.yml`.
```
