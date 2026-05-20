# Ticket Order Join Validation Output Template

Use this template when answering:

```text
Run a quick check: count rows in stg_tickets with a non-null order_id, count distinct ticket order_ids, and count how many of those order_ids match an order_id in int_orders_enriched. Tell me whether stg_tickets is one-to-one or one-to-many at the order grain.
```

Also use it for equivalent prompts such as:

```text
Count rows in stg_tickets with a non-null order_id, count distinct ticket order_ids, and count how many of those order_ids match an order_id from enriched orders. What is the cardinality of stg_tickets to int_orders_enriched?
```

Populate the bracketed values from read-only warehouse checks against `stg_tickets` and `int_orders_enriched`. If compile or `dbt show` is blocked, use direct warehouse queries and say so only if it matters to the answer.

```markdown
Cardinality: **[cardinality_classification]**.

| Metric | Value |
|---|---:|
| `stg_tickets` rows with non-null `order_id` | `[ticket_rows_with_order_id]` |
| Distinct `stg_tickets.order_id` values | `[distinct_ticket_order_ids]` |
| Ticket rows matching `int_orders_enriched.order_id` | `[matching_ticket_rows]` |
| Distinct matched `order_id` values | `[matching_distinct_order_ids]` |
| Max tickets per order among matched/non-null rows | `[max_tickets_per_order]` |

## Interpretation

[If no ticket rows have `order_id`: `stg_tickets.order_id` is entirely null in current data, so no current relationship is observable. `stg_tickets` is not joinable to `int_orders_enriched` at order grain today.]

[If max tickets per order = 1 and all ticket order IDs match: Current data behaves one-to-one from `stg_tickets.order_id` to `int_orders_enriched.order_id`, but keep the model defensive because support tickets are naturally many-to-one at order grain.]

[If max tickets per order > 1: Current data is many tickets to one enriched order. Aggregate `stg_tickets` to one row per `order_id` before joining to preserve `int_orders_enriched`'s one-row-per-order grain.]

[If some ticket order IDs do not match: Some ticket `order_id` values do not exist in `int_orders_enriched`. Report the unmatched count and do not inner join unless dropping unmatched tickets is explicitly intended.]
```

Rules:

- Use `submit_table` for the metrics.
- Always filter the primary ticket counts to `where order_id is not null`.
- Count both ticket rows and distinct ticket `order_id` values.
- Count both matching ticket rows and distinct matched order IDs.
- Compute a fanout metric such as max tickets per order for non-null or matched order IDs.
- Classify cardinality from the observed data:
  - **No observable order relationship**: zero non-null ticket `order_id` values.
  - **One-to-one in current data**: non-null ticket rows equal distinct ticket order IDs and max tickets per order is 1.
  - **Many-to-one**: max tickets per order is greater than 1.
  - **Partially unmatched**: non-null ticket order IDs exist, but matched distinct order IDs are lower than distinct ticket order IDs.
- Even if current data appears one-to-one, remind that support tickets are naturally modeled as many-to-one by order, so aggregation before joining is the safer design.

For this HOL project, the populated output should usually resemble:

```markdown
Cardinality: **no current relationship is observable** because `stg_tickets.order_id` is entirely null.

- `stg_tickets` rows with non-null `order_id`: **0**
- distinct ticket `order_id` values: **0**
- rows matching `int_orders_enriched.order_id`: **0**

So with current data, `stg_tickets` is **not joinable to `int_orders_enriched` at order grain**. If `order_id` were populated, the expected modeling assumption would be **many tickets to one order**, requiring aggregation to one row per `order_id` before joining.
```
