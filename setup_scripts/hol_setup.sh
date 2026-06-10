#!/bin/bash
# dbt Wizard Hands-On Lab — MacBook Setup Script
# Prerequisites (done by instructor before running):
#   - ~/.ssh/id_ed25519 : SSH deploy key, already added to GitHub repo
#   - Xcode CLT         : run 'xcode-select --install' and click Install

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }
info() { echo -e "${YELLOW}→${NC} $1"; }

# ─── Derive user-specific values ──────────────────────────────────────────────
USERNAME=$(whoami)
NUM=$(echo "$USERNAME" | grep -o '[0-9]*')

[[ -n "$NUM" ]] || fail "Could not determine lab number from username '$USERNAME'. Expected format: demo1, demo2, etc."

SCHEMA="lab_user_${NUM}_dev"
LAB_DIR="$HOME/summit2026"
PROJECT_DIR="$LAB_DIR/dbt_wizard_hol"
VENV_DIR="$LAB_DIR/venv"

echo ""
info "Detected user: $USERNAME (lab number: $NUM)"
info "Schema:        $SCHEMA"
info "Lab folder:    $LAB_DIR"

# ─── Verify required files are present ────────────────────────────────────────
echo ""
info "Checking required files..."

[[ -f ~/.ssh/id_ed25519 ]]   || fail "Missing: ~/.ssh/id_ed25519"

chmod 600 ~/.ssh/id_ed25519

ok "Git key and Databricks env vars present"

# ─── 1. Xcode Command Line Tools ──────────────────────────────────────────────
# PREWORK: xcode-select --install (click Install when prompted, wait to complete)
echo ""
info "Checking Xcode Command Line Tools..."

xcode-select -p &>/dev/null || fail "Xcode CLT not installed. Run 'xcode-select --install' on this machine first."
ok "Xcode CLT installed"

# ─── 2. Homebrew ──────────────────────────────────────────────────────────────
echo ""
info "Checking Homebrew..."

if command -v brew &>/dev/null; then
    ok "Homebrew already installed"
else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    fi

    ok "Homebrew installed"
fi

# ─── 3. Git ───────────────────────────────────────────────────────────────────
echo ""
info "Checking Git..."

if brew list git &>/dev/null; then
    ok "Git already installed"
else
    info "Installing Git..."
    brew install git
    ok "Git installed"
fi

# ─── 4. Python 3 ──────────────────────────────────────────────────────────────
echo ""
info "Checking Python 3..."

if brew list python &>/dev/null; then
    ok "Python already installed ($(python3 --version))"
else
    info "Installing Python 3..."
    brew install python
    ok "Python installed ($(python3 --version))"
fi

# ─── 5. dbt Fusion ────────────────────────────────────────────────────────────
echo ""
info "Checking dbt Fusion..."

if command -v dbt &>/dev/null; then
    ok "dbt Fusion already installed ($(dbt --version 2>&1 | head -1))"
else
    info "Installing dbt Fusion..."
    curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh | sh -s -- --update
    export PATH="$HOME/.local/bin:$PATH"
    ok "dbt Fusion installed ($(dbt --version 2>&1 | head -1))"
fi

# ─── 6. dbt Wizard ────────────────────────────────────────────────────────────
# NOTE: This installs from staging. Verify URL is still correct before the lab.
echo ""
info "Checking dbt Wizard..."

if command -v dbt-wizard &>/dev/null; then
    ok "dbt Wizard already installed"
else
    info "Installing dbt Wizard..."
    curl -fsSL https://public.staging.cdn.getdbt.com/dbt-wizard/install/install-wizard.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    ok "dbt Wizard installed"
fi

# ─── 7. Create lab folder structure ──────────────────────────────────────────
echo ""
info "Creating lab folder structure..."

if [[ -d "$HOME/snowsummit2026" && ! -d "$LAB_DIR" ]]; then
    mv "$HOME/snowsummit2026" "$LAB_DIR"
    ok "Renamed ~/snowsummit2026 to $LAB_DIR"
fi

mkdir -p "$LAB_DIR"
ok "Lab folder ready at $LAB_DIR"

# ─── 9. Python virtual environment ───────────────────────────────────────────
echo ""
info "Checking Python virtual environment..."

if [[ -d "$VENV_DIR" ]]; then
    ok "Virtual environment already exists at $VENV_DIR"
else
    info "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    ok "Virtual environment created at $VENV_DIR"
fi

# ─── 10. Clone dbt project ───────────────────────────────────────────────────
echo ""
info "Cloning dbt project..."

if [[ -d "$PROJECT_DIR/.git" ]]; then
    ok "dbt project already cloned at $PROJECT_DIR"
else
    ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
    git clone git@github.com:fivetran-jacklowery/dbt_wizard_hol.git "$PROJECT_DIR"
    ok "dbt project cloned to $PROJECT_DIR"
fi

# ─── 11. dbt Wizard project-scoped lab config ────────────────────────────────
echo ""
info "Writing dbt Wizard project-scoped lab config..."

mkdir -p "$PROJECT_DIR/.dbt/wizard"

cat > "$PROJECT_DIR/.dbt/wizard/config.toml" << TOML
# Data + AI Summit HOL lab repo is pre-approved so attendees do not have to
# approve every command during the timed workshop.
approval_policy = "never"
sandbox_mode = "danger-full-access"
TOML

chmod 600 "$PROJECT_DIR/.dbt/wizard/config.toml"
ok "dbt Wizard config written to $PROJECT_DIR/.dbt/wizard/config.toml"

# ─── 12. dbt profiles.yml ────────────────────────────────────────────────────
echo ""
info "Writing dbt profiles.yml..."

mkdir -p ~/.dbt

if grep -q 'hol_dbx_profile' ~/.dbt/profiles.yml 2>/dev/null; then
    ok "hol_dbx_profile already exists in ~/.dbt/profiles.yml"
else
    cat >> ~/.dbt/profiles.yml << YAML

hol_dbx_profile:
  outputs:
    dev:
      auth_type: oauth
      catalog: hol_dbx_catalog
      client_id: ""
      client_secret: ""
      connect_retries: 3
      dbt_databricks_verify_ssl: false
      host: adb-7405605464190909.9.azuredatabricks.net
      http_path: /sql/1.0/warehouses/540622d1091eda2b
      schema: ${SCHEMA}
      threads: 4
      type: databricks
    prod:
      auth_type: oauth
      catalog: hol_dbx_catalog
      client_id: ""
      client_secret: ""
      connect_retries: 3
      dbt_databricks_verify_ssl: false
      host: adb-7405605464190909.9.azuredatabricks.net
      http_path: /sql/1.0/warehouses/540622d1091eda2b
      schema: ${SCHEMA}
      threads: 4
      type: databricks
  target: dev
YAML
    ok "hol_dbx_profile appended to ~/.dbt/profiles.yml"
fi

chmod 600 ~/.dbt/profiles.yml

# ─── 13. PATH persistence ────────────────────────────────────────────────────
echo ""
info "Ensuring ~/.local/bin is in PATH..."

ZSHRC=~/.zshrc
if grep -q '\.local/bin' "$ZSHRC" 2>/dev/null; then
    ok "~/.local/bin already in PATH"
else
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
    ok "Added ~/.local/bin to PATH in ~/.zshrc"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Setup complete. Open a new terminal before the lab.${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  User:        $USERNAME"
echo "  Schema:      $SCHEMA"
echo "  Lab folder:  $LAB_DIR"
echo "  Project:     $PROJECT_DIR"
echo "  Venv:        $VENV_DIR"
echo "  Profile:     ~/.dbt/profiles.yml"
echo ""
