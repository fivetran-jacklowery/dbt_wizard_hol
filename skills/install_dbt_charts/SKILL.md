---
name: install_dbt_charts
description: >
  Install Dataface ("dbt Charts") into the HOL environment so attendees can build
  declarative YAML dashboards on top of the dbt project. Standardizes on Python
  3.13, pip installs dataface, runs `dft init` (adds skills + appends AGENTS.md,
  no editor-extension auto-install), and installs the Dataface VS Code extension
  from the public download link. Triggers on "$install_dbt_charts",
  "install dbt charts", "set up dataface", "add dataface / dft to the lab".
metadata:
  team: sales-engineering
  owner: "Dave Fowler <dave.fowler@fivetran.com>"
  short-description: Install Dataface (dbt Charts) for the dbt Wizard HOL
---

# Install Dataface (dbt Charts)

You are setting up **Dataface** (`dft`) on top of the existing dbt Wizard HOL
project so the user can build declarative YAML dashboards over the dbt models.
Dataface reads the project's existing `~/.dbt/profiles.yml`, so it connects to
Snowflake the **same way dbt already does** — no new credentials.

Work through the steps in order. Run each command, confirm it succeeded, and
only then move on. Keep output short; on success report a one-line confirmation.

**Prerequisite:** the dbt side of the lab is already working (`dbt debug` passes).
If it doesn't, fix that first — Dataface uses the same profile and will fail to
query data until dbt connects.

---

## Step 1 — Standardize on Python 3.13

Dataface supports Python `>=3.10,<3.14`; we standardize on **3.13**.

Check what's available:

```bash
python3 --version
python3.13 --version 2>/dev/null || echo "no python3.13"
```

If `python3.13` is missing (macOS / Homebrew):

```bash
brew install python@3.13
```

Confirm you have a 3.13 interpreter before continuing.

---

## Step 2 — Install Dataface

Install into a Python environment that the `dft` command will run from. To keep
it isolated and aligned with the lab layout, use a 3.13 venv:

```bash
mkdir -p ~/dataaisummit2026
# (Re)create the venv on 3.13 if it isn't already
python3.13 -m venv ~/dataaisummit2026/dft_venv
source ~/dataaisummit2026/dft_venv/bin/activate
pip install --upgrade pip
pip install "dataface[snowflake]"
```

> The `[snowflake]` extra ships the Snowflake adapter so `dft` can connect on its
> own using `~/.dbt/profiles.yml` (the lab's key-pair auth). Plain
> `pip install dataface` is enough only if `dft` runs inside an environment that
> already has a Snowflake dbt adapter.

### 2b — Put `dft` on PATH (so it works in every terminal)

The venv keeps `dft` isolated, but attendees shouldn't have to activate it. Symlink
the binary into `~/.local/bin`, which `hol_setup.sh` already guarantees is on PATH:

```bash
mkdir -p ~/.local/bin
ln -sf ~/dataaisummit2026/dft_venv/bin/dft ~/.local/bin/dft
```

Now `dft` resolves in any new terminal — no venv activation needed.

Verify (open a fresh shell, or just run):

```bash
dft --version
```

If `dft` is still not found, confirm `~/.local/bin` is on PATH
(`echo $PATH | tr ':' '\n' | grep local/bin`); `hol_setup.sh` adds it to
`~/.zshrc`, so a new terminal will pick it up.

---

## Step 3 — Scaffold the project with `dft init`

Run from the **dbt project root** (where `dbt_project.yml` lives):

```bash
cd "$(git -C . rev-parse --show-toplevel 2>/dev/null || pwd)"
dft init \
  --skills \
  --agents-md \
  --no-vscode \
  --no-cursor \
  --no-mcp \
  --no-claude-md \
  --no-chat-extra \
  --no-with-playground
```

What each flag does (all explicit so the command is non-interactive):

- `--skills` — installs the Dataface workflow skills into the agent skill dirs.
- `--agents-md` — appends the Dataface snippet to `AGENTS.md` (creates it if
  absent; refreshes only the marked section if already present).
- `--no-vscode --no-cursor` — **skip** dft's built-in extension install. That
  path pulls the `.vsix` from the private `fivetran/dataface` repo via `gh`; we
  install from the public link in Step 4 instead.
- `--no-mcp --no-claude-md --no-chat-extra --no-with-playground` — skip the
  extras we don't need for the lab, so nothing prompts.

This creates `faces/` (with a starter `guide.yml`), `faces/partials/`,
`dataface.yml`, and appends to `AGENTS.md`.

Confirm `faces/guide.yml` and `dataface.yml` now exist.

---

## Step 4 — Install the Dataface VS Code extension (public link)

Download the published `.vsix` and install it into VS Code:

```bash
curl -L -o /tmp/dataface-latest.vsix \
  https://storage.googleapis.com/dataface-downloads/dataface-latest.vsix
code --install-extension /tmp/dataface-latest.vsix
```

For Cursor instead of VS Code, swap the last line:

```bash
cursor --install-extension /tmp/dataface-latest.vsix
```

If `code` (or `cursor`) is not found, tell the user to open VS Code, run
**Cmd+Shift+P → "Shell Command: Install 'code' command in PATH"**, then re-run the
install line.

---

## Step 5 — Verify

```bash
dft --version
dft validate faces/guide.yml
```

- `dft validate` should report the starter face is valid.
- For a live check, the user can run `dft serve` (defaults to
  http://127.0.0.1:8000) — it will query Snowflake through the dbt profile.

On success, report:

> "Dataface (dbt Charts) is installed: `dft <version>`, `faces/` scaffolded,
> AGENTS.md updated, and the VS Code extension installed. Run `dft serve` to
> preview dashboards."

---

## Troubleshooting

- **`dft: command not found`** — the PATH symlink from Step 2b is missing or
  `~/.local/bin` isn't on PATH. Re-run
  `ln -sf ~/dataaisummit2026/dft_venv/bin/dft ~/.local/bin/dft` and open a new
  terminal. (Falling back, `source ~/dataaisummit2026/dft_venv/bin/activate` also
  works.)
- **`dft init` prompts despite flags** — you're on an older dataface; upgrade with
  `pip install -U "dataface[snowflake]"` and re-run, or add `--yes` (note `--yes`
  defaults the editor extension to install, so keep `--no-vscode --no-cursor`).
- **`dft serve` / `dft query` errors connecting** — same root cause as a failing
  `dbt debug`. Confirm `~/.dbt/profiles.yml` works for dbt first.
- **VS Code extension didn't appear** — confirm the `code` CLI is on PATH (Step 4
  note) and re-run `code --install-extension /tmp/dataface-latest.vsix`.
