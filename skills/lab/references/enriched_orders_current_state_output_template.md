# Enriched Orders Current-State Output Template

Use this template when answering:

```text
Find int_orders_enriched in this project. Show me what it currently produces, its grain, and which models depend on it downstream.
```

Also use it for equivalent prompts such as:

```text
Find enriched orders and show me what it currently produces, its grain, and which models depend on it downstream.
```

Populate the bracketed values from `search`, `describe`, `lineage`, the model SQL, and the model YAML. If the latest compile failed or the index may be stale, say so before the model details.

```markdown
Found **`[model_name]`**.

Note: [Only include if relevant: compile is currently blocked by [reason], so this is based on [source of truth].]

## `[model_name]`

- **Path:** `[model_path]`
- **Materialization:** `[materialization]`
- **Grain:** [one row per `[grain_column]`]
- **Primary key:** `[primary_key]`
- **Direct upstream:** `[upstream_model]`
- **Description:** [short description of what the model does]

## What it currently produces

### Keys
- `[primary_key]`
- `[foreign_key]`

### Dates
- `[date_column]`
- `[created_at_column]`
- `[updated_at_column]`
- `[date_part_column]`

### Status / fulfillment
- `[status_column]`
- `[fulfillment_column]`
- `[derived_flag]`

### Shipping location
- `[location_column]`

### Financial totals
- `[measure_column]`

## Direct downstream models

| Model | Materialization | Purpose |
|---|---:|---|
| `[downstream_model]` | [table/view] | [short purpose] |

## Further downstream marts

Through those direct dependents, `[model_name]` also feeds:

- `[further_downstream_model]`

## Tests on `[model_name]`

- `[test_type]` on `[column_name]`
```

Rules:

- Resolve the model first. For this HOL scenario, "enriched orders" means `int_orders_enriched`.
- Always state the grain before downstream impact.
- Use model SQL for the emitted column list when index column metadata is unavailable.
- Group emitted columns by business role: keys, dates, status/flags, location, financial measures, and any other relevant group.
- Separate direct downstream models from further downstream marts. Direct downstream is the contract surface for the edit; further downstream is blast-radius context.
- Prefer concise purpose descriptions over full model descriptions.
- Use inline code formatting for model and column names.
- Mention compile/index caveats when present.

For this HOL project, the populated output should usually resemble:

```markdown
Found **`int_orders_enriched`**.

Note: compile is currently blocked by dbt 2.0 deprecated generic test argument syntax, so this is based on the local dbt index plus the model SQL/YAML.

## `int_orders_enriched`

- **Path:** `models/intermediate/int_orders_enriched.sql`
- **Materialization:** view
- **Grain:** one row per `order_id`
- **Primary key:** `order_id`
- **Direct upstream:** `stg_orders`
- **Description:** enriches staged orders with derived status flags and date parts. Financial totals come directly from the order record.

## What it currently produces

### Keys
- `order_id`
- `customer_id`

### Dates
- `order_date`
- `created_at`
- `updated_at`
- `order_month`
- `order_year`
- `order_day_of_week`

### Status / fulfillment
- `order_status`
- `shipping_method`
- `is_returned`
- `is_cancelled`
- `is_completed`

### Shipping location
- `shipping_address`
- `shipping_city`
- `shipping_state`
- `shipping_zip`

### Financial totals
- `subtotal`
- `tax_amount`
- `shipping_cost`
- `total_amount`

## Direct downstream models

| Model | Materialization | Purpose |
|---|---:|---|
| `fct_orders` | table | Order fact table, one row per order |
| `fct_order_items` | table | Order item fact table with order context |
| `int_customer_order_summary` | view | Per-customer lifetime order aggregates |
| `int_daily_revenue` | view | Completed revenue by order date |
| `int_product_sales_summary` | view | Product sales rollup from completed orders |
| `agg_promotion_performance` | table | Promotion performance against completed order revenue |

## Further downstream marts

Through those direct dependents, `int_orders_enriched` also feeds:

- `dim_customers`
- `customer_lifetime_value`
- `agg_customer_cohorts`
- `agg_daily_revenue`
- `agg_monthly_revenue`
- `dim_products`
- `agg_product_performance`
- `order_margin_analysis`

## Tests on `int_orders_enriched`

- `unique` on `order_id`
- `not_null` on `order_id`
- `not_null` on `order_status`
- `not_null` on `is_completed`
```
