---
name: scenario-2
description: Use this skill when the user wants to extend the existing `int_orders_enriched` dbt model with customer support ticket context from `retail.RET_TICKETS`, and wants dbt Wizard to guide the safe modification end-to-end. Triggers on natural-language phrasing like "add support tickets to orders", "extend orders with ticket counts", "show which orders have support tickets", "wire tickets into int_orders_enriched", "add a new source to an existing model", "modify an existing intermediate model to bring in another source", or "join support ticket data into enriched orders without breaking downstream". Use for the modify-existing-model-with-new-source workflow specifically — not for inventory/shipment problems (scenario-1), customer segmentation from scratch (scenario-3), or upstream schema breakage (scenario-4).
---

# dbt Wizard - Extending Orders with Support Ticket Context

A six-step workflow for the most common real-world analytics-engineering task: an existing intermediate model is missing a domain, and a Fivetran-synced source already in the warehouse can fill the gap. The job is to wire the new source into the existing model **without breaking the downstream consumers that already depend on it**.

The setup: the Director of Operations wants to know which orders generated support burden. The source data already exists in Snowflake as `retail.RET_TICKETS`, and the project already stages it as `stg_tickets`. The missing piece is order-level ticket context in `int_orders_enriched`.

## How to run this skill

This scenario uses this fixed setup:

- **Target model:** `int_orders_enriched`
- **New source:** `retail.RET_TICKETS` / `stg_tickets`
- **Entity grain:** one row per order
- **Join key:** `order_id`
- **New columns:** `ticket_count`, `has_open_ticket_flag`, `last_ticket_status`
- **Stakeholder ask:** *"For every order in the enriched view, can we see how many support tickets were opened against it so we can flag problematic orders for postmortem?"*

For every step:

1. Show the user the question to ask dbt Wizard inside a plain fenced code block, with no quoting or decoration, so it can be copied cleanly or read off a printed lab sheet.
2. Always frame the question as *"copy this as written, or rephrase it in your own words"*. Copy-as-written is recommended for the timed lab.
3. State briefly what dbt Wizard exercises under the hood.
4. After dbt Wizard responds, interpret in one or two lines what the user now knows. Do not restate dbt Wizard's output. Name the *insight*, then surface the next question in another plain code block, again with the copy-or-rephrase framing.

Never tell the user to "say next," "paste your output here," "ready for the next step," or anything similar. They advance by typing each business question themselves. Run the steps in order.

If dbt Wizard is not yet configured, send the user to `references/dbt_wizard_setup.md` before Step 1.

---

## Step 1 - Locate the target model

Ask dbt Wizard - copy this as written (recommended), or rephrase it in your own words:

```
Find int_orders_enriched in this project. Show me what it currently produces, its grain, and which models depend on it downstream.
```

Exercises `search`, `describe`, and `lineage`. We start from the model we're being asked to extend, not from a blank file. Knowing the downstream consumers up front is what separates a safe edit from a Slack thread about a broken dashboard.

When dbt Wizard returns, confirm in one line that `int_orders_enriched` exists, its grain is one row per order, and it has downstream consumers such as `fct_orders`, `fct_order_items`, `int_daily_revenue`, and customer/product rollups. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Find every support-ticket source or model in this project that int_orders_enriched does NOT currently reference. I want to know what ticket data is sitting in our warehouse that is not connected to enriched orders yet.
```

---

## Step 2 - Discover the unused source

Exercises `status`, `search`, and source-vs-model cross-referencing. This is the step that earns the workflow: dbt Wizard surfaces a Fivetran-synced source already configured in the project but not connected to the target model. No need to spelunk through `_staging__sources.yml` or guess what's been added since the last time anyone looked.

When dbt Wizard returns the candidate source, confirm in one line that `retail.RET_TICKETS` exists, is staged as `stg_tickets`, includes `order_id`, and is not currently referenced by `int_orders_enriched`. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Describe stg_tickets. Show me the columns, their types, the grain, and how order_id joins back to int_orders_enriched.
```

---

## Step 3 - Validate the join

Exercises `describe`, `warehouse`, and join-key inspection. This is the step that prevents the most common silent failure of cross-domain joins: a key that looks right by name but doesn't behave right by data.

Three things to verify before any SQL is touched:

- **Grain.** `stg_tickets` is many-rows-per-order because one order can have multiple tickets. Aggregate before the join, or `int_orders_enriched` will fan out and break its one-row-per-order contract.
- **Coverage.** Count how many ticket `order_id` values match orders already in `int_orders_enriched`. Tickets may be nullable on `order_id`, so explicitly filter to order-linked tickets for this check.
- **Join key match.** Confirm both sides use the same numeric `order_id` format.

Tell dbt Wizard to confirm each of these directly:

```
Run a quick check: count rows in stg_tickets with a non-null order_id, count distinct ticket order_ids, and count how many of those order_ids match an order_id in int_orders_enriched. Tell me whether stg_tickets is one-to-one or one-to-many at the order grain.
```

If the grain is many-rows-per-order, aggregate tickets to one row per `order_id` before joining. The required metrics are `ticket_count`, `has_open_ticket_flag`, and `last_ticket_status`.

---

## Step 4 - Modify the existing model

Exercises file edits on the existing model file, not a new file. This is deliberate. The skill being demonstrated is *safe modification of an existing asset*, not *another bolt-on intermediate model*.

Ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Update int_orders_enriched to add ticket_count, has_open_ticket_flag, and last_ticket_status from stg_tickets. Aggregate stg_tickets to one row per order_id before joining, use a LEFT JOIN so orders without tickets still appear, and preserve every column int_orders_enriched currently emits — only add the new columns at the end.
```

The two non-negotiables in this step:

- **Left join, not inner.** Inner-joining quietly drops every order without a support ticket.
- **Preserve existing columns.** Downstream consumers select specific columns. Reordering them is fine; renaming or removing them is a contract break.

When dbt Wizard's edit returns, the user spot-checks the diff to confirm: the existing column list is intact, the new columns are appended at the end, the join is a `LEFT JOIN`, and the ticket aggregation happens in a CTE before the join. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Compile int_orders_enriched and every downstream model that depends on it. Then preview 20 rows of int_orders_enriched ordered deterministically by order_id. Do not materialize anything.
```

---

## Step 5 - Compile downstream + safe preview

Exercises `dbt_compile` across the lineage and `dbt_show` on the target. Compiling **the downstream models too** is the compile-time guarantee that we haven't broken any consumer that depends on a column that no longer exists or has changed type. The cost is small; the catch rate is high.

When the previews render, confirm:

- The 20-row preview of `int_orders_enriched` shows `ticket_count`, `has_open_ticket_flag`, and `last_ticket_status`.
- Orders without tickets still appear, with `ticket_count = 0` or null-safe equivalent behavior approved by dbt Wizard.
- The total row count of `int_orders_enriched` is unchanged from before the edit. If it grew, the ticket aggregation was wrong and Step 4 needs a re-edit.
- Every downstream model compiled without error.

If any of these fail, stop and diagnose with dbt Wizard before materializing. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Materialize int_orders_enriched into my dev schema. Skip the verification pass — the preview and downstream compile already confirmed the output.
```

---

## Step 6 - Materialize

Exercises `dbt_run` against the user's dev schema. The "skip the verification pass" instruction is deliberate and scoped to this timed lab. Step 5 already validated the output and downstream compile, so a separate verification run burns roughly 10% of the lab's budget on duplicate work. The instructor drops dev schemas after the lab via a cleanup script, so this build is safe and disposable.

When the build succeeds, confirm `int_orders_enriched` landed in the user's dev schema with `ticket_count`, `has_open_ticket_flag`, and `last_ticket_status` populated and the row count unchanged from the pre-edit baseline.

---

## Wrap-up

The user started with an operations ask that `int_orders_enriched` could not answer, used dbt Wizard to find ticket data already in the warehouse, validated the order-level join's grain and coverage before writing SQL, modified the existing model with a left-joined aggregation, and confirmed the downstream lineage still compiles. All in minutes.

Done by hand, the everyday extend-an-existing-model task takes half a day of grepping plus a deferred Slack thread when a downstream dashboard breaks. dbt Wizard collapses it into a guided workflow that keeps the engineer focused on the change itself instead of the surrounding archaeology.

---

## Final artifact

- `int_orders_enriched` now emits `ticket_count`, `has_open_ticket_flag`, and `last_ticket_status` from `stg_tickets` in the user's dev schema. Existing column contract is preserved, downstream models still compile, and row count is unchanged.

---

## References

- `references/dbt_wizard_setup.md`: install, run, config, and auth requirements for dbt Wizard.
