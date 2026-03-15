#!/bin/bash

# Environment Setup Script
# This script sets up a complete development environment including:
# - Work tools directories and repositories
# - SSH keys and GitHub access
# - UV package manager and Python environments
# - Pre-commit hooks and linting tools
# Usage:
#   curl -fsSL https://github.com/jconwell3115/global_env/raw/roadhouse/environment_setup.sh -o environment_setup.sh
#   chmod +x environment_setup.sh
#   ./environment_setup.sh

# ------------- Config -------------
export WORK_ENV_DIR="$HOME/Work_Environments"
export WORK_TOOLS_DIR="$HOME/my_work_tools"
export BIN_DIR=$WORK_TOOLS_DIR/bin/
export GLOBAL_ENV_DIR="$WORK_TOOLS_DIR/global_env"
SSH_DIR="$HOME/.ssh"
USERNAME="Jonathan Conwell"

# Set variables for key generation
KEY_NAME="id_ed25519"
export KEY_PATH="$HOME/.ssh/$KEY_NAME"  # Used by shell_functions.sh ask_renew_ssh()
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

# Now source shell_functions.sh from the cloned repo
# shellcheck source=/home/jconwell3115/my_work_tools/global_env/shell_functions.sh
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
  # Set script name for cleanup function
  export SCRIPT_NAME="environment_setup.sh"
  # Set up cleanup trap
  trap cleanup EXIT
fi

# ---- Project-specific configurations ----
read -rp "Enter the project name (Leave blank to only set up shared my_work_tools): " PROJECT_NAME
export PROJECT_NAME
# Accept one or more space-separated repo names so a project with multiple repos
# can all be cloned and configured in a single run.
read -rp "Enter the repo name(s), space-separated (leave blank if just setting up the project directory): " REPO_NAMES_INPUT
# Store as an array; REPO_NAME retains the first entry for backward compatibility
# with functions that only need a single reference (e.g. default description).
IFS=' ' read -ra REPO_NAMES <<< "$REPO_NAMES_INPUT"
REPO_NAME="${REPO_NAMES[0]:-}"

# Allow empty project name to mean "only set up shared my_work_tools"
if [[ -z "$PROJECT_NAME" ]]; then
  warn "No project name provided - only the shared my_work_tools environment will be set up"
  SKIP_PROJECT_SETUP=true
else
  SKIP_PROJECT_SETUP=false
fi

# Warn if no repo names provided
if [[ ${#REPO_NAMES[@]} -eq 0 || -z "${REPO_NAMES[0]}" ]]; then
  warn "No repo name provided - setting up project directory only (no repository will be cloned)"
else
  read -rp "Enter the repo owner: (Leave blank for jconwell3115) " REPO_OWNER
  export REPO_OWNER
fi

# Export variables needed by shell_functions.sh
# REPO_NAME  - first (or only) repo, for backward-compatible single-repo functions
# REPO_NAMES - space-separated list for validate_setup() and multi-repo loops
export REPO_NAME
export REPO_NAMES="${REPO_NAMES[*]}"
# bash export flattens arrays to scalars; re-split so the array is usable later in this script
IFS=' ' read -ra REPO_NAMES <<< "$REPO_NAMES"

# Validate system requirements
validate_requirements
# Ensure shell lint tool is available (shellcheck)
ensure_shell_tools_installed

# Define project directory
export PROJECT_DIR="$WORK_ENV_DIR/$PROJECT_NAME"  # Used by validate_setup()

# If a project name was provided, collect project-specific metadata
if [[ "${SKIP_PROJECT_SETUP:-false}" != true ]]; then
  # Update pyproject.toml template
  read -rp "Enter the project version (default 0.1.0): " PROJECT_VERSION
  PROJECT_VERSION=${PROJECT_VERSION:-0.1.0}

  # Set default description based on whether any repo names are provided
  if [[ -n "$REPO_NAME" ]]; then
    # Join all repo names for a more descriptive default
    default_desc="Project for ${REPO_NAMES[*]}"
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

  # Clone each project repo (skip if no repos were provided)
  if [[ ${#REPO_NAMES[@]} -gt 0 && -n "${REPO_NAMES[0]}" ]]; then
    info "Cloning ${#REPO_NAMES[@]} project repo(s): ${REPO_NAMES[*]}"
    for _repo in "${REPO_NAMES[@]}"; do
      clone_or_pull "git@github.com:${REPO_OWNER:-jconwell3115}/$_repo.git"

      cd "$PROJECT_DIR/$_repo" || exit
      info "Changed to repository directory: $(pwd)"

      if is_git_repo; then
        # Ensure .gitignore exists
        if [[ ! -f .gitignore ]]; then
          cp "$GLOBAL_ENV_DIR/.gitignore" ./
          info "Copied .gitignore to $_repo"
        fi
        # Copy pre-commit config
        copy_precommit_config .
        # Copy copilot instructions to .github directory
        copy_copilot_instructions .
        info "Installing pre-commit for $_repo directory..."
        pre-commit install
      else
        warn "$_repo directory is not a git repository, skipping pre-commit install"
      fi
      create_log_files

      cd "$PROJECT_DIR" || exit
    done
  else
    warn "No repo names provided, skipping repository clone, pre-commit install, and log file creation"
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
