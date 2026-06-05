# Full Lab Environment Reset Guide

Use this when you want Snowflake and the local project to match the clean pre-scenario state of the lab.

This reset is appropriate before validating the whole lab end-to-end or preparing a fresh instructor/demo environment.

## Design principle

This guide must remain independent of the project's current model set. Do not add reset steps that name specific dbt models, model files, or scenario-created artifacts. If models are changed, renamed, added, or removed later, this reset should still work because it resets the git checkout, raw source schema, and dbt target schemas by convention.


## Protected primary source schema

The primary raw source schema for this project is:

```text
hol_dbx_catalog.hol_2026_retail
```

Never drop this schema in an agent/user reset flow, even if the user has permission. Full environment resets may recreate the tables inside this schema by running the approved `ddl.sql` and `dml.sql` scripts, but the reset instructions must not include `DROP SCHEMA` for `hol_2026_retail`.

## What this resets

- Local git working tree
- Local dbt artifacts
- Raw Snowflake source schema data
- dbt-built schemas for the current lab user

## Assumptions

- Repository branch: `main`
- Source database: `hol_dbx_catalog`
- Raw source schema: `hol_2026_retail`
- dbt schemas are generated with this pattern:

```text
<target_schema>_staging
<target_schema>_intermediate
<target_schema>_marts
<target_schema>_marketing
```

For example, if the dbt target schema is `JI`, dbt creates:

```text
JI_staging
JI_intermediate
JI_marts
JI_marketing
```

## 1. Reset local project files

From the project root:

```bash
git switch main
git pull
git status
```

If there are local edits that should be discarded:

```bash
git restore .
git clean -nd
```

Review the `git clean -nd` output. If it only lists files safe to delete:

```bash
git clean -fd
```

Remove local dbt artifacts:

```bash
rm -rf target
```

Confirm the repo is clean:

```bash
git status
```

Expected:

```text
nothing to commit, working tree clean
```

## 2. Reset raw Snowflake source tables

Run the DDL script first:

```sql
-- lab_reference/lab_scripts/ddl.sql
```

Then run the DML script:

```sql
-- lab_reference/lab_scripts/dml.sql
```

These scripts reset and repopulate:

```text
hol_dbx_catalog.hol_2026_retail
```

`ddl.sql` recreates the source tables with `CREATE OR REPLACE TABLE`.

`dml.sql` reloads deterministic demo data.

## 3. Drop dbt-built schemas for the lab user

This step intentionally drops schemas by dbt schema convention, not by model name. That keeps the reset stable even if the project model list changes later.

Replace `<target_schema>` with the lab user's dbt target schema prefix.

```sql
drop schema if exists hol_dbx_catalog.<target_schema>_staging cascade;
drop schema if exists hol_dbx_catalog.<target_schema>_intermediate cascade;
drop schema if exists hol_dbx_catalog.<target_schema>_marts cascade;
drop schema if exists hol_dbx_catalog.<target_schema>_marketing cascade;
```

Example for target schema `JI`:

```sql
drop schema if exists hol_dbx_catalog.JI_staging cascade;
drop schema if exists hol_dbx_catalog.JI_intermediate cascade;
drop schema if exists hol_dbx_catalog.JI_marts cascade;
drop schema if exists hol_dbx_catalog.JI_marketing cascade;
```

Only drop schemas that belong to the lab user being reset. Never drop `hol_dbx_catalog.hol_2026_retail`.

## 4. Rebuild clean dbt baseline

From the project root:

```bash
dbt build
```

This rebuilds the project from clean `main` using the current dbt target.

## 5. Validate the reset

Check local repo state:

```bash
git status
```

Expected:

```text
nothing to commit, working tree clean
```

Optional compile smoke test:

```bash
dbt compile
```

Optional model list check:

```bash
dbt ls --resource-type model
```

## Expected final state

- Local repo matches clean `main`
- Raw Snowflake source schema is reloaded from deterministic scripts
- dbt-built schemas are freshly rebuilt
- No local scenario edits remain because the repo was restored to clean `main`
- Environment is ready for a full end-to-end lab test
