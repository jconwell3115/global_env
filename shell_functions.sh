#!/bin/bash
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

customize_pyproject_toml() {
  local pyproject_file="$1"
  local project_name="$2"
  local project_version="$3"
  local project_description="$4"
  if [[ -f "$pyproject_file" && -n "${project_name:-}" && -n "${project_version:-}" && -n "${project_description:-}" ]]; then
    info "Customizing pyproject.toml for project..."
    sed -i "s/name = \"my-project\"/name = \"$project_name\"/" "$pyproject_file"
    sed -i "s/version = \"0.1.0\"/version = \"$project_version\"/" "$pyproject_file"
    sed -i "s/description = \"Example project using UV and pre-commit\"/description = \"$project_description\"/" "$pyproject_file"

    # Add UV sources configuration if not already present
    if ! grep -q "\[tool.uv\]" "$pyproject_file"; then
      cat >> "$pyproject_file" << 'EOF'

[tool.uv]
# Primary index
index-url = "https://pypi.org/simple"
# Extra indexes to check for packages not found in primary
extra-index-url = ["https://artifactory.marriott.com/artifactory/api/pypi/network-devops-pypi-local/simple/"]
# Extra build dependencies for packages that don't declare them properly
extra-build-dependencies = { "mind-libs" = ["setuptools"] }

EOF
      info "Added UV configuration to pyproject.toml"
    fi
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
  for pattern in "requirements*" "pyproject.toml" ".ansible-lint" ".pre-commit-config.yaml" ".gitignore" ".pymarkdown"; do
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

# Ensure shell tooling (shellcheck) is available; try to install when missing
ensure_shell_tools_installed() {
  local missing=()
  local tools=("shellcheck")
  for tool in "${tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing+=("$tool")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    info "Shell tools present: ShellCheck"
    return 0
  fi

  info "Missing shell tools: ${missing[*]}. Attempting automated install..."

  # Prefer rpm-ostree when present (Fedora Silverblue / CoreOS style hosts).
  if command -v rpm-ostree >/dev/null 2>&1; then
    warn "Using rpm-ostree to install: ${missing[*]}"
    # rpm-ostree is used on immutable systems. Installation creates a new
    # deployment and may require a reboot to activate. Attempt the install
    # and inform the user about next steps.
    if ! sudo rpm-ostree install "${missing[@]}"; then
      warn "rpm-ostree install failed for: ${missing[*]}. You may need to use toolbox, overlays, or install manually"
    else
      info "rpm-ostree install attempted; a reboot or rebase may be required to complete. Run 'sudo systemctl reboot' to apply changes."
    fi
  elif command -v apt-get >/dev/null 2>&1; then
    warn "Using apt-get to install: ${missing[*]} (may prompt for sudo)"
    sudo apt-get update || warn "apt-get update failed"
    sudo apt-get install -y "${missing[@]}" || warn "apt-get install failed"
  elif command -v dnf >/dev/null 2>&1; then
    warn "Using dnf to install: ${missing[*]}"
    sudo dnf install -y "${missing[@]}" || warn "dnf install failed"
  elif command -v yum >/dev/null 2>&1; then
    warn "Using yum to install: ${missing[*]}"
    sudo yum install -y epel-release || true
    sudo yum install -y "${missing[@]}" || warn "yum install failed"
  elif command -v apk >/dev/null 2>&1; then
    warn "Using apk to install: ${missing[*]}"
    sudo apk add "${missing[@]}" || warn "apk add failed"
  elif command -v brew >/dev/null 2>&1; then
    warn "Using brew to install: ${missing[*]}"
    brew install "${missing[@]}" || warn "brew install failed"
  else
    warn "No supported package manager found to install: ${missing[*]}"
    warn "Please install them manually. See https://www.shellcheck.net"
  fi

  # Re-check and report
  local still_missing=()
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
  local issues=()

  # Check if directories exist
  [[ -d "$GLOBAL_ENV_DIR" ]] || issues+=("global_env directory missing")
  [[ -d "$BIN_DIR" ]] || issues+=("bin directory missing")
  [[ -d "$PROJECT_DIR/$REPO_NAME" ]] || issues+=("project directory missing")

  # Check if UV is available
  command -v uv >/dev/null 2>&1 || issues+=("uv command not available")

  # Check if pre-commit is available
  command -v pre-commit >/dev/null 2>&1 || issues+=("pre-commit command not available")

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
  python "$BIN_DIR/update_pyproject_tools.py" "$global_pyproject" "$project_pyproject"
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
# ------------- End of shell_functions.sh -------------
