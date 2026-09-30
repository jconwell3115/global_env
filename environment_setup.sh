#!/usr/bin/env bash

# Machine Setup Script
# One-time bootstrap for a new machine. Safe to re-run. In order, it sets up:
# - OS package repos and shell tools
# - SSH key and GitHub access
# - Work tools repos (global_env, bin) cloned into ~/my_work_tools
# - UV package manager and Python environment for my_work_tools
# - Pre-commit hooks for the global_env and bin repos
# - ~/.bashrc (a loader line for global_env/mybashrc) and ~/.gitconfig (an include
#   of global_env/global_git_config)
#
# For setting up a new project on an already-configured machine, use:
#   setup_project.sh
#
# Usage (new machine, before SSH keys exist):
#   curl -fsSL https://github.com/jconwell3115/global_env/raw/roadhouse/environment_setup.sh -o environment_setup.sh
#   chmod +x environment_setup.sh
#   ./environment_setup.sh [-y]
#
# Options:
#   -y   Answer yes to every prompt and take the defaults (unattended run)

set -euo pipefail

GLOBAL_ENV_REPO="global_env"
GLOBAL_ENV_BRANCH="roadhouse"

usage() {
  echo "Usage: $0 [-y]"
  echo "  -y   Answer yes to every prompt and take the defaults (unattended run)"
}

while getopts ":yh" opt; do
  case "$opt" in
    y) export ASSUME_YES=1 ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

# ------------- Self-bootstrap -------------
# Downloaded on its own (see Usage), this script has no helper files next to it yet.
# Clone global_env over HTTPS (no SSH key needed yet) and re-run from the clone.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -f "$SCRIPT_DIR/setup_lib.sh" ]]; then
  bootstrap_dir="${WORK_TOOLS_DIR:-$HOME/my_work_tools}/$GLOBAL_ENV_REPO"
  if [[ "$SCRIPT_DIR" == "$bootstrap_dir" ]]; then
    echo "setup_lib.sh is missing from $bootstrap_dir; is the clone complete?" >&2
    exit 1
  fi
  command -v git >/dev/null 2>&1 || { echo "git is required; install it first (e.g. sudo dnf install -y git)" >&2; exit 1; }
  if [[ ! -d "$bootstrap_dir/.git" ]]; then
    echo "Cloning $GLOBAL_ENV_REPO over HTTPS into $bootstrap_dir ..."
    mkdir -p "$(dirname "$bootstrap_dir")"
    git clone --branch "$GLOBAL_ENV_BRANCH" \
      "https://github.com/${GITHUB_OWNER:-jconwell3115}/$GLOBAL_ENV_REPO.git" "$bootstrap_dir"
  fi
  exec "$bootstrap_dir/environment_setup.sh" "$@"
fi

# ------------- Config -------------
# shellcheck source=paths.sh
source "$SCRIPT_DIR/paths.sh"
# shellcheck source=setup_lib.sh
source "$SCRIPT_DIR/setup_lib.sh"

export PYTHON_VERSION="${PYTHON_VERSION:-3.12}"

KEY_TYPE="ed25519"
KEY_PATH="$SSH_DIR/id_$KEY_TYPE"

# uv and its tools (pre-commit, ...) install to ~/.local/bin, which a fresh shell may lack
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# Only set trap if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  export SCRIPT_NAME="environment_setup.sh"
  trap cleanup EXIT
fi

# ------------- Preflight -------------
validate_requirements
info "Some steps need sudo (package repos and tool installs)"
sudo -v
setup_repos
ensure_shell_tools_installed

# ------------- Setup SSH -------------
section "Setting up SSH keys..."

if ask_renew_ssh; then
  EMAIL="${GIT_EMAIL:-}"
  [[ -n "$EMAIL" ]] || EMAIL=$(git config -f "$GLOBAL_ENV_DIR/global_git_config" user.email 2>/dev/null || true)
  [[ -n "$EMAIL" ]] || EMAIL=$(git config --global user.email 2>/dev/null || true)
  [[ -n "$EMAIL" ]] || EMAIL=$(ask "Email for the SSH key comment")
  [[ -n "$EMAIL" ]] || die "An email is required for the SSH key comment (or set GIT_EMAIL)"

  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  if [[ -f "$KEY_PATH" ]]; then
    key_backup_ts=$(date +%Y%m%d_%H%M%S)
    mv "$KEY_PATH" "$KEY_PATH.bak.$key_backup_ts"
    if [[ -f "$KEY_PATH.pub" ]]; then
      mv "$KEY_PATH.pub" "$KEY_PATH.pub.bak.$key_backup_ts"
    fi
    info "Moved the old key pair to $KEY_PATH.bak.$key_backup_ts"
  fi

  if [[ "${ASSUME_YES:-0}" == 1 ]]; then
    ssh-keygen -t "$KEY_TYPE" -N "" -f "$KEY_PATH" -C "$EMAIL"
  else
    info "Choose a passphrase for the new key (leave empty for none)"
    ssh-keygen -t "$KEY_TYPE" -f "$KEY_PATH" -C "$EMAIL"
  fi
  chmod 600 "$KEY_PATH"
  if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
    ssh-add "$KEY_PATH" || warn "Could not add the key to ssh-agent"
  fi

  info "SSH keypair generated. Add this public key at https://github.com/settings/ssh/new :"
  cat "$KEY_PATH.pub"
  read -rp "Press Enter once the key is uploaded to GitHub ..." _ || true
fi

# ssh -T always exits non-zero; GitHub's greeting is the real signal
github_ssh_out=$(ssh -T -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 git@github.com 2>&1 || true)
if [[ "$github_ssh_out" == *"successfully authenticated"* ]]; then
  GITHUB_SSH_OK=true
  info "GitHub SSH access confirmed"
else
  GITHUB_SSH_OK=false
  warn "GitHub SSH check failed; SSH clones and pulls below will fail until the key is uploaded"
fi

# ------------- Clone Work Tools Repos -------------
section "Cloning work tools repositories..."

create_dir_if_not_exists "$WORK_TOOLS_DIR" "work tools directory"
cd "$WORK_TOOLS_DIR"

# A self-bootstrapped global_env was cloned over HTTPS; move it to SSH once SSH works
if [[ "$GITHUB_SSH_OK" == true && -d "$GLOBAL_ENV_DIR/.git" ]] \
  && [[ "$(git -C "$GLOBAL_ENV_DIR" config --get remote.origin.url)" == https://* ]]; then
  git -C "$GLOBAL_ENV_DIR" remote set-url origin "git@github.com:$GITHUB_OWNER/$GLOBAL_ENV_REPO.git"
  info "Switched global_env remote to SSH"
fi

clone_or_pull "git@github.com:$GITHUB_OWNER/$GLOBAL_ENV_REPO.git"
clone_or_pull "git@github.com:$GITHUB_OWNER/bin.git"

# ------------- Shared my_work_tools Environment -------------
section "Setting up shared my_work_tools environment..."

SKIP_SHARED_SETUP=false
if [[ -f "$WORK_TOOLS_DIR/uv.lock" || -d "$WORK_TOOLS_DIR/.venv" ]]; then
  warn "$WORK_TOOLS_DIR already appears to contain an initialized environment."
  if ! confirm "Proceed to update the shared my_work_tools environment? This may modify files under $WORK_TOOLS_DIR"; then
    info "Skipping shared my_work_tools setup to avoid overwriting an existing environment"
    SKIP_SHARED_SETUP=true
  fi
fi

if [[ "$SKIP_SHARED_SETUP" == false ]]; then
  cd "$WORK_TOOLS_DIR"
  copy_config_files "$WORK_TOOLS_DIR"

  WORKTOOLS_PYPROJECT="$WORK_TOOLS_DIR/pyproject.toml"
  if [[ -f "$WORKTOOLS_PYPROJECT" ]]; then
    info "Updating pyproject.toml for my_work_tools..."
    WORKTOOLS_PROJECT_VERSION=$(ask "Enter version for shared my_work_tools" "0.1.0")
    customize_pyproject_toml "$WORKTOOLS_PYPROJECT" "my_work_tools" "$WORKTOOLS_PROJECT_VERSION" "Environment for general work tools"
  else
    info "No pyproject.toml found in $WORK_TOOLS_DIR; skipping customization"
  fi

  info "Setting up shared UV environment in my_work_tools..."
  setup_uv_if_needed "my_work_tools"
  generate_uv_diagnostics
else
  info "Shared my_work_tools setup skipped."
fi

# ------------- Pre-commit Hooks for Work Tools Repos -------------
section "Installing pre-commit hooks..."

# global_env holds the shared .pre-commit-config.yaml itself; bin gets a symlink to it
if [[ -d "$BIN_DIR/.git" ]]; then
  copy_precommit_config "$BIN_DIR"
  if [[ ! -f "$BIN_DIR/.gitignore" ]]; then
    cp "$GLOBAL_ENV_DIR/.gitignore" "$BIN_DIR/"
    info "Copied .gitignore to bin directory"
  fi
fi

for repo_dir in "$GLOBAL_ENV_DIR" "$BIN_DIR"; do
  if [[ ! -d "$repo_dir/.git" ]]; then
    warn "$repo_dir is not a git repository, skipping pre-commit install"
    continue
  fi
  if command -v pre-commit >/dev/null 2>&1; then
    info "Installing pre-commit for $repo_dir..."
    (cd "$repo_dir" && pre-commit install)
  else
    warn "pre-commit not found; skipping hook install for $repo_dir"
  fi
  (cd "$repo_dir" && create_log_files)
done

# ------------- Configure Shell -------------
section "Configuring ~/.bashrc..."

BASHRC="$HOME/.bashrc"
BASHRC_LOADER="[ -f \"$GLOBAL_ENV_DIR/mybashrc\" ] && . \"$GLOBAL_ENV_DIR/mybashrc\""

if [[ -f "$BASHRC" ]] && grep -qxF "$BASHRC_LOADER" "$BASHRC"; then
  info "Your ~/.bashrc already loads mybashrc"
elif [[ -f "$BASHRC" ]] && grep -q "global_env/shell_functions.sh" "$BASHRC"; then
  # An old full copy of mybashrc; loading mybashrc on top would run everything twice
  if confirm "Your ~/.bashrc is an old copy of mybashrc. Replace it with a line that loads mybashrc? (a backup is made)"; then
    cp "$BASHRC" "$BASHRC.bak.$(date +%Y%m%d_%H%M%S)"
    printf '# .bashrc\n\n# Load the shared environment from global_env\n%s\n' "$BASHRC_LOADER" > "$BASHRC"
    info "Replaced ~/.bashrc with a mybashrc loader (backup created)"
  else
    info "Left existing ~/.bashrc intact"
  fi
else
  printf '\n# Load the shared environment from global_env\n%s\n' "$BASHRC_LOADER" >> "$BASHRC"
  info "Added a mybashrc loader line to ~/.bashrc"
fi

# ------------- Configure Git -------------
section "Configuring global git config..."

GLOBAL_GIT_CONFIG="$GLOBAL_ENV_DIR/global_git_config"
GITCONFIG="$HOME/.gitconfig"
if [[ ! -f "$GLOBAL_GIT_CONFIG" ]]; then
  warn "Global git config not found at $GLOBAL_GIT_CONFIG; skipping git configuration"
elif grep -qxF "$GLOBAL_GIT_CONFIG" <<< "$(git config --global --get-all include.path 2>/dev/null || true)"; then
  info "Your ~/.gitconfig already includes $GLOBAL_GIT_CONFIG"
else
  # The include goes first so settings in ~/.gitconfig override the shared ones
  gitconfig_tmp=$(mktemp)
  printf '[include]\n\tpath = %s\n' "$GLOBAL_GIT_CONFIG" > "$gitconfig_tmp"
  if [[ -f "$GITCONFIG" ]] && ! diff -q "$GLOBAL_GIT_CONFIG" "$GITCONFIG" >/dev/null 2>&1; then
    # Keep local settings; an identical old copy of the template is simply dropped
    cp "$GITCONFIG" "$GITCONFIG.bak.$(date +%Y%m%d_%H%M%S)"
    printf '\n' >> "$gitconfig_tmp"
    cat "$GITCONFIG" >> "$gitconfig_tmp"
  fi
  mv "$gitconfig_tmp" "$GITCONFIG"
  info "Your ~/.gitconfig now includes $GLOBAL_GIT_CONFIG"
fi

# ------------- Validate Bootstrap -------------
validate_setup "bootstrap"

section "Bootstrap complete. Please check for errors above."
info "Open a new shell (or run: source ~/.bashrc) to load the environment"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  trap - EXIT
  unset SCRIPT_NAME
fi

# Offer to run setup_project.sh immediately (never in an unattended run)
if [[ "${ASSUME_YES:-0}" != 1 ]] && confirm "Would you like to set up a project now?"; then
  bash "$GLOBAL_ENV_DIR/setup_project.sh"
else
  info "To set up a project later, run: $GLOBAL_ENV_DIR/setup_project.sh"
fi
