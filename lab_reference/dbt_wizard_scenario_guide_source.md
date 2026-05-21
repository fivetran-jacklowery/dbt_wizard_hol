# Fivetran dbt Wizard Scenario Prompt Guide

## Business Value Mapped to Technical Functionality

# Purpose

This guide provides short, booth-friendly prompts that build on each other within each business scenario. The goal is to show how dbt Wizard turns a business problem into a safe dbt workflow: discover only the relevant assets, inspect the minimum data needed, build the model, and validate the result.

Each scenario connects a concrete business outcome to the dbt Wizard functionality used to deliver it.

# Recommended Booth Pattern

* New User Onboarding  
* Scenario 2  
* Scenario 3

Scenario 1 and Scenario 4 are optional for lab times longer than 20 minutes.

# Onboarding Scenario: New Analytics Engineer

**Persona:** It's your first week at The Builder Depot. You've been handed access to the dbt repo and a vague mandate: "get familiar with the project and ship something small by Friday." You've never seen this codebase before. You'll use dbt Wizard as your onboarding buddy — to orient yourself, learn the conventions, and make your first contribution safely.

**Lab Goal:** Show how dbt Wizard collapses the typical 2-week "where is everything?" onboarding into a single guided session.

| Step | User Prompt | What It Demonstrates | dbt Wizard Functionality |
| :---- | :---- | :---- | :---- |
| 1 | Give me a project summary | A new hire's first question is always "what am I looking at?" Wizard reads the project structure, dbt\_project.yml, and folder layout to give you a plain-English overview — no need to scroll through a README that may not exist. | Project-level status \+ repo summarization |
| 2 | List the staging, intermediate, and mart models. Group them by layer and domain. | Teaches the project's layering convention (staging → intermediate → marts) and shows which business domains are modeled. This is the mental map you'd otherwise build over 2 weeks of Slack questions. | search \+ folder/tag-based model grouping |
| 3 | Show me the lineage, grain, and key columns for the orders mart model. | You pick one mart model and Wizard tells you (a) what feeds into it, (b) what one row represents, and (c) what each column means. This is the "read one model deeply" exercise every new AE does — automated. | describe \+ lineage |
| 4 | Show me a 10-row sample of the orders mart and the distinct values in the order\_status column. | Bridges the gap between schema and reality. New hires often write incorrect filters because they assumed a status value that doesn't exist — this step prevents that on Day 1\. | warehouse — live sample \+ distinct-value queries |
| 5 | What tests and contracts are defined on the orders model? Are any currently failing? | Shows the new hire what the team considers correct — unique keys, not-null constraints, accepted values, freshness SLAs. Failing tests are an immediate signal of where the project's pain points live. | Test introspection \+ run-results inspection |
| 6 | Create a new mart model called orders\_by\_week that aggregates orders to the week grain with order count, gross revenue, and distinct customers. | Your first PR-worthy artifact. Wizard scaffolds the model following the project's existing conventions so you don't have to reverse-engineer the style guide. | File-edit \+ model-generation, convention-aware |
| 7 | Compile and preview orders\_by\_week. Don't materialize it. | Closes the loop: you wrote something, you validated it works, you saw the sample output — all without writing to the warehouse or opening a PR. | dbt\_compile \+ dbt\_show |

# 

# Scenario 2: Extending Orders with Support Ticket Context

## Business Value

The Director of Operations needs to flag problematic orders for postmortem review. retail.RET\_TICKETS is already landing in Snowflake via Fivetran and is staged as stg\_tickets, but it has never been wired into int\_orders\_enriched. The goal is to add ticket\_count, has\_open\_ticket\_flag, and last\_ticket\_status to the order model without breaking the downstream consumers that already depend on it.

## Prompt Flow

| Step | User Prompt | What It Demonstrates | dbt Wizard Functionality |
| :---- | :---- | :---- | :---- |
| 1 | Find enriched orders and show me what it currently produces, its grain, and which models depend on it downstream. | Starts from the model being extended, confirms the one-row-per-order contract, and surfaces downstream consumers before any edit. | search, describe, lineage |
| 2 | Find ticket data in our warehouse that is not connected to enriched orders yet. | Identifies retail.RET\_TICKETS and stg\_tickets as available ticket data not yet connected to enriched orders. | status, search, source/model cross-reference |
| 3 | Count rows in stg\_tickets with a non-null order\_id, count distinct ticket order\_ids, and count how many of those order\_ids match an order\_id from enriched orders. What is the cardinality of stg\_tickets to int\_orders\_enriched? | Validates grain, coverage, and join-key compatibility before any SQL is written — prevents silent fan-out and mostly-null new columns at the order level. | describe, warehouse, join-key inspection |
| 4 | Update enriched orders to add ticket count, has\_open\_ticket\_flag, and last\_ticket\_status from stg\_tickets. Then aggregate stg\_tickets to one row per order\_id before joining. Use a left join so orders without tickets still appear. Preserve every column. | Modifies the existing model file in place, preserving its public column contract; LEFT JOIN \+ pre-aggregation enforce the two non-negotiables. | file edits on existing model |
| 5 | Compile enriched orders, and every dependent model downstream. Then preview 20 rows from this model ordered by order\_id. Do not materialize anything. | Compile-time guarantee across the full lineage — catches column-contract breaks before they hit a dashboard; null-safe behavior for unmatched orders is spot-checked in the preview. | dbt\_compile across lineage, dbt\_show |

## Expected Model Output

* int\_orders\_enriched emits ticket\_count, has\_open\_ticket\_flag, and last\_ticket\_status from stg\_tickets in the dev schema.  
* Existing column contract preserved — downstream models compile without changes.  
* Row count unchanged from pre-edit baseline (LEFT JOIN \+ pre-aggregation held).  
* Ticket columns populated for matched orders; null-safe values for orders with no ticket.

## Business-to-Technical Link

The Director of Ops asked "which orders have open tickets?" and the answer was sitting in a Fivetran-synced table no one had wired up. Done by hand, this task takes half a day of grepping plus a deferred Slack thread when a downstream dashboard breaks. dbt Wizard collapses it: surface retail.RET\_TICKETS and stg\_tickets alongside int\_orders\_enriched, validate the order-grain join, edit in place, and confirm the full downstream lineage still compiles — all in minutes.

# 

# Scenario 3: Broken Product Model from a Source Column Rename

## Business Value

retail.RET\_PRODUCTS.brand was renamed brand\_name overnight. stg\_products is broken and the blast radius spans \~8 downstream files across intermediates and marts. The fix preserves the public dbt column name via select brand\_name as brand so no downstream model has to change. The morning standup is in 30 minutes.

## Prompt Flow

| Step | User Prompt | What It Demonstrates | dbt Wizard Functionality |
| :---- | :---- | :---- | :---- |
| 0 | (Run in the terminal, not in Wizard, `cd /Users/youraccount/snowsummit2026/dbt_wizard_hol`And then Run `dbt run --select stg_products+` | Reproduces the failure live so the rest of the workflow is grounded in a real error message, not a hypothetical. | terminal — dbt run |
| 1 | My dbt run just failed. Read the most recent run results and tell me which model failed, what the error was, and which upstream source or column the error references. | Reads run-results, parses the error, and names stg\_products and the missing column brand — no scrolling stack traces. | status, dbt\_show, error parsing |
| 2 | Describe the current schema of retail.RET\_PRODUCTS. List every column that exists today. | Pulls the live column list from Snowflake and converts "something changed" into "brand was renamed brand\_name." | describe, warehouse |
| 3 | Show me every model, source definition, and test in this project that references the product column brand. I need a complete blast-radius list before I change anything. | Maps the full product blast radius — stg\_products and downstream intermediates and marts. This is a risk check, not a request to edit every downstream file. | search, lineage, impact analysis |
| 4 | Update stg\_products to read brand\_name from retail.RET\_PRODUCTS but keep the public column name as brand. Preserve the downstream contract so models that already select brand do not need to change. | Applies the alias-preserving staging fix. Public column brand is unchanged; no downstream model has to be edited. | file edit on staging model |
| 5 | Compile stg\_products and every downstream product model, then preview the first 10 rows of stg\_products ordered deterministically by product\_id. Do not materialize anything yet. | Compile across the lineage is the smoke test — any missed source-side brand reference fails here, not in the warehouse. Preview confirms brand\_name is flowing through as brand. | dbt\_compile, dbt\_show |
| 6 | (Run in the terminal, not in Wizard) dbt run \--select stg\_products+ | Closes the loop on the pre-step failure — green run confirms the fix end-to-end. | terminal — dbt run |

## Expected Outcome

* stg\_products compiles and runs green.  
* All \~8 downstream models (intermediates and marts) resolve without further edits.  
* Public column brand preserved via select brand\_name as brand.  
* Column tests in \_staging\_\_models.yml pass.  
* No source-side references to the missing RET\_PRODUCTS.brand remain; public dbt column brand is preserved.

## Business-to-Technical Link

retail.RET\_PRODUCTS.brand was renamed brand\_name overnight and stg\_products took down \~8 downstream models. dbt Wizard reads the error, surfaces brand\_name in the live RET\_PRODUCTS schema, maps every downstream dependency that relies on the public brand column, and applies select brand\_name as brand in staging — broken pipeline to green re-run in minutes without changing downstream models.

# 

# REFERENCE \- Optional Scenarios

# Scenario 1: Inventory Misallocation

## Business Value

Help operations quickly identify where missing inventory went so the business can correct a shipping issue before a major sale.

## Prompt Flow

| Step | User Prompt | What It Demonstrates | dbt Wizard Functionality |
| :---- | :---- | :---- | :---- |
| 1 | Check Product 42 shipments and inventory. Expected quantity is 200 per store. | Interrogates only the data needed for the focal item and expected allocation — skipping straight to the business question. | warehouse, dbt\_show |
| 2 | Create a model showing stores with the incorrect number of units of Product 42\. | Builds the business answer: which stores are over-counted or under-counted against the expected allocation. | file edits, dbt model creation |
| 3 | Compile and preview the model. Do not materialize it yet. | Validates safely before writing anything to the warehouse. | dbt\_compile, dbt\_show |
| 4 | Materialize the view. | Commits the validated model to the warehouse. | dbt\_run |

## Expected Model Output

* store name  
* city or region  
* item name  
* actual inventory count  
* expected count, fixed at 200  
* variance quantity  
* variance direction showing over-count or under-count

## Business-to-Technical Link

The business needs to find the missing shipment. dbt Wizard demonstrates targeted data inspection, model creation, safe preview, and materialization. Variance-focused outputs should include stores where actual inventory differs from expected inventory; matched stores can appear in completeness checks but should not be treated as variance stores.

# 

# Scenario 4: Optional Marketing Targeted Campaigns

## Business Value

Help Marketing identify high-value customers for targeted campaigns using recent purchase behavior by store.

## Prompt Flow

| Step | User Prompt | What It Demonstrates | dbt Wizard Functionality |
| :---- | :---- | :---- | :---- |
| 1 | Check recent order dates and category values needed for a 180-day segmentation model. | Inspects only the data required for the rolling window and category-loyal logic — the values that will drive filter conditions in the models. | warehouse, dbt\_show |
| 2 | Create a 180-day customer activity model by store. | Creates the reusable activity layer needed for segmentation. | file edits, dbt model creation |
| 3 | Create a segment model for VIPs, big spenders, and category-loyal customers. | Creates the business-facing targeting asset as a second model that refs the activity layer — demonstrating multi-model chained design. | file edits, dbt model creation |
| 4 | Compile and preview the segment model. Exclude customers with no segment. | Validates the final targeted campaign list safely, with a business-meaningful filter applied at preview time. | dbt\_compile, dbt\_show |

## Segment Definitions

* VIP: average transaction value greater than 100 dollars and at least 3 transactions  
* Big spender: at least one transaction greater than 300 dollars  
* Category-loyal: at least 10 transactions in the same category  
* Customers can appear in multiple segments

## Expected Model Output

* customer identifier  
* store name  
* segment name  
* supporting metrics such as transaction count, average transaction value, max transaction value, category, and category transaction count

## Business-to-Technical Link

Marketing needs a usable campaign audience. dbt Wizard demonstrates targeted data inspection, multi-model chained design, and safe preview of the final campaign list.  