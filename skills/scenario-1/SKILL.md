---
name: scenario-1
description: Use this skill when the user is investigating inventory shortages, missing shipments, overages, undercounts, or stores that received the wrong stock allocation, and wants dbt Wizard to find where the inventory went. Triggers on natural-language phrasing like "where did our missing inventory go", "which stores got too much of an item", "which stores are short inventory", "find stores above or below expected stock", "find the stores that received excess stock", "investigate a shipment misallocation", "we shipped wrong inventory amounts before a sale", "stores have more or less inventory than they should", "track down a missing shipment", or "some stores received extra inventory and we need to find them". Use for inventory/shipment/store-allocation problems specifically — not for support-ticket enrichment on orders (that is scenario-2), and not for customer segmentation or marketing questions (that is scenario-3).
---

# dbt Wizard — Inventory Misallocation Investigation

A six-step workflow that turns a stakeholder question — *"where did the missing inventory go?"* — into a materialized dbt model naming the stores with inventory counts above or below the expected shipment-plan quantity. No codebase spelunking. No SQL written from a blank file. No guessing at schemas.

## How to run this skill

For the live hands-on lab, tell attendees to copy the canonical question exactly. Rephrasing is supported, but canonical wording keeps model names, result shapes, and support instructions consistent across the room.

If dbt Wizard displays sub-agent names, refer to them by role in your explanation: Summary Agent, Verification Agent, Explorer Agent, or Worker Agent. Do not emphasize the generated nickname.

For every step:

1. Show the user the question to ask dbt Wizard inside a plain fenced code block — no quoting, no decoration, so it can be triple-clicked and copied or read off a printed lab sheet.
2. Always frame the question as *"copy this as written, or rephrase it in your own words"* — but call copy-as-written the recommended path for the timed lab.
3. State briefly what dbt Wizard exercises under the hood.
4. After dbt Wizard responds, interpret in one or two lines what the user can now do. Do not restate dbt Wizard's output — name the *insight* the user just earned. Then surface the next question in another plain code block, again with the copy-or-rephrase framing.

Never tell the user to "say next," "paste your output here," "ready for the next step," or anything similar. They advance by typing each business question themselves. Run the steps in order.

### Continuation behavior

The first prompt starts the inventory misallocation story for the current chat session. After that, do not make the user restate the business scenario. Treat short follow-up prompts about inventory/store/item/shipment grain, expected-versus-actual inventory, variance direction, `inventory_shipment_variance`, deterministic preview, or materialization as continuation of this investigation unless the user clearly changes tasks.

The copyable prompts are intentionally concise and should stay natural. If a brand-new independent session starts in the middle with no prior Step 1 context, have the user restart at Step 1 or provide a one-sentence resume cue such as "I'm investigating inventory misallocation at the variance preview step."

---

## Step 1 — Discovery

Ask dbt Wizard — copy this as written (recommended), or rephrase it in your own words:

```
Operations thinks inventory was misallocated across stores before a sale. Find the models in this project related to inventory, stores, items, and shipments.
```

Exercises `status` and `search`. We start from the business problem, not the file tree. The user does not need to know schema names or directory layout in advance — that is the entire point.

When dbt Wizard returns its list, confirm in one line that the inventory, store, item, and shipment models all surfaced. If one is missing, name it now — every downstream step depends on this. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
For those models, show the grain, key columns, and how they join together.
```

---

## Step 2 — Schema Understanding

Exercises `describe` and `lineage`. This is where you decide *before* writing SQL whether the data can answer the question at all. Grain mismatches and missing join keys are the silent killers of analytics work — catch them here, not three hours into a query you have to throw away.

When the grain and joins come back, note in one line whether the shipments → stores → items path is clean and what the inventory grain is. Then ask dbt Wizard — copy this as written, or rephrase it in your own words. The item and expected quantity should come from the user's prompt for this lab:

```
Check [specific item] shipments and inventory. Expected quantity is [N] per store. Show the per-store expected quantity, actual inventory, variance quantity, and variance direction, ordered by absolute variance desc, warehouse_id.
```

---

## Step 3 — Data Inspection

Exercises `warehouse` and `dbt_show` on a targeted slice — no full scans, no materialization. The user sees real rows for one item across the affected stores and reads the expected per-store quantity directly off the data, not off a slide.

When the per-store breakdown returns, name the stores that are over-counted and the stores that are under-counted against the expected quantity. Capture those store identifiers — Step 5 will check that they appear in the preview. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Create a dbt model named inventory_shipment_variance that lists every store where actual inventory for that item differs from the expected per-store quantity. Include store name, city or region, item name, actual inventory count, expected count, variance quantity, and a variance direction showing over-count or under-count.
```

---

## Step 4 — Model Creation

Exercises file edits and model generation. dbt Wizard writes the `inventory_shipment_variance.sql` model into the project — versioned, reviewable, testable. This is the difference between an answer and an asset.

When the model is generated, confirm in one line that the model is named `inventory_shipment_variance`, the column list matches the request, and the filter captures both over-counts and under-counts using the expected quantity from Step 3. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Compile the model and preview the first 20 rows using deterministic ordering. Order inventory variances by abs(variance_quantity) desc, warehouse_id, product_id.
```

---

## Step 5 — Safe Preview

Exercises `dbt_compile` and `dbt_show`. The SQL compiles, the first 20 rows render in a deterministic order, nothing lands in the warehouse yet.

When the preview renders, confirm:

- The over-counted and under-counted stores identified in Step 3 appear in the preview.
- The expected columns are present: store name, city/region, item name, actual count, expected count, variance quantity, variance direction.
- Row count is non-zero.
- The output is ordered deterministically.

If the preview does not match the expected row count, expected columns, or the example stores from Step 3, stop and diagnose before materializing. Do not move on. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Before materializing, confirm the active dbt target, the dev schema, and permission to create the model. Then materialize inventory_shipment_variance into my dev schema as a table. For this timed lab, skip extended verification after the successful compile and deterministic preview. Materialize only after the expected rows appear.
```

---

## Step 6 — Materialize

Exercises `dbt_run` against the user's dev schema (`dev_lab_user_N`). The instructor drops dev schemas after the lab via a cleanup script, so this build is safe and disposable.

The "skip extended verification" instruction is deliberate and scoped to this timed lab only — it is not a recommendation for production work. Step 5's deterministic preview already proved correctness; a full verification pass on top of that burns roughly 10% of the lab's budget on duplicate work.

When the build succeeds, close with one line: the user took a stakeholder question and produced a queryable table — `inventory_shipment_variance` — of misallocated stores, including both over-counts and under-counts. Discovery, schema validation, targeted inspection, model creation, deterministic preview, build — without writing SQL by hand. That table is now an asset Operations can call against directly. *That* is what dbt Wizard accelerates.

---

## Final artifact

- Model: `inventory_shipment_variance` — one row per misallocated store/item where actual inventory differs from expected, in the participant's dev schema
