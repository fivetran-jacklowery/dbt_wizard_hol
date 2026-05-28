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

## Lab prerequisite

This skill is the workshop flow only. It assumes `$lab_init` has already prepared the repo, reset Snowflake dev schemas, and built the baseline project.

When `$lab` is triggered from a freshly initialized repo, do not run setup or cleanup. Start by showing Prompt 1 once in the standard next-prompt callout.

If the repo appears dirty, the baseline build is missing, or the user asks to reset/prepare/clean up, stop and direct them to run `$lab_init` first.

---

## How to run this skill

Keep lab responses concise. Prefer a short answer that gets the attendee to the next action over long explanations. Only expand when the user asks for detail, a validation step fails, or a modeling choice has non-obvious downstream consequences.

For every prompt:

1. Show the user the question to ask dbt Wizard inside a plain fenced code block — no quoting or decoration — so it can be triple-clicked or read off a printed lab sheet.
2. Frame it as *"copy this as written, or rephrase it in your own words."* Copy-as-written is recommended for the timed lab.
3. After dbt Wizard responds, name the *insight* the user just earned in one sentence. Do not restate the output.
4. **At the end of your response for every prompt, display the next prompt in a prominent callout.** Use a horizontal rule, then a bold `⬇ YOUR NEXT PROMPT:` heading, then the next copyable question in a fenced code block, then another horizontal rule. Make it impossible to miss.

Do not duplicate the same prompt in a single response. If the current response is only setup/readiness, the callout containing Prompt 1 is sufficient.

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
Create a new mart model called orders_by_week that aggregates orders to the week grain with order_count, gross_revenue, and distinct_customers. Then compile and preview it.
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
Add order-level support ticket context to int_orders_enriched: ticket_count, has_open_ticket_flag, and last_ticket_status.
```
---

---

## Prompt 4 — Modify int_orders_enriched

Exercises `search`, `describe`, and `lineage` to locate the target and understand the downstream blast radius, then a file edit on the existing model.

The attendee-facing prompt is intentionally short. Treat it as shorthand for the full implementation request below; do not ask the attendee to provide the extra details.

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

## Lab cleanup

After Prompt 5, or after the optional materialization step, use `$lab_init` to reset the repo and Snowflake dev schemas for the next attendee.

---

## References

- `references/project_summary_output_template.md`
- `references/model_inventory_output_template.md`
- `references/mart_lineage_grain_output_template.md`
- `references/enriched_orders_current_state_output_template.md`
- `references/ticket_data_discovery_output_template.md`
- `references/ticket_order_join_validation_output_template.md`
