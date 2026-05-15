---
name: onboarding
description: Use this skill when the user is new to a dbt project and wants dbt Wizard to act as an onboarding buddy — giving them a guided tour of the codebase, the model layers, the lineage, the data, the tests, and ending with a small first-PR-style model they can ship. Triggers on natural-language phrasing like "I'm new to this dbt project", "help me onboard", "what does this project do", "give me a tour of the repo", "first week at a new job and I just got dbt access", "show me how the project is organized", "where do I start with this dbt project", "I just inherited this dbt project", "summarize this project for me", "I need to get familiar with this codebase and ship something small", or "walk me through this dbt repo". Use for the orient-a-new-engineer-on-an-unfamiliar-dbt-project workflow specifically — not for inventory or shipment problems (scenario-1), extending an existing model with a new source (scenario-2), customer segmentation (scenario-3), or upstream schema breakage (scenario-4). The other scenarios assume the attendee already knows the project; this one assumes Day 1.
---

# dbt Wizard - First-Week Onboarding Tour

A seven-step workflow that collapses the typical two-week "where is everything?" onboarding into a single guided session. The attendee starts the lab having never seen this dbt project before, and ends it with a working model they wrote themselves, previewed but not materialized, because Day 1 is not when you build things into a shared schema.

The setup: it's your first week at The Builder Depot. You've been handed access to the dbt repo and a vague mandate: *"get familiar with the project and ship something small by Friday."* You don't know the folder layout, the naming conventions, the grain of the marts, or which tests are currently failing. You'll use dbt Wizard as your onboarding buddy.

## How to run this skill

For every step:

1. Show the user the question to ask dbt Wizard inside a plain fenced code block, with no quoting or decoration, so it can be copied cleanly or read off a printed lab sheet.
2. Always frame the question as *"copy this as written, or rephrase it in your own words"*. Copy-as-written is recommended for the timed lab.
3. State briefly what dbt Wizard exercises under the hood.
4. After dbt Wizard responds, interpret in one or two lines what the user now knows. Do not restate dbt Wizard's output. Name the *insight* the user just earned, then surface the next question in another plain code block, again with the copy-or-rephrase framing.

Never tell the user to "say next," "paste your output here," "ready for the next step," or anything similar. They advance by typing each business question themselves. Run the steps in order.

If dbt Wizard is not yet configured, send the user to `references/dbt_wizard_setup.md` before Step 1.

---

## Step 1 - Project summary

Ask dbt Wizard - copy this as written (recommended), or rephrase it in your own words:

```
Summarize what this dbt project does. What are the main subject areas and how is the project organized?
```

Exercises project-level `status` and repo summarization. We start from the top, not from a model and not from a folder. The user does not need to read the README, scroll the file tree, or guess at the domain. dbt Wizard reads the project as a whole and returns the elevator pitch: what business this is, what the major subject areas are (customers, orders, products, stores, inventory, etc.), and how the project is layered (staging, intermediate, marts).

When the response returns, confirm in one line that the user can name the business domain and the layering convention. If dbt Wizard surfaces a layer the user wasn't expecting (e.g., a `snapshots/` directory or a `seeds/` folder), note it now. Every later step is easier when the full shape of the project is named up front. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
List the staging, intermediate, and mart models. Group them by domain.
```

---

## Step 2 - Inventory the models

Exercises `search` plus folder and tag grouping. This is where the project goes from "a folder I just cloned" to "a map I can read." dbt Wizard returns the model list bucketed two ways at once, by layer (staging vs. intermediate vs. mart) and by domain (customers, orders, products, etc.), so the user can see both axes of the project on one screen.

When the list returns, confirm in one line:

- The staging layer has roughly one model per source table. That's the convention, and a violation here is a tell.
- The intermediate layer has the join-and-aggregate work.
- The marts are the consumer-facing tables a stakeholder or BI tool would actually query.

If any domain is missing from a layer that should obviously have it (e.g., orders has staging and marts but no intermediate), flag it now. That gap is either a deliberate design choice or a piece of unfinished work, and either way it's onboarding intel. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Show me the lineage, grain, and key columns for the orders mart model.
```

---

## Step 3 - Deep-dive on one mart

Exercises `describe` and `lineage`. We pick the orders mart specifically because it sits at the busiest intersection of the project. Every retail dbt project has an orders fact, and it tends to be the model with the widest upstream lineage and the most downstream consumers. If the user can read this one model, they can read any of the others.

When the response returns, confirm in one line:

- The **grain** of the orders mart. Is it one row per order, one row per order line, or one row per order x something else?
- The **upstream lineage**: which staging and intermediate models feed it.
- The **key columns**: the primary key, the foreign keys that join out to other marts, and the headline measures.

The grain question is the one most new engineers skip and then regret. Naming it out loud here saves an hour later when a join produces a row count that doesn't match expectations. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Show me a 10-row sample of the orders mart and the distinct values in the order_status column.
```

---

## Step 4 - Look at the actual data

Exercises `warehouse` for a live sample of the mart and a `select distinct` against the status column. The point of this step is to make the project real. Up to now, the project has been schemas and DAG diagrams. Now it's rows.

The distinct-values check on `order_status` is the load-bearing part of this step. Without it, Day-1 attendees will reflexively write filters like `where order_status = 'completed'` or `where order_status = 'shipped'`, values they made up from how they think retail systems should label orders. The real values in this project might be `delivered`, `in_progress`, `cancelled`, `returned`, or something entirely domain-specific. Reading the distinct values directly is a 10-second habit that prevents a class of silent-wrong-result bugs that can persist for weeks.

When the response returns:

- Read the 10 sample rows and confirm the columns from Step 3 are populated as expected.
- Read the distinct `order_status` values and **write them down**. They are now your reference list for any filter you write against orders for the rest of the lab.

Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
What tests and contracts are defined on the orders model? Are any currently failing?
```

---

## Step 5 - Tests and failure signal

Exercises test introspection and `run-results` parsing. dbt Wizard returns every test attached to the orders model (uniqueness, not-null, accepted-values, referential-integrity, plus any custom or contract tests) and cross-references the most recent run results to flag which ones are currently failing.

This step has two payoffs:

- The test list tells the user **what the project's authors decided is true** about this model. A `unique` test on `order_id` is a contract; a `not_null` test on `customer_id` is a contract; an `accepted_values` test on `order_status` is the canonical answer to the question you just asked in Step 4.
- The list of **currently failing tests** is the single most useful piece of onboarding intel in the entire lab. Failing tests are where the project's pain points actually live. They tell the new engineer where the data is dirty, which assumptions don't hold, and which areas of the project are likely to be the topic of the first "hey can you take a look at this?" Slack message they'll get.

When the response returns, confirm the test count, the contract status, and the number of currently failing tests. If anything is failing, name the test and the model. That's a candidate for a follow-up ticket, not something to fix mid-lab. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Create a new mart model called orders_by_week that aggregates orders to the week grain with order count, gross revenue, and distinct customers.
```

---

## Step 6 - Ship something small

Exercises file edits and convention-aware model generation. This is the "ship something by Friday" deliverable from the persona, and the design constraints come straight from the project conventions the user just learned in Steps 1-5.

dbt Wizard writes `orders_by_week.sql` into `models/marts/` (or wherever Step 2 said marts live), built on the orders mart from Step 3 (not on staging - we respect the layering). The model emits:

- `order_week`: the week the order was placed, truncated to a consistent week-start (Sunday or Monday, follow project convention if one exists)
- `order_count`: count of orders in that week
- `gross_revenue`: sum of order total in that week
- `distinct_customers`: count of distinct customers who placed at least one order that week

When the file lands, the user spot-checks it against the project conventions surfaced in Steps 1-2: file is in the right folder, naming style matches neighboring marts (snake_case, `_by_` or `_per_` pattern if that's the house style), the upstream `ref()` points at the orders mart, and the SQL uses the same date-truncation function family the rest of the project uses. That's what "convention-aware" means: the model doesn't just work, it looks like the rest of the project. Then ask dbt Wizard - copy this as written, or rephrase it in your own words:

```
Compile and preview orders_by_week. Don't materialize it.
```

---

## Step 7 - Compile and preview (no materialization)

Exercises `dbt_compile` and `dbt_show`. The model compiles, a sample of weekly rows renders, **nothing lands in the warehouse**. That's the safe-sandbox property the persona needs. It's Day 1, and Day 1 is not when you start writing tables into a shared dev schema. The user gets to confirm their first model works without taking on any of the cleanup responsibility that comes with materialized output.

When the preview renders, confirm:

- The row count is plausible (one row per week, so roughly 52 rows per year of order history).
- `order_count`, `gross_revenue`, and `distinct_customers` are all populated with sane non-zero values.
- The week column is a date, not a string, and the truncation looks right (every value is a week-start, no mid-week dates).

If anything looks off, ask dbt Wizard to explain the discrepancy before deciding whether to edit the model. Do not materialize. The deliverable for this lab is the previewed, compiled, reviewable `orders_by_week.sql` file in the repo, not a built table.

---

## Wrap-up

The user started the lab knowing nothing about this dbt project and ended it having toured the layering, inventoried every model by layer and domain, read the grain and lineage of the headline mart, sampled real rows and pinned down the actual `order_status` values, mapped the test coverage and the currently failing tests, and shipped a brand-new convention-aware mart model that compiles cleanly and previews correctly. All without materializing anything into a shared schema.

Done by hand, the everyday first-week onboarding takes most engineers a week or two of grepping, asking teammates, and reading README files that are 18 months out of date. dbt Wizard collapses it into a guided session that hands the new engineer a real map of the project plus a small first-PR-style deliverable they can open a review on.

---

## Final artifact

- `models/marts/orders_by_week.sql`: a new mart model aggregating orders to the week grain with `order_count`, `gross_revenue`, and `distinct_customers`. Compiled and previewed successfully. **Not materialized**. This is a Day-1 deliverable that lives in the repo as a reviewable file, not as a table in a shared schema.

---

## References

- `references/dbt_wizard_setup.md`: install, run, config, and auth requirements for dbt Wizard.
