---
name: lab_init
description: >
  Reset and prepare the dbt Wizard hands-on lab repo before or after a lab run.
  Use when the user asks to initialize, reset, clean up, prepare the HOL repo,
  clear Databricks/dev schemas, restore hol_dbx, remove local changes, clear
  dbt artifacts, or verify the local lab skills setup.
---

# dbt Wizard HOL — Lab Init

This skill is the all-in-one initializer/cleanup for the hands-on lab repo. It is intentionally destructive: it resets local code, clears dbt artifacts, drops only the lab user's dbt-managed dev schemas, verifies the expected local skill layout, and rebuilds the baseline project.

## Safety contract

- Only operate inside the current repo.
- Never drop `hol_dbx_catalog.hol_2026_retail` or any raw/source schema.
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

Make sure the working branch is `hol_dbx`:

```bash
git checkout hol_dbx
```

If `origin/hol_dbx` is available, update to it:

```bash
git fetch origin hol_dbx
git reset --hard origin/hol_dbx
```

If network/fetch is unavailable, reset to the local `hol_dbx` instead:

```bash
git reset --hard hol_dbx
```

Immediately after the branch is confirmed and reset, sync the Wizard skills from
the repo so all subsequent steps run with skills from the correct branch. Follow
the full skill sync logic from step 3 below, then continue to step 2.

### 2. Clear local repo state, dbt artifacts, and Dataface output

Run:

```bash
git restore .
git clean -fd
rm -rf target
```

`git clean -fd` already removes any attendee-created (untracked) faces, and
`git restore .` reverts edits to the committed baseline faces. Also clear the
Dataface render/cache artifacts, which are gitignored and therefore survive a
normal clean — this is what guarantees no stray dashboards or cached query
results carry over between attendees. Note `.dft/` (the `dft serve` query cache,
on by default since dataface 0.1.5) lives at the project root, so clear it
explicitly — otherwise the next attendee can see the previous attendee's cached
board data:

```bash
git clean -fdx faces renders .dft 2>/dev/null || true
git restore faces 2>/dev/null || true
```

Then verify:

```bash
git status --short
```

Expected: no output. The `faces/` directory should now contain only the
committed baseline lab faces.

### 3. Verify local Wizard skills

> Skills were already synced at the end of step 1. This step documents the sync
> logic and serves as a reference if the step 1 sync needs to be retried.

The repo should expose exactly three local lab skills:

```text
skills/lab/SKILL.md
skills/lab_init/SKILL.md
skills/install_dbt_charts/SKILL.md
```

Run:

```bash
find skills -mindepth 2 -maxdepth 2 -name SKILL.md | sort
```

If the result differs, stop and surface the mismatch. There should be no root-level `skills/SKILL.md`.

Then check whether those skills are already installed in the Wizard user skills
directory:

```bash
wizard_skills="${DBT_WIZARD_HOME:-$HOME/.dbt/wizard}/skills"
missing=0

for skill in install_dbt_charts lab lab_init; do
  if [ ! -f "$wizard_skills/$skill/SKILL.md" ]; then
    echo "Missing Wizard skill: $skill"
    missing=1
  fi
done

if [ "$missing" -eq 0 ]; then
  echo "Wizard lab skills already present; skipping skill sync."
fi
```

Expected if the skills are already installed:

```text
Wizard lab skills already present; skipping skill sync.
```

When the skip message appears, continue to step 4. These local lab skills are
installed during setup and should not change during normal attendee resets.

Only if one or more expected skills are missing, install/update the lab skills
from this repo. Remove stale non-system skill entries, preserve `.system`, and
install/update only `lab`, `lab_init`, and `install_dbt_charts`:

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

if expected != {'lab', 'lab_init', 'install_dbt_charts'}:
    raise SystemExit(f'Expected repo skills lab, lab_init, install_dbt_charts, found: {sorted(expected)}')

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

After installing missing skills, verify the installed non-system skills:

```bash
find "${DBT_WIZARD_HOME:-$HOME/.dbt/wizard}/skills" -mindepth 1 -maxdepth 2 -name SKILL.md | grep -v '/.system/' | sort
```

Expected:

```text
~/.dbt/wizard/skills/install_dbt_charts/SKILL.md
~/.dbt/wizard/skills/lab/SKILL.md
~/.dbt/wizard/skills/lab_init/SKILL.md
```

### 4. Configure repo-scoped lab permissions

Configure Wizard for this repo so attendees do not have to approve every command during the timed workshop. Keep this project-scoped rather than global:

```bash
mkdir -p .dbt/wizard
if [ -f .dbt/wizard/config.toml ] \
  && grep -qx 'approval_policy = "never"' .dbt/wizard/config.toml \
  && grep -qx 'sandbox_mode = "danger-full-access"' .dbt/wizard/config.toml; then
  echo "Wizard lab permissions already configured."
else
  cat > .dbt/wizard/config.toml << TOML
# Data + AI Summit HOL lab repo is pre-approved so attendees do not have to
# approve every command during the timed workshop.
approval_policy = "never"
sandbox_mode = "danger-full-access"
TOML
fi
chmod 600 .dbt/wizard/config.toml
```

### 5. Ensure Dataface (dft) is installed

The lab now includes a Dataface ("dbt Charts") section, so `dft` must be present.
Check for it:

```bash
~/summit2026/venv/bin/dft --version 2>/dev/null \
  || dft --version 2>/dev/null \
  || echo "dft missing"
```

If `dft` is missing, install it by running the `$install_dbt_charts` skill, then
continue. Do not hand-roll the install here — that skill is the single source of
truth for the Dataface setup (Python 3.13, `pip install dataface`, `dft init`,
and the VS Code extension).

If `dft` is already installed, confirm the project is still scaffolded
(`dataface.yml` and `faces/` exist from the repo). The faces reset in step 2
already cleared any attendee-created dashboards.

### 6. Identify active dbt target schema

Run:

```bash
dbt debug
```

Use the active `catalog` and `schema` from the connection block. The schema is the target prefix used for cleanup.

### 7. Drop only dbt-managed dev schemas

Use the checked-in `lab_init_drop_dev_schemas` dbt macro. It derives the active
catalog/database and schema from the dbt target, refuses raw/source schemas, and
drops only these generated schemas:

```text
<target>_staging
<target>_intermediate
<target>_marts
<target>_marketing
```

Run:

```bash
dbt run-operation lab_init_drop_dev_schemas
```

If the active target cannot infer the catalog/database, pass the values from
`dbt debug` explicitly:

```bash
dbt run-operation lab_init_drop_dev_schemas --args '{"catalog_name":"<catalog>","target_schema":"<target>"}'
```

### 8. Rebuild the baseline project

Run:

```bash
dbt build
```

If the build succeeds, optionally verify the four target schemas are populated via `information_schema.tables`.

### 9. Success response

On success, respond concisely:

```text
Lab init is complete ✅
The repo is on hol_dbx, local changes/artifacts are cleared, Wizard lab permissions and skills are synced, dev schemas were reset, and the baseline dbt build passed.
```

Do not show the lab Prompt 1. The user can trigger `$lab` when ready to start the workshop flow.
