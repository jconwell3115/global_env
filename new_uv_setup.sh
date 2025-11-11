#!/usr/bin/env bash
# Automate migration from Pipenv (or requirements.txt) to UV
# + configure global tools and shared cache
#
# Usage:
#   ./migrate_to_uv.sh                # default migration in current dir
#   UV_GLOBAL_TOOLS="black ruff mypy" ./migrate_to_uv.sh
#   PYTHON_VERSION=3.12 ./migrate_to_uv.sh
#
# Behavior:
# - If requirements.txt exists: imports with `uv add -r requirements.txt`
# - If requirements-dev.txt exists: imports as dev with `uv add --dev -r requirements-dev.txt`
# - If requirements.yml exists: installs with ansible-galaxy (requires Ansible installed)
# - If Pipfile exists: uses `uvx migrate-to-uv`
# - If neither exists but pyproject.toml exists: just `uv lock && uv sync`
# - Sets a shared cache and installs global tools and a Python version

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shell_functions.sh"

# ------------- Config (override with env vars) -------------
: "${PYTHON_VERSION:=3.12}"
: "${UV_CACHE_DIR:=$HOME/.uv-cache}"
: "${UV_GLOBAL_TOOLS:=black ruff mypy bandit pydocstyle ansible-lint yamllint djlint pre-commit}"     # space-separated list
: "${UV_CHANNEL:=https://astral.sh/uv/install.sh}"  # install script URL

# ------------- Preflight -------------
info "Starting migration to UV in: $(pwd)"

if ! command -v uv >/dev/null 2>&1; then
  info "UV not found. Installing UV..."
  # shellcheck disable=SC2155
  curl -LsSf "$UV_CHANNEL" | sh
  # Add typical install locations to PATH for the current session
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
fi

info "Using UV: $(uv --version)"

# Ensure cache directory
export UV_CACHE_DIR
mkdir -p "$UV_CACHE_DIR"
info "Shared cache directory: $UV_CACHE_DIR"

# ------------- Global Python version -------------
if [[ -n "$PYTHON_VERSION" ]]; then
  if uv python list | grep -q "^$PYTHON_VERSION"; then
    info "Python $PYTHON_VERSION is already installed"
  else
    info "Installing global Python $PYTHON_VERSION via UV..."
    uv python install "$PYTHON_VERSION" || warn "Unable to install Python $PYTHON_VERSION"
  fi
fi

# Check if already migrated
if [[ -f uv.lock ]]; then
  info "uv.lock already exists, assuming already migrated. Running sync..."
  uv sync
  exit 0
fi

# ------------- Detect project shape -------------
HAS_PIPFILE=false
HAS_REQS=false
HAS_DEV_REQS=false
HAS_ANSIBLE_REQS=false
HAS_PYPROJECT=false

[[ -f Pipfile ]] && HAS_PIPFILE=true
[[ -f requirements.txt ]] && HAS_REQS=true
[[ -f requirements-dev.txt ]] && HAS_DEV_REQS=true
[[ -f requirements.yml ]] && HAS_ANSIBLE_REQS=true
[[ -f pyproject.toml ]] && HAS_PYPROJECT=true

# ------------- Migrate -------------
if $HAS_PIPFILE; then
  info "Pipenv project detected (Pipfile present). Converting manually to UV..."

  # Backup original files
  backup_file Pipfile
  backup_file Pipfile.lock

  # Initialize UV project first (only if not already initialized)
  if ! [[ -f pyproject.toml ]]; then
    uv init .
  fi
  uv venv

  # Import requirements if they exist
  if $HAS_REQS; then
    info "requirements.txt also found; importing into project..."
    backup_file requirements.txt
    uv add -r requirements.txt --no-build-isolation
  fi

  # Import dev requirements if present
  if $HAS_DEV_REQS; then
    info "requirements-dev.txt found; importing as dev dependencies..."
    backup_file requirements-dev.txt
    uv add --dev -r requirements-dev.txt --no-build-isolation
  fi

  # Clean up Pipenv files post-conversion
  warn "Removing Pipfile and Pipfile.lock after migration..."
  remove_file Pipfile
  remove_file Pipfile.lock

  uv sync --no-build-isolation

elif $HAS_REQS; then
  info "requirements.txt detected without Pipfile. Initializing a UV project and importing..."
  if ! $HAS_PYPROJECT; then
    # Make a project if none exists
    uv init .
    uv venv  # Create virtual environment
  else
    info "Existing pyproject.toml found; will import into it."
    uv venv  # Ensure venv exists
  fi

  backup_file requirements.txt
  uv add -r requirements.txt --no-build-isolation

  # Import dev requirements if present
  if $HAS_DEV_REQS; then
    info "requirements-dev.txt found; importing as dev dependencies..."
    backup_file requirements-dev.txt
    uv add --dev -r requirements-dev.txt --no-build-isolation
  fi

  # (optional) If you want to keep requirements.txt around for CI mirroring, comment the next line:
  # remove_file requirements.txt

  uv sync --no-build-isolation

elif $HAS_PYPROJECT; then
  info "pyproject.toml detected (no Pipfile/requirements.txt). Locking & syncing with UV..."
  uv venv  # Ensure venv exists

  # Import dev requirements if present
  if $HAS_DEV_REQS; then
    info "requirements-dev.txt found; importing as dev dependencies..."
    uv add --dev -r requirements-dev.txt --no-build-isolation
  fi

  uv sync --no-build-isolation
else
  info "No Pipfile/requirements.txt/pyproject.toml found. Initializing a new UV project..."
  uv init .
  uv venv  # Create virtual environment
  uv sync --no-build-isolation
fi

# ------------- Ansible Requirements -------------
if $HAS_ANSIBLE_REQS; then
  info "requirements.yml detected. Installing Ansible requirements..."
  if uv run ansible --version >/dev/null 2>&1; then
    uv run ansible-galaxy install -r requirements.yml || warn "Failed to install Ansible requirements."
  else
    warn "Ansible not installed in UV environment. Install Ansible first (e.g., uv add ansible-core) and re-run to install requirements.yml."
  fi
fi

# ------------- Global tools -------------
if [[ -n "$UV_GLOBAL_TOOLS" ]]; then
  info "Installing global tools: $UV_GLOBAL_TOOLS"
  # shellcheck disable=SC2086
  for tool in $UV_GLOBAL_TOOLS; do
    uv tool install "$tool" || warn "Failed to install tool: $tool"
  done
fi

# ------------- Summary -------------
if command -v uv >/dev/null 2>&1 && [[ -f uv.lock ]]; then
  info "Generating dependency tree reference file..."
  uv tree --no-dev > "uv-dependencies-$(date +%Y%m%d).txt" 2>/dev/null || warn "Could not generate dependency tree"
fi

# ------------- Summary -------------
cat <<EOF

============================================================
Migration complete.

Key files:
  - pyproject.toml (project configuration)
  - uv.lock        (deterministic lockfile)
Cache:
  - UV_CACHE_DIR=$UV_CACHE_DIR

Commands to use:
  - uv run <cmd>           # run under project environment
  - uv add <pkg>           # add deps to pyproject + lock
  - uv sync                # install from uv.lock
  - uv tool run <tool>     # run globally installed tool

If you kept requirements.txt for reference, it has been backed up.
Dev requirements (if requirements-dev.txt was present) have been imported as dev dependencies.
Ansible requirements (if requirements.yml was present) have been installed via ansible-galaxy.
Consider updating your CI/CD to use 'uv lock' + 'uv sync'.

============================================================
EOF
