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
LAB_CREDENTIALS_FILE="${HOL_LAB_CREDENTIALS_FILE:-$HOME/.hol_lab_credentials}"

# ─── User-specific credentials ───────────────────────────────────────────────
# Optional instructor-managed file format for overrides:
#   export HOL_USER_1_DATABRICKS_CLIENT_ID='...'
#   export HOL_USER_1_DATABRICKS_CLIENT_SECRET='...'
#   export HOL_USER_1_SSH_PASSPHRASE='...'
#
# You can also set DATABRICKS_CLIENT_ID / DATABRICKS_CLIENT_SECRET /
# SSH_KEY_PASSPHRASE directly for the active shell. Databricks credentials and
# the SSH key passphrase default by lab user, and explicit variables override it.
if [[ -f "$LAB_CREDENTIALS_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$LAB_CREDENTIALS_FILE"
fi

case "$NUM" in
    1)
        DEFAULT_DATABRICKS_CLIENT_ID="edf3a1eb-246e-40c4-9637-ea7488b57380"
        DEFAULT_DATABRICKS_CLIENT_SECRET="dose3b21b64aba646f97377363061caa7c27"
        ;;
    2)
        DEFAULT_DATABRICKS_CLIENT_ID="e2b022d0-4b98-446c-8486-cb96399c0ebe"
        DEFAULT_DATABRICKS_CLIENT_SECRET="dose0130e04e2a1d75f03a7c9b78b28bdcec"
        ;;
    3)
        DEFAULT_DATABRICKS_CLIENT_ID="bfd19f1f-251b-44e6-988e-ad9070a5f526"
        DEFAULT_DATABRICKS_CLIENT_SECRET="dose273ff3023af85053165356a1c5875f6d"
        ;;
    4)
        DEFAULT_DATABRICKS_CLIENT_ID="eedb4eec-f865-4d8a-900c-bc9401c5f23c"
        DEFAULT_DATABRICKS_CLIENT_SECRET="dose4f46186237e50a12d10e3210f0f291b7"
        ;;
    5)
        DEFAULT_DATABRICKS_CLIENT_ID="5edb0c39-b416-4d8d-abab-8c3c8efefbd4"
        DEFAULT_DATABRICKS_CLIENT_SECRET="dosebef17de4bbc515833b8e9e5cf7b20e0e"
        ;;
    6)
        DEFAULT_DATABRICKS_CLIENT_ID="82493076-beea-49cd-9577-d1be0b4d3422"
        DEFAULT_DATABRICKS_CLIENT_SECRET="doseeffdeb99492e51a29bc993e780d48bce"
        ;;
    *)
        DEFAULT_DATABRICKS_CLIENT_ID=""
        DEFAULT_DATABRICKS_CLIENT_SECRET=""
        ;;
esac

CLIENT_ID_VAR="HOL_USER_${NUM}_DATABRICKS_CLIENT_ID"
CLIENT_SECRET_VAR="HOL_USER_${NUM}_DATABRICKS_CLIENT_SECRET"
SSH_PASSPHRASE_VAR="HOL_USER_${NUM}_SSH_PASSPHRASE"

DATABRICKS_CLIENT_ID="${!CLIENT_ID_VAR:-${DATABRICKS_CLIENT_ID:-$DEFAULT_DATABRICKS_CLIENT_ID}}"
DATABRICKS_CLIENT_SECRET="${!CLIENT_SECRET_VAR:-${DATABRICKS_CLIENT_SECRET:-$DEFAULT_DATABRICKS_CLIENT_SECRET}}"
SSH_KEY_PASSPHRASE="${!SSH_PASSPHRASE_VAR:-${SSH_KEY_PASSPHRASE:-labuser${NUM}}}"

echo ""
info "Detected user: $USERNAME (lab number: $NUM)"
info "Schema:        $SCHEMA"
info "Lab folder:    $LAB_DIR"

# ─── Verify required files are present ────────────────────────────────────────
echo ""
info "Checking required files..."

[[ -f ~/.ssh/id_ed25519 ]]   || fail "Missing: ~/.ssh/id_ed25519"
[[ -n "$DATABRICKS_CLIENT_ID" ]] || fail "Missing Databricks client id for $USERNAME. Set $CLIENT_ID_VAR or DATABRICKS_CLIENT_ID."
[[ -n "$DATABRICKS_CLIENT_SECRET" ]] || fail "Missing Databricks client secret for $USERNAME. Set $CLIENT_SECRET_VAR or DATABRICKS_CLIENT_SECRET."

chmod 600 ~/.ssh/id_ed25519

ok "Git key and Databricks credentials present"

prepare_git_ssh() {
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null || true

    if [[ -n "$SSH_KEY_PASSPHRASE" ]]; then
        local askpass_dir askpass_script
        askpass_dir=$(mktemp -d)
        askpass_script="$askpass_dir/askpass.sh"
        cat > "$askpass_script" <<'BASH'
#!/bin/bash
printf '%s\n' "$SSH_KEY_PASSPHRASE"
BASH
        chmod 700 "$askpass_script"

        eval "$(ssh-agent -s)" >/dev/null
        if SSH_KEY_PASSPHRASE="$SSH_KEY_PASSPHRASE" SSH_ASKPASS="$askpass_script" SSH_ASKPASS_REQUIRE=force DISPLAY=:0 ssh-add --apple-use-keychain ~/.ssh/id_ed25519 </dev/null 2>/dev/null; then
            ok "Git SSH key added to macOS keychain"
        elif SSH_KEY_PASSPHRASE="$SSH_KEY_PASSPHRASE" SSH_ASKPASS="$askpass_script" SSH_ASKPASS_REQUIRE=force DISPLAY=:0 ssh-add ~/.ssh/id_ed25519 </dev/null 2>/dev/null; then
            ok "Git SSH key added to ssh-agent"
        else
            rm -rf "$askpass_dir"
            fail "Could not add ~/.ssh/id_ed25519 to ssh-agent. Check $SSH_PASSPHRASE_VAR or SSH_KEY_PASSPHRASE."
        fi

        rm -rf "$askpass_dir"
    else
        ssh-add -q ~/.ssh/id_ed25519 2>/dev/null || true
    fi

    if [[ -f ~/.ssh/config ]] && grep -q 'Host github.com' ~/.ssh/config; then
        ok "SSH config already has github.com entry"
    else
        cat >> ~/.ssh/config <<'SSHCONFIG'

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  UseKeychain yes
SSHCONFIG
        chmod 600 ~/.ssh/config
        ok "SSH config updated for GitHub"
    fi
}

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

prepare_git_ssh

if [[ -d "$PROJECT_DIR/.git" ]]; then
    ok "dbt project already cloned at $PROJECT_DIR"
else
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

# ─── 12. dbt Wizard lab skills ───────────────────────────────────────────────
echo ""
info "Installing repo-local dbt Wizard lab skills..."

(
    cd "$PROJECT_DIR"
    python3 - <<'PY'
from pathlib import Path
import filecmp
import os
import shutil

repo_skills = Path('skills').resolve()
wizard_home = Path(os.environ.get('DBT_WIZARD_HOME', str(Path.home() / '.dbt' / 'wizard')))
wizard_skills = wizard_home / 'skills'
expected = {'lab', 'lab_init', 'install_dbt_charts'}
found = {p.name for p in repo_skills.iterdir() if p.is_dir() and (p / 'SKILL.md').exists()}

if found != expected:
    raise SystemExit(f'Expected repo skills {sorted(expected)}, found: {sorted(found)}')

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
)

ok "dbt Wizard lab skills installed"

# ─── 13. dbt profiles.yml ────────────────────────────────────────────────────
echo ""
info "Writing dbt profiles.yml..."

mkdir -p ~/.dbt

if [[ -f ~/.dbt/profiles.yml ]]; then
    cp ~/.dbt/profiles.yml ~/.dbt/profiles.yml.hol_setup.bak
fi

cat > ~/.dbt/profiles.yml << YAML

hol_dbx_profile:
  outputs:
    dev:
      auth_type: oauth
      catalog: hol_dbx_catalog
      client_id: "${DATABRICKS_CLIENT_ID}"
      client_secret: "${DATABRICKS_CLIENT_SECRET}"
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
      client_id: "${DATABRICKS_CLIENT_ID}"
      client_secret: "${DATABRICKS_CLIENT_SECRET}"
      connect_retries: 3
      dbt_databricks_verify_ssl: false
      host: adb-7405605464190909.9.azuredatabricks.net
      http_path: /sql/1.0/warehouses/540622d1091eda2b
      schema: ${SCHEMA}
      threads: 4
      type: databricks
  target: dev
YAML
ok "hol_dbx_profile written to ~/.dbt/profiles.yml"

chmod 600 ~/.dbt/profiles.yml

# ─── 14. PATH persistence ────────────────────────────────────────────────────
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
