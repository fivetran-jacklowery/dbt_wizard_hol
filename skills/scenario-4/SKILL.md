---
name: scenario-4
description: Use this skill when the user is investigating a broken dbt model caused by an upstream source schema change — specifically a column rename in a Fivetran-synced source — and wants dbt Wizard to help diagnose and fix it. Triggers on natural-language phrasing like "my dbt run is failing", "this model used to work and now doesn't", "the source changed and broke my model", "column not found error after a Fivetran sync", "help me figure out which column was renamed", "fix the broken staging model", "a column was renamed upstream and I need to find every reference", "dbt run errored after the source schema changed", or "the upstream column name changed, help me update the model". Use for upstream-source-schema-drift failures specifically — not for inventory or shipment problems (scenario-1), product quality (scenario-2), or customer segmentation (scenario-3). The HOL attendee picks one of three column renames to investigate (products.brand, orders.order_status, customers.customer_type).
---

# dbt Wizard - Broken Model from a Source Column Rename

A five-step workflow that turns a red `dbt run` ("Column 'X' does not exist in source") into a fixed, re-running pipeline. No grep-and-pray across the project, no manual `DESC TABLE` against the warehouse, no guessing which downstream models also break.

The setup: a Fivetran-synced retail source column was renamed upstream overnight. Your `dbt run` is broken. You need to find what changed, find every place the old name was referenced, fix them, and re-run, all before the morning standup.

## How to run this skill

This scenario is **choose-your-path**. At the start, the attendee picks one of three renames to investigate:

- **Path A - Products:** `retail.RET_PRODUCTS.brand` was renamed to `brand_name`. Breaks `stg_products` and roughly 8 downstream files: 4 intermediates (`int_inventory_status`, `int_order_items_enriched`, `int_product_sales_summary`, `int_products_enriched`) and 4 marts (`dim_products`, `fct_inventory_transactions`, `fct_order_items`, `agg_product_performance`).
- **Path B - Orders:** `retail.RET_ORDERS.status` was renamed to `order_status`. Wide blast radius: breaks `stg_orders`, the YAML column tests in `_staging__models.yml`, and roughly 7 downstream files including `int_orders_enriched`, `int_daily_revenue`, `int_customer_order_summary`, and `fct_orders`. Note: the staging model already aliases `status as order_status`, so the fix is mechanical but the blast radius makes the demo land.
- **Path C - Customers:** `retail.RET_CUSTOMERS.customer_type` was renamed to `segment`. Compact blast radius: breaks `stg_customers`, the YAML column tests in `_staging__models.yml`, and 5 downstream files (`int_customer_cohorts`, `dim_customers`, `customer_lifetime_value`, `fct_tickets`, `agg_customer_cohorts`).

Confirm the user's choice in one line before Step 1. The questions below reference `[OLD_COLUMN]`, `[NEW_COLUMN]`, and `[BROKEN_MODEL]`. Substitute the values for the path the user picked. Wording is otherwise the same across paths so the instructor can run a room with attendees on different paths simultaneously.

For every step:

1. Show the user the question to ask dbt Wizard inside a plain fenced code block, with no quoting or decoration, so it can be copied cleanly or read off a printed lab sheet.
2. Always frame the question as *"copy this as written, or rephrase it in your own words"*. Copy-as-written is recommended for the timed lab.
3. State briefly what dbt Wizard exercises under the hood.
4. After dbt Wizard responds, interpret in one or two lines what the user now knows. Do not restate dbt Wizard's output. Name the *insight*, then surface the next question in another plain code block, again with the copy-or-rephrase framing.

Never tell the user to "say next," "paste your output here," "ready for the next step," or anything similar. They advance by typing each business question themselves. Run the steps in order.

If dbt Wizard is not yet configured, send the user to `references/dbt_wizard_setup.md` before Step 1.

---

## Pre-step - Reproduce the failure

The lab environment was set up with the rename already applied to the source table, so the first thing the user does is run dbt and watch it fail. This grounds the rest of the workflow in a real error message, not a hypothetical.

Tell the user to run, from the project root:

```
dbt run --select [BROKEN_MODEL]+
```

They will see a compile or runtime error referencing `[OLD_COLUMN]`. Capture the exact error text. Step 1 uses it.

---

## Step 1 - Explain the failure

Ask dbt Wizard - copy this as written (recommended), or rephrase it in your own words:

```
My dbt run just failed. Read the most recent run results and tell me which model failed, what the error was, and which upstream source or column the error references.
```

Exercises `status`, `dbt_show` against `run-results`, and error parsing. We start from the failure, not from a hunch. No need to scroll through stack traces in the terminal. dbt Wizard surfaces the model name, the failing column, and the source it traces back to.

When dbt Wizard returns its summary, confirm in one line that the failing model is `[BROKEN_MODEL]` and the missing column is `[OLD_COLUMN]` on the `retail` source. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Describe the current schema of the upstream source table that [BROKEN_MODEL] reads from. List every column that exists today.
```

---

## Step 2 - Compare model code against current source schema

Exercises `describe` and `warehouse`. dbt Wizard pulls the live column list from Snowflake, the source-of-truth, and lays it next to what the model is asking for. This is the step that converts "something changed upstream" into "this specific column was renamed."

When the current schema comes back, the user reads it and spots that `[OLD_COLUMN]` is gone and `[NEW_COLUMN]` is new. Confirm with the user in one line: the rename is `[OLD_COLUMN]` to `[NEW_COLUMN]`. Do not let the user move on until they've named both columns out loud. Guessing the new column name from context is the #1 way this fix goes sideways.

Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Show me every model, source definition, and test in this project that references the column [OLD_COLUMN]. I need a complete blast-radius list before I change anything.
```

---

## Step 3 - Blast-radius check

Exercises `search` plus `lineage`. This is the step that prevents the "I fixed it but it's still broken" loop. dbt Wizard returns every file that references the old name: staging SQL, intermediate SQL, mart SQL, the column tests defined in `_staging__models.yml`, and any other YAML descriptions.

When the list comes back, the user reads it and confirms the count matches their expectation for the path they picked:

- **Path A (brand to brand_name):** `stg_products.sql` plus 8 downstream files, 4 intermediates and 4 marts. If only 2-3 files come back, dbt Wizard missed the marts; push back.
- **Path B (status to order_status):** `stg_orders.sql`, the column-test entry in `_staging__models.yml`, and ~7 downstream files including `int_orders_enriched`, `int_daily_revenue`, `int_customer_order_summary`, and `fct_orders`. Wide list, which is the point of picking this path.
- **Path C (customer_type to segment):** `stg_customers.sql`, the column-test entry in `_staging__models.yml`, and 5 downstream files (1 intermediate + 4 marts). Compact list.

If the count is suspiciously low (e.g., only the staging model surfaces), tell the user to ask dbt Wizard one follow-up: *"Are you searching tests and YAML files too? Make sure `_staging__models.yml` is in the result."* Column-test definitions in `_staging__models.yml` are where this scenario most commonly catches an incomplete fix: schema tests against the old column name silently keep passing the compile step but fail the test step. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Update [BROKEN_MODEL] and every other file you just listed to use [NEW_COLUMN] instead of [OLD_COLUMN]. Keep the downstream column alias the same so consumers of these models don't break — only the source-side reference should change.
```

---

## Step 4 - Apply the fix, preserve the contract

Exercises file edits across multiple files. The critical instruction here is the **alias preservation**: we change the source-side reference to `[NEW_COLUMN]` but keep the public column name (`brand`, `order_status`, `customer_type`) so every downstream model and dashboard keeps working without further changes.

A staging model selecting `brand` becomes `select brand_name as brand`, not `select brand_name`. dbt Wizard should write the edit this way by default; if it doesn't, the user pushes back with: *"Re-alias to the original name so downstream models don't have to change."*

When the edits return, the user spot-checks the staging file (the one that touches the source directly) and confirms the alias is in place. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Compile [BROKEN_MODEL] and every downstream model you just edited, then preview the first 10 rows of [BROKEN_MODEL] ordered deterministically. Do not materialize anything yet.
```

---

## Step 5 - Compile, preview, and re-run

Exercises `dbt_compile` and `dbt_show`. The compile is the smoke test. If any file still references `[OLD_COLUMN]`, the compile fails here, not in the warehouse. The preview confirms the renamed column is flowing through correctly under its original public name.

When the preview renders, confirm:

- The preview returns rows (non-zero).
- The output still has a column named `[OLD_COLUMN]` (the alias survived) with sane-looking values.
- No compile errors anywhere in the lineage.

Then tell the user to run the actual re-build from the terminal:

```
dbt run --select [BROKEN_MODEL]+
```

This is the "did we really fix it?" moment. A green run here closes the loop on the original failure from the pre-step.

---

## Wrap-up

The user started the lab with a failed `dbt run` and a Fivetran source that had silently changed shape overnight. They used dbt Wizard to read the error, diff the live source schema against the model code, map the full blast radius, apply an alias-preserving fix across every affected file, and re-run to green, without grepping the project by hand or breaking a single downstream model.

That's the everyday analytics-engineering problem dbt Wizard exists to solve: upstream-source drift caught and fixed in minutes, not in a Slack thread that lasts the rest of the day.

---

## Final artifact

- The previously broken model (`stg_products`, `stg_orders`, or `stg_customers` depending on path) now compiles, runs, and emits the renamed source column under its original public name. Every downstream model in the project still resolves without further changes.

---

## References

- `references/dbt_wizard_setup.md`: install, run, config, and auth requirements for dbt Wizard.
- `references/instructor_setup.md`: how the instructor applies the source column rename in Snowflake before the lab.
