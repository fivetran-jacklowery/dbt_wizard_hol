# Scenario 3 Step 0 - Schema Drift Failure Output Template

Use this template whenever Scenario 3 starts with a failed `dbt run` caused by upstream schema drift in `retail.RET_PRODUCTS`.

Populate values from the most recent dbt run output or `target/run_results.json`. Keep the response concise and preserve this structure.

```text
• Run attempted for:

  dbt run --select <selector> --threads <threads>

  Result: failed on <model_name>.

  Error:

  <short warehouse error>
  <compiled file path> line <line_number>

  Impact:

  - <model_name> failed to build.
  - <downstream_count> downstream models were skipped, including:
      - <representative_downstream_model_1>
      - <representative_downstream_model_2>
      - <representative_downstream_model_3>
      - <representative_downstream_model_4>
      - <representative_downstream_model_5>
      - <representative_downstream_model_6>
      - <grouped_description_for_remaining_downstream_models>

  This looks like upstream schema drift: the model is selecting <old_column>, but Snowflake no longer exposes that identifier. If you want, I can inspect RET_PRODUCTS and patch stg_products to the current source column.
```

For the standard lab setup, the populated example is:

```text
• Run attempted for:

  dbt run --select stg_products+ --threads 4

  Result: failed on stg_products.

  Error:

  invalid identifier 'BRAND'
  compiled/models/staging/stg_products.sql line 21

  Impact:

  - stg_products failed to build.
  - 19 downstream models were skipped, including:
      - int_products_enriched
      - int_order_items_enriched
      - dim_products
      - fct_order_items
      - fct_orders
      - agg_product_performance
      - agg_promotion_performance
      - related downstream customer/revenue marts

  This looks like upstream schema drift: the model is selecting brand, but Snowflake no longer exposes that identifier. If you want, I can inspect RET_PRODUCTS and patch stg_products to the current source column.
```
