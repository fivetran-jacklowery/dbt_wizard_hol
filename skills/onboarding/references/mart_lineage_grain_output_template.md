# Mart Lineage, Grain, and Key Columns Output Template

Use this template when answering:

```text
Show me the lineage, grain, and key columns for the orders mart model.
```

Also use it for equivalent prompts asking for a mart model's lineage, grain, and important columns. Populate the bracketed values from `search`, `describe`, `lineage`, the model SQL, and the model YAML. If the latest compile failed or the index may be stale, say so before the details.

```markdown
The orders mart resolves to **`[mart_model_name]`**.

Note: [Only include if relevant: the latest compile failed because [reason]. This is based on [source of truth], not a fresh successful compile.]

## `[mart_model_name]`

- **Path:** `[model_path]`
- **Materialization:** `[materialization]`
- **Grain:** [one row per `[grain_column]`]
- **Primary key:** `[primary_key]`
- **Description:** [short model description]

## Lineage

### Direct upstream

`[mart_model_name]` is built from:

| Upstream model | Layer | What it contributes |
|---|---|---|
| `[direct_parent_1]` | intermediate | [short contribution] |
| `[direct_parent_2]` | intermediate | [short contribution] |

### Upstream staging and sources

| Staging model | Source table | What it contributes |
|---|---|---|
| `[stg_model_1]` | `[source_name].[source_table_1]` | [short contribution] |
| `[stg_model_2]` | `[source_name].[source_table_2]` | [short contribution] |

### Downstream

The main downstream model is:

- `[downstream_model]`

Also mention relevant downstream tests if they clarify the contract.

## Key columns

### Keys

- `[primary_key]` — primary key, unique per [entity]
- `[foreign_key]` — foreign key to `[dimension_or_parent_model]`

### Dates

- `[date_column]`
- `[date_part_column]`

### Status / flags

- `[status_column]`
- `[flag_column]`

Accepted `[status_column]` values are documented as:

- `[value_1]`
- `[value_2]`

### Measures

- `[measure_1]`
- `[measure_2]`

## Join shape

Summarize the model's join pattern. Include a short SQL snippet only if it helps explain the grain-preserving logic.
```

Rules:

- Resolve the likely mart model first. For this HOL project, "orders mart" means `fct_orders`.
- Always state the grain before listing lineage or columns.
- In upstream lineage, list staging models **with their source table in the same row**. This keeps the warehouse lineage clear in one place.
- Prefer concise contribution descriptions over full model descriptions.
- Use inline code formatting for model, source, and column names.
- If direct column metadata is unavailable in the index, read the model SQL and YAML before answering.
- Do not hard-code counts, statuses, or accepted values unless they were just retrieved from metadata/files.

For this HOL project, the populated output should usually resemble:

````markdown
The orders mart resolves to **`fct_orders`**.

Note: the session-start compile failed due to deprecated generic test argument syntax in `models/staging/_staging__models.yml`, so this is based on the local index plus the model/YAML files, not a fresh successful compile.

## `fct_orders`

- **Path:** `models/marts/core/fct_orders.sql`
- **Materialization:** table
- **Grain:** one row per `order_id`
- **Primary key:** `order_id`
- **Description:** order fact table with order-record financial totals, line-item revenue rollups, and status flags.

## Lineage

### Direct upstream

`fct_orders` is built from:

| Upstream model | Layer | What it contributes |
|---|---|---|
| `int_orders_enriched` | intermediate | order header data, date fields, status fields, shipping fields, and order-level flags |
| `int_order_items_enriched` | intermediate | line-item revenue and quantity aggregated to `order_id` |

### Upstream staging and sources

| Staging model | Source table | What it contributes |
|---|---|---|
| `stg_orders` | `retail.RET_ORDERS` | source order records, status, shipping details, and financial totals |
| `stg_order_items` | `retail.RET_ORDER_ITEMS` | order line items, quantities, unit prices, and discounts |
| `stg_products` | `retail.RET_PRODUCTS` | product attributes used by enriched line items |
| `stg_product_categories` | `retail.RET_PRODUCT_CATEGORIES` | top-level product category lookup |
| `stg_product_subcategories` | `retail.RET_PRODUCT_SUBCATEGORIES` | product subcategory lookup and category join path |

### Downstream

The main downstream model is:

- `order_margin_analysis`

There are also tests downstream of `fct_orders`, including uniqueness, not-null, accepted-values, relationships, and custom revenue assertions.

## Key columns

### Keys

- `order_id` — primary key, unique per order
- `customer_id` — foreign key to `dim_customers`

### Dates

- `order_date`
- `order_month`
- `order_year`

### Status / fulfillment

- `order_status`
- `shipping_method`
- `is_returned`
- `is_cancelled`
- `is_completed`

Accepted `order_status` values are documented as:

- `completed`
- `returned`
- `pending`
- `cancelled`
- `processing`
- `shipped`
- `delivered`

### Shipping location

- `shipping_address`
- `shipping_city`
- `shipping_state`
- `shipping_zip`

### Financial measures

From the order record:

- `subtotal`
- `tax_amount`
- `shipping_cost`
- `total_amount`

From line-item aggregation:

- `order_revenue`
- `order_revenue_after_discount`
- `line_item_count`
- `total_quantity`

## Join shape

`fct_orders` drives from `int_orders_enriched` and left joins aggregated line items:

```sql
from orders o
left join order_items oi
  on o.order_id = oi.order_id
```

That preserves one row per order, even if an order has no matching line items.
````
