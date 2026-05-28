---
name: lab_init
description: >
  Reset and prepare the dbt Wizard hands-on lab repo before or after a lab run.
  Use when the user asks to initialize, reset, clean up, prepare the HOL repo,
  clear Snowflake/dev schemas, restore hol_branch, remove local changes, clear
  dbt artifacts, or verify the local lab skills setup.
---

# dbt Wizard HOL — Lab Init

This skill is the all-in-one initializer/cleanup for the hands-on lab repo. It is intentionally destructive: it resets local code, clears dbt artifacts, drops only the lab user's dbt-managed dev schemas, verifies the expected local skill layout, and rebuilds the baseline project.

## Safety contract

- Only operate inside the current repo.
- Never drop `SNOWFLAKE_SUMMIT_2026_HOL_DB.SF_HOL_2026_RETAIL` or any raw/source schema.
- Only drop schemas derived from the active dbt target schema prefix:
  - `<target>_staging`
  - `<target>_intermediate`
  - `<target>_marts`
  - `<target>_marketing`
- Treat this skill trigger as explicit permission to discard local lab changes, but still surface unexpected failures before continuing.
- Keep output quiet. On success, report only a short readiness message.

## Workflow

### 1. Confirm repo and branch

Run:

```bash
pwd
git rev-parse --show-toplevel
git branch --show-current
```

If this is not the dbt Wizard HOL repo, stop and tell the user.

Make sure the working branch is `hol_branch`:

```bash
git checkout hol_branch
```

If `origin/hol_branch` is available, update to it:

```bash
git fetch origin hol_branch
git reset --hard origin/hol_branch
```

If network/fetch is unavailable, reset to the local `hol_branch` instead:

```bash
git reset --hard hol_branch
```

### 2. Clear local repo state and dbt artifacts

Run:

```bash
git restore .
git clean -fd
rm -rf target
```

Then verify:

```bash
git status --short
```

Expected: no output.

### 3. Verify local skill layout

The repo should expose exactly two local lab skills:

```text
skills/lab/SKILL.md
skills/lab_init/SKILL.md
```

Run:

```bash
find skills -mindepth 2 -maxdepth 2 -name SKILL.md | sort
```

If the result differs, stop and surface the mismatch. There should be no root-level `skills/SKILL.md`.

Also inspect the Wizard user skills directory, if present:

```bash
find "${DBT_WIZARD_HOME:-$HOME/.dbt/wizard}/skills" -mindepth 1 -maxdepth 2 -name SKILL.md | sort
```

Ignore system skills under `.system`. Any non-system local skill should correspond to this repo's two lab skills (`lab` and `lab_init`). Do not delete user skills automatically; report mismatches so the instructor can decide whether to remove or reinstall them.

### 4. Identify active dbt target schema

Run:

```bash
uvx --from dbt-snowflake dbt debug
```

Use the active `database` and `schema` from the connection block. The schema is the target prefix used for cleanup.

### 5. Drop only dbt-managed dev schemas

Using the warehouse mutation tool, drop these four schemas in the active database, replacing `<database>` and `<target>` from dbt debug:

```sql
drop schema if exists <database>.<target>_staging cascade;
drop schema if exists <database>.<target>_intermediate cascade;
drop schema if exists <database>.<target>_marts cascade;
drop schema if exists <database>.<target>_marketing cascade;
```

Run each statement separately if the tool does not allow multi-statement execution.

### 6. Rebuild the baseline project

Run:

```bash
uvx --from dbt-snowflake dbt build
```

If the build succeeds, optionally verify the four target schemas are populated via `information_schema.tables`.

### 7. Success response

On success, respond concisely:

```text
Lab init is complete ✅
The repo is on hol_branch, local changes/artifacts are cleared, the two lab skills are present, dev schemas were reset, and the baseline dbt build passed.
```

Do not show the lab Prompt 1. The user can trigger `$lab` when ready to start the workshop flow.
