---
name: scenario-2
description: Use this skill when the user is evaluating a vendor contract, investigating product quality complaints, or measuring defective return rates with dbt Wizard. Triggers on natural-language phrasing such as "are these vendor complaints real", "which products have a high defective return rate", "should we renew this vendor's contract", "find the products with quality problems", "quantify product returns by vendor", "investigate defective return rate over 20%", "is this vendor's product line failing", or "build a model for faulty products". Use this skill for product/vendor/returns analysis specifically — not for inventory or shipment questions (that is scenario-1), and not for customer segmentation or marketing questions (that is scenario-3). Walks the user through a six-step dbt Wizard investigation ending in a materialized model in their dev schema.
---

# dbt Wizard — Faulty Product Discovery

A six-step workflow that replaces anecdotal vendor complaints with a measurable defective-return-rate metric — so a contract-renewal decision rests on data, not on a salesperson's gut feel.

## How to run this skill

For every step:

1. Show the user the question to ask dbt Wizard inside a plain fenced code block — no quoting, no decoration, so it can be triple-clicked and copied or read off a printed lab sheet.
2. Always frame the question as *"copy this as written, or rephrase it in your own words"* — give the user the explicit choice between using the canonical version and paraphrasing. Either path is correct; the lab is about the workflow, not the wording.
3. State briefly what dbt Wizard exercises under the hood.
4. After dbt Wizard responds, interpret in one or two lines where the user now stands. Do not restate dbt Wizard's output — name the *insight* the user just earned. Then surface the next question in another plain code block, again with the copy-or-rephrase framing.

Never tell the user to "say next," "paste output here," "ready for the next step," or anything similar. They advance by typing each business question themselves. Run the steps in order.

If dbt Wizard is not yet installed, see `references/dbt_wizard_setup.md` before Step 1.

---

## Step 1 — Discovery

Ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Find the models related to products, vendors, sales, and returns.
```

Exercises `status` and `search`. dbt Wizard surfaces only the models relevant to the business question — the user does not need to know the file layout.

Confirm all four domains surfaced. If returns or the product↔vendor link is missing, name it now — the metric cannot be built without them.

Important HOL note: the physical returns table is `RET_RETURNS`, and it carries the `RETURN_REASON` field needed for the defective-return numerator. If returns do not surface in dbt search, inspect `information_schema` for `RET_RETURNS` and add/repair the `RET_RETURNS` source plus a `stg_returns` model before proceeding.

Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Show the grain and key columns for those models.
```

---

## Step 2 — Schema Understanding

Exercises `describe` and `lineage`. Confirms the *numerator* (defective returns), the *denominator* (units sold), and the join path to vendor — before any SQL is written. Skipping this step is how teams ship a ratio metric where the numerator and denominator are on different grains.

When the response comes back, name in one or two lines: the grain of the sales / order-items table (your denominator), the grain of `stg_returns` / `RET_RETURNS` (one row per product return record, with `return_reason`), and the join path returns → order items/orders → products → vendors or brand. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Show the distinct return reasons in the returns data.
```

---

## Step 3 — Categorical Inspection

Exercises `warehouse` to inspect actual values rather than guess the filter string. This is the step that separates an analytics engineer from someone who is about to silently corrupt a board-level metric.

When the distinct values return, help the user pick the string(s) that map to "defective." Examples you might see — frame them as illustrative, never authoritative:

- All-caps codes like `DEFECTIVE`, `DAMAGED`, `QUALITY_ISSUE`
- Human-readable strings like `Product Defect`, `Damaged - Manufacturing`
- Multiple values that all mean defective — Step 4 will need an `IN (...)` clause, not `=`

HOL rule: use only `return_reason = 'defective'` for the defective-return numerator. Exclude `return_reason = 'damaged in transit'` because it is treated as logistics damage, not a product-quality defect.

Confirm the exact string(s) with the user before moving on. A wrong filter here makes the rest of the analysis silently wrong and the vendor conversation indefensible. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Create a model for products with a defective return rate over 20% in the trailing 365 days. Include product name, vendor name, units sold, defective units returned, and the defective return rate.
```

---

## Step 4 — Model Creation

Exercises file edits and model creation. Expected columns:

- product / item name
- vendor name
- `units_sold_trailing_365d` — denominator
- `defective_units_returned_trailing_365d` — numerator, filtered to the reason string(s) from Step 3; in this HOL, include only `return_reason = 'defective'` and explicitly exclude `return_reason = 'damaged in transit'`
- `defective_return_rate` — numerator divided by denominator
- Filter: `defective_return_rate > 0.20`

When the model is generated, confirm in one or two lines: the reason filter matches Step 3 exactly, the trailing-365-day window is applied consistently to numerator and denominator, and the 20% threshold is applied to the aggregated rate (not to raw rows). Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Compile and preview the model with product, vendor, units sold, defective returns, and return rate.
```

---

## Step 5 — Safe Preview

Exercises `dbt_compile` and `dbt_show`. The SQL compiles, sample rows render, nothing lands in the warehouse yet.

When the preview returns, confirm the column list matches Step 4. Then flag two failure modes a stakeholder will catch if you don't:

- Products near the 20% threshold (roughly 19–22%) — these are the rows the vendor will dispute first, and the rows you should stress-test with a different window before citing them.
- Products with a very small denominator (e.g., fewer than 50 units sold) — a high return rate on a tiny base is not yet defensible evidence.

Naming these up front is the difference between a metric the business trusts and a metric the business has to walk back. Then ask dbt Wizard — copy this as written, or rephrase it in your own words:

```
Materialize this model into my dev schema. Skip the verification pass — go straight to the build.
```

---

## Step 6 — Materialize

Exercises `dbt_run` against the user's dev schema (`dev_lab_user_N`). The "skip the verification pass" instruction is deliberate: Step 5 already validated the output, and verification consumes roughly 10% of the lab's total time. The instructor drops dev schemas after the lab via a cleanup script, so this build is safe and disposable.

When the build succeeds, confirm the model landed in the user's dev schema with a non-zero row count. The user now has a queryable, versioned table they can hand to procurement or wire into a vendor scorecard dashboard.

---

## Wrap-up

In two or three sentences: the user started with *"are these vendor complaints real?"* and ended with a materialized, queryable model of products whose defective return rate exceeds 20% over the trailing year. The contract-renewal conversation now rests on a measurable, reproducible metric instead of anecdotes. That is the analytics-engineering job — and dbt Wizard moved the user through it in minutes, not days.

---

## References

- `references/dbt_wizard_setup.md` — install, run, config, and auth for dbt Wizard.
