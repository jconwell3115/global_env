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
WORK_ENV_DIR="$HOME/Work_Environments"
WORK_TOOLS_DIR="$HOME/my_work_tools"
BIN_DIR=$WORK_TOOLS_DIR/bin/
GLOBAL_ENV_DIR="$WORK_TOOLS_DIR/global_env"
CONDA_DIR="/home/jconw483/miniconda3/"
PIPCONF_DIR="$HOME/.config/pip"
SSH_DIR="$HOME/.ssh"
USERNAME="Jonathan Conwell"

# Set variables for key generation
KEY_NAME="id_ed25519"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
KEY_TYPE="ed25519"
KEY_SIZE="2048"
EMAIL="jonathan.conwell@marriott-sp.com"

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shell_functions.sh"

# Only set trap if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Set script name for cleanup function
  export SCRIPT_NAME="environment_setup.sh"
  # Set up cleanup trap
  trap cleanup EXIT
fi

# ---- Project-specific configurations ----
read -rp "Enter the project name: " PROJECT_NAME
read -rp "Enter the repo name: (Leave blank if just setting up the project directory) " REPO_NAME
read -rp "Enter the repo owner: (Just press enter for Network-DevOps) " REPO_OWNER

# Validate inputs
if [[ -z "$PROJECT_NAME" ]]; then
  err "Project name is required"
  exit 1
fi

# Warn if no repo name provided
if [[ -z "$REPO_NAME" ]]; then
  warn "No repo name provided - setting up project directory only (no repository will be cloned)"
fi

# Validate system requirements
validate_requirements

# Define project directory
PROJECT_DIR="$WORK_ENV_DIR/$PROJECT_NAME"

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
PYPROJECT_FILE="$GLOBAL_ENV_DIR/pyproject.toml"

# ------------- Preflight -------------

cleanup_old_virtualenvs "$PROJECT_NAME"

cd ~/ || exit

# ------------- Setup Work Tools -------------
create_dir_if_not_exists "$WORK_TOOLS_DIR" "work directory"

# Setup UV for my_work_tools (shared environment)
cd "$WORK_TOOLS_DIR" || exit

info "Changed to work tools directory: $(pwd)"

info "Copying configuration files to my_work_tools..."
copy_config_files "$WORK_TOOLS_DIR"

info "Updating pyproject.toml for project..."
customize_pyproject_toml "$PYPROJECT_FILE" "$PROJECT_NAME" "$PROJECT_VERSION" "$PROJECT_DESCRIPTION"

info "Setting up shared UV environment in my_work_tools..."
setup_uv_if_needed "my_work_tools"
generate_uv_diagnostics


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

# ------------- Clone Work Tools Repos -------------
section "Cloning work tools repositories..."

clone_or_pull "git@git.marriott.com:jconw483/global_env.git"

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

clone_or_pull "git@git.marriott.com:jconw483/bin.git"

# Setup bin directory with config files and pre-commit
cd "$BIN_DIR" || exit
info "Setting up bin directory with configuration files..."
copy_config_files "$BIN_DIR"
if is_git_repo; then
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

# ------------- Configure Environment -------------
section "Configuring work tools environment..."

info "Setting .bashrc parameters..."
cat "$GLOBAL_ENV_DIR/mybashrc" > "$HOME/.bashrc"
source "$HOME/.bashrc"

info "Copying the .pem for AAP CLI..."
create_dir_if_not_exists "$SSH_DIR" "SSH directory"
cp -pr "$GLOBAL_ENV_DIR/ansible-prod-user.pem" "$SSH_DIR"
ls -al "$SSH_DIR"
sleep 5

# ------------- Setup Project Environment -------------
section "Setting up project environment..."

# Skip project setup if this is the my_work_tools directory itself
if [[ "$PROJECT_NAME" == "my_work_tools" ]]; then
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
    clone_or_pull "git@git.marriott.com:${REPO_OWNER:-Network-DevOps}/$REPO_NAME.git"

    cd "$PROJECT_DIR/$REPO_NAME" || exit
    info "Changed to repository directory: $(pwd)"
    
    if is_git_repo; then
      # Ensure .gitignore exists
      if [[ ! -f .gitignore ]]; then
        cp "$GLOBAL_ENV_DIR/.gitignore" ./
        info "Copied .gitignore to project repository"
      fi
      info "Installing pre-commit and creating log files in project"
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

  info "Updating pyproject.toml for project..."
  customize_pyproject_toml "$PYPROJECT_FILE" "$PROJECT_NAME" "$PROJECT_VERSION" "$PROJECT_DESCRIPTION"

  # Setup UV for the project
  info "Setting up UV for the project..."
  setup_uv_if_needed "$PROJECT_NAME"
  generate_uv_diagnostics
fi


# ------------- Configure Git -------------
section "Setting Global Git Parameters"
# Only set git config if not already configured
if ! git config --global --get user.name >/dev/null 2>&1; then
  git config --global user.name "$USERNAME"
  info "Set global git user.name to $USERNAME"
else
  info "Global git user.name already set, skipping..."
fi

if ! git config --global --get user.email >/dev/null 2>&1; then
  git config --global user.email "$EMAIL"
  info "Set global git user.email to $EMAIL"
else
  info "Global git user.email already set, skipping..."
fi

if ! git config --global --get credential.helper >/dev/null 2>&1; then
  git config --global credential.helper "cache --timeout=86400"
  info "Set global git credential helper"
else
  info "Global git credential helper already set, skipping..."
fi

if ! git config --global --get pull.rebase >/dev/null 2>&1; then
  git config --global pull.rebase false
  info "Set global git pull.rebase to false"
else
  info "Global git pull.rebase already set, skipping..."
fi

if ! git config --global --get alias.bc >/dev/null 2>&1; then
  git config --global alias.bc "branch --show-current"
  info "Set global git alias 'bc'"
else
  info "Global git alias 'bc' already set, skipping..."
fi

# Validate that setup was successful
validate_setup

section "Environment setup complete please check for errors"

# Unset the trap if it was set (only when run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  trap - EXIT
  unset SCRIPT_NAME
fi
