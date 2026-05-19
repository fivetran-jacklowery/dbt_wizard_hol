---
name: hol-instructor-setup
description: >
  Step-by-step setup guide for instructors of the dbt Wizard Hands-On Lab
  (Snowflake Summit 2026). Walks through Snowflake access, RSA key setup,
  GitHub repo access, dbt environment setup, and VS Code validation.
  Use this skill when an instructor needs to prepare their laptop for the lab.
metadata:
  team: sales-engineering
  owner: "Jack Lowery <jack.lowery@fivetran.com>"
  short-description: Instructor laptop setup for dbt Wizard HOL at Snowflake Summit 2026
---

# dbt Wizard HOL — Instructor Setup

You are guiding a **lab instructor** through setting up their personal laptop to run and teach the dbt Wizard Hands-On Lab at Snowflake Summit 2026. Work through the steps below in order. Complete each step and confirm success before moving to the next. Be encouraging — this is a varied environment and some friction is expected.

If at any point the user is stuck and you cannot resolve it, tell them to **message Jack Lowery on Slack**.

---

## Step 1 — Verify Snowflake Access

Tell the user:

> "Let's start by confirming you can log into the lab Snowflake account. Open your browser and go to:
>
> **https://GQ81837-SALES_ENG_TESTING_AWS.snowflakecomputing.com**
>
> - **Username:** your work email (try all lowercase if it doesn't work)
> - **Password:** `SnowLab2026!`
>
> You'll be prompted to set a new password on first login — go ahead and do that.
>
> Let me know once you're in, or if you hit any issues."

Wait for confirmation.

- If they confirm they're in → proceed to Step 2.
- If they cannot log in → tell them to message **Jack Lowery on Slack** with the error they're seeing before continuing.

---

## Step 2 — RSA Key Check

Tell the user you're going to check their machine for the required RSA key pair, then run:

```bash
ls ~/.ssh/rsa_key.p8 ~/.ssh/rsa_key.pub 2>&1
```

**If both files exist:**
- Run the following to display the public key:
  ```bash
  cat ~/.ssh/rsa_key.pub
  ```
- Show the output to the user and say:
  > "Found your RSA key pair. Copy the public key above and send it to **Jack Lowery on Slack** so he can register it against your Snowflake user. Let me know once Jack confirms it's been added."
- Wait for confirmation before proceeding to Step 3.

**If either file is missing:**
- Tell the user:
  > "I couldn't find your RSA key pair at `~/.ssh/rsa_key.p8` / `~/.ssh/rsa_key.pub`. This is a prerequisite that should have been set up already — it looks like you may be behind on some earlier setup steps. Please message **Jack Lowery on Slack** to get this sorted before continuing."
- Do not proceed until they confirm the keys are in place.

---

## Step 3 — GitHub Repo Access

Tell the user you're testing their SSH access to the lab repo, then run:

```bash
git ls-remote git@github.com:fivetran-jacklowery/dbt_wizard_hol.git 2>&1
```

**If the command succeeds (returns refs):**
- Tell the user:
  > "GitHub access confirmed — you can reach the lab repo."
- Proceed to Step 4.

**If the command fails:**
- Check for their GitHub SSH public key:
  ```bash
  cat ~/.ssh/id_ed25519.pub 2>&1
  ```
- If the key exists, display it and tell the user:
  > "You don't have access to the repo yet. Send the following to **Jack Lowery on Slack**:
  > 1. Your GitHub username
  > 2. This public key:
  > `<key contents>`
  >
  > Jack will add it as a deploy key. Let me know once he confirms."
- If `id_ed25519.pub` doesn't exist either, tell the user:
  > "You don't have an SSH key for GitHub set up on this machine. Message **Jack Lowery on Slack** — you'll need to generate one and have it added to the repo."
- Wait for confirmation before proceeding.

---

## Step 4 — dbt Environment Setup

Tell the user you're checking their dbt setup and setting up an isolated environment under `~/snowsummit2026`.

### 4a — Create folder and venv

```bash
mkdir -p ~/snowsummit2026
```

Check if a venv already exists:
```bash
ls ~/snowsummit2026/venv 2>&1
```

If not, create it:
```bash
python3 -m venv ~/snowsummit2026/venv
```

### 4b — Check dbt Fusion

```bash
~/snowsummit2026/venv/bin/dbt --version 2>&1 || ~/.local/bin/dbt --version 2>&1
```

If dbt Fusion is not found anywhere, install it:
```bash
curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh | sh -s -- --update
export PATH="$HOME/.local/bin:$PATH"
```

### 4c — Check dbt Wizard

```bash
~/.local/bin/dbt-wizard --version 2>&1
```

If not found, install it:
```bash
curl -fsSL https://public.staging.cdn.getdbt.com/dbt-wizard/install/install-wizard.sh | sh
export PATH="$HOME/.local/bin:$PATH"
```

### 4d — Check profiles.yml

```bash
cat ~/.dbt/profiles.yml 2>&1
```

**If it exists:** show the user a summary of what's in it (target, account, schema) and confirm it looks right for the lab environment (`GQ81837-SALES_ENG_TESTING_AWS`, database `snowflake_summit_2026_hol_db`). If it's pointing elsewhere, ask the user if they want to add a lab profile without overwriting theirs.

**If it doesn't exist:** tell the user you'll create one and ask:
> "I need a few details to set up your dbt profile:
> 1. What is your work email? (e.g. `jack.lowery@fivetran.com`)
> 2. What is the passphrase for your RSA key (`~/.ssh/rsa_key.p8`)?
>
> I'll derive your schema name from your name automatically."

Once you have their email:
- Derive `FIRST_LAST` from the name portion of the email (e.g. `jack.lowery@fivetran.com` → `jack_lowery`)
- Schema = `jack_lowery_dev`

Write `~/.dbt/profiles.yml`:

```yaml
dbt_hands_on_lab_profile:
  outputs:
    dev:
      account: GQ81837-SALES_ENG_TESTING_AWS
      database: snowflake_summit_2026_hol_db
      private_key_passphrase: <their passphrase>
      private_key_path: /Users/<username>/.ssh/rsa_key.p8
      role: lab_user_role
      schema: <first_last>_dev
      threads: 4
      type: snowflake
      user: <their email>
      warehouse: default
    prod:
      account: GQ81837-SALES_ENG_TESTING_AWS
      database: snowflake_summit_2026_hol_db
      private_key_passphrase: <their passphrase>
      private_key_path: /Users/<username>/.ssh/rsa_key.p8
      role: lab_user_role
      schema: <first_last>_dev
      threads: 4
      type: snowflake
      user: <their email>
      warehouse: default
  target: dev
```

Set permissions: `chmod 600 ~/.dbt/profiles.yml`

### 4e — Report back

Give the user a clear summary:
> "Here's what I found / set up:
> - dbt Fusion: ✓ installed (version X) / ✗ installed fresh
> - dbt Wizard: ✓ installed / ✗ installed fresh
> - profiles.yml: ✓ already existed / ✓ created fresh"

---

## Step 5 — Clone Repo and Validate in VS Code

### 5a — Clone the project

Check if it's already cloned:
```bash
ls ~/snowsummit2026/dbt_wizard_hol/.git 2>&1
```

If not:
```bash
ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
git clone git@github.com:fivetran-jacklowery/dbt_wizard_hol.git ~/snowsummit2026/dbt_wizard_hol
```

### 5b — Open in VS Code

```bash
code ~/snowsummit2026/dbt_wizard_hol
```

If `code` command is not found, tell the user:
> "VS Code doesn't have the `code` CLI command set up. Open VS Code manually, then go to **Cmd+Shift+P** and run **'Shell Command: Install code command in PATH'**, then come back and let me know."

Wait for confirmation that VS Code is open before continuing.

### 5c — Run dbt debug

Tell the user to open the terminal inside VS Code and run:

```bash
source ~/snowsummit2026/venv/bin/activate
cd ~/snowsummit2026/dbt_wizard_hol
dbt debug
```

**If dbt debug passes:**
> "You're all set! Your instructor environment is fully configured and connected to Snowflake. You're ready to run the lab."

**If dbt debug fails:**
- Show the error and help troubleshoot:
  - `Invalid private key` → wrong passphrase in profiles.yml
  - `IP policy` or `network` error → VPN or network issue
  - `User not found` → RSA key not registered yet in Snowflake (check with Jack)
  - `Could not connect` → wrong account identifier in profiles.yml
- If you cannot resolve it, tell them to message **Jack Lowery on Slack** with the full error output.
