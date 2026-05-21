---
name: scenario-4
description: Use this skill when the user is building a customer segmentation model, identifying VIPs or high-value customers, or creating a targeted campaign audience for Marketing using recent purchase behavior by store. Triggers on natural-language phrases like "build a customer segment for Marketing", "who are our VIPs", "find high-value customers by store", "I need a targeted campaign audience", "segment customers by spend and loyalty", "180-day customer activity by store", "identify category-loyal customers", or "build a big-spender segment". Use this skill specifically for the customers × stores × orders × categories segmentation workflow — not for inventory or shipment problems (scenario-1), support-ticket enrichment on orders (scenario-2), or upstream product-source schema drift (scenario-3).
---

# dbt Wizard — High-Value Customer Segmentation

A seven-step workflow that turns *"which customers should Marketing target?"* into a reusable activity layer plus a segment model, materialized into the user's dev schema. Two-model design on purpose: the activity layer is testable and reusable so downstream work (churn, RFM, dashboards) does not re-derive the same aggregates from scratch.

## How to run this skill

For every step:

1. Present the question for dbt Wizard inside a plain fenced code block — no quoting, no decoration, so the user can triple-click and copy or type it off a printed lab sheet.
2. Always frame the question as *"copy this as written, or rephrase it in your own words"* — give the user the explicit choice between using the canonical version and paraphrasing. Either path is correct; the lab is about the workflow, not the wording.
3. State briefly what dbt Wizard exercises under the hood.
4. After dbt Wizard responds, interpret in one or two lines what the user can now do. Do not restate dbt Wizard's output — name the *insight* the user just earned. Then surface the next question in another plain code block, again with the copy-or-rephrase framing.

Never invite the user to "say next," "paste output here," "ready for the next step," or anything similar. They advance by typing each business question themselves. Run the steps in order; do not skip ahead.

### Continuation behavior

The first prompt starts the Marketing customer-segmentation story for the current chat session. After that, do not make the user restate the campaign audience goal. Treat short follow-up prompts about customers, stores, orders, order lines, products, categories, 180-day activity, VIPs, big spenders, category-loyal customers, segment preview, or materialization as continuation of this workflow unless the user clearly changes tasks.

The copyable prompts are intentionally concise and should stay natural. If a brand-new independent session starts in the middle with no prior Step 1 context, have the user restart at Step 1 or provide a one-sentence resume cue such as "I'm building the Marketing customer segment at the activity-model step."

If dbt Wizard is not yet configured, send the user to `lab_reference/dbt_wizard_setup.md` before Step 1.

---

## Step 1 — Discovery

Ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Marketing needs a targeted customer segment based on recent purchase behavior by store. Find the models related to customers, stores, orders, order lines, products, and categories.
```

Exercises `status` and `search`. Six entity types — wider than the other scenarios — which is exactly why discovery has to happen before any SQL.

When the response comes back, confirm all six domains surfaced. Two are commonly missed: a dedicated **categories** model (sometimes category lives only as a column on products) and a separate **order lines** model (sometimes folded into orders). Name either before moving on — the downstream logic depends on it. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Show the grain and joins for those models.
```

---

## Step 2 — Schema Understanding

Exercises `describe` and `lineage`. Check three things when the response returns:

- Where **category** actually lives — product level, order-line level, or order header. Category-loyal logic in Step 5 lives or dies on this.
- The grain of orders versus order lines — this defines the transaction-count denominator.
- Whether **store** is on the order, on the customer, or on both — per-store segmentation requires store on the transaction, not just on the customer.

These are the joins teams quietly get wrong and then spend a week debugging. Name any blocker now, before writing the activity layer. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Check recent order dates and category values needed for a 180-day segmentation model.
```

---

## Step 3 — Data Inspection

Exercises `warehouse` and `dbt_show` on the rolling-window anchor and the distinct category values. Two silent bugs to watch for:

- A **stale `max(order_date)`** that quietly shrinks the 180-day window. If the most recent order is months old, "trailing 180 days from today" returns far less data than the user expects.
- A **category field with nulls, whitespace, or mixed case** that breaks category-loyal logic later.

If the max order date is more than a few days old, decide with the user whether to anchor the window on `current_date` or on `max(order_date)`. If categories are dirty, decide on exclude-versus-coalesce now. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Create a 180-day customer activity model by store.
```

---

## Step 4 — Activity Layer Model

Exercises file edits and model creation. This is the **reusable intermediate model** — not the segment model yet. Per-customer × store aggregates over the trailing 180 days:

- `transaction_count` — count of orders in the window
- `avg_transaction_value` — mean order value
- `max_transaction_value` — largest single order value
- `category_transaction_count` — per-category transaction counts at customer × store × category grain

Building this as its own model is the design choice that pays back for years. Churn models, RFM models, executive dashboards — all of them can sit on this layer instead of re-deriving the same aggregates in five different places. That is the difference between an analytics-engineering practice and a pile of one-off queries.

When the SQL is generated, verify the 180-day window is applied consistently and that the grain is customer × store (with customer × store × category for the category counts). Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Create a segment model for VIPs, big spenders, and category-loyal customers, built on top of the activity model.
```

---

## Step 5 — Segment Model

Exercises file edits and model creation on top of the activity layer. The three canonical segment definitions for this scenario:

- **VIP** — `avg_transaction_value > $100` AND `transaction_count >= 3`
- **Big spender** — `max_transaction_value > $300` (at least one transaction over $300)
- **Category-loyal** — `category_transaction_count >= 10` for any single category

Customers can belong to multiple segments. The model should tag or union rows so a single customer can appear with multiple `segment_name` values — that is the business definition, not a bug. Expected columns: customer identifier, `store_name`, `segment_name`, `transaction_count`, `avg_transaction_value`, `max_transaction_value`, `category`, `category_transaction_count`.

When the SQL is generated, verify the multi-segment logic and confirm the thresholds match the definitions above. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Compile and preview the segment model. Exclude customers with no segment.
```

---

## Step 6 — Safe Preview

Exercises `dbt_compile` and `dbt_show`. The SQL compiles, sample rows render, nothing lands in the warehouse yet. The "exclude no segment" filter doubles as a data-quality check: if a large share of customers fall out, the thresholds or the date window need a second look *before* Marketing ever sees the list.

When the preview returns:

- Confirm multi-segment customers appear on multiple rows. If they don't, the union or tagging logic is wrong.
- Flag any segment that comes back suspiciously empty (zero VIPs, for example). That is almost always a threshold or join issue, not reality.
- Eyeball whether the audience size is plausible for a Marketing campaign. A list of 11 customers is not a campaign; a list of 1.1 million is not targeted.

Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Materialize the segment model into my dev schema. Skip the verification pass — the preview already confirmed the output.
```

---

## Step 7 — Materialize

Exercises `dbt_run` against the user's dev schema (`dev_lab_user_N`). The "skip the verification pass" instruction is deliberate: the Step 6 preview already validated the output, and re-running a full verification pass burns roughly 10% of a 20-minute lab on duplicate work. The instructor drops dev schemas after the lab via a cleanup script, so this build is safe and reversible.

When the build succeeds, confirm the model landed in the user's dev schema and the row count is consistent with the Step 6 preview. The campaign audience now lives as a queryable, versioned table that Marketing — or a campaign-orchestration tool — can pull from directly.

---

## Wrap-up

In two or three sentences: the user took a Marketing question — *"which customers should we target?"* — and used dbt Wizard to discover six entity types, validate grain and joins, inspect the data for a fresh date anchor, build a reusable activity layer, build a segment model on top of it, safely preview the audience, and materialize the result into their own dev schema. The campaign list now sits on a reusable, testable two-model design — not a screenshot of a query somebody ran once. That is what an analytics-engineering workflow looks like.

---

## References

- `lab_reference/dbt_wizard_setup.md`: lab-level setup reference retained outside the skill bundle.
