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

### 3. Sync local Wizard skills

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

Then make the Wizard user skills directory match this repo. Remove stale non-system skill entries, preserve `.system`, and install/update only `lab` and `lab_init`:

```bash
python3 - <<'PY'
from pathlib import Path
import filecmp
import os
import shutil

repo_skills = Path('skills').resolve()
wizard_home = Path(os.environ.get('DBT_WIZARD_HOME', str(Path.home() / '.dbt' / 'wizard')))
wizard_skills = wizard_home / 'skills'
expected = {p.name for p in repo_skills.iterdir() if p.is_dir() and (p / 'SKILL.md').exists()}

if expected != {'lab', 'lab_init'}:
    raise SystemExit(f'Expected repo skills lab and lab_init, found: {sorted(expected)}')

wizard_skills.mkdir(parents=True, exist_ok=True)

def remove_path(path: Path) -> None:
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    else:
        path.unlink()

def dirs_match(left: Path, right: Path) -> bool:
    cmp = filecmp.dircmp(left, right, ignore=['.DS_Store', '__pycache__'])
    if cmp.left_only or cmp.right_only or cmp.diff_files or cmp.funny_files:
        return False
    return all(dirs_match(Path(cmp.left) / name, Path(cmp.right) / name) for name in cmp.common_dirs)

for entry in wizard_skills.iterdir():
    if entry.name in {'.system', '.DS_Store', '__pycache__'}:
        continue
    if entry.name not in expected:
        remove_path(entry)

for name in sorted(expected):
    src = repo_skills / name
    dest = wizard_skills / name
    if dest.exists() and dest.is_dir() and dirs_match(src, dest):
        continue
    if dest.exists() or dest.is_symlink():
        remove_path(dest)
    shutil.copytree(src, dest, ignore=shutil.ignore_patterns('.DS_Store', '__pycache__', '*.pyc'))

print('Wizard skills synced:', ', '.join(sorted(expected)))
PY
```

Verify the installed non-system skills:

```bash
find "${DBT_WIZARD_HOME:-$HOME/.dbt/wizard}/skills" -mindepth 1 -maxdepth 2 -name SKILL.md | grep -v '/.system/' | sort
```

Expected:

```text
~/.dbt/wizard/skills/lab/SKILL.md
~/.dbt/wizard/skills/lab_init/SKILL.md
```

### 4. Configure repo-scoped lab permissions

Configure Wizard for this repo so attendees do not have to approve every command during the timed workshop. Keep this project-scoped rather than global:

```bash
mkdir -p .dbt/wizard
cat > .dbt/wizard/config.toml << TOML
# Snowflake Summit HOL lab repo is pre-approved so attendees do not have to
# approve every command during the timed workshop.
approval_policy = "never"
sandbox_mode = "danger-full-access"
TOML
chmod 600 .dbt/wizard/config.toml
```

### 5. Identify active dbt target schema

Run:

```bash
uvx --from dbt-snowflake dbt debug
```

Use the active `database` and `schema` from the connection block. The schema is the target prefix used for cleanup.

### 6. Drop only dbt-managed dev schemas

Using the warehouse mutation tool, drop these four schemas in the active database, replacing `<database>` and `<target>` from dbt debug:

```sql
drop schema if exists <database>.<target>_staging cascade;
drop schema if exists <database>.<target>_intermediate cascade;
drop schema if exists <database>.<target>_marts cascade;
drop schema if exists <database>.<target>_marketing cascade;
```

Run each statement separately if the tool does not allow multi-statement execution.

### 7. Rebuild the baseline project

Run:

```bash
uvx --from dbt-snowflake dbt build
```

If the build succeeds, optionally verify the four target schemas are populated via `information_schema.tables`.

### 8. Success response

On success, respond concisely:

```text
Lab init is complete ✅
The repo is on hol_branch, local changes/artifacts are cleared, Wizard lab permissions and skills are synced, dev schemas were reset, and the baseline dbt build passed.
```

Do not show the lab Prompt 1. The user can trigger `$lab` when ready to start the workshop flow.
