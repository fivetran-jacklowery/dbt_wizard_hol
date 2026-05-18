# Single Lab User Reset Guide

Use this between timed lab sessions when the shared computer should be prepared for the next attendee.

This is the fast reset path. It does **not** reload the shared raw source data. It only resets the local project checkout and removes the current lab user's dbt-built schemas.

## Design principle

This guide must remain independent of the project's current model set. Do not add reset steps that name specific dbt models, model files, or scenario-created artifacts. If models are changed, renamed, added, or removed later, this reset should still work because it resets the git checkout and drops dbt target schemas by convention.


## Protected primary source schema

The primary raw source schema for this project is:

```text
SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL
```

Never drop this schema in an agent/user reset flow, even if the user has permission. The single-user reset only removes dbt-created schemas for the current lab user's target schema prefix.

## When to use this

Use this every time a new lab starts, for example every 20 minutes, when you need to reset the generic lab user's environment.

## What this resets

- Local git working tree
- Local dbt artifacts
- The current user's dbt-created schemas:
  - `<target_schema>_staging`
  - `<target_schema>_intermediate`
  - `<target_schema>_marts`
  - `<target_schema>_marketing`

## What this does not reset

- Shared raw source schema: `SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL`
- Shared lab scripts
- Remote git branches
- Other users' dbt schemas

## 1. Reset the local project checkout

From the project root:

```bash
git switch main
git pull
git restore .
git clean -nd
```

Review the dry-run output from `git clean -nd`. If it only lists files safe to delete:

```bash
git clean -fd
```

Remove local dbt artifacts:

```bash
rm -rf target
```

Confirm clean state:

```bash
git status
```

Expected:

```text
nothing to commit, working tree clean
```

## 2. Identify the lab user's dbt target schema prefix

The project uses `generate_schema_name`, so dbt creates schemas using this pattern:

```text
<target_schema>_staging
<target_schema>_intermediate
<target_schema>_marts
<target_schema>_marketing
```

Find the current target schema from the user's dbt profile or by running:

```bash
uvx --from dbt-snowflake dbt debug
```

Look for the active target/schema in the output.

## 3. Drop only that user's dbt schemas

This step intentionally drops schemas by dbt schema convention, not by model name. That keeps the reset stable even if the project model list changes later.

Replace `<target_schema>` with the lab user's target schema prefix.

```sql
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.<target_schema>_staging cascade;
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.<target_schema>_intermediate cascade;
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.<target_schema>_marts cascade;
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.<target_schema>_marketing cascade;
```

Example for target schema `JI`:

```sql
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.JI_staging cascade;
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.JI_intermediate cascade;
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.JI_marts cascade;
drop schema if exists SNOWFLAKE_SUMMIT_2026_HOL_DB.JI_marketing cascade;
```

Do not drop shared source schemas or schemas owned by another attendee. Never drop `SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL`.

## 4. Optional: pre-compile for the next lab

To make sure the local project is ready without creating warehouse objects:

```bash
uvx --from dbt-snowflake dbt compile
```

Do not run `dbt build` here unless the next lab should start with prebuilt dbt models. For a clean attendee experience, leaving dbt schemas absent is usually preferable because the attendee can create models during the lab.

## Fast reset checklist

```text
[ ] git switch main
[ ] git pull
[ ] git restore .
[ ] git clean -nd, then git clean -fd after review
[ ] rm -rf target
[ ] confirm git status is clean
[ ] identify target schema prefix
[ ] drop <target_schema>_staging
[ ] drop <target_schema>_intermediate
[ ] drop <target_schema>_marts
[ ] drop <target_schema>_marketing
[ ] optionally run dbt compile
```

## Expected final state

- Local repo is clean on latest `main`
- No local scenario edits remain because the repo was restored to clean `main`
- The lab user's dbt-created schemas are gone
- Shared raw source data remains intact
- Computer is ready for the next timed lab attendee
