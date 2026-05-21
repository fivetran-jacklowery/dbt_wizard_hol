---
name: scenario-3
description: Use for upstream product-source schema drift in the dbt Wizard HOL, especially `retail.RET_PRODUCTS.brand` renamed to `brand_name` breaking `stg_products` and downstream product models. Trigger on failed dbt runs, missing product columns, brand column not found, Fivetran/source schema changes, or requests to diagnose/fix `stg_products`. For failed-run summaries, use `references/schema_drift_step0_failure_output_template.md`. Not for inventory allocation, ticket/order enrichment, or customer segmentation.
---

# dbt Wizard - Broken Product Model from a Source Column Rename

A five-step workflow that turns a red `dbt run` (`Column 'BRAND' does not exist in source`) into a fixed, re-running pipeline. No grep-and-pray across the project, no manual `DESC TABLE` against the warehouse, no guessing which downstream models also break.

The setup: the Fivetran-synced `retail.RET_PRODUCTS` source column `brand` was renamed upstream to `brand_name` overnight. `stg_products` still selects `brand`, so the product lineage is broken. You need to find what changed, find every place the old name was referenced, fix the staging contract, and re-run before the morning standup.

## How to run this skill

This scenario uses this fixed setup:

- **Broken model:** `stg_products`
- **Upstream source:** `retail.RET_PRODUCTS`
- **Old source column:** `brand`
- **New source column:** `brand_name`
- **Public dbt column contract to preserve:** `brand`
- **Expected blast radius:** `stg_products.sql` plus product downstream models including `int_inventory_status`, `int_order_items_enriched`, `int_product_sales_summary`, `int_products_enriched`, `dim_products`, `fct_inventory_transactions`, `fct_order_items`, and `agg_product_performance`.

For every step:

1. Show the user the question to ask dbt Wizard inside a plain fenced code block, with no quoting or decoration, so it can be copied cleanly or read off a printed lab sheet.
2. Always frame the question as *"copy this as written, or rephrase it in your own words"*. Copy-as-written is recommended for the timed lab.
3. State briefly what dbt Wizard exercises under the hood.
4. After dbt Wizard responds, interpret in one or two lines what the user now knows. Do not restate dbt Wizard's output. Name the *insight*, then surface the next question in another plain code block, again with the copy-or-rephrase framing.

Never tell the user to "say next," "paste your output here," "ready for the next step," or anything similar. They advance by typing each business question themselves. Run the steps in order.

If dbt Wizard is not yet configured, send the user to `references/dbt_wizard_setup.md` before Step 1.

---

## Pre-step - Reproduce the failure

The lab environment was set up with the product column rename already applied to the source table, so the first thing the user does is run dbt and watch it fail. This grounds the rest of the workflow in a real error message, not a hypothetical.

Tell the user to run, from the project root:

```
dbt run --select stg_products+
```

They will see a compile or runtime error referencing `brand`. Capture the exact error text. Step 1 uses it.

When summarizing the failed run for the user, use `references/schema_drift_step0_failure_output_template.md`. Populate it from the latest terminal output or `target/run_results.json`. Keep the format stable: attempted command, failed model, short error, compiled file line, downstream impact, and schema-drift interpretation.

---

## Step 1 - Explain the failure

Ask dbt Wizard - copy this as written (recommended), or rephrase it in your own words:

```
My dbt run just failed. Read the most recent run results and tell me which model failed, what the error was, and which upstream source or column the error references.
```

Exercises `status`, `dbt_show` against `run-results`, and error parsing. We start from the failure, not from a hunch. No need to scroll through stack traces in the terminal. dbt Wizard surfaces the model name, the failing column, and the source it traces back to.

When dbt Wizard returns its summary, confirm in one line that the failing model is `stg_products` and the missing column is `brand` on the `retail.RET_PRODUCTS` source. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Describe the current schema of retail.RET_PRODUCTS. List every column that exists today.
```

---

## Step 2 - Compare model code against current source schema

Exercises `describe` and `warehouse`. dbt Wizard pulls the live column list from Snowflake, the source-of-truth, and lays it next to what the model is asking for. This is the step that converts "something changed upstream" into "this specific column was renamed."

When the current schema comes back, the user reads it and spots that `brand` is gone and `brand_name` is new. Confirm with the user in one line: the rename is `brand` to `brand_name`. Do not let the user move on until they've named both columns out loud. Guessing the new column name from context is the #1 way this fix goes sideways.

Then ask dbt Wizard - copy this as written, or rephrase it in your own words. Use `references/blast_radius_prompt_template.md` for the reusable grouped-output template behind this prompt:

```
Show me every model, source definition, test, and YAML file in this project that references the product column brand. I need a complete blast-radius list before changing anything.

Please list the results grouped as:
1. Broken source-side references
2. Source definitions or YAML documentation
3. Downstream models using the public dbt contract column
4. Tests that directly reference the column
5. Any other relevant files

For each result, include the file path, line number if available, and why it matters. Also tell me which references need to change versus which downstream references should stay unchanged because the staging model should preserve the public column name.
```

---

## Step 3 - Blast-radius check

Exercises `search` plus `lineage`. This is the step that prevents the "I fixed it but it's still broken" loop. dbt Wizard returns every file that references the old name, grouped by fix-required source references, YAML/docs, downstream public-contract references, direct tests, and any other relevant files. For the reusable grouped prompt, read `references/blast_radius_prompt_template.md`.

When the list comes back, the user reads it and confirms the count matches the expected product blast radius: `stg_products.sql` plus 8 downstream files — 4 intermediates (`int_inventory_status`, `int_order_items_enriched`, `int_product_sales_summary`, `int_products_enriched`) and 4 marts (`dim_products`, `fct_inventory_transactions`, `fct_order_items`, `agg_product_performance`). If only 2-3 files come back, dbt Wizard missed the marts; push back.

If the count is suspiciously low, tell the user to ask dbt Wizard one follow-up: *"Are you searching tests and YAML files too? Make sure source/model YAML files are included in the result."* Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Update stg_products to read brand_name from retail.RET_PRODUCTS but keep the public column name as brand. Preserve the downstream contract so models that already select brand do not need to change.
```

---

## Step 4 - Apply the fix, preserve the contract

Exercises the alias-preserving staging fix. The critical instruction here is **contract preservation**: change the source-side reference to `brand_name` but keep the public dbt column name `brand` so every downstream model and dashboard keeps working without further changes.

The staging model should change from selecting `brand` to selecting `brand_name as brand`, not `brand_name`. dbt Wizard should write the edit this way by default; if it doesn't, the user pushes back with: *"Re-alias to the original name so downstream models don't have to change."*

When the edit returns, the user spot-checks `models/staging/stg_products.sql` and confirms the alias is in place. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Compile stg_products and every downstream product model, then preview the first 10 rows of stg_products ordered deterministically by product_id. Do not materialize anything yet.
```

---

## Step 5 - Compile, preview, and re-run

Exercises `dbt_compile` and `dbt_show`. The compile is the smoke test. If any file still references the missing source-side column incorrectly, the compile fails here, not in the warehouse. The preview confirms the renamed column is flowing through correctly under its original public name.

When the preview renders, confirm:

- The preview returns rows (non-zero).
- The output still has a column named `brand` (the alias survived) with sane-looking values.
- No compile errors anywhere in the product lineage.

Then tell the user to run the actual re-build from the terminal:

```
dbt run --select stg_products+
```

This is the "did we really fix it?" moment. A green run here closes the loop on the original failure from the pre-step.

---

## Wrap-up

The user started the lab with a failed `dbt run` and a Fivetran product source that had silently changed shape overnight. They used dbt Wizard to read the error, diff the live source schema against the model code, map the full product blast radius, apply an alias-preserving fix, and re-run to green, without grepping the project by hand or breaking a single downstream model.

That's the everyday analytics-engineering problem dbt Wizard exists to solve: upstream-source drift caught and fixed in minutes, not in a Slack thread that lasts the rest of the day.

---

## Final artifact

- `stg_products` now compiles, runs, and emits the renamed source column `brand_name` under its original public name `brand`. Every downstream product model in the project still resolves without further changes.

---

## References

- `references/dbt_wizard_setup.md`: install, run, config, and auth requirements for dbt Wizard.
- `references/instructor_setup.md`: how the instructor applies the `brand` to `brand_name` source column rename in Snowflake before the lab.
