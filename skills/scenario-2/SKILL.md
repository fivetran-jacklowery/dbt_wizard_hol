---
name: scenario-2
description: Use this skill whenever a user wants to investigate product quality issues, defective return rates, or vendor performance using dbt Wizard. Triggers on phrases like "scenario 2", "run scenario 2", "faulty product", "defective returns", "vendor contract review", "return rate by product", "product quality complaints", or any multi-step dbt Wizard investigation involving products, vendors, sales, and returns. This skill walks the user through all 5 prompt steps interactively.
---

# dbt Wizard — Faulty Product Discovery

A guided, interactive 5-step workflow for using dbt Wizard to investigate faulty product returns — replacing anecdotal vendor complaints with measurable return-rate evidence so the business can make a defensible vendor-contract renewal decision.

The skill starts from a **business problem** ("are these vendor complaints real, and which products justify them?") and walks the user through dbt Wizard's discovery, schema, categorical inspection, modeling, and safe-preview capabilities — without ever materializing changes to the warehouse.

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

> Find the models related to products, vendors, sales, and returns.

**What this does:** Uses dbt Wizard's `status` and `search` capabilities to surface only the relevant models for product quality analysis — starting from the business question, not the full project. The user doesn't need to know the file layout or naming conventions in advance.

After the user runs this, pause and wait. If they paste back a list of models, confirm that all four expected domains (products, vendors, sales, returns) surfaced. If one is missing — especially returns or the product↔vendor link — flag it before moving on, since the metric can't be built without all four.

---

## Step 2 — Schema Understanding

Prompt:

> Show the grain and key columns for those models.

**What this does:** Uses `describe` and `lineage` to confirm the **numerator** (defective returns), the **denominator** (units sold), and how the **vendor relationship** joins in — *before* writing any SQL. The user learns the grain of each table and the join path in one pass.

After the user runs this, pause. If they share output, briefly note:
- The grain of the sales/order-items table (per line item? per order?) — this defines the denominator.
- The grain of the returns table and whether a return row carries a reason code.
- The join path from returns → sales → products → vendors.
- Anything that would block the next step (e.g., returns table has no `reason` column, or vendor only joins through a bridge table).

---

## Step 3 — Categorical Inspection

Prompt:

> Show the distinct return reasons in the returns data.

**What this does:** Uses `warehouse` to inspect actual values in the data rather than guessing the filter string for "defective" returns. This is the single most important step for avoiding a silent wrong-filter bug that would corrupt the metric — e.g., filtering for `'defective'` when the warehouse actually stores `'DEFECTIVE'`, `'Product Defect'`, or `'Damaged – Manufacturing'`.

After the user runs this, pause. If they share the distinct values, help them identify which value(s) map to "defective." Examples to watch for:
- All-caps codes: `DEFECTIVE`, `DAMAGED`, `QUALITY_ISSUE`
- Human-readable strings: `Product Defect`, `Damaged – Manufacturing`, `Item not as described`
- Multiple values that all mean defective — in which case the Step 4 filter will need an `IN (...)` clause, not `=`.

Confirm the exact string(s) with the user before moving to Step 4. A wrong filter string here means the rest of the analysis is silently wrong.

---

## Step 4 — Model Creation

Prompt:

> Create a model for products with a defective return rate over 20% in the past year.

**What this does:** Uses dbt Wizard's file edits and model-creation tools to write a new dbt model. The expected output columns:

- `product_name` (or item name)
- `vendor_name`
- `units_sold_trailing_365d` — denominator, trailing 365 days
- `defective_units_returned_trailing_365d` — numerator, trailing 365 days, filtered to the defective reason(s) confirmed in Step 3
- `defective_return_rate` — numerator / denominator
- Filter: only rows where `defective_return_rate > 0.20`

After the user runs this, pause. If they share the generated SQL, briefly verify:
- The defective-reason filter uses the exact string(s) confirmed in Step 3.
- The trailing-365-day window is applied consistently to both numerator and denominator (date filter on the same date column, or aligned date columns).
- The 20% threshold is applied as a `HAVING` (or outer filter on the aggregated rate), not on raw rows.

---

## Step 5 — Safe Preview

Prompt:

> Compile and preview the model with product, vendor, units sold, defective returns, and return rate.

**What this does:** Uses `dbt_compile` and `dbt_show` to validate the model output without materializing it — the SQL compiles, sample rows are previewed, but nothing is written to the warehouse. The business gets evidence *before* anything hits production.

After the user runs this, pause. If they share the preview table:
- Confirm the column list matches Step 4's expected output.
- Flag any products whose `defective_return_rate` is **near the 20% threshold** (e.g., 19–22%) — these are the rows a business stakeholder will most likely want to double-check or stress-test with a different window before making a contract decision.
- Flag any product where `units_sold_trailing_365d` is very small (e.g., <50) — a high return rate on a tiny denominator may not be statistically meaningful, and the business should know that before citing it in a vendor conversation.

---

## Wrap-up

After Step 5 completes, summarize for the user:

> You started with a business question — *"are these vendor complaints real, and which products justify not renewing the contract?"* — and used dbt Wizard to:
>
> 1. **Discover** the relevant models (products, vendors, sales, returns) from the business problem, not the file tree.
> 2. **Validate the schema** to confirm the numerator, denominator, and vendor join were all available.
> 3. **Inspect categorical values** in the returns data so the "defective" filter matches what's actually in the warehouse — eliminating a silent wrong-filter bug.
> 4. **Create a dbt model** computing trailing-365-day defective return rate per product+vendor, filtered to >20%.
> 5. **Safely preview** the model output without materializing it, so the business has evidence before anything is written.
>
> The business-to-technical link: dbt Wizard replaced anecdotal vendor complaints with a measurable, defensible return-rate metric — via relevant model discovery → categorical value inspection → correct metric calculation → safe validation. The contract-renewal decision now rests on data, not stories.

If the user wants to materialize the model after the preview (e.g., to share with the vendor or build a dashboard), that's a separate step — confirm with them before running `dbt run` on the new model.

---

## References

- `references/dbt_wizard_setup.md` — install, run, config, and auth requirements for dbt Wizard.
