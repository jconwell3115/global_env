#!/bin/bash

# Environment Setup Script
# This script sets up a complete development environment including:
# - Work tools directories and repositories
# - SSH keys and GitHub access
# - UV package manager and Python environments
# - Pre-commit hooks and linting tools
# Usage:
#   ./environment_setup.sh
# Function calls are made to shared utilities defined in shell_functions.sh

# ------------- Config -------------
export WORK_ENV_DIR="$HOME/Work_Environments"
export WORK_TOOLS_DIR="$HOME/my_work_tools"
export BIN_DIR=$WORK_TOOLS_DIR/bin/
export GLOBAL_ENV_DIR="$WORK_TOOLS_DIR/global_env"
SSH_DIR="$HOME/.ssh"
USERNAME="Jonathan Conwell"

# Set variables for key generation
KEY_NAME="id_ed25519"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
KEY_TYPE="ed25519"
KEY_SIZE="2048"
EMAIL="jconwell3115@gmail.com"
export PYTHON_VERSION="${PYTHON_VERSION:-3.12}"

set -euo pipefail

# Bootstrap: Download shell_functions.sh if not present (for standalone execution)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_FUNCTIONS="$SCRIPT_DIR/shell_functions.sh"

if [[ ! -f "$SHELL_FUNCTIONS" ]]; then
  echo "shell_functions.sh not found, downloading from GitHub..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/jconwell3115/global_env/roadhouse/shell_functions.sh -o "$SHELL_FUNCTIONS"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$SHELL_FUNCTIONS" https://raw.githubusercontent.com/jconwell3115/global_env/roadhouse/shell_functions.sh
  else
    echo "ERROR: Neither curl nor wget found. Cannot download shell_functions.sh"
    exit 1
  fi
  echo "Downloaded shell_functions.sh"
fi

# Source shared utilities
# shellcheck source=/home/jconwell3115/my_work_tools/global_env/shell_functions.sh
source "$SHELL_FUNCTIONS"

# Only set trap if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Set script name for cleanup function
  export SCRIPT_NAME="environment_setup.sh"
  # Set up cleanup trap
  trap cleanup EXIT
fi

# ---- Project-specific configurations ----
read -rp "Enter the project name (Leave blank to only set up shared my_work_tools): " PROJECT_NAME
export PROJECT_NAME
read -rp "Enter the repo name: (Leave blank if just setting up the project directory) " REPO_NAME
export REPO_NAME

# Allow empty project name to mean "only set up shared my_work_tools"
if [[ -z "$PROJECT_NAME" ]]; then
  warn "No project name provided - only the shared my_work_tools environment will be set up"
  SKIP_PROJECT_SETUP=true
else
  SKIP_PROJECT_SETUP=false
fi

# Warn if no repo name provided
if [[ -z "$REPO_NAME" ]]; then
  warn "No repo name provided - setting up project directory only (no repository will be cloned)"
else
  read -rp "Enter the repo owner: (Leave blank for jconwell3115) " REPO_OWNER
  export REPO_OWNER
fi

# Validate system requirements
validate_requirements
# Ensure shell lint tool is available (shellcheck)
ensure_shell_tools_installed

# Define project directory
export PROJECT_DIR="$WORK_ENV_DIR/$PROJECT_NAME"

# If a project name was provided, collect project-specific metadata
if [[ "${SKIP_PROJECT_SETUP:-false}" != true ]]; then
  # Update pyproject.toml template
  read -rp "Enter the project version (default 0.1.0): " PROJECT_VERSION
  PROJECT_VERSION=${PROJECT_VERSION:-0.1.0}

  # Set default description based on whether repo name is provided
  if [[ -n "$REPO_NAME" ]]; then
    default_desc="Project for $REPO_NAME"
  else
    default_desc="Project $PROJECT_NAME"
  fi

  read -rp "Enter the project description (default '$default_desc'): " PROJECT_DESCRIPTION
  PROJECT_DESCRIPTION=${PROJECT_DESCRIPTION:-"$default_desc"}
else
  PROJECT_VERSION=""
  PROJECT_DESCRIPTION=""
fi

# ------------- Preflight -------------

# Only attempt to cleanup virtualenvs when a project name was provided
if [[ "${SKIP_PROJECT_SETUP:-false}" != true ]]; then
  cleanup_old_virtualenvs "$PROJECT_NAME"
fi

cd ~/ || exit

# ------------- Setup Work Tools -------------
# Ensure the work tools directory exists
if [[ -d "$WORK_TOOLS_DIR" ]]; then
  info "Found existing work tools directory: $WORK_TOOLS_DIR"
  # Detect if the directory appears initialized (uv.lock, .venv, or git)
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

# Setup UV for my_work_tools (shared environment) unless user chose to skip
if [[ "$SKIP_SHARED_SETUP" == false ]]; then
  cd "$WORK_TOOLS_DIR" || exit
  info "Changed to work tools directory: $(pwd)"

  info "Copying configuration files to my_work_tools..."
  copy_config_files "$WORK_TOOLS_DIR"

  # Update pyproject.toml in the shared work tools dir (if present)
  WORKTOOLS_PYPROJECT="$WORK_TOOLS_DIR/pyproject.toml"
  if [[ -f "$WORKTOOLS_PYPROJECT" ]]; then
  info "Updating pyproject.toml for my_work_tools..."
  # Use fixed metadata for the shared my_work_tools pyproject
  WORKTOOLS_PROJECT_NAME="my_work_tools"
  # Ask the user for a version for the shared my_work_tools package (default 0.1.0)
  read -rp "Enter version for shared my_work_tools (default 0.1.0): " WORKTOOLS_PROJECT_VERSION
  WORKTOOLS_PROJECT_VERSION=${WORKTOOLS_PROJECT_VERSION:-0.1.0}
  WORKTOOLS_PROJECT_DESCRIPTION="Environment for general work tools"

  customize_pyproject_toml "$WORKTOOLS_PYPROJECT" "$WORKTOOLS_PROJECT_NAME" "$WORKTOOLS_PROJECT_VERSION" "$WORKTOOLS_PROJECT_DESCRIPTION"
  else
    info "No pyproject.toml found in $WORK_TOOLS_DIR; skipping customization"
  fi

  info "Setting up shared UV environment in my_work_tools..."
  # If the directory already has a uv.lock, prefer sync over reinitializing
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

clone_or_pull "git@github.com:jconwell3115/global_env.git"

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

# Wait for 30 seconds
info "Pausing for 30 seconds or until you press enter ..."
read -t 30 -rp "" || true

clone_or_pull "git@github.com:jconwell3115/bin.git"

# Setup bin directory with config files and pre-commit
cd "$BIN_DIR" || exit
info "Setting up bin directory with configuration files..."
if is_git_repo; then
  # ensure the most recent pre-config is copied
  copy_precommit_config "$BIN_DIR"
  # Ensure .gitignore exists
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

  # Set permissions for the private key
  chmod 600 "$KEY_PATH"

  # Display success message and key locations
  info "SSH keypair generated successfully!"
  cat "$KEY_PATH.pub"

  # Add key to GH
  read -rp "Press Enter to continue after uploading the key to GitHub ..."
fi

# ------------- Configure Environment -------------
section "Configuring work tools environment..."

info "Setting .bashrc parameters..."
# Only install or overwrite ~/.bashrc if user confirms (avoid clobbering)
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
# Source ~/.bashrc if present
# shellcheck disable=SC1090
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"


# ------------- Setup Project Environment -------------
section "Setting up project environment..."

# Skip project setup if this is the my_work_tools directory itself or no project name was given
if [[ "${SKIP_PROJECT_SETUP:-false}" == true ]]; then
  info "No project name provided; skipping project setup (only shared my_work_tools configured)"
elif [[ "$PROJECT_NAME" == "my_work_tools" ]]; then
  info "Skipping project setup for my_work_tools (already configured above)"
else
  # Create the Work_Environments directory
  create_dir_if_not_exists "$WORK_ENV_DIR" "work environments directory"

  # Move to Work_Environments directory
  cd "$WORK_ENV_DIR" || exit
  info "Changed to work environments directory: $(pwd)"

  # Create the Project directory
  create_dir_if_not_exists "$PROJECT_DIR" "project directory"

  cd "$PROJECT_DIR" || exit
  info "Changed to project directory: $(pwd)"

  # Clone project repo (only if REPO_NAME is provided)
  if [[ -n "$REPO_NAME" ]]; then
    info "Cloning project repository..."
    clone_or_pull "git@github.com:${REPO_OWNER:-jconwell3115}/$REPO_NAME.git"

    cd "$PROJECT_DIR/$REPO_NAME" || exit
    info "Changed to repository directory: $(pwd)"
    
    if is_git_repo; then
      # Ensure .gitignore exists
      if [[ ! -f .gitignore ]]; then
        cp "$GLOBAL_ENV_DIR/.gitignore" ./
        info "Copied .gitignore to project repository"
      fi
      # Copy pre-commit config
      copy_precommit_config .
      # Copy copilot instructions to .github directory
      copy_copilot_instructions .
  info "Installing pre-commit for $REPO_NAME directory..."
      pre-commit install
    else
      warn "Project repository is not a git repository, skipping pre-commit install"
    fi
    create_log_files
  else
    warn "No repo name provided, skipping repository clone, pre-commit install, and log file creation"
  fi

  cd "$PROJECT_DIR" || exit
  info "Changed to project directory: $(pwd)"

  info "Copying configuration files to project..."
  copy_config_files "$PROJECT_DIR"

  # Update pyproject.toml in the project directory (if present and project setup not skipped)
  PROJECT_PYPROJECT="$PROJECT_DIR/pyproject.toml"
  if [[ -f "$PROJECT_PYPROJECT" && "${SKIP_PROJECT_SETUP:-false}" != true ]]; then
    info "Updating pyproject.toml for project..."
    customize_pyproject_toml "$PROJECT_PYPROJECT" "$PROJECT_NAME" "$PROJECT_VERSION" "$PROJECT_DESCRIPTION"
  else
    info "No pyproject.toml found in $PROJECT_DIR or project setup skipped; skipping customization"
  fi

  # Setup UV for the project
  info "Setting up UV for the project..."
  setup_uv_if_needed "$PROJECT_NAME"
  generate_uv_diagnostics
fi


# ------------- Configure Git -------------
section "Installing global Git config"
# Simplified behavior: copy a prepared global git config into ~/.gitconfig
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

# Validate that setup was successful
validate_setup

section "Environment setup complete please check for errors"

# Unset the trap if it was set (only when run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  trap - EXIT
  unset SCRIPT_NAME
fi
