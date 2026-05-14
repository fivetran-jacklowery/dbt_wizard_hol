---
name: scenario-1
description: Use this skill whenever a user wants to investigate inventory problems, shipment discrepancies, stock imbalance, overstock, understock, or misallocation issues using dbt Wizard. Triggers on phrases like "scenario 1", "run scenario 1", "find where inventory went", "check shipment allocation", "which stores got too much", "which stores got too little", "overstock stores", "understock stores", "inventory variance", "inventory misallocation", or any multi-step dbt Wizard investigation workflow involving stores, items, and shipments. This skill walks the user through all 5 prompt steps interactively.
---

# dbt Wizard — Inventory Misallocation Investigation

A guided, interactive 5-step workflow for using dbt Wizard to investigate inventory misallocation — for example, finding which stores received excess inventory **or too little inventory** of a specific item ahead of a major sale.

The skill starts from a **business problem** ("where did the shipment go, and which stores are short?") and walks the user through dbt Wizard's discovery, schema, inspection, modeling, and safe-preview capabilities — without ever materializing changes to the warehouse.

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

> Find the models related to inventory, stores, items, and shipments.

**What this does:** Uses dbt Wizard's `status` and `search` capabilities to surface only the relevant models from the project. We start from the business problem, not from the codebase — so the user does not have to know the schema or file layout in advance.

After the user runs this, pause and wait. If they paste back a list of models, confirm that the four expected domains (inventory, stores, items, shipments) all surfaced. If one is missing, flag it before moving on.

---

## Step 2 — Schema Understanding

Prompt:

> For those models, show the grain, key columns, and how they join together.

**What this does:** Uses `describe` and `lineage` to confirm whether the data can actually answer the question *before* writing any SQL. The user learns the grain of each table, the join keys, and the upstream lineage in one pass.

After the user runs this, pause. If they share output, briefly note:
- The grain of the inventory table (per-store-per-item? per-shipment?).
- The join path from shipments → stores → items.
- Anything that would block the next step (e.g., missing join key, wrong grain).

---

## Step 3 — Data Inspection

Prompt the user, asking them to fill in the item name and expected quantity. The default example is **Item A** and **200 units**:

> Check [Item Name] shipments and inventory. Expected quantity is [N] per store.

**What this does:** Uses `warehouse` and `dbt_show` to inspect only the targeted slice of data — no full table scans, no materializations. The user sees actual rows for the item in question, scoped to the relevant stores.

After the user runs this, pause. If they share output, look for stores where actual inventory differs from the expected quantity:

- `actual_inventory_count > expected_count` → **overstock**
- `actual_inventory_count < expected_count` → **understock**
- `actual_inventory_count = expected_count` → balanced; usually exclude from the exception model

Both overstock and understock stores are candidates for the next step. Do not frame the investigation as overage-only.

---

## Step 4 — Model Creation

Prompt:

> Create a model showing stores with more or less than [N] units of [Item Name].

**What this does:** Uses dbt Wizard's file edits and model-creation tools to write a new dbt model. The expected output columns are:

- `store_name`
- `city` / `region`
- `item_name`
- `actual_inventory_count`
- `expected_count` (the fixed N from Step 3)
- `inventory_variance` (actual − expected; positive means overstock, negative means understock)
- `stock_status` (`overstock` when actual > expected, `understock` when actual < expected)

After the user runs this, pause. If they share the generated SQL, briefly verify:

- The column list matches the expected output.
- The filter uses the correct N.
- The model includes both sides of the variance, usually with `actual_inventory_count != expected_count`, not only `actual_inventory_count > expected_count`.
- `stock_status` is derived from the sign of `inventory_variance`.

---

## Step 5 — Safe Preview

Prompt:

> Compile and preview the model. Do not materialize it yet.

**What this does:** Uses `dbt_compile` and `dbt_show` to validate the model safely — the SQL compiles, sample rows are previewed, but nothing is written to the warehouse. This is the "look before you leap" step before the user decides to run the model for real.

After the user runs this, pause and confirm the preview returned the expected misallocated stores, including both overstock and understock rows when both exist.

---

## Wrap-up

After Step 5 completes, summarize for the user:

> You started with a business question — *"where did the shipment go, and which stores are short?"* — and used dbt Wizard to:
>
> 1. **Discover** the relevant models from the business problem (not the file tree).
> 2. **Validate the schema** to confirm the data could answer the question.
> 3. **Inspect targeted data** to spot stores above and below the expected count.
> 4. **Create a dbt model** capturing both overstock and understock variance logic.
> 5. **Safely preview** the model without touching the warehouse.
>
> The business-to-technical link: dbt Wizard turned a stakeholder question into a discovery → schema validation → targeted inspection → model creation → safe preview workflow, with no manual codebase spelunking and no risky writes. The resulting model identifies inventory exceptions in both directions, so operations can rebalance surplus stores and replenish short stores.

If the user wants to materialize the model after the preview, that's a separate step — confirm with them before running `dbt run` on the new model.

---

## References

- `references/dbt_wizard_setup.md` — install, run, config, and auth requirements for dbt Wizard.
