#!/usr/bin/env bash
# Shared utility functions for environment setup scripts

# ------------- Helpers -------------
info()  { section "\033[1;34m[INFO]\033[0m $*"; }
warn()  { section "\033[1;33m[WARN]\033[0m $*"; }
err()   { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
die()   { err "$*"; exit 1; }

section() {
  echo ""
  echo -e "=== $* ==="
  echo ""
}

ask_renew_ssh() {
  if [ -f "$KEY_PATH" ]; then
    read -rp "SSH key already exists at $KEY_PATH. Renew it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      info "Renewing SSH key"
      return 0
    else
      section "Using existing SSH key"
      cat "$KEY_PATH.pub"
      return 1
    fi
  else
    return 0
  fi
}

clone_or_pull() {
  local repo_url="$1"
  local dir_name
  dir_name=$(basename "$repo_url" .git)
  if [ -d "$dir_name" ]; then
    if [ -d "$dir_name/.git" ]; then
      info "Directory $dir_name exists and is a git repo, pulling latest"
      cd "$dir_name" || return 1
      git pull
      cd ..
    else
      warn "Directory $dir_name exists but is not a git repo, skipping"
    fi
  else
    info "Cloning $repo_url"
    git clone "$repo_url"
  fi
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
    uv sync
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

  # Get list of config files to potentially copy
  local config_files=()
  for pattern in "requirements*" "pyproject.toml" ".pre-commit-config.yaml" ; do
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
    if [[ "$filename" == "pyproject.toml" && -f "$target_file" ]]; then
      info "Skipped $filename (already exists; will not overwrite to preserve local dependencies)"
      continue
    fi

    # Only process if file doesn't exist or is different
    if [[ ! -f "$target_file" ]] || ! diff -q "$source_file" "$target_file" >/dev/null 2>&1; then
      # Backup existing file if it exists (only when we're actually going to copy)
      if [[ -f "$target_file" ]]; then
        backup_file "$target_file"
        info "Updated $filename (files were different)"
      else
        info "Copied $filename (new file)"
      fi
      cp -pr "$source_file" "$target_dir" 2>/dev/null || true
    else
      info "Skipped $filename (no changes)"
    fi
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
    if ! sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo >/dev/null 2>&1; then
      warn "Could not add GitHub CLI repo; gh may not be available via dnf"
    else
      info "GitHub CLI repo added"
    fi
  else
    info "No dnf found; skipping repo setup"
  fi
}

# Ensure shell tooling (shellcheck, rg) is available; try to install when missing
ensure_shell_tools_installed() {
  local missing=()
  local tools=("bat" "btop" "eza" "fd" "fzf" "jq" "ncdu" "procs" "rg" "shellcheck" "tldr" "tree" "zoxide")
  for tool in "${tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing+=("$tool")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    info "Shell tools present: ${tools[*]}"
    return 0
  fi

  info "Missing shell tools: ${missing[*]}. Attempting automated install..."

  # Map binary names to dnf package names where they differ
  declare -A pkg_map
  pkg_map["bat"]="bat"
  pkg_map["btop"]="btop"
  pkg_map["eza"]="eza"
  pkg_map["fd"]="fd-find"
  pkg_map["fzf"]="fzf"
  pkg_map["jq"]="jq"
  pkg_map["ncdu"]="ncdu"
  pkg_map["procs"]="procs"
  pkg_map["rg"]="ripgrep"
  pkg_map["shellcheck"]="shellcheck"
  pkg_map["tldr"]="tldr"
  pkg_map["tree"]="tree"
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
    warn "Using dnf to install packages: ${install_pkgs[*]} (binaries: ${missing[*]})"
    if ! sudo dnf install -y "${install_pkgs[@]}"; then
      warn "dnf install failed for: ${install_pkgs[*]}"
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

  # Final fallback: use webi.sh installer for shellcheck if it's still missing
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
  # Usage: validate_setup [bootstrap|project|all]
  # bootstrap - checks shared work tools dirs and required commands
  # project   - checks project repo directories
  # all       - both (default, used by the legacy environment_setup.sh)
  local mode="${1:-all}"
  local issues=()

  # Bootstrap checks: shared infrastructure and required commands
  if [[ "$mode" == "bootstrap" || "$mode" == "all" ]]; then
    [[ -d "$GLOBAL_ENV_DIR" ]] || issues+=("global_env directory missing")
    [[ -d "$BIN_DIR" ]] || issues+=("bin directory missing")
    command -v uv >/dev/null 2>&1 || issues+=("uv command not available")
    command -v pre-commit >/dev/null 2>&1 || issues+=("pre-commit command not available")
  fi

  # Project checks: repo directories under PROJECT_DIR
  # REPO_NAMES is a space-separated list; fall back to scalar REPO_NAME for backward compatibility.
  if [[ "$mode" == "project" || "$mode" == "all" ]]; then
    if [[ -n "${REPO_NAMES:-}" ]]; then
      local _any_repo_found=false
      for _repo in $REPO_NAMES; do
        if [[ -d "${PROJECT_DIR:-}/$_repo" ]]; then
          _any_repo_found=true
          break
        fi
      done
      if [[ "$_any_repo_found" == false ]]; then
        issues+=("no project repository directories found under ${PROJECT_DIR:-PROJECT_DIR_not_set}")
      fi
    elif [[ -n "${REPO_NAME:-}" ]]; then
      [[ -d "${PROJECT_DIR:-}/$REPO_NAME" ]] || issues+=("project directory missing")
    fi
  fi

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
  diag_file="uv-setup-diagnostics-$(date +%Y%m%d_%H%M%S).txt"

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

# Bash utility functions
countfiles() {
  local dir="${1:-.}"  # Use current directory if none provided
  for d in "$dir"/*/* ; do
    [ -d "$d" ] && echo -n "$d: " && find "$d" -type f | wc -l
  done
}

extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz) tar xzf "$1" ;;
      *.bz2) bunzip2 "$1" ;;
      *.rar) unrar x "$1" ;;
      *.gz) gunzip "$1" ;;
      *.tar) tar xf "$1" ;;
      *.tbz2) tar xjf "$1" ;;
      *.tgz) tar xzf "$1" ;;
      *.zip) unzip "$1" ;;
      *.Z) uncompress "$1" ;;
      *.7z) 7z x "$1" ;;
      *) echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

mkcd() {
  if [ -z "${1:-}" ]; then
    err "mkcd requires a directory argument"
    return 1
  fi
  mkdir -p "$1" || { err "Failed to create directory $1"; return 1; }
  cd "$1" || { err "Failed to change directory to $1"; return 1; }
}

backup() {
  cp "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
}

serve() {
  local port="${1:-8000}"
  python3 -m http.server "$port"
}

findreplace() {
  if [ $# -ne 3 ]; then
    echo "Usage: findreplace <find> <replace> <file_pattern>"
    return 1
  fi
  # Escape delimiter and special regex chars in find string
  local find_escaped
  find_escaped=$(printf '%s' "$1" | sed 's/[.[\]*^$\/|]/\\&/g')
  # Escape & and \ in replacement string
  local replace_escaped
  replace_escaped=$(printf '%s' "$2" | sed 's/[&\\/]/\\&/g')
  find . -type f -name "$3" -exec sed -i "s|$find_escaped|$replace_escaped|g" {} +
}

is_git_repo() {
  git rev-parse --git-dir >/dev/null 2>&1
}

cleanup_old_virtualenvs() {
  local project_name="$1"
  info "Searching for and removing old virtualenvs for project '$project_name'"

  # Search for virtualenvs in common locations
  local virtualenv_paths=(
    "$HOME/.local/share/virtualenvs"
    "$HOME/.virtualenvs"
    "$HOME/.venv"
    "$HOME/virtualenvs"
  )

  local found_and_removed=false
  for venv_dir in "${virtualenv_paths[@]}"; do
    if [[ -d "$venv_dir" ]]; then
      # Find virtualenvs matching the project name pattern
      while IFS= read -r -d '' venv_path; do
        if [[ -d "$venv_path" ]]; then
          info "Removing old virtualenv: $venv_path"
          rm -rf "$venv_path"
          found_and_removed=true
        fi
      done < <(find "$venv_dir" -maxdepth 1 -type d -name "*${project_name}*" -print0 2>/dev/null)
    fi
  done

  if [[ "$found_and_removed" == false ]]; then
    info "No existing virtualenvs found for project '$project_name'"
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

  info "Copying .pre-commit-config.yaml to project: $project_path"
  cp -pr "$global_precommit" "$project_path"
  info "Copied .pre-commit-config.yaml to $project_path"
}

copy_copilot_instructions() {
  local project_path="$1"
  local global_copilot="$GLOBAL_ENV_DIR/copilot-instructions-template.md"
  local home_github_dir="$HOME/.github"
  local home_copilot="$home_github_dir/copilot-instructions.md"
  local github_dir="$project_path/.github"
  local target_file="$github_dir/copilot-instructions.md"

  if [[ -z "$project_path" ]]; then
    err "Usage: copy_copilot_instructions <project_directory>"
    return 1
  fi

  if [[ ! -f "$global_copilot" ]]; then
    warn "Global copilot-instructions-template.md not found at $global_copilot; skipping"
    return 0
  fi

  # Check and update ~/.github/copilot-instructions.md
  if [[ ! -d "$home_github_dir" ]]; then
    mkdir -p "$home_github_dir"
    info "Created .github directory at $home_github_dir"
  fi

  if [[ -f "$home_copilot" ]]; then
    # Check if home version differs from template
    if ! diff -q "$global_copilot" "$home_copilot" >/dev/null 2>&1; then
      backup_file "$home_copilot"
      cp -pr "$global_copilot" "$home_copilot"
      info "Updated $HOME/.github/copilot-instructions.md (old version backed up)"
    else
      info "$HOME/.github/copilot-instructions.md is up to date"
    fi
  else
    # No home version exists - create it
    cp -pr "$global_copilot" "$home_copilot"
    info "Created $HOME/.github/copilot-instructions.md"
  fi

  # Create .github directory if it doesn't exist
  if [[ ! -d "$github_dir" ]]; then
    mkdir -p "$github_dir"
    info "Created .github directory at $github_dir"
  fi

  # Handle existing copilot-instructions.md in project
  if [[ -f "$target_file" ]]; then
    # Check if existing file is identical to template
    if diff -q "$global_copilot" "$target_file" >/dev/null 2>&1; then
      info "Existing copilot-instructions.md is identical to template; skipping"
      return 0
    else
      # Files differ - create a reference copy and warn user
      local template_copy="$github_dir/copilot-instructions-template.md"
      cp -pr "$global_copilot" "$template_copy"
      warn "Existing copilot-instructions.md differs from template"
      warn "Template saved as $template_copy for reference"
      warn "Please manually merge changes or replace the existing file"
      return 0
    fi
  fi

  # No existing file - safe to copy
  cp -pr "$global_copilot" "$target_file"
  info "Copied copilot-instructions-template.md -> $target_file"
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

# Renew the homepage container stack
renew_homepage() {
  local dir="$HOME/containers/homepage"

  if [[ ! -d "$dir" ]]; then
    err "renew_homepage: directory not found: $dir"
    return 1
  fi

  cd "$dir" || { err "renew_homepage: failed to change directory to $dir"; return 1; }

  info "renew_homepage: stopping containers (podman-compose down)"
  if ! podman-compose down; then
    warn "renew_homepage: podman-compose down failed"
  fi

  info "renew_homepage: fixing ownership of config/"
  if ! sudo chown -R rhlabs:rhlabs "$HOME"/containers/homepage; then
    warn "renew_homepage: sudo chown failed (you may need to run manually)"
  fi

  if [[ -d ../.git ]]; then
    info "renew_homepage: pulling latest from git (in parent directory)"
    cd ..
    if ! git pull; then
      warn "renew_homepage: git pull failed"
    fi
    cd "$dir" || return
  else
    warn "renew_homepage: no .git directory found in parent, skipping git pull"
  fi

  info "renew_homepage: starting containers (podman-compose up -d)"
  if ! podman-compose up -d; then
    err "renew_homepage: podman-compose up failed"
    return 1
  fi

  info "renew_homepage: completed"
  return 0
}

# search_config_blocks
# --------------------
# Search configuration-like files under a directory, grouping lines into blocks
# and printing only the blocks that match the requested criteria.
#
# A "block" is defined by:
#   - start_re: regular expression that marks the beginning of a block
#   - end_re:   regular expression that marks the end of a block (optional)
#
# Parameters:
#   $1 dir       : Root directory to search. Must exist.
#   $2 pattern   : Pattern to test within each block (typically a regex used
#                  inside the AWK script). How it is interpreted depends on
#                  the AWK logic inside this function.
#   $3 start_re  : Regular expression that identifies the first line of each
#                  block (e.g., '^\\[tool\\.uv\\]' or '^\\[project\\]').
#   $4 mode      : Block selection mode (optional, default: "match"):
#                    - match : print only blocks where the block content
#                              matches "pattern"
#                    - invert: print only blocks where the block content does
#                              NOT match "pattern"
#                    - all   : print every block regardless of "pattern"
#   $5 end_re    : Regular expression that marks the end of a block
#                  (optional; default '^!' which is unlikely to occur,
#                  effectively treating the file end as the block terminator).
#
# Return codes:
#   0 : Success (one or more blocks processed; whether anything was printed
#       may depend on "mode" and "pattern").
#   1 : General failure from underlying commands / AWK (if used in the body).
#   2 : Invalid arguments (missing dir, pattern, or start_re).
#   3 : Directory not found.
#   4 : Invalid mode (must be 'match', 'invert', or 'all').
#
# Usage examples:
#   # Print [tool.uv] blocks that reference "pytest" within a project:
#   #   search_config_blocks "$PROJECT_DIR" "pytest" "^\\[tool\\.uv\\]"
#   #
#   # Print all [project] blocks, regardless of content:
#   #   search_config_blocks "$PROJECT_DIR" ".*" "^\\[project\\]" "all"
#   #
#   # Print blocks starting at '# BEGIN CUSTOM' that do NOT mention 'legacy':
#   #   search_config_blocks "." "legacy" "^# BEGIN CUSTOM" "invert" "^# END CUSTOM"
search_config_blocks() {
    local dir="${1:-}"
    local pattern="${2:-}"
    local start_re="${3:-}"
    local mode="${4:-match}"   # mode: match | invert | all
    local end_re="${5:-^!}"

    # Validate required parameters
    if [[ -z "$dir" || -z "$pattern" || -z "$start_re" ]]; then
      err "Usage: search_config_blocks <dir> <pattern> <start_re> [mode] [end_re]"
      err "  mode: match (default) | invert (non-matching blocks) | all (every block)"
      return 2
    fi

    if [[ ! -d "$dir" ]]; then
      err "Directory not found: $dir"
      return 3
    fi

    if [[ ! "$mode" =~ ^(match|invert|all)$ ]]; then
      err "Invalid mode: $mode (must be match|invert|all)"
      return 4
    fi

    # Save original IFS and set to handle filenames with spaces/newlines
    local OLD_IFS="$IFS"
    IFS=$'\n\t'

    # iterate files safely (handles spaces/newlines in names)
    find "$dir" -type f -print0 | while IFS= read -r -d '' file; do
      awk -v start_re="$start_re" -v end_re="$end_re" -v pat="$pattern" -v fname="$file" -v mode="$mode" '
        BEGIN { IGNORECASE = 1; inblock = 0; block = ""; header_printed = 0; hname = fname; sub(".*/", "", hname) }
        {
          if ($0 ~ /^[[:space:]]*hostname[[:space:]]+/) {
            split($0, a, /[[:space:]]+/)
            if (a[2] != "") hname = a[2]
          }

          if (!inblock && $0 ~ start_re) {
            inblock = 1
            block = $0 "\n"
            next
          }
          if (inblock) {
            if ($0 ~ end_re) {
              matched = (tolower(block) ~ tolower(pat))
              do_print = (mode == "all") || (mode == "match" && matched) || (mode == "invert" && !matched)
              if (do_print) {
                if (!header_printed) {
                  printf("%s\n", hname)
                  header_printed = 1
                }
                n = split(block, lines, "\n")
                for (i = 1; i <= n; i++)
                  if (length(lines[i])) printf("  %s\n", lines[i])
              }
              inblock = 0
              block = ""
            } else {
              block = block $0 "\n"
            }
          }
        }
        END {
          if (inblock) {
            matched = (tolower(block) ~ tolower(pat))
            do_print = (mode == "all") || (mode == "match" && matched) || (mode == "invert" && !matched)
            if (do_print) {
              if (!header_printed) {
                printf("%s\n", hname)
                header_printed = 1
              }
              n = split(block, lines, "\n")
              for (i = 1; i <= n; i++)
                if (length(lines[i])) printf("  %s\n", lines[i])
            }
          }
        }
      ' "$file"
    done

    # restore IFS
    IFS="$OLD_IFS"
}

podman_volume_mounts() {
  # Or get detailed mount info for all containers
  for container in $(podman ps -aq); do
    echo "Container: $(podman inspect "$container" --format '{{.Name}}')"
    podman inspect "$container" | jq -r '.[0].Mounts[] | select(.Name != null) | "  \(.Name) -> \(.Destination)"'
    echo
  done
}

# List the contents of a Podman volume by name
podman_volume_ls() {
  if [ $# -lt 1 ]; then
    podman volume ls
    return 0
  fi

  local vol="$1"; shift
  local mp
  mp=$(podman volume inspect "$vol" --format '{{.Mountpoint}}' 2>/dev/null) || {
    echo "podman: volume not found: $vol" >&2
    return 3
  }

  if [ -z "$mp" ]; then
    echo "podman: mountpoint not found for volume: $vol" >&2
    return 4
  fi

  ls -la "$mp" "$@"
}
# ------------- End of shell_functions.sh -------------
