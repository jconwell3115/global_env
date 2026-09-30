#!/usr/bin/env bash

# Project Setup Script
# Sets up a new project environment on an already-configured machine.
# Assumes environment_setup.sh has already been run (global_env and bin are cloned,
# SSH keys exist).
#
# Usage:
#   setup_project.sh [-n NAME] [-r "repo1 repo2"] [-o OWNER] [-v VERSION] [-d DESCRIPTION] [-y]
#
# Any value not given as an option is prompted for. With -y nothing is prompted:
# missing values take their defaults (a project name is still required).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paths.sh
source "$SCRIPT_DIR/paths.sh"
# shellcheck source=setup_lib.sh
source "$SCRIPT_DIR/setup_lib.sh"

usage() {
  cat <<EOF
Usage: $0 [-n NAME] [-r "repo1 repo2"] [-o OWNER] [-v VERSION] [-d DESCRIPTION] [-y]
  -n   Project name (directory under $WORK_ENV_DIR)
  -r   Space-separated repo names to clone ("" for none)
  -o   Repo owner (default: $GITHUB_OWNER)
  -v   Project version (default: 0.1.0)
  -d   Project description
  -y   Don't prompt; take defaults for anything not given
EOF
}

PROJECT_NAME=""
REPO_NAMES_INPUT=""
REPOS_GIVEN=false
REPO_OWNER=""
PROJECT_VERSION=""
PROJECT_DESCRIPTION=""

while getopts ":n:r:o:v:d:yh" opt; do
  case "$opt" in
    n) PROJECT_NAME="$OPTARG" ;;
    r) REPO_NAMES_INPUT="$OPTARG"; REPOS_GIVEN=true ;;
    o) REPO_OWNER="$OPTARG" ;;
    v) PROJECT_VERSION="$OPTARG" ;;
    d) PROJECT_DESCRIPTION="$OPTARG" ;;
    y) export ASSUME_YES=1 ;;
    h) usage; exit 0 ;;
    :) die "Option -$OPTARG needs a value" ;;
    *) usage >&2; exit 2 ;;
  esac
done

# Only set trap if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  export SCRIPT_NAME="setup_project.sh"
  trap cleanup EXIT
fi

# ------------- Input Collection -------------
NAME_RE='^[A-Za-z0-9_][A-Za-z0-9._-]*$'

[[ -n "$PROJECT_NAME" ]] || PROJECT_NAME=$(ask "Enter the project name")
[[ -n "$PROJECT_NAME" ]] || die "Project name is required"
[[ "$PROJECT_NAME" =~ $NAME_RE ]] \
  || die "Invalid project name '$PROJECT_NAME' (letters, digits, '.', '_', '-'; must not start with '.' or '-')"

if [[ "$REPOS_GIVEN" == false ]]; then
  REPO_NAMES_INPUT=$(ask "Enter the repo name(s), space-separated (leave blank to skip cloning)")
fi
read -ra REPO_NAMES <<< "$REPO_NAMES_INPUT"
for repo in "${REPO_NAMES[@]}"; do
  [[ "$repo" =~ $NAME_RE ]] || die "Invalid repo name '$repo'"
done

if [[ ${#REPO_NAMES[@]} -gt 0 ]]; then
  [[ -n "$REPO_OWNER" ]] || REPO_OWNER=$(ask "Enter the repo owner" "$GITHUB_OWNER")
else
  warn "No repo names provided - setting up project directory only (no repository will be cloned)"
fi

[[ -n "$PROJECT_VERSION" ]] || PROJECT_VERSION=$(ask "Enter the project version" "0.1.0")

if [[ ${#REPO_NAMES[@]} -gt 0 ]]; then
  default_desc="Project for ${REPO_NAMES[*]}"
else
  default_desc="Project $PROJECT_NAME"
fi
[[ -n "$PROJECT_DESCRIPTION" ]] || PROJECT_DESCRIPTION=$(ask "Enter the project description" "$default_desc")

PROJECT_DIR="$WORK_ENV_DIR/$PROJECT_NAME"

# ------------- Preflight -------------
validate_requirements
check_shell_tools
cleanup_old_virtualenvs "$PROJECT_NAME"

# ------------- Setup Project Directory -------------
section "Setting up project environment for '$PROJECT_NAME'..."

create_dir_if_not_exists "$WORK_ENV_DIR" "work environments directory"
create_dir_if_not_exists "$PROJECT_DIR" "project directory"

# ------------- Clone Repositories -------------
for repo in "${REPO_NAMES[@]}"; do
  section "Setting up repository $REPO_OWNER/$repo..."
  cd "$PROJECT_DIR"
  if ! clone_or_pull "git@github.com:$REPO_OWNER/$repo.git"; then
    warn "Could not clone $REPO_OWNER/$repo; skipping it"
    continue
  fi

  repo_dir="$PROJECT_DIR/$repo"
  if [[ -d "$repo_dir/.git" ]]; then
    copy_precommit_config "$repo_dir"
    copy_copilot_instructions "$repo_dir"
    if command -v pre-commit >/dev/null 2>&1; then
      info "Installing pre-commit for $repo..."
      (cd "$repo_dir" && pre-commit install)
    else
      warn "pre-commit not found; skipping hook install for $repo"
    fi
    (cd "$repo_dir" && create_log_files)
    exclude_from_git "$repo_dir" "/logs/"
  else
    warn "$repo_dir is not a git repository, skipping pre-commit install"
  fi
done

# ------------- Configure Project Files -------------
cd "$PROJECT_DIR"
info "Changed to project directory: $(pwd)"

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
validate_setup project "$PROJECT_DIR" "${REPO_NAMES[@]}"

section "Project setup complete for '$PROJECT_NAME'! Please check for errors."

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  trap - EXIT
  unset SCRIPT_NAME
fi
