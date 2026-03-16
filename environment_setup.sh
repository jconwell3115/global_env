#!/usr/bin/env bash

# Machine Setup Script
# One-time bootstrap for a new machine. Sets up:
# - Work tools directories (my_work_tools, bin, global_env repos)
# - SSH keys and GitHub access
# - UV package manager and Python environment for my_work_tools
# - Pre-commit hooks for global_env and bin repos
# - ~/.bashrc and global git config
#
# For setting up a new project on an already-configured machine, use:
#   setup_project.sh
#
# Usage (new machine, before SSH keys exist):
#   curl -fsSL https://github.com/jconwell3115/global_env/raw/roadhouse/environment_setup.sh -o environment_setup.sh
#   chmod +x environment_setup.sh
#   ./environment_setup.sh

# ------------- Config -------------
export WORK_TOOLS_DIR="$HOME/my_work_tools"
export BIN_DIR="$WORK_TOOLS_DIR/bin/"
export GLOBAL_ENV_DIR="$WORK_TOOLS_DIR/global_env"

# SSH key generation variables
KEY_NAME="id_ed25519"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
KEY_TYPE="ed25519"
KEY_SIZE="2048"
EMAIL="jconwell3115@gmail.com"
export PYTHON_VERSION="${PYTHON_VERSION:-3.12}"

set -euo pipefail

# ------------- Bootstrap: Clone Work Tools Repos First -------------
echo "=== Bootstrapping work tools environment ==="

# Create work tools directory if it doesn't exist
if [[ ! -d "$WORK_TOOLS_DIR" ]]; then
  echo "Creating work tools directory: $WORK_TOOLS_DIR"
  mkdir -p "$WORK_TOOLS_DIR"
fi

cd "$WORK_TOOLS_DIR" || exit
echo "Changed to work tools directory: $(pwd)"

# Clone or pull global_env repo
if [[ -d "$GLOBAL_ENV_DIR/.git" ]]; then
  echo "Found existing global_env repository, pulling latest changes..."
  (cd "$GLOBAL_ENV_DIR" && git pull) || echo "Warning: Could not pull latest changes"
else
  echo "Cloning global_env repository..."
  if ! git clone git@github.com:jconwell3115/global_env.git; then
    echo "ERROR: Failed to clone global_env repository. Ensure SSH keys are set up."
    exit 1
  fi
fi

# Source shell_functions.sh from the cloned repo
# shellcheck disable=SC1091
source "$GLOBAL_ENV_DIR/shell_functions.sh"
echo "Loaded shell_functions.sh successfully"
echo

# Clone or pull bin repo
if [[ -d "$BIN_DIR/.git" ]]; then
  info "Found existing bin repository, pulling latest changes..."
  (cd "$BIN_DIR" && git pull) || warn "Could not pull latest changes"
else
  info "Cloning bin repository..."
  clone_or_pull "git@github.com:jconwell3115/bin.git"
fi

# Only set trap if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  export SCRIPT_NAME="environment_setup.sh"
  trap cleanup EXIT
fi

# Validate system requirements
validate_requirements
# Ensure shell lint tool is available (shellcheck)
ensure_shell_tools_installed

cd ~/ || exit

# ------------- Setup my_work_tools UV Environment -------------
section "Setting up my_work_tools environment..."

# Detect if the directory appears already initialized
if [[ -f "$WORK_TOOLS_DIR/uv.lock" || -d "$WORK_TOOLS_DIR/.venv" ]]; then
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
    info "Detected existing uv.lock; running 'uv sync' instead of reinitializing."
    (cd "$WORK_TOOLS_DIR" && uv sync) || warn "uv sync failed in $WORK_TOOLS_DIR"
  else
    setup_uv_if_needed "my_work_tools"
  fi
  generate_uv_diagnostics
else
  info "Shared my_work_tools setup skipped."
fi

# ------------- Setup Repos with Pre-commit -------------
section "Setting up work tools repositories..."

# Setup global_env directory with pre-commit
cd "$GLOBAL_ENV_DIR" || exit
if is_git_repo; then
  info "Installing pre-commit for global_env directory..."
  pre-commit install
else
  warn "global_env directory is not a git repository, skipping pre-commit install"
fi
create_log_files
cd "$WORK_TOOLS_DIR" || exit

# Setup bin directory with config files and pre-commit
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

# ------------- Configure ~/.bashrc -------------
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
# shellcheck disable=SC1090,SC1091
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"

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

# ------------- Done -------------
validate_setup

section "Machine setup complete!"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  trap - EXIT
  unset SCRIPT_NAME
fi

# Offer to run setup_project.sh immediately
read -rp "Would you like to set up a project now? (y/N): " RUN_PROJECT_SETUP
if [[ $RUN_PROJECT_SETUP =~ ^[Yy]$ ]]; then
  SETUP_PROJECT_SCRIPT="$GLOBAL_ENV_DIR/setup_project.sh"
  if [[ -f "$SETUP_PROJECT_SCRIPT" ]]; then
    bash "$SETUP_PROJECT_SCRIPT"
  else
    warn "setup_project.sh not found at $SETUP_PROJECT_SCRIPT"
  fi
else
  info "To set up a project later, run: $GLOBAL_ENV_DIR/setup_project.sh"
fi
