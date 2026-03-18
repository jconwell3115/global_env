#!/usr/bin/env bash

# Project Setup Script
# Sets up a new project environment: creates directories, clones repos,
# installs pre-commit hooks, copies config files, and initializes the UV environment.
#
# Assumes bootstrap.sh has already been run and ~/.bashrc is sourced so that
# GLOBAL_ENV_DIR, WORK_ENV_DIR, and BIN_DIR are available in the environment.
#
# Usage:
#   ./setup_project.sh

set -euo pipefail

# ------------- Guard: require env vars from ~/.bashrc -------------
# These are set by mybashrc. If they're missing, bootstrap.sh hasn't been run
# or ~/.bashrc hasn't been sourced.
: "${GLOBAL_ENV_DIR:?GLOBAL_ENV_DIR is not set — run bootstrap.sh first or source ~/.bashrc}"
: "${WORK_ENV_DIR:?WORK_ENV_DIR is not set — run bootstrap.sh first or source ~/.bashrc}"
: "${BIN_DIR:?BIN_DIR is not set — run bootstrap.sh first or source ~/.bashrc}"
export BIN_DIR GLOBAL_ENV_DIR

WORK_TOOLS_DIR="${WORK_TOOLS_DIR:-$HOME/my_work_tools}"

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/shell_functions.sh"

# Only set trap if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  export SCRIPT_NAME="setup_project.sh"
  trap cleanup EXIT
fi

# ------------- Input Collection -------------
read -rp "Enter the project name: " PROJECT_NAME
if [[ -z "$PROJECT_NAME" ]]; then
  die "Project name is required"
fi

read -rp "Enter the repo name(s), space-separated (leave blank to skip cloning): " REPO_NAMES_INPUT
IFS=' ' read -ra REPO_NAMES <<< "$REPO_NAMES_INPUT"
REPO_NAME="${REPO_NAMES[0]:-}"

REPO_OWNER=""
if [[ ${#REPO_NAMES[@]} -gt 0 && -n "${REPO_NAMES[0]}" ]]; then
  read -rp "Enter the repo owner (leave blank for Network-DevOps): " REPO_OWNER
  REPO_OWNER="${REPO_OWNER:-Network-DevOps}"
else
  warn "No repo names provided - setting up project directory only (no repository will be cloned)"
fi

read -rp "Enter the project version (default 0.1.0): " PROJECT_VERSION
PROJECT_VERSION="${PROJECT_VERSION:-0.1.0}"

if [[ -n "$REPO_NAME" ]]; then
  default_desc="Project for ${REPO_NAMES[*]}"
else
  default_desc="Project $PROJECT_NAME"
fi
read -rp "Enter the project description (default '$default_desc'): " PROJECT_DESCRIPTION
PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION:-$default_desc}"

# Export for shell_functions.sh (validate_setup, etc.)
export REPO_NAME
export REPO_NAMES="${REPO_NAMES[*]}"
export PROJECT_DIR="$WORK_ENV_DIR/$PROJECT_NAME"
# Re-split after export flattens the array
IFS=' ' read -ra REPO_NAMES <<< "$REPO_NAMES"

# ------------- Preflight -------------
validate_requirements
ensure_shell_tools_installed
cleanup_old_virtualenvs "$PROJECT_NAME"

# ------------- Create Directories -------------
section "Setting up project environment for '$PROJECT_NAME'..."

create_dir_if_not_exists "$WORK_ENV_DIR" "work environments directory"

cd "$WORK_ENV_DIR" || exit
info "Changed to work environments directory: $(pwd)"

create_dir_if_not_exists "$PROJECT_DIR" "project directory"

cd "$PROJECT_DIR" || exit
info "Changed to project directory: $(pwd)"

# ------------- Clone Repos -------------
if [[ ${#REPO_NAMES[@]} -gt 0 && -n "${REPO_NAMES[0]}" ]]; then
  info "Cloning ${#REPO_NAMES[@]} project repo(s): ${REPO_NAMES[*]}"
  for _repo in "${REPO_NAMES[@]}"; do
    clone_or_pull "git@git.marriott.com:${REPO_OWNER}/$_repo.git"

    cd "$PROJECT_DIR/$_repo" || exit
    info "Changed to repository directory: $(pwd)"

    if is_git_repo; then
      copy_precommit_config .
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

# ------------- Copy Config Files & Customize pyproject.toml -------------
cd "$PROJECT_DIR" || exit
info "Copying configuration files to project..."
copy_config_files "$PROJECT_DIR"

PROJECT_PYPROJECT="$PROJECT_DIR/pyproject.toml"
if [[ -f "$PROJECT_PYPROJECT" ]]; then
  info "Updating pyproject.toml for project..."
  customize_pyproject_toml "$PROJECT_PYPROJECT" "$PROJECT_NAME" "$PROJECT_VERSION" "$PROJECT_DESCRIPTION"
else
  info "No pyproject.toml found in $PROJECT_DIR; skipping customization"
fi

# ------------- Setup UV -------------
info "Setting up UV for the project..."
setup_uv_if_needed "$PROJECT_NAME"
generate_uv_diagnostics

# ------------- Validate -------------
validate_setup "project"

section "Project setup complete for '$PROJECT_NAME'. Please check for errors above."

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  trap - EXIT
  unset SCRIPT_NAME
fi
