# dbt Wizard - Setup Reference

Quick reference for installing, configuring, and running dbt Wizard before starting an investigation workflow.

## Install

```bash
curl -fsSL https://public.staging.cdn.getdbt.com/dbt-wizard/install/install-wizard.sh | sh
```

## Run

From inside a dbt project directory:

```bash
cd /path/to/dbt_project
dbt-wizard
```

## Configuration

dbt Wizard's config file lives at:

```
~/.dbt/wizard/config.toml
```

Edit this file to adjust model defaults, tool permissions, and warehouse connections.

## Authentication

dbt Wizard requires Google Cloud authentication for its model backend. Run once per machine (or whenever credentials expire):

```bash
gcloud auth application-default login
```

## dbt Core users

If you're on dbt Core (not dbt Cloud), make sure your project's virtualenv has:

```
run-cache>=2.6.1
```

Install with:

```bash
pip install "run-cache>=2.6.1"
```

Without this, dbt Wizard's `dbt_show` and `dbt_compile` tools may fail to retrieve cached run state.

## Troubleshooting

- **"command not found: dbt-wizard"**: Re-run the install script, or check that the install location is on your `PATH`.
- **Auth errors when running a prompt**: Re-run `gcloud auth application-default login`. ADC tokens expire.
- **`dbt_show` returns no rows but the table has data**: Check that your dbt profile points at the right warehouse/schema, and that `run-cache` is installed in the active venv.
- **Scenario 4, `dbt run` succeeds when it should fail**: The instructor's pre-lab column rename did not apply for your user. See `instructor_setup.md` and re-run the rename SQL against your dev schema.
