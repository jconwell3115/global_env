#!/bin/bash

# Bootstrap Script
# One-time machine setup: installs shared work tools, clones infrastructure repos,
# configures SSH, .bashrc, .gitconfig, and the UV environment for my_work_tools.
#
# Run this on a fresh machine before using setup_project.sh.
# The original environment_setup.sh is retained as a reference/fallback.
#
# Usage:
#   ./bootstrap.sh

# ------------- Config -------------
# Defined here because ~/.bashrc may not be installed yet on a fresh machine.
# After bootstrap completes these become persistent via mybashrc.
WORK_TOOLS_DIR="$HOME/my_work_tools"
export BIN_DIR="$WORK_TOOLS_DIR/bin/"
export GLOBAL_ENV_DIR="$WORK_TOOLS_DIR/global_env"
SSH_DIR="$HOME/.ssh"

export KEY_NAME="id_ed25519"
export KEY_PATH="$HOME/.ssh/$KEY_NAME"
KEY_TYPE="ed25519"
KEY_SIZE="2048"
EMAIL="jonathan.conwell@marriott.com"

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/shell_functions.sh"

# Only set trap if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  export SCRIPT_NAME="bootstrap.sh"
  trap cleanup EXIT
fi

# ------------- Preflight -------------
validate_requirements
setup_repos
ensure_shell_tools_installed

# ------------- Setup Work Tools -------------
section "Setting up shared my_work_tools environment..."

if [[ -d "$WORK_TOOLS_DIR" ]]; then
  info "Found existing work tools directory: $WORK_TOOLS_DIR"
  if [[ -f "$WORK_TOOLS_DIR/uv.lock" || -d "$WORK_TOOLS_DIR/.venv" || -d "$WORK_TOOLS_DIR/.git" ]]; then
    warn "$WORK_TOOLS_DIR already appears to contain an initialized environment."
    read -rp "Proceed to update the shared my_work_tools environment? This may modify files under $WORK_TOOLS_DIR (y/N): " PROCEED_SHARED
    if [[ ! $PROCEED_SHARED =~ ^[Yy]$ ]]; then
      info "Skipping shared my_work_tools setup to avoid overwriting an existing environment"
      SKIP_SHARED_SETUP=true
    else
      SKIP_SHARED_SETUP=false
    fi
  else
    SKIP_SHARED_SETUP=false
  fi
else
  create_dir_if_not_exists "$WORK_TOOLS_DIR" "work directory"
  SKIP_SHARED_SETUP=false
fi

if [[ "$SKIP_SHARED_SETUP" == false ]]; then
  cd "$WORK_TOOLS_DIR" || exit
  info "Changed to work tools directory: $(pwd)"

  info "Copying configuration files to my_work_tools..."
  copy_config_files "$WORK_TOOLS_DIR"

  WORKTOOLS_PYPROJECT="$WORK_TOOLS_DIR/pyproject.toml"
  if [[ -f "$WORKTOOLS_PYPROJECT" ]]; then
    info "Updating pyproject.toml for my_work_tools..."
    read -rp "Enter version for shared my_work_tools (default 0.1.0): " WORKTOOLS_PROJECT_VERSION
    WORKTOOLS_PROJECT_VERSION=${WORKTOOLS_PROJECT_VERSION:-0.1.0}
    customize_pyproject_toml "$WORKTOOLS_PYPROJECT" "my_work_tools" "$WORKTOOLS_PROJECT_VERSION" "Environment for general work tools"
  else
    info "No pyproject.toml found in $WORK_TOOLS_DIR; skipping customization"
  fi

  info "Setting up shared UV environment in my_work_tools..."
  if [[ -f "$WORK_TOOLS_DIR/uv.lock" ]]; then
    info "Detected existing uv.lock in $WORK_TOOLS_DIR; running 'uv sync' instead of reinitializing."
    (cd "$WORK_TOOLS_DIR" && uv sync) || warn "uv sync failed in $WORK_TOOLS_DIR"
  else
    setup_uv_if_needed "my_work_tools"
  fi
  generate_uv_diagnostics
else
  info "Shared my_work_tools setup skipped."
fi

# ------------- Clone Work Tools Repos -------------
section "Cloning work tools repositories..."

clone_or_pull "git@git.marriott.com:jconw356/global_env.git"

cd "$GLOBAL_ENV_DIR" || exit
if is_git_repo; then
  info "Installing pre-commit for global_env directory..."
  pre-commit install
else
  warn "global_env directory is not a git repository, skipping pre-commit install"
fi
create_log_files
cd "$WORK_TOOLS_DIR" || exit

info "Pausing for 30 seconds or until you press enter ..."
read -t 30 -rp "" || true

clone_or_pull "git@git.marriott.com:jconw356/bin.git"

cd "$BIN_DIR" || exit
info "Setting up bin directory with configuration files..."
if is_git_repo; then
  copy_precommit_config "$BIN_DIR"
  if [[ ! -f .gitignore ]]; then
    cp "$GLOBAL_ENV_DIR/.gitignore" ./
    info "Copied .gitignore to bin directory"
  fi
  info "Installing pre-commit for bin directory..."
  pre-commit install
else
  warn "bin directory is not a git repository, skipping pre-commit install"
fi
create_log_files
cd "$WORK_TOOLS_DIR" || exit

# ------------- Setup SSH -------------
section "Setting up SSH keys..."

if ask_renew_ssh; then
  ssh-keygen -t "$KEY_TYPE" -b "$KEY_SIZE" -N "" -f "$KEY_PATH" -C "$EMAIL"
  chmod 600 "$KEY_PATH"
  info "SSH keypair generated successfully!"
  cat "$KEY_PATH.pub"
  read -rp "Press Enter to continue after uploading the key to GitHub ..."
fi

# ------------- Configure Environment -------------
section "Configuring work tools environment..."

info "Setting .bashrc parameters..."
if [[ -f "$HOME/.bashrc" ]]; then
  if diff -q "$GLOBAL_ENV_DIR/mybashrc" "$HOME/.bashrc" >/dev/null 2>&1; then
    info "Existing ~/.bashrc is identical to template; skipping overwrite"
  else
    read -rp "Replace existing ~/.bashrc with template from global_env? This will back up your current ~/.bashrc (y/N): " REPLY_BASHRC
    if [[ $REPLY_BASHRC =~ ^[Yy]$ ]]; then
      cp "$HOME/.bashrc" "$HOME/.bashrc.bak.$(date +%Y%m%d_%H%M%S)"
      cp "$GLOBAL_ENV_DIR/mybashrc" "$HOME/.bashrc"
      info "Replaced ~/.bashrc (backup created)"
    else
      info "Left existing ~/.bashrc intact"
    fi
  fi
else
  cp "$GLOBAL_ENV_DIR/mybashrc" "$HOME/.bashrc"
  info "Installed template ~/.bashrc"
fi
# shellcheck disable=SC1091
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"

info "Copying the .pem for AAP CLI..."
create_dir_if_not_exists "$SSH_DIR" "SSH directory"
cp -pr "$GLOBAL_ENV_DIR/ansible-prod-user.pem" "$SSH_DIR"
ls -al "$SSH_DIR"
sleep 5

# ------------- Configure Git -------------
section "Installing global Git config"

GLOBAL_GIT_CONFIG="$GLOBAL_ENV_DIR/global_git_config"
if [[ -f "$GLOBAL_GIT_CONFIG" ]]; then
  if [[ -f "$HOME/.gitconfig" ]]; then
    backup_file "$HOME/.gitconfig"
  fi
  cp -pr "$GLOBAL_GIT_CONFIG" "$HOME/.gitconfig"
  info "Installed global git config from $GLOBAL_GIT_CONFIG -> ~/.gitconfig"
else
  warn "Global git config not found at $GLOBAL_GIT_CONFIG; skipping git configuration"
fi

# ------------- Validate Bootstrap -------------
validate_setup "bootstrap"

section "Bootstrap complete. Please check for errors above."

# ------------- Optional: Run Project Setup -------------
read -rp "Run setup_project.sh now to set up a project? (y/N): " RUN_PROJECT_SETUP
if [[ $RUN_PROJECT_SETUP =~ ^[Yy]$ ]]; then
  "$SCRIPT_DIR/setup_project.sh"
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  trap - EXIT
  unset SCRIPT_NAME
fi
