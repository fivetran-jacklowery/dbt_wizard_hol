---
name: scenario-2
description: Use this skill when the user wants to extend an existing dbt model by adding a new source that the model does not currently reference, and wants dbt Wizard to guide the safe modification end-to-end. Triggers on natural-language phrasing like "add a new source to an existing model", "extend a model with another table", "this Fivetran source isn't being used yet and I need it in the customer model", "wire support tickets into the customer summary", "add promotions to enriched orders", "add product reviews to product performance", "modify an existing intermediate model to bring in another source", "join a new source into an existing model without breaking downstream", or "extend an existing model to include another domain". Use for the modify-existing-model-with-new-source workflow specifically — not for inventory/shipment problems (scenario-1), customer segmentation from scratch (scenario-3), or upstream schema breakage (scenario-4). The HOL attendee picks one of three extension paths.
---

# dbt Wizard — Extending an Existing Model with a New Source

A six-step workflow for the most common real-world analytics-engineering task: an existing intermediate model is missing a domain, and a Fivetran-synced source already in the warehouse can fill the gap. The job is to wire the new source into the existing model **without breaking the downstream consumers that already depend on it**.

The setup: a stakeholder has a follow-up question that the current model can't answer. The data they need is already arriving in Snowflake via Fivetran — it just isn't connected to the model they're staring at.

## How to run this skill

This scenario is **choose-your-path**. At the start, the attendee picks one of three extensions to perform:

- **Path A — Customer 360 + Support Tickets.** Stakeholder: VP of Customer Success. Ask: *"When we segment customers for renewal outreach, can we deprioritize customers with open complaints?"* Target model: `int_customer_order_summary`. New source: `retail.RET_TICKETS`. Add: `open_tickets_count`, `last_ticket_status`, `last_ticket_opened_at` per customer.

- **Path B — Orders + Customer Support Tickets.** Stakeholder: Director of Operations. Ask: *"For every order in the enriched view, can we see how many support tickets were opened against it so we can flag problematic orders for postmortem?"* Target model: `int_orders_enriched`. New source: `retail.RET_TICKETS` (joined at the order grain — note this is the same source Path A uses at the customer grain; that's the point, the source is "new to this model" not new to the project). Add: `ticket_count`, `has_open_ticket_flag`, `last_ticket_status` per order.

- **Path C — Product Performance + Reviews.** Stakeholder: Head of Merchandising. Ask: *"In product performance, can we surface average customer rating and review volume so we can see which top sellers are also well-rated?"* Target model: `int_product_sales_summary`. New source: `retail.RET_PRODUCT_REVIEWS`. Add: `avg_rating`, `review_count`, `low_rating_count` (1–2 stars) per product.

Confirm the user's choice in one line before Step 1. The questions below reference `[TARGET_MODEL]`, `[NEW_SOURCE]`, `[ENTITY]`, and `[NEW_COLUMNS]` — substitute the values for the path the user picked. Wording is otherwise consistent across paths so the instructor can run a room with attendees on different paths simultaneously.

For every step:

1. Show the user the question to ask dbt Wizard inside a plain fenced code block — no quoting, no decoration, so it can be triple-clicked and copied or read off a printed lab sheet.
2. Always frame the question as *"copy this as written, or rephrase it in your own words"* — copy-as-written is recommended for the timed lab.
3. State briefly what dbt Wizard exercises under the hood.
4. After dbt Wizard responds, interpret in one or two lines what the user now knows. Do not restate dbt Wizard's output — name the *insight*. Then surface the next question in another plain code block, again with the copy-or-rephrase framing.

Never tell the user to "say next," "paste your output here," "ready for the next step," or anything similar. They advance by typing each business question themselves. Run the steps in order.

If dbt Wizard is not yet configured, send the user to `references/dbt_wizard_setup.md` before Step 1.

---

## Step 1 — Locate the target model

Ask dbt Wizard — copy this as written (recommended), or rephrase it in your own words:

```
Find [TARGET_MODEL] in this project. Show me what it currently produces, its grain, and which models depend on it downstream.
```

Exercises `search`, `describe`, and `lineage`. We start from the model we're being asked to extend, not from a blank file. Knowing the downstream consumers up front is the difference between a safe edit and a Slack thread about a broken dashboard.

When dbt Wizard returns, confirm in one line that the model exists, its grain (one row per [ENTITY]), and at least one downstream consumer that will inherit any changes you make. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Find every source in this project related to [ENTITY] that [TARGET_MODEL] does NOT currently reference. I want to know what data is sitting in our warehouse that we're not using yet.
```

---

## Step 2 — Discover the unused source

Exercises `status`, `search`, and source-vs-model cross-referencing. This is the step that earns the workflow — dbt Wizard surfaces a Fivetran-synced source that's already configured in the project but isn't connected to the target model. The user does not need to spelunk through `_staging__sources.yml` or guess what's been added since the last time they looked.

When dbt Wizard returns the candidate source, confirm in one line that `[NEW_SOURCE]` is the one — it exists in the warehouse, it's defined as a source, and the target model does not currently reference it. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Describe the schema of [NEW_SOURCE]. Show me the columns, their types, the grain, and which column joins back to [ENTITY].
```

---

## Step 3 — Validate the join

Exercises `describe`, `warehouse`, and join-key inspection. This is the step that prevents the most common silent failure of cross-domain joins: a key that looks right by name but doesn't behave right by data.

Three things to verify before any SQL is touched:

- **Grain.** Is the new source one-row-per-`[ENTITY]`, or many-rows-per-`[ENTITY]`? If it's many, an aggregation belongs in the new model before the join, not after — otherwise you fan out the target model and silently double-count downstream metrics.
- **Coverage.** How many rows in the new source match an `[ENTITY]` that already exists in the target model? If coverage is low, the new columns will be mostly null and the stakeholder will ask why.
- **Join key match.** Are the data types and value formats identical (e.g., both numeric IDs, no leading zeros, no case differences in string keys)?

Tell dbt Wizard to confirm each of these directly:

```
Run a quick check: count rows in [NEW_SOURCE], count distinct join keys, and count how many of those keys match an [ENTITY] already in [TARGET_MODEL]. Tell me whether the grain is one-to-one or one-to-many.
```

If the grain is many-rows-per-`[ENTITY]`, the user must decide with dbt Wizard's help whether to aggregate (most common — open tickets count, review count) or pick the latest row by timestamp (e.g., last ticket status). Name the aggregation choice out loud before Step 4 — this is the design decision that defines the new columns.

---

## Step 4 — Modify the existing model

Exercises file edits on the existing model file, not a new file. This is deliberate. The skill being demonstrated is *safe modification of an existing asset*, not *another bolt-on intermediate model*.

Ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Update [TARGET_MODEL] to add [NEW_COLUMNS] from [NEW_SOURCE]. Use a LEFT JOIN so [ENTITY] rows without a match still appear, and aggregate [NEW_SOURCE] to one-row-per-[ENTITY] before joining if its grain is many-to-one. Preserve every column the model currently emits — only add new columns at the end.
```

The two non-negotiables in this step:

- **Left join, not inner.** Inner-joining quietly drops every `[ENTITY]` without a matching row in the new source. That alone has broken more downstream models than any other single mistake in this category of work.
- **Preserve existing columns.** Downstream consumers select specific columns. Reordering them is fine; renaming or removing them is a contract break.

When dbt Wizard's edit returns, the user spot-checks the diff to confirm: the existing column list is intact, the new columns are appended at the end, the join is a `LEFT JOIN`, and any required aggregation happens in a CTE before the join. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Compile [TARGET_MODEL] and every downstream model that depends on it. Then preview 20 rows of [TARGET_MODEL] ordered deterministically. Do not materialize anything.
```

---

## Step 5 — Compile downstream + safe preview

Exercises `dbt_compile` across the lineage and `dbt_show` on the target. Compiling **the downstream models too** is the compile-time guarantee that we haven't broken any consumer that depends on a column that no longer exists or has changed type. The cost is small; the catch rate is high.

When the previews render, confirm:

- The 20-row preview of `[TARGET_MODEL]` shows the new columns populated for `[ENTITY]` rows that have matching data in `[NEW_SOURCE]`, and null (not error) for `[ENTITY]` rows that don't.
- The total row count of `[TARGET_MODEL]` is unchanged from before the edit. If it grew, the join fan-out check from Step 3 was wrong and Step 4 needs a re-edit.
- Every downstream model compiled without error.

If any of these three fail, stop and diagnose with dbt Wizard before materializing. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Materialize [TARGET_MODEL] into my dev schema. Skip the verification pass — the preview and downstream compile already confirmed the output.
```

---

## Step 6 — Materialize

Exercises `dbt_run` against the user's dev schema. The "skip the verification pass" instruction is deliberate and scoped to this timed lab — Step 5 already validated the output and downstream compile, so a separate verification run burns roughly 10% of the lab's budget on duplicate work. The instructor drops dev schemas after the lab via a cleanup script, so this build is safe and disposable.

When the build succeeds, confirm `[TARGET_MODEL]` landed in the user's dev schema with the new columns populated and the row count unchanged from the pre-edit baseline.

---

## Wrap-up

In two or three sentences: the user started with a stakeholder ask that the current model could not answer, used dbt Wizard to find an unused Fivetran-synced source already in the warehouse, validated the join's grain and coverage before writing any SQL, modified the existing model with an alias-safe, left-joined extension, and confirmed the entire downstream lineage still compiles — all in minutes.

That is the everyday extend-an-existing-model task that, done by hand, takes half a day of grepping plus a deferred Slack thread when a downstream dashboard breaks. dbt Wizard collapses it into a guided workflow that does not require the engineer to hold the whole project in their head.

---

## Final artifact

- `[TARGET_MODEL]` now emits `[NEW_COLUMNS]` from `[NEW_SOURCE]` in the user's dev schema. Existing column contract is preserved, downstream models still compile, row count is unchanged.

---

## References

- `references/dbt_wizard_setup.md` — install, run, config, and auth requirements for dbt Wizard.
