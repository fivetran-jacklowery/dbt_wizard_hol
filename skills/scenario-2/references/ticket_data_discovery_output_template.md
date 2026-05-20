# Ticket Data Discovery Output Template

Use this template when answering:

```text
Find every support-ticket source or model in this project that int_orders_enriched does NOT currently reference. I want to know what ticket data is sitting in our warehouse that is not connected to enriched orders yet.
```

Also use it for equivalent prompts such as:

```text
Find ticket data in our warehouse that is not connected to enriched orders yet.
```

Populate the bracketed values from `search`, `lineage`, `describe`, the ticket model SQL, and read-only warehouse checks. If compile or `dbt show` is blocked, say so briefly and name the source of truth used instead.

```markdown
Found ticket data, but it is **not connected to `[target_model]`**.

Note: [Only include if relevant: compile/dbt show is currently blocked by [reason], so this is based on the local dbt index, model SQL/YAML, and read-only warehouse queries.]

## Current `[target_model]` upstream

`[target_model]` currently depends on:

- `[direct_upstream_model]`
- source `[upstream_source]`

It does **not** reference `[ticket_source]`, `[ticket_staging_model]`, `[ticket_fact_model]`, or `[ticket_summary_model]`.

## Ticket data found

| Asset | Layer | Grain | Current downstream path | Connected to `[target_model]`? | Notes |
|---|---|---|---|---|---|
| `[ticket_source]` | source | [grain or not documented] | `[ticket_source]` → `[ticket_staging_model]` → `[ticket_fact_model]` / `[ticket_summary_model]` | No | [short source description] |
| `[ticket_staging_model]` | staging model | `[ticket_pk]` | `[ticket_staging_model]` → `[ticket_fact_model]`; `[ticket_staging_model]` → `[ticket_summary_model]` → `[customer_model]` | No | Contains `[ticket_pk]`, `[customer_fk]`, `[order_fk]`, status, priority, issue, and timestamps. |
| `[ticket_fact_model]` | mart model | `[ticket_pk]` | `[ticket_fact_model]` [current consumers] | No | Denormalizes tickets with customer and order context, but does not feed `[target_model]`. |
| `[ticket_summary_model]` | intermediate model | `[customer_fk]` | `[ticket_summary_model]` → `[customer_model]` → `[clv_model]` | No | Aggregates support history per customer, not per order. |

## Order-linkage check

| Metric | Value |
|---|---:|
| Ticket rows | `[ticket_rows]` |
| Distinct ticket IDs | `[distinct_ticket_ids]` |
| Tickets with `order_id` | `[tickets_with_order_id]` |
| Distinct ticket `order_id` values | `[distinct_ticket_order_ids]` |
| Ticket rows joining to `[target_model]` | `[linked_ticket_rows]` |
| Distinct matched order IDs | `[linked_distinct_order_ids]` |

## Interpretation

`[ticket_staging_model]` is the candidate asset for order-level ticket enrichment because it contains `[order_fk]`.

[If order linkage is present: Aggregate `[ticket_staging_model]` to one row per `[order_fk]` before joining to preserve `[target_model]`'s one-row-per-order grain.]

[If no order linkage is present: Current data has no populated `[order_fk]`, so order-level enrichment would produce no matched ticket context unless `[order_fk]` starts being populated or the design shifts to customer-level enrichment.]
```

Rules:

- Resolve the target model first. For this HOL scenario, "enriched orders" means `int_orders_enriched`.
- Separate "ticket data exists" from "ticket data joins to orders." The second claim requires a warehouse check.
- Always inspect `int_orders_enriched` upstream lineage to prove the ticket assets are disconnected.
- Always inspect the ticket source/staging lineage to show where ticket data currently flows.
- Always run a read-only order-linkage check:
  - total ticket rows
  - distinct ticket IDs
  - tickets with non-null `order_id`
  - distinct ticket `order_id` values
  - ticket rows joining to `int_orders_enriched`
  - distinct matched order IDs
- If `stg_tickets.order_id` is empty, say that plainly. Do not imply order-level enrichment will produce matched ticket metrics with current data.
- Use `submit_table` for the ticket asset inventory and the order-linkage check.

For this HOL project, the populated output should usually resemble:

```markdown
Found ticket data, but it is **not connected to `int_orders_enriched`**.

Current `int_orders_enriched` upstream is only:

- `stg_orders`
- source `retail.RET_ORDERS`

Ticket path exists separately:

- source `retail.RET_TICKETS`
- `stg_tickets`
- `fct_tickets`
- `int_customer_support_summary`

Important data caveat: `stg_tickets` has **50 ticket rows**, but **0 rows currently have `order_id` populated**, so there are currently **0 ticket rows that join to `int_orders_enriched` at `order_id` grain**.

The candidate asset is still **`stg_tickets`**, but with the current data, order-level enrichment would produce no matched ticket context unless `order_id` starts being populated or we choose a customer-level enrichment instead.
```
