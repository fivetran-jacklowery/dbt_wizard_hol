---
name: lab
description: >
  Full 15-minute dbt Wizard hands-on lab. Covers a guided onboarding tour of
  the project followed by a safe enrichment of an existing intermediate model.
  Triggers on prompts like "help me onboard", "give me a repo tour",
  "summarize this dbt project", "add support tickets to orders",
  "extend orders with ticket counts", "wire tickets into int_orders_enriched",
  or any prompt that starts the lab flow from the beginning.
---

# dbt Wizard — Hands-On Lab

**The setup:** It's your first week at The Builders Depot. You've been handed access to the dbt repo with a vague mandate: *"get familiar and ship something small by Friday."* Shortly after, the Director of Operations stops by with a follow-up ask: they want to know which orders have been generating the most support burden.

This lab runs in two sections. The first three prompts orient you to the project and get a small first contribution shipped. The last two prompts extend an existing model with a new data source — without breaking anything downstream.

---

## Lab Setup — run this before Prompt 1

When this skill is triggered, run the following steps before showing Prompt 1. Do not skip them. Do not advance to Prompt 1 if any step fails.

### Setup output style

Keep setup output quiet. Do not stream or summarize routine command logs, test names, dbt node output, schema listings, or successful command details to the user. Only surface details if a setup step fails, requires approval, or leaves the working tree/schema state unexpected.

On success, report only a concise readiness message and immediately show Prompt 1, for example:

> Lab setup is complete ✅  
> The repo is clean, the initial dbt build passed, and your dev schemas are ready.

### 1. Clear local changes and dbt artifacts

```bash
git restore .
git clean -fd
rm -rf target
```

Confirm the working tree is clean:

```bash
git status
```

Expected: `nothing to commit, working tree clean`. If there are unexpected uncommitted files, stop and surface them to the user before continuing.

### 2. Verify the target schemas are empty

Identify the current target schema prefix. Run `dbt debug` if it is not already known:

```bash
uvx --from dbt-snowflake dbt debug
```

Look for the active `schema` in the output. Then check whether any of the four dbt-managed schemas already exist in Snowflake and drop them if they do. Replace `<target>` with the active schema prefix:

```sql
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.<target>_staging cascade;
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.<target>_intermediate cascade;
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.<target>_marts cascade;
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.<target>_marketing cascade;
```

**Never drop `SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL`.** That is the shared raw source schema and must not be touched.

### 3. Run dbt build

```bash
uvx --from dbt-snowflake dbt build
```

Wait for the build to complete. If it succeeds, confirm the target schemas are now populated and proceed to Prompt 1. If it fails, surface the error — do not continue the lab until the build is clean.

---

---

## How to run this skill

For every prompt:

1. Show the user the question to ask dbt Wizard inside a plain fenced code block — no quoting or decoration — so it can be triple-clicked or read off a printed lab sheet.
2. Frame it as *"copy this as written, or rephrase it in your own words."* Copy-as-written is recommended for the timed lab.
3. After dbt Wizard responds, name the *insight* the user just earned in one sentence. Do not restate the output.
4. **At the end of your response for every prompt, display the next prompt in a prominent callout.** Use a horizontal rule, then a bold `⬇ YOUR NEXT PROMPT:` heading, then the next copyable question in a fenced code block, then another horizontal rule. Make it impossible to miss.

Never tell the user to "say next," "paste your output here," or "ready for the next step?" They advance by typing each question themselves.

### Continuation behavior

Once this skill is triggered, treat all follow-up prompts as continuation of the lab flow. Track which prompt the user is on and resume from there — don't restart the lab or ask the user to re-introduce themselves.

---

## Prompt 1 — Project tour and model inventory

Ask dbt Wizard — copy this as written (recommended), or rephrase it in your own words:

```
I'm a new analytics engineer onboarding to this dbt project. Summarize what it does, the main subject areas, and how it is organized. Then list all the models grouped by layer and domain.
```

Exercises project-level `status`, repo summarization, `search`, and folder/tag grouping. One question, two payoffs: the elevator pitch (what business is this, what are the subject areas, how is it layered) plus the full model map (staging, intermediate, marts bucketed by domain).

For the project summary portion, use `references/project_summary_output_template.md`. For the model inventory portion, use `references/model_inventory_output_template.md`.

After responding, end with:

---
**⬇ YOUR NEXT PROMPT** — copy this as written, or type something similar in your own words:

```
Show me a 10-row sample from fct_orders and the distinct values in the order_status column. Use submit_table for both outputs. For the sample, show a representative subset of key columns so the table is readable.
```
---

---

## Prompt 2 — Sample real data from a mart

Exercises `warehouse` for a live 10-row sample of `fct_orders` and a `SELECT DISTINCT` on `order_status`.

This step makes the project real — up to now it was schemas and DAG diagrams, now it's rows. The `order_status` distinct-values check is the load-bearing part: without it, attendees will write filters based on guesses (`where order_status = 'shipped'`, `where order_status = 'complete'`). The real values in this project might be `delivered`, `in_progress`, `cancelled`, `returned`. Reading them directly prevents silent wrong-result bugs.

For the 10-row sample, show a readable representative subset: identifiers, dates, status field, primary financial measures, 1–2 useful flags. Render the distinct-values summary in a separate `submit_table`.

After responding, end with:

---
**⬇ YOUR NEXT PROMPT** — copy this as written, or type something similar in your own words:

```
Create a new mart model called orders_by_week that aggregates orders to the week grain with order_count, gross_revenue, and distinct_customers. Then compile and preview it — don't materialize it.
```
---

---

## Prompt 3 — Create, compile, and preview orders_by_week

Exercises file edits and convention-aware model generation, followed by `dbt_compile` and `dbt_show`.

Write `orders_by_week.sql` into `models/marts/core/`, built on `fct_orders` via `ref()` — not on staging. The model emits:

- `order_week` — week the order was placed, truncated to week-start using the same date-truncation function the rest of the project uses
- `order_count` — count of orders in that week
- `gross_revenue` — sum of `order_revenue` for that week
- `distinct_customers` — count of distinct `customer_id` values that week

After writing the file, compile and preview. Do **not** run `dbt run`. Confirm:

- Row count is plausible (roughly one row per week of order history).
- `order_count`, `gross_revenue`, and `distinct_customers` are populated with non-zero values.
- The week column is a date, not a string, and truncation looks correct.

The deliverable is a compiled, previewed `.sql` file in the repo — not a built table.

After responding, end with:

---
**⬇ YOUR NEXT PROMPT** — copy this as written, or type something similar in your own words:

```
We have a support tickets table in the warehouse that nobody has connected to orders yet. I want to add ticket context to int_orders_enriched — how many tickets each order generated, whether any are still open, and the status of the most recent one. Update the model. Aggregate stg_tickets to one row per order_id before joining so the grain stays one row per order, use a LEFT JOIN so orders without tickets still appear, and preserve every column int_orders_enriched currently emits.
```
---

---

## Prompt 4 — Modify int_orders_enriched

Exercises `search`, `describe`, and `lineage` to locate the target and understand the downstream blast radius, then a file edit on the existing model.

**Fixed setup:**
- Target model: `int_orders_enriched`
- New source: `retail.RET_TICKETS` / `stg_tickets`
- Join key: `order_id`
- New columns: `ticket_count`, `has_open_ticket_flag`, `last_ticket_status`

Two non-negotiables:

- **LEFT JOIN, not INNER.** An inner join silently drops every order with no ticket.
- **Preserve existing columns.** Downstream consumers select columns by name. New columns are appended at the end only.

The edit adds three CTEs before the `enriched` CTE: `ticket_rollup` (count + open flag per order), `latest_ticket` (most recent status via `QUALIFY ROW_NUMBER()`), and `ticket_summary` (joins the two). The `enriched` CTE then left-joins to `ticket_summary` and appends the three new columns.

For consistent current-state context, use `references/enriched_orders_current_state_output_template.md` when summarizing what the model currently produces.

After responding, end with:

---
**⬇ YOUR NEXT PROMPT** — copy this as written, or type something similar in your own words:

```
Compile int_orders_enriched and every downstream model that depends on it. Then preview 20 rows of int_orders_enriched ordered by order_id — don't materialize anything.
```
---

---

## Prompt 5 — Compile downstream and preview

Exercises `dbt_compile` across the full downstream lineage and `dbt_show` on the target model. Compiling downstream is the guarantee that no consumer lost a column or had a type change.

Confirm all four of these before reporting success:

1. The preview shows `ticket_count`, `has_open_ticket_flag`, and `last_ticket_status` in the output.
2. Orders without tickets still appear — `ticket_count` is `0` for orders with no linked tickets.
3. The row count of `int_orders_enriched` is unchanged from the pre-edit baseline. If it grew, the ticket aggregation fanned out and the model needs a re-edit.
4. All downstream models compiled without error.

If anything fails, diagnose with dbt Wizard before suggesting materialization.

After responding (assuming all checks pass), end with:

---
**⬇ LAB COMPLETE — optional bonus if you have time:**

```
Materialize int_orders_enriched into my dev schema. Skip the extended verification — the preview and downstream compile already confirmed the output.
```
---

---

## Final artifacts

- `models/marts/core/orders_by_week.sql` — mart model aggregating `fct_orders` to the week grain. Compiled and previewed. **Not materialized.**
- `int_orders_enriched` — updated to emit `ticket_count`, `has_open_ticket_flag`, and `last_ticket_status`. Existing column contract preserved. Downstream models compile. Row count unchanged.

---

## Lab Teardown — run this after the lab is complete

After Prompt 5 (and after the optional materialize step if the attendee ran it), drop the target schemas to leave a clean slate for the next attendee. Replace `<target>` with the lab user's schema prefix:

```sql
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.<target>_staging cascade;
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.<target>_intermediate cascade;
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.<target>_marts cascade;
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.<target>_marketing cascade;
```

**Never drop `SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL`.**

Then reset the git working tree and dbt artifacts for the next attendee:

```bash
git restore .
git clean -fd
rm -rf target
```

---

## References

- `references/project_summary_output_template.md`
- `references/model_inventory_output_template.md`
- `references/mart_lineage_grain_output_template.md`
- `references/enriched_orders_current_state_output_template.md`
- `references/ticket_data_discovery_output_template.md`
- `references/ticket_order_join_validation_output_template.md`
