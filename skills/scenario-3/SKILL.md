---
name: scenario-3
description: Use this skill whenever a user wants to build customer segmentation models, identify high-value customers, create targeted campaign audiences, or analyze purchase behavior by store using dbt Wizard. Triggers on phrases like "scenario 3", "run scenario 3", "targeted campaign", "customer segments", "VIP customers", "high-value customers", "category-loyal", "big spenders", "180-day activity", or any multi-step dbt Wizard workflow involving customers, orders, and categories. This skill walks the user through all 6 prompt steps interactively.
---

# dbt Wizard — High-Value Customer Segmentation

A guided, interactive 6-step workflow for using dbt Wizard to help Marketing identify high-value customers for targeted campaigns — using recent purchase behavior, store context, and category loyalty over a rolling 180-day window.

The skill starts from a **business problem** ("which customers should Marketing target?") and walks the user through dbt Wizard's discovery, schema, inspection, multi-model creation, and safe-preview capabilities — without ever materializing changes to the warehouse.

This scenario differs from prior ones in two ways:

- **Wider entity surface** — 6 model types (customers, stores, orders, order lines, products, categories) instead of 3–4.
- **Two-model design** — a reusable activity layer feeds a downstream segment model, so the logic is testable and reusable.

## How to use this skill

For each step below:

1. **Show the user the exact prompt** to paste into dbt Wizard (use a blockquote so it's copy-pasteable).
2. **Explain what dbt Wizard will do** under the hood (which tools/capabilities are exercised).
3. **Pause** and ask: *"Ready for the next step? Paste your dbt Wizard output here or just say 'next' to continue."*
4. If the user pastes output, **briefly interpret** what it means for the investigation before advancing.
5. Do not skip ahead. Run the steps in order.

If the user has not yet installed or configured dbt Wizard, refer them to `references/dbt_wizard_setup.md` before Step 1.

---

## Step 1 — Discovery

Prompt the user to paste this into dbt Wizard:

> Find the models related to customers, stores, orders, order lines, products, and categories.

**What this does:** Uses dbt Wizard's `status` and `search` capabilities to surface only the assets needed for customer segmentation. This domain is wider than prior scenarios (6 entity types), so discovery is especially important *before* touching any SQL — the user doesn't have to know naming conventions or file layout in advance.

After the user runs this, pause and wait. If they paste back a list of models, confirm that all six expected domains surfaced. The two most commonly missed: a dedicated **categories** model (sometimes category lives only as a column on products), and a separate **order lines** model (sometimes folded into orders). Flag either before moving on.

---

## Step 2 — Schema Understanding

Prompt:

> Show the grain and joins for those models.

**What this does:** Uses `describe` and `lineage` to confirm that customer, store, transaction, and category logic can all be connected.

After the user runs this, pause. If they share output, flag for the user:

- If **order lines and orders are separate models**, confirm the join key (typically `order_id`) and that **category lives on the product or order line level — not the order header**. Category-loyal logic in Step 5 depends on this grain being correct.
- The grain of the orders table (one row per order? per order line?) — this defines the transaction-count denominator.
- The customer↔store relationship: is store on the order, on the customer, or both? Per-store segmentation needs the store on the transaction.
- Any blockers (e.g., missing customer_id on orders, no date column on order lines) before moving on.

---

## Step 3 — Data Inspection

Prompt:

> Check recent order dates and category values needed for a 180-day segmentation model.

**What this does:** Uses `warehouse` and `dbt_show` to inspect the actual rolling-window anchor (what is the max order date?) and the distinct category values in the data. This avoids two silent bugs:

- A **stale date anchor** that shrinks the 180-day window — if the most recent order is months old, "trailing 180 days from today" returns far less data than expected.
- A **category field with unexpected nulls or formatting** (mixed case, whitespace, sparse population) that would silently break the category-loyal logic in Step 5.

After the user runs this, pause. If the max order date looks stale (more than a few days behind today's date), flag it so the user can decide whether to anchor the window on `current_date` or on `max(order_date)`. If categories have nulls or odd values, decide with the user how to handle them (exclude vs. coalesce) before Step 4.

---

## Step 4 — Activity Layer Model Creation

Prompt:

> Create a 180-day customer activity model by store.

**What this does:** Uses dbt Wizard's file edits and model-creation tools to build the **reusable activity layer** — not the segment model yet. This intermediate model should produce per-customer, per-store aggregates over the trailing 180 days:

- `transaction_count` — count of orders in the window
- `avg_transaction_value` — mean order value
- `max_transaction_value` — largest single order value
- Category-level transaction counts — count of transactions per category (per customer × store × category)

**Why a separate model:** building this as its own model (not inlined into the segment model) makes the logic **testable and reusable**. Other downstream models (churn, RFM, dashboards) can sit on the same activity layer instead of re-deriving these aggregates.

After the user runs this, pause. If they share the generated SQL, briefly verify:

- The 180-day window is applied consistently to all aggregates.
- The grain is **customer × store** (or customer × store × category for the category counts) — not just customer.
- The category counts can be joined back to the customer × store grain in Step 5.

---

## Step 5 — Segment Model Creation

Prompt:

> Create a segment model for VIPs, big spenders, and category-loyal customers.

**What this does:** Uses file edits and dbt model creation, built **on top of the activity layer from Step 4**. The three segment definitions:

- **VIP** — `avg_transaction_value > $100` AND `transaction_count >= 3`
- **Big spender** — `max_transaction_value > $300` (at least one transaction over $300)
- **Category-loyal** — at least 10 transactions in the same category (`category_transaction_count >= 10`)

**Important:** customers can appear in multiple segments. The model should `UNION` (or otherwise tag rows) so a single customer can have multiple segment rows.

Expected output columns:

- Customer identifier
- `store_name`
- `segment_name` (VIP / Big spender / Category-loyal)
- `transaction_count`
- `avg_transaction_value`
- `max_transaction_value`
- `category`
- `category_transaction_count`

After the user runs this, pause and remind them this is a **two-model design**: the activity layer (Step 4) feeds the segment model (Step 5). Optional next steps before opening a pull request:

- `dbt_test` for segment-model grain (uniqueness of customer × store × segment × category) and relationships (customer_id, store_id resolve to dim tables).
- `dbt_test` for the ratio logic (e.g., avg_transaction_value is non-negative, transaction_count > 0).
- A `diff` against the prior model version (or against production) to confirm the change is intentional.

---

## Step 6 — Safe Preview

Prompt:

> Compile and preview the segment model. Exclude customers with no segment.

**What this does:** Uses `dbt_compile` and `dbt_show` to validate the final targeted campaign list without materializing anything. The "exclude no segment" filter is a **data quality check**: if a large share of customers have no segment, the activity-layer thresholds or the date window may need revisiting *before* the model goes to Marketing.

After the user runs this, pause. If they share the preview:

- Confirm the column list matches Step 5's expected output and that multi-segment customers appear on multiple rows.
- If **a large share of customers show no segment** (e.g., the filtered preview is far smaller than the unfiltered customer count would suggest), suggest revisiting the thresholds ($100 / 3 / $300 / 10) or the date window (180 days) before handing the list to Marketing. The thresholds are business-tunable; the date window depends on Step 3's date-anchor decision.
- Flag any segment that is suspiciously empty (e.g., zero VIPs) — that usually points to a threshold or join issue rather than reality.

---

## Wrap-up

After Step 6 completes, summarize for the user:

> You started with a business question — *"which customers should Marketing target?"* — and used dbt Wizard to:
>
> 1. **Discover** the relevant models across 6 entity types (customers, stores, orders, order lines, products, categories) from the business problem, not the file tree.
> 2. **Validate the schema** — grain, join keys, and where category actually lives.
> 3. **Inspect the data** for a fresh date anchor and clean category values before writing any rolling-window logic.
> 4. **Build a reusable activity layer** with per-customer, per-store, per-category aggregates over a trailing 180-day window.
> 5. **Build a segment model** on top of the activity layer — VIPs, big spenders, and category-loyal customers — with multi-segment customers supported.
> 6. **Safely preview** the final audience without materializing anything, with a built-in data-quality filter.
>
> The business-to-technical link: Marketing needed a usable campaign audience; dbt Wizard demonstrated targeted asset discovery, join and grain validation, rolling-window logic, multi-model design (activity layer → segment model), and safe preview without materializing anything. The campaign list now rests on a reusable, testable layer — not a one-off query.

If the user wants to materialize the segment model after the preview (e.g., to hand to Marketing or feed a campaign tool), that's a separate step — confirm with them before running `dbt run` on the new model.

---

## References

- `references/dbt_wizard_setup.md` — install, run, config, and auth requirements for dbt Wizard.
