#!/usr/bin/env bash
# Shared helpers for the setup scripts (environment_setup.sh, setup_project.sh,
# new_uv_setup.sh). Keep interactive-only helpers in shell_functions.sh.

# ------------- Helpers -------------
info()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*" >&2; }
err()   { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
die()   { err "$*"; exit 1; }

section() {
  printf "\n\033[1m=== %s ===\033[0m\n\n" "$*"
}

# Ask a y/N question; returns 0 for yes.
# ASSUME_YES=1 answers yes without asking. No input (EOF) counts as no.
confirm() {
  local prompt="$1" reply=""
  if [[ "${ASSUME_YES:-0}" == 1 ]]; then
    info "$prompt (y/N): y [ASSUME_YES]"
    return 0
  fi
  read -rp "$prompt (y/N): " reply || true
  [[ "$reply" =~ ^[Yy]$ ]]
}

# Prompt for a value and print it, falling back to a default.
# ASSUME_YES=1 takes the default without asking.
# Usage: var=$(ask "Enter the project version" "0.1.0")
ask() {
  local prompt="$1" default="${2:-}" reply=""
  if [[ "${ASSUME_YES:-0}" != 1 ]]; then
    read -rp "$prompt${default:+ [$default]}: " reply || true
  fi
  printf '%s' "${reply:-$default}"
}

ask_renew_ssh() {
  if [[ -f "$KEY_PATH" ]]; then
    if [[ "${ASSUME_YES:-0}" != 1 ]] && confirm "SSH key already exists at $KEY_PATH. Renew it?"; then
      info "Renewing SSH key"
      return 0
    fi
    info "Using existing SSH key:"
    cat "$KEY_PATH.pub"
    return 1
  fi
  return 0
}

# Clone a repo into the current directory, or fast-forward it if already cloned.
# A failed pull (local changes, diverged branch) only warns.
clone_or_pull() {
  local repo_url="$1"
  local dir_name
  dir_name=$(basename "$repo_url" .git)
  if [[ -d "$dir_name/.git" ]]; then
    info "Directory $dir_name exists and is a git repo, pulling latest"
    git -C "$dir_name" pull --ff-only || warn "git pull failed in $dir_name (local changes or diverged branch?); leaving it as is"
  elif [[ -d "$dir_name" ]]; then
    warn "Directory $dir_name exists but is not a git repo, skipping"
  else
    info "Cloning $repo_url"
    git clone "$repo_url"
  fi
}

# Add patterns to a repo's .git/info/exclude so local tooling files never show
# up in git status. Only affects untracked files. No-op outside a git repo.
# Usage: exclude_from_git <repo_path> <pattern>...
exclude_from_git() {
  local repo_path="$1"; shift
  local exclude_file pattern
  exclude_file=$(git -C "$repo_path" rev-parse --git-path info/exclude 2>/dev/null) || return 0
  [[ "$exclude_file" == /* ]] || exclude_file="$repo_path/$exclude_file"
  mkdir -p "$(dirname "$exclude_file")"
  for pattern in "$@"; do
    grep -qxF "$pattern" "$exclude_file" 2>/dev/null || echo "$pattern" >> "$exclude_file"
  done
}

create_log_files() {
  mkdir -p logs
  touch logs/ansible-lint.log
  touch logs/bandit.log
  touch logs/djlint-reformat.log
  touch logs/djlint.log
  touch logs/markdownlint.log
  touch logs/mypy.log
  touch logs/pydocstyle.log
  touch logs/pylint.log
  touch logs/ruff-format.log
  touch logs/ruff.log
  touch logs/shellcheck.log
  touch logs/yamllint.log
}

create_dir_if_not_exists() {
  local dir_path="$1"
  local description="$2"
  if [ ! -d "$dir_path" ]; then
    info "Creating $description at $dir_path ..."
    mkdir -p "$dir_path"
  else
    warn "$description already exists at $dir_path ..."
  fi
}

setup_uv_if_needed() {
  local location="$1"
  if [[ -f uv.lock ]]; then
    warn "UV already set up in $location, running sync..."
    uv sync || warn "uv sync failed in $location; see the diagnostics file for details"
  else
    "$GLOBAL_ENV_DIR/new_uv_setup.sh"
  fi
}

_sed_escape() {
  printf '%s' "$1" | sed 's/[\\&/]/\\&/g'
}

# Ensure [tool.uv] section with package = false exists in a pyproject.toml.
# Idempotent: safe to call on both fresh and already-customized files.
# Usage: ensure_package_false <path-to-pyproject.toml>
ensure_package_false() {
  local pyproject_file="$1"
  if [[ ! -f "$pyproject_file" ]]; then
    warn "ensure_package_false: $pyproject_file not found, skipping"
    return 0
  fi
  if ! grep -q "^\[tool\.uv\]" "$pyproject_file"; then
    # No [tool.uv] section at all — append one
    cat >> "$pyproject_file" << 'EOF'

[tool.uv]
# Treat this as a virtual project (dependencies only, not an installable package).
# Without this, UV >=0.4 tries to build and install this directory as a Python package.
package = false
index-url = "https://pypi.org/simple"

EOF
    info "ensure_package_false: added [tool.uv] with package = false to $pyproject_file"
  elif ! grep -q "^package = false" "$pyproject_file"; then
    # [tool.uv] exists but package = false is missing — insert it on the next line
    sed -i '/^\[tool\.uv\]/a package = false' "$pyproject_file"
    info "ensure_package_false: inserted 'package = false' into [tool.uv] in $pyproject_file"
  fi
}

customize_pyproject_toml() {
  local pyproject_file="$1"
  local project_name="$2"
  local project_version="$3"
  local project_description="$4"
  if [[ -f "$pyproject_file" && -n "${project_name:-}" && -n "${project_version:-}" && -n "${project_description:-}" ]]; then
    info "Customizing pyproject.toml for project..."
    # Use | as sed delimiter to safely handle project names/descriptions containing /
    local name_esc version_esc desc_esc
    name_esc=$(_sed_escape "$project_name")
    version_esc=$(_sed_escape "$project_version")
    desc_esc=$(_sed_escape "$project_description")
    sed -i "s|name = \"my-project\"|name = \"$name_esc\"|" "$pyproject_file"
    sed -i "s|version = \"0.1.0\"|version = \"$version_esc\"|" "$pyproject_file"
    sed -i "s|description = \"Example project using UV and pre-commit\"|description = \"$desc_esc\"|" "$pyproject_file"

    # Add UV sources configuration if not already present
    ensure_package_false "$pyproject_file"
  fi
}

backup_file() {
  local f="$1"
  if [[ -f "$f" && "$f" != *".bak"* ]]; then
    # Check if this is a requirements file that matches the global template
    local template_file
    template_file="$GLOBAL_ENV_DIR/$(basename "$f")"
    if [[ -f "$template_file" ]] && diff -q "$f" "$template_file" >/dev/null 2>&1; then
      info "Skipped backup of $f (identical to template)"
      return 0
    fi
    cp -f "$f" "${f}.bak.$(date +%Y%m%d_%H%M%S)"
    info "Backed up $f -> ${f}.bak.*"
  fi
}

copy_config_files() {
  local target_dir="$1"
  info "Copying configuration files to $target_dir ..."

  # Get list of config files to potentially process.
  # .pre-commit-config.yaml is not here: it only belongs inside git repos (see copy_precommit_config).
  local config_files=()
  for pattern in "requirements*" "pyproject.toml" ; do
    for file in "$GLOBAL_ENV_DIR"/$pattern; do
      if [[ -f "$file" ]]; then
        config_files+=("$file")
      fi
    done
  done

  # Process each config file
  for source_file in "${config_files[@]}"; do
    local filename
    filename=$(basename "$source_file")
    local target_file="$target_dir/$filename"

    # pyproject.toml is treated as a create-once file.
    # Never overwrite an existing one — it may contain locally-added dependencies
    # and tool configs that should not be clobbered on subsequent runs.
    if [[ "$filename" == "pyproject.toml" ]]; then
      if [[ -f "$target_file" ]]; then
        info "Skipped $filename (already exists; will not overwrite to preserve local dependencies)"
      else
        cp -pr "$source_file" "$target_dir" 2>/dev/null || true
        info "Copied $filename (new file)"
      fi
      continue
    fi

    # requirements* files are managed as symlinks so all
    # projects stay in sync with a single source of truth in GLOBAL_ENV_DIR.
    if [[ -L "$target_file" ]] && [[ "$(readlink -f "$target_file")" == "$(readlink -f "$source_file")" ]]; then
      info "Skipped $filename (symlink already up to date)"
      continue
    fi

    # Back up a plain file before replacing it with a symlink
    if [[ -f "$target_file" && ! -L "$target_file" ]]; then
      backup_file "$target_file"
      info "Replaced $filename with symlink (backed up original)"
    else
      info "Created symlink for $filename -> $source_file"
    fi
    ln -sf "$source_file" "$target_file"
  done
}

validate_requirements() {
  local missing_tools=()

  # Check for required tools
  for tool in git ssh-keygen curl; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing_tools+=("$tool")
    fi
  done

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    err "Missing required tools: ${missing_tools[*]}"
    err "Please install them and re-run the script"
    exit 1
  fi

  info "All required tools are available"
}

# Enable OS package repos needed before tool installs (EPEL, VS Code, GitHub CLI).
# Safe to call multiple times — repo-manager commands are idempotent.
setup_repos() {
  if command -v dnf >/dev/null 2>&1; then
    # Detect DNF major version: 4 uses --add-repo; 5 uses addrepo --from-repofile=
    # DNF 4 prints "4.20.0"; DNF 5 prints "dnf5 version 5.2.18.0" — scan fields for
    # the first one that looks like a version number (starts with a digit and a dot).
    local dnf_major
    dnf_major=$(dnf --version 2>/dev/null | awk 'NR==1{ for(i=1;i<=NF;i++) if($i~/^[0-9]+\./) { print int($i); exit } }')

    info "Enabling EPEL repository via dnf..."
    if ! sudo dnf install -y epel-release >/dev/null 2>&1; then
      warn "Could not enable epel-release via dnf; some packages may not be found"
    else
      info "epel-release enabled"
    fi

    info "Enabling VS Code repository..."
    if [[ ! -f /etc/yum.repos.d/vscode.repo ]]; then
      sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || warn "Could not import Microsoft GPG key"
      sudo tee /etc/yum.repos.d/vscode.repo >/dev/null << 'REPOEOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
REPOEOF
      info "VS Code repo added"
    else
      info "VS Code repo already present"
    fi

    info "Enabling GitHub CLI repository..."
    local _gh_url="https://cli.github.com/packages/rpm/gh-cli.repo"
    local _gh_ok=false
    if [[ "${dnf_major}" -ge 5 ]]; then
      sudo dnf config-manager addrepo --from-repofile="$_gh_url" >/dev/null 2>&1 && _gh_ok=true
    else
      sudo dnf config-manager --add-repo "$_gh_url" >/dev/null 2>&1 && _gh_ok=true
    fi
    if [[ "$_gh_ok" == true ]]; then
      info "GitHub CLI repo added"
    else
      warn "Could not add GitHub CLI repo; gh may not be available via dnf"
    fi

    info "Enabling Starship COPR repository (atim/starship)..."
    if ! sudo dnf copr enable -y atim/starship >/dev/null 2>&1; then
      warn "Could not enable atim/starship COPR repo; starship may not be available via dnf"
    else
      info "Starship COPR repo enabled"
    fi
  else
    info "No dnf found; skipping repo setup"
  fi
}

# Command-line tools expected on every machine (binary names)
SHELL_TOOLS=("bat" "btop" "bzip2" "eza" "fd" "fzf" "jq" "ncdu" "procs" "restic" "rg" "shellcheck" "starship" "tldr" "tree" "unzip" "vault" "zstd" "zoxide")

# Print the SHELL_TOOLS binaries that are not on PATH
_missing_shell_tools() {
  local tool
  for tool in "${SHELL_TOOLS[@]}"; do
    command -v "$tool" >/dev/null 2>&1 || echo "$tool"
  done
}

# Quick check without installing anything; warns about missing tools
check_shell_tools() {
  local missing=()
  mapfile -t missing < <(_missing_shell_tools)
  if [[ ${#missing[@]} -eq 0 ]]; then
    info "Shell tools present"
  else
    warn "Missing shell tools: ${missing[*]} (run 'shellinstall' or environment_setup.sh to install them)"
  fi
}

# Ensure shell tooling is available; try to install when missing
ensure_shell_tools_installed() {
  local missing=()
  mapfile -t missing < <(_missing_shell_tools)

  if [[ ${#missing[@]} -eq 0 ]]; then
    info "Shell tools present: ${SHELL_TOOLS[*]}"
    return 0
  fi

  info "Missing shell tools: ${missing[*]}. Attempting automated install..."

  # Map binary names to dnf package names where they differ
  declare -A pkg_map
  pkg_map["bat"]="bat"
  pkg_map["btop"]="btop"
  pkg_map["bzip2"]="bzip2"
  pkg_map["eza"]="eza"
  pkg_map["fd"]="fd-find"
  pkg_map["fzf"]="fzf"
  pkg_map["jq"]="jq"
  pkg_map["ncdu"]="ncdu"
  pkg_map["procs"]="procs"
  pkg_map["restic"]="restic"
  pkg_map["rg"]="ripgrep"
  pkg_map["shellcheck"]="shellcheck"
  pkg_map["starship"]="starship"
  pkg_map["tldr"]="tldr"
  pkg_map["tree"]="tree"
  pkg_map["unzip"]="unzip"
  pkg_map["vault"]="vault"
  pkg_map["zstd"]="zstd"
  pkg_map["zoxide"]="zoxide"

  local install_pkgs=()
  for bin in "${missing[@]}"; do
    if [[ -n "${pkg_map[$bin]:-}" ]]; then
      install_pkgs+=("${pkg_map[$bin]}")
    else
      install_pkgs+=("$bin")
    fi
  done

  if command -v dnf >/dev/null 2>&1; then
    # Filter to only packages that exist in the configured repos
    local available_pkgs=()
    local unavailable_pkgs=()
    for pkg in "${install_pkgs[@]}"; do
      info "Checking repo availability: $pkg ..."
      if dnf repoquery --available --quiet "$pkg" 2>/dev/null | grep -q .; then
        info "  $pkg: available"
        available_pkgs+=("$pkg")
      else
        warn "  $pkg: not found in repos"
        unavailable_pkgs+=("$pkg")
      fi
    done
    if [[ ${#unavailable_pkgs[@]} -gt 0 ]]; then
      warn "Packages not found in repos (skipping): ${unavailable_pkgs[*]}"
    fi
    if [[ ${#available_pkgs[@]} -eq 0 ]]; then
      warn "No available packages to install via dnf"
    else
      warn "Using dnf to install packages: ${available_pkgs[*]} (binaries: ${missing[*]})"
      if ! sudo dnf install -y "${available_pkgs[@]}"; then
        warn "dnf install failed for: ${available_pkgs[*]}"
      fi
    fi
  else
    warn "No supported package manager found to install: ${install_pkgs[*]}"
    warn "Please install them manually (binaries: ${missing[*]}) or add them to your PATH."
  fi

  # Re-check and report what remains missing
  local still_missing=()
  for tool in "${missing[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      still_missing+=("$tool")
    fi
  done

  # Final fallback: upstream installers for shellcheck (webi.sh) and starship
  if [[ ${#still_missing[@]} -gt 0 ]]; then
    for tool in "${still_missing[@]}"; do
      if [[ "$tool" == "shellcheck" ]]; then
        warn "shellcheck still missing; attempting webi.sh installer as final fallback"
        if curl -sS https://webi.sh/shellcheck | sh; then
          info "shellcheck installed via webi.sh"
        else
          warn "webi.sh installer failed for shellcheck"
        fi
      fi
      if [[ "$tool" == "starship" ]]; then
        warn "starship still missing; attempting the starship.rs installer as final fallback"
        if curl -sS https://starship.rs/install.sh | sh -s -- -y; then
          info "starship installed via starship.rs installer"
        else
          warn "starship.rs installer failed for starship"
        fi
      fi
    done
  fi

  # Re-evaluate after fallbacks
  still_missing=()
  for tool in "${missing[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      still_missing+=("$tool")
    fi
  done

  if [[ ${#still_missing[@]} -gt 0 ]]; then
    warn "The following shell tools are still missing: ${still_missing[*]}"
    warn "Install them manually or add them to your PATH before re-running this script"
  else
    info "Shell tools installed: ${missing[*]}"
  fi
}

validate_setup() {
  # Usage: validate_setup bootstrap
  #        validate_setup project <project_dir> [repo...]
  # bootstrap - checks shared work tools dirs and required commands
  # project   - checks the project directory and that each repo was cloned into it
  local mode="${1:-bootstrap}"
  local issues=()

  case "$mode" in
    bootstrap)
      [[ -d "$GLOBAL_ENV_DIR" ]] || issues+=("global_env directory missing")
      [[ -d "$BIN_DIR" ]] || issues+=("bin directory missing")
      command -v uv >/dev/null 2>&1 || issues+=("uv command not available")
      command -v pre-commit >/dev/null 2>&1 || issues+=("pre-commit command not available")
      ;;
    project)
      local project_dir="${2:-}" repo
      [[ -d "$project_dir" ]] || issues+=("project directory missing: ${project_dir:-<not given>}")
      for repo in "${@:3}"; do
        [[ -d "$project_dir/$repo/.git" ]] || issues+=("repository not cloned: $project_dir/$repo")
      done
      ;;
    *)
      err "validate_setup: unknown mode '$mode' (use bootstrap or project)"
      return 1
      ;;
  esac

  if [[ ${#issues[@]} -gt 0 ]]; then
    warn "Setup completed with issues:"
    for issue in "${issues[@]}"; do
      warn "  - $issue"
    done
  else
    info "Setup validation passed - all components are available"
  fi
}

# Cleanup function for script exit
cleanup() {
  local exit_code=$?
  # Only show cleanup messages if we're in a script context (not interactive commands)
  if [[ -n "${SCRIPT_NAME:-}" ]] && [[ $exit_code -ne 0 ]]; then
    err "Script '$SCRIPT_NAME' failed with exit code $exit_code"
    err "Check the output above for error details"
  fi
}

remove_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    rm -f "$f"
    info "Removed $f"
  fi
}

generate_uv_diagnostics() {
  local diag_file
  mkdir -p logs
  diag_file="logs/uv-setup-diagnostics-$(date +%Y%m%d_%H%M%S).txt"

  info "Generating comprehensive diagnostics file: $diag_file"

  {
    echo "================================================================"
    echo "UV Setup Diagnostics - $(date)"
    echo "Project Directory: $(pwd)"
    echo "================================================================"
    echo ""

    echo "=== SYSTEM INFORMATION ==="
    echo "OS: $(uname -s) $(uname -r)"
    echo "Shell: $SHELL"
    echo "User: $(whoami)"
    echo ""

    echo "=== UV INFORMATION ==="
    if command -v uv >/dev/null 2>&1; then
      echo "UV Version: $(uv --version)"
      echo "UV Cache Dir: ${UV_CACHE_DIR:-Not set}"
      echo "UV Python Versions:"
      uv python list 2>/dev/null || echo "  (Could not list Python versions)"
    else
      echo "UV: Not found in PATH"
    fi
    echo ""

    echo "=== PYTHON INFORMATION ==="
    if command -v python3 >/dev/null 2>&1; then
      echo "Python3 Path: $(command -v python3)"
      echo "Python3 Version: $(python3 --version 2>&1)"
    fi
    if command -v python >/dev/null 2>&1; then
      echo "Python Path: $(command -v python)"
      echo "Python Version: $(python --version 2>&1)"
    fi
    echo ""

    echo "=== PROJECT ENVIRONMENT ==="
    if [[ -f pyproject.toml ]]; then
      echo "pyproject.toml: Present"
      echo "Project Name: $(grep -E '^name\s*=' pyproject.toml | head -1 | sed 's/.*= *//' | tr -d '"')"
      echo "Python Version Required: $(grep -E '^requires-python\s*=' pyproject.toml | head -1 | sed 's/.*= *//' | tr -d '"')"
    else
      echo "pyproject.toml: Not found"
    fi

    if [[ -f uv.lock ]]; then
      echo "uv.lock: Present ($(stat -c%s uv.lock 2>/dev/null || echo "size unknown") bytes)"
    else
      echo "uv.lock: Not found"
    fi

    if [[ -d .venv ]]; then
      echo "Virtual Environment: .venv directory present"
    else
      echo "Virtual Environment: Not found"
    fi
    echo ""

    echo "=== DEPENDENCIES ==="
    echo "--- Production Dependencies ---"
    if command -v uv >/dev/null 2>&1 && [[ -f uv.lock ]]; then
      uv tree --no-dev 2>/dev/null || echo "  (Could not generate dependency tree)"
    else
      echo "  (UV not available or no lock file)"
    fi
    echo ""

    echo "--- All Dependencies (including dev) ---"
    if command -v uv >/dev/null 2>&1 && [[ -f uv.lock ]]; then
      uv tree 2>/dev/null || echo "  (Could not generate dependency tree)"
    else
      echo "  (UV not available or no lock file)"
    fi
    echo ""

    echo "=== INSTALLED PACKAGES ==="
    if command -v uv >/dev/null 2>&1 && [[ -f uv.lock ]]; then
      uv export 2>/dev/null || echo "  (Could not export requirements)"
    else
      echo "  (UV not available or no lock file)"
    fi
    echo ""

    echo "=== GLOBAL TOOLS ==="
    if command -v uv >/dev/null 2>&1; then
      echo "Installed global tools:"
      uv tool list 2>/dev/null || echo "  (Could not list global tools)"
    else
      echo "  (UV not available)"
    fi
    echo ""

    echo "=== ENVIRONMENT VARIABLES ==="
    echo "PATH: $PATH"
    echo "VIRTUAL_ENV: ${VIRTUAL_ENV:-Not set}"
    echo "UV_CACHE_DIR: ${UV_CACHE_DIR:-Not set}"
    echo "PYTHONPATH: ${PYTHONPATH:-Not set}"
    echo ""

    echo "=== DIRECTORY STRUCTURE ==="
    echo "Current directory contents:"
    ls -la 2>/dev/null || echo "  (Could not list directory)"
    echo ""

    echo "=== SETUP CONFIGURATION ==="
    echo "PYTHON_VERSION: ${PYTHON_VERSION:-Not set}"
    echo "UV_GLOBAL_TOOLS: ${UV_GLOBAL_TOOLS:-Not set}"
    echo "UV_CHANNEL: ${UV_CHANNEL:-Not set}"
    echo ""

    echo "================================================================"
    echo "Diagnostics complete - $(date)"
    echo "================================================================"

  } > "$diag_file"

  info "Diagnostics saved to: $diag_file"
}

is_git_repo() {
  git rev-parse --git-dir >/dev/null 2>&1
}

cleanup_old_virtualenvs() {
  local project_name="$1"
  info "Searching for old virtualenvs for project '$project_name'"

  # Pipenv/virtualenvwrapper locations; Pipenv names envs "<project>-<hash>"
  local virtualenv_paths=(
    "$HOME/.local/share/virtualenvs"
    "$HOME/.virtualenvs"
    "$HOME/virtualenvs"
  )

  local matches=() venv_dir venv_path
  for venv_dir in "${virtualenv_paths[@]}"; do
    [[ -d "$venv_dir" ]] || continue
    while IFS= read -r -d '' venv_path; do
      matches+=("$venv_path")
    done < <(find "$venv_dir" -mindepth 1 -maxdepth 1 -type d \( -name "$project_name" -o -name "${project_name}-*" \) -print0 2>/dev/null)
  done

  if [[ ${#matches[@]} -eq 0 ]]; then
    info "No existing virtualenvs found for project '$project_name'"
    return 0
  fi

  warn "Found old virtualenvs for '$project_name':"
  printf '  %s\n' "${matches[@]}" >&2
  # Deleting is never automatic, even with ASSUME_YES
  if [[ "${ASSUME_YES:-0}" != 1 ]] && confirm "Delete these virtualenvs?"; then
    for venv_path in "${matches[@]}"; do
      rm -rf "$venv_path"
      info "Removed old virtualenv: $venv_path"
    done
  else
    info "Kept old virtualenvs"
  fi
}

update_project_pyproject_tools() {
  local project_path="$1"
  local global_pyproject="$GLOBAL_ENV_DIR/pyproject.toml"
  local project_pyproject="$project_path/pyproject.toml"

  if [[ -z "$project_path" ]]; then
    err "Usage: update_project_pyproject_tools <project_directory>"
    return 1
  fi

  if [[ ! -f "$global_pyproject" ]]; then
    err "Global pyproject.toml not found at $global_pyproject"
    return 1
  fi

  if [[ ! -f "$project_pyproject" ]]; then
    err "Project pyproject.toml not found at $project_pyproject"
    return 1
  fi

  info "Updating pyproject.toml tool configurations for project: $project_path"
  "$project_path/.venv/bin/python" "$BIN_DIR/update_pyproject_tools.py" "$global_pyproject" "$project_pyproject"
}

copy_precommit_config() {
  local project_path="$1"
  local global_precommit="$GLOBAL_ENV_DIR/.pre-commit-config.yaml"

  if [[ -z "$project_path" ]]; then
    err "Usage: copy_precommit_config <project_directory>"
    return 1
  fi

  if [[ ! -f "$global_precommit" ]]; then
    err "Global .pre-commit-config.yaml not found at $global_precommit"
    return 1
  fi

  local target_file="$project_path/.pre-commit-config.yaml"

  # A repo that tracks its own config keeps it; a symlink would show up as a change to commit
  if [[ -e "$target_file" && ! -L "$target_file" ]] \
    && git -C "$project_path" ls-files --error-unmatch .pre-commit-config.yaml >/dev/null 2>&1; then
    warn "$target_file is tracked in git; leaving it as is (git rm --cached it to use the shared symlink)"
    return 0
  fi

  if [[ -L "$target_file" ]] && [[ "$(readlink -f "$target_file")" == "$(readlink -f "$global_precommit")" ]]; then
    info ".pre-commit-config.yaml symlink already up to date in $project_path"
  else
    if [[ -f "$target_file" && ! -L "$target_file" ]]; then
      backup_file "$target_file"
    fi
    ln -sf "$global_precommit" "$target_file"
    info "Symlinked .pre-commit-config.yaml -> $global_precommit in $project_path"
  fi
  exclude_from_git "$project_path" "/.pre-commit-config.yaml" "/.pre-commit-config.yaml.bak.*"
}

copy_copilot_instructions() {
  local project_path="$1"
  local global_copilot="$GLOBAL_ENV_DIR/global-copilot-instructions.md"
  local github_dir="$project_path/.github"
  local target_file="$github_dir/copilot-instructions.md"

  if [[ -z "$project_path" ]]; then
    err "Usage: copy_copilot_instructions <project_directory>"
    return 1
  fi

  if [[ ! -f "$global_copilot" ]]; then
    warn "$global_copilot not found; skipping"
    return 0
  fi

  # Create .github directory if it doesn't exist
  if [[ ! -d "$github_dir" ]]; then
    mkdir -p "$github_dir"
    info "Created .github directory at $github_dir"
  fi

  # Handle existing copilot-instructions.md in project
  if [[ -f "$target_file" && ! -L "$target_file" ]]; then
    # Already a correct symlink — nothing to do
    if diff -q "$global_copilot" "$target_file" >/dev/null 2>&1; then
      info "Existing copilot-instructions.md is identical to template; replacing with symlink"
      rm -f "$target_file"
    else
      # Files differ — preserve project customizations under a distinct name
      local project_copy="$github_dir/project-copilot-instructions.md"
      mv "$target_file" "$project_copy"
      info "Moved existing copilot-instructions.md -> project-copilot-instructions.md"
      info "Project-specific instructions preserved at $project_copy"
    fi
  elif [[ -L "$target_file" ]] && [[ "$(readlink -f "$target_file")" == "$(readlink -f "$global_copilot")" ]]; then
    info "copilot-instructions.md symlink already points to global template; skipping"
    exclude_from_git "$project_path" "/.github/copilot-instructions.md"
    return 0
  fi

  # Create symlink -> global template (covers new file, replaced identical, and moved-differ cases)
  ln -sf "$global_copilot" "$target_file"
  info "Symlinked copilot-instructions.md -> $global_copilot"
  exclude_from_git "$project_path" "/.github/copilot-instructions.md"
}

copy_global_requirements() {
  local project_path="$1"

  if [[ -z "$project_path" ]]; then
    err "Usage: copy_global_requirements <project_directory>"
    return 1
  fi

  if [[ ! -d "$project_path" ]]; then
    err "Project directory does not exist: $project_path"
    return 1
  fi

  info "Copying global requirements files to project: $project_path"

  # Copy requirements files if they exist
  local req_files=("requirements.txt" "requirements-dev.txt" "requirements.yml")
  for req_file in "${req_files[@]}"; do
    local global_file="$GLOBAL_ENV_DIR/$req_file"
    if [[ -f "$global_file" ]]; then
      cp -pr "$global_file" "$project_path"
      info "Copied $req_file to $project_path"
    else
      warn "Global $req_file not found, skipping"
    fi
  done

  # Change to project directory and update UV dependencies
  cd "$project_path" || return 1

  if [[ -f "requirements.txt" ]]; then
    info "Adding requirements.txt to UV project..."
    uv add -r requirements.txt --no-build-isolation || warn "Failed to add requirements.txt"
  fi

  if [[ -f "requirements-dev.txt" ]]; then
    info "Adding requirements-dev.txt as dev dependencies..."
    uv add --dev -r requirements-dev.txt --no-build-isolation || warn "Failed to add requirements-dev.txt"
  fi

  if [[ -f "requirements.yml" ]]; then
    info "Installing Ansible requirements..."
    if command -v ansible-galaxy >/dev/null 2>&1; then
      ansible-galaxy install -r requirements.yml || warn "Failed to install Ansible requirements"
    else
      warn "ansible-galaxy not found, skipping requirements.yml"
    fi
  fi

  # Sync UV
  if [[ -f "pyproject.toml" ]]; then
    info "Syncing UV dependencies..."
    uv sync --no-build-isolation || warn "UV sync failed"
  fi

  cd - >/dev/null || { err "Failed to return to previous directory"; return 1; }
}

renew_project() {
  local project_path="$1"

  if [[ -z "$project_path" ]]; then
    err "Usage: renew_project <project_directory>"
    return 1
  fi

  info "Starting renew for project: $project_path"

  # Update pyproject tool configuration
  update_project_pyproject_tools "$project_path" || {
    err "update_project_pyproject_tools failed for $project_path"
    return 1
  }

  # Copy pre-commit config
  copy_precommit_config "$project_path" || {
    err "copy_precommit_config failed for $project_path"
    return 1
  }

  # Copy global requirements and sync uv/deps
  copy_global_requirements "$project_path" || {
    err "copy_global_requirements failed for $project_path"
    return 1
  }

  info "Renew completed for project: $project_path"
}
# ------------- End of setup_lib.sh -------------
