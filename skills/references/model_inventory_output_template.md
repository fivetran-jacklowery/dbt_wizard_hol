# Model Inventory Output Template

Use this template when answering:

```text
List the staging, intermediate, and mart models. Group them by domain.
```

Populate the bracketed values from `status`, `search`, `dbt_project.yml`, and the model tree. If the latest compile failed or the index may be stale, say so before the table. Keep the answer concise and factual.

```markdown
The project has **[model_count] models** in the dbt index: **[staging_count] staging**, **[intermediate_count] intermediate**, **[mart_count] marts**. Domain grouping is inferred from [model names/descriptions/tags/folders]; domains are [not encoded as tags / encoded by tags / encoded by folder].

Note: [Only include if relevant: the latest compile failed because [reason]. This list is from [source of truth], not a fresh successful compile.]

| Domain | Staging | Intermediate | Marts |
|---|---|---|---|
| **[Domain 1]** | `[stg_model]`, `[stg_model]` | `[int_model]`, `[int_model]` | `[mart_model]`, `[mart_model]` |
| **[Domain 2]** | `[stg_model]` | `[int_model]` | `[mart_model]` |
| **[Domain 3]** | `[stg_model]`, `[stg_model]` | — | `[mart_model]` |
```

Rules:

- Group by business domain, not by folder alone.
- Use `—` when a domain has no model in a layer.
- Prefer model names only; omit paths unless the user asks for file locations.
- Use inline code formatting for model names.
- Mention how the grouping was inferred if domains are not explicit metadata.
- Do not hard-code counts unless they were just retrieved.

For this HOL project, the populated output should usually resemble:

```markdown
The project has **35 models** in the dbt index: **12 staging**, **10 intermediate**, **13 marts**. Domain grouping is inferred from model names/descriptions; domains are not encoded as tags.

Note: the session-start compile failed because `models/staging/_staging__models.yml` uses deprecated generic test argument syntax. This list is from the local project/index, not a fresh successful compile.

| Domain | Staging | Intermediate | Marts |
|---|---|---|---|
| **Customer** | `stg_customers` | `int_customer_cohorts`, `int_customer_order_summary` | `dim_customers`, `customer_lifetime_value`, `agg_customer_cohorts` |
| **Orders & revenue** | `stg_orders`, `stg_order_items` | `int_orders_enriched`, `int_order_items_enriched`, `int_daily_revenue` | `fct_orders`, `fct_order_items`, `agg_daily_revenue`, `agg_monthly_revenue`, `order_margin_analysis` |
| **Product & catalog** | `stg_products`, `stg_product_categories`, `stg_product_subcategories`, `stg_product_reviews` | `int_products_enriched`, `int_product_reviews_summary`, `int_product_sales_summary` | `dim_products`, `agg_product_performance` |
| **Inventory & warehouses** | `stg_inventory`, `stg_inventory_transactions`, `stg_warehouses` | `int_inventory_status` | `fct_inventory_transactions` |
| **Support** | `stg_tickets` | `int_customer_support_summary` | `fct_tickets` |
| **Promotions** | `stg_promotions` | — | `agg_promotion_performance` |
```
