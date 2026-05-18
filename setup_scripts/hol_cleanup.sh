#!/bin/bash
# dbt Wizard Hands-On Lab — MacBook Cleanup Script
# Removes: SSH keys, dbt Fusion, dbt Wizard, lab folder, dbt profile, PATH entries
# Does NOT remove: Xcode CLT, VS Code, Homebrew, Git, Python

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${YELLOW}→${NC} $1"; }
skip() { echo -e "  ${NC}skipped — $1${NC}"; }

# ─── Derive paths ─────────────────────────────────────────────────────────────
USERNAME=$(whoami)
LAB_DIR="$HOME/snowsummit2026"

# ─── Preview what will be removed ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}The following will be removed from this machine ($USERNAME):${NC}"
echo ""
echo "  ~/.ssh/rsa_key.p8"
echo "  ~/.ssh/id_ed25519"
echo "  ~/.ssh/id_ed25519.pub"
echo "  ~/.local/bin/dbt"
echo "  ~/.local/bin/dbt-wizard"
echo "  $LAB_DIR/  (includes venv and dbt project)"
echo "  ~/.dbt/profiles.yml"
echo "  ~/.local/bin PATH entry from ~/.zshrc"
echo ""
echo -e "${YELLOW}NOT removed: Xcode CLT, VS Code, Homebrew, Git, Python${NC}"
echo ""

# ─── Confirm ──────────────────────────────────────────────────────────────────
read -r -p "Are you sure you want to remove all of the above? (yes/no): " CONFIRM
echo ""

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# ─── SSH keys ─────────────────────────────────────────────────────────────────
info "Removing SSH keys..."

if [[ -f ~/.ssh/rsa_key.p8 ]]; then
    rm -f ~/.ssh/rsa_key.p8
    ok "Removed ~/.ssh/rsa_key.p8"
else
    skip "~/.ssh/rsa_key.p8 not found"
fi

if [[ -f ~/.ssh/id_ed25519 ]]; then
    rm -f ~/.ssh/id_ed25519
    ok "Removed ~/.ssh/id_ed25519"
else
    skip "~/.ssh/id_ed25519 not found"
fi

if [[ -f ~/.ssh/id_ed25519.pub ]]; then
    rm -f ~/.ssh/id_ed25519.pub
    ok "Removed ~/.ssh/id_ed25519.pub"
else
    skip "~/.ssh/id_ed25519.pub not found"
fi

# ─── dbt Fusion ───────────────────────────────────────────────────────────────
info "Removing dbt Fusion..."

if [[ -f ~/.local/bin/dbt ]]; then
    rm -f ~/.local/bin/dbt
    ok "Removed ~/.local/bin/dbt"
else
    skip "dbt Fusion binary not found"
fi

# ─── dbt Wizard ───────────────────────────────────────────────────────────────
info "Removing dbt Wizard..."

if [[ -f ~/.local/bin/dbt-wizard ]]; then
    rm -f ~/.local/bin/dbt-wizard
    ok "Removed ~/.local/bin/dbt-wizard"
else
    skip "dbt Wizard binary not found"
fi

# ─── Lab folder ───────────────────────────────────────────────────────────────
info "Removing lab folder..."

if [[ -d "$LAB_DIR" ]]; then
    rm -rf "$LAB_DIR"
    ok "Removed $LAB_DIR"
else
    skip "$LAB_DIR not found"
fi

# ─── dbt profiles.yml ─────────────────────────────────────────────────────────
info "Removing dbt profiles.yml..."

if [[ -f ~/.dbt/profiles.yml ]]; then
    rm -f ~/.dbt/profiles.yml
    ok "Removed ~/.dbt/profiles.yml"
else
    skip "~/.dbt/profiles.yml not found"
fi

# Remove ~/.dbt if now empty
if [[ -d ~/.dbt ]] && [[ -z "$(ls -A ~/.dbt)" ]]; then
    rmdir ~/.dbt
    ok "Removed empty ~/.dbt directory"
fi

# ─── PATH entry in ~/.zshrc ───────────────────────────────────────────────────
info "Removing ~/.local/bin PATH entry from ~/.zshrc..."

if grep -q '\.local/bin' ~/.zshrc 2>/dev/null; then
    sed -i '' '/\.local\/bin/d' ~/.zshrc
    ok "Removed PATH entry from ~/.zshrc"
else
    skip "PATH entry not found in ~/.zshrc"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Cleanup complete.${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
