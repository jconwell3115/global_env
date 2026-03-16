#!/usr/bin/env bash

# Project Setup Script
# Sets up a new project environment on an already-configured machine.
# Assumes environment_setup.sh has already been run (global_env and bin are cloned,
# shell_functions.sh is available, SSH keys exist).
#
# Usage:
#   $GLOBAL_ENV_DIR/setup_project.sh
#   # or from anywhere:
#   ~/my_work_tools/global_env/setup_project.sh

# ------------- Config -------------
export WORK_ENV_DIR="$HOME/Work_Environments"
export WORK_TOOLS_DIR="$HOME/my_work_tools"
export GLOBAL_ENV_DIR="$WORK_TOOLS_DIR/global_env"
export PYTHON_VERSION="${PYTHON_VERSION:-3.12}"

set -euo pipefail

# ------------- Bootstrap: Source shell_functions.sh -------------
if [[ ! -f "$GLOBAL_ENV_DIR/shell_functions.sh" ]]; then
  echo "ERROR: shell_functions.sh not found at $GLOBAL_ENV_DIR/shell_functions.sh"
  echo "Run environment_setup.sh first to configure this machine."
  exit 1
fi

# shellcheck disable=SC1091
source "$GLOBAL_ENV_DIR/shell_functions.sh"
echo "Loaded shell_functions.sh successfully"
echo

# Only set trap if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  export SCRIPT_NAME="setup_project.sh"
  trap cleanup EXIT
fi

# ------------- Project-specific prompts -------------
read -rp "Enter the project name: " PROJECT_NAME
export PROJECT_NAME

if [[ -z "$PROJECT_NAME" ]]; then
  echo "ERROR: Project name cannot be empty." >&2
  exit 1
fi

read -rp "Enter the repo name (leave blank to skip cloning a repository): " REPO_NAME
export REPO_NAME

if [[ -n "$REPO_NAME" ]]; then
  read -rp "Enter the repo owner (leave blank for jconwell3115): " REPO_OWNER
  REPO_OWNER="${REPO_OWNER:-jconwell3115}"
  export REPO_OWNER
fi

read -rp "Enter the project version (default 0.1.0): " PROJECT_VERSION
PROJECT_VERSION="${PROJECT_VERSION:-0.1.0}"

if [[ -n "$REPO_NAME" ]]; then
  default_desc="Project for $REPO_NAME"
else
  default_desc="Project $PROJECT_NAME"
fi

read -rp "Enter the project description (default '$default_desc'): " PROJECT_DESCRIPTION
PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION:-"$default_desc"}"

export PROJECT_DIR="$WORK_ENV_DIR/$PROJECT_NAME"

# ------------- Preflight -------------
validate_requirements
ensure_shell_tools_installed
cleanup_old_virtualenvs "$PROJECT_NAME"

# ------------- Setup Project Directory -------------
section "Setting up project environment for '$PROJECT_NAME'..."

create_dir_if_not_exists "$WORK_ENV_DIR" "work environments directory"

cd "$WORK_ENV_DIR" || exit
info "Changed to work environments directory: $(pwd)"

create_dir_if_not_exists "$PROJECT_DIR" "project directory"

cd "$PROJECT_DIR" || exit
info "Changed to project directory: $(pwd)"

# ------------- Clone Repository -------------
if [[ -n "$REPO_NAME" ]]; then
  info "Cloning project repository..."
  clone_or_pull "git@github.com:${REPO_OWNER}/$REPO_NAME.git"

  cd "$PROJECT_DIR/$REPO_NAME" || exit
  info "Changed to repository directory: $(pwd)"

  if is_git_repo; then
    if [[ ! -f .gitignore ]]; then
      cp "$GLOBAL_ENV_DIR/.gitignore" ./
      info "Copied .gitignore to project repository"
    fi
    copy_precommit_config .
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

# ------------- Configure Project Files -------------
cd "$PROJECT_DIR" || exit
info "Changed to project directory: $(pwd)"

info "Copying configuration files to project..."
copy_config_files "$PROJECT_DIR"

PROJECT_PYPROJECT="$PROJECT_DIR/pyproject.toml"
if [[ -f "$PROJECT_PYPROJECT" ]]; then
  info "Updating pyproject.toml for project..."
  customize_pyproject_toml "$PROJECT_PYPROJECT" "$PROJECT_NAME" "$PROJECT_VERSION" "$PROJECT_DESCRIPTION"
else
  info "No pyproject.toml found in $PROJECT_DIR; skipping customization"
fi

# ------------- Setup UV Environment -------------
info "Setting up UV for the project..."
setup_uv_if_needed "$PROJECT_NAME"
generate_uv_diagnostics

# ------------- Done -------------
validate_setup

section "Project setup complete for '$PROJECT_NAME'! Please check for errors."

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  trap - EXIT
  unset SCRIPT_NAME
fi
