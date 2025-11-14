# AI Coding Agent Instructions for global_env

## Project Overview
Shared configuration files and shell functions for consistent project setup and environment management.

## Architecture
- **shell_functions.sh**: Utility functions for logging, git, file operations, and project initialization
- **Config files**: Standard `pyproject.toml`, `requirements*.txt`, `.pre-commit-config.yaml` templates
- **Setup scripts**: Bash scripts for UV, pipenv, and environment configuration
- **logs/**: Setup and diagnostic logs (gitignored)

## Key Patterns
- **Shell functions**: Source `shell_functions.sh` for `info()`, `warn()`, `err()`, `die()`
- **File backup**: Use `backup_file()` before modifying configs (creates `.bak.TIMESTAMP`)
- **UV setup**: Call `setup_uv_if_needed()` and `uv sync` for dependency management
- **Project customization**: Use `customize_pyproject_toml()` to set name, version, description

## Developer Workflows
- **Source functions**: `. shell_functions.sh` in scripts or interactive shell
- **Setup project**: Run `environment_setup.sh` or `new_uv_setup.sh` for new projects
- **Copy configs**: Use `copy_config_files()` to propagate global templates
- **Diagnostics**: Run `generate_uv_diagnostics()` for troubleshooting

## Conventions
- **Logging**: Use `info "message"`, `warn "message"`, `err "message"` for consistent output
- **Git operations**: Use `clone_or_pull()` for repo management
- **Directory creation**: Use `create_dir_if_not_exists()` with description
- **Validation**: Check tools with `validate_requirements()`, environments with `validate_setup()`

## Integration Points
- **UV**: Manage Python dependencies with `uv add`, `uv sync`, custom index URLs
- **Pre-commit**: Copy `.pre-commit-config.yaml` for linting hooks
- **Ansible**: Install collections/roles from `requirements.yml`
- **Pip**: Fallback management with `pip.conf` for Artifactory access

## Configurable Parameters
Environment variables and script parameters commonly used in setup workflows:

- **GLOBAL_ENV_DIR**: Path to this directory (e.g., `/home/user/my_work_tools/global_env`)
- **BIN_DIR**: Path to bin/ directory for utility scripts
- **PROJECT_DIR**: Target directory for new projects
- **REPO_NAME**: Name of repository being cloned/setup
- **PYTHON_VERSION**: Python version for UV/virtualenv (default: `3.12`)
- **UV_CACHE_DIR**: UV cache location (optional, for custom cache paths)
- **UV_CHANNEL**: UV release channel (e.g., `stable`, `preview`)
- **UV_GLOBAL_TOOLS**: Space-separated list of global tools to install via UV
- **KEY_PATH**: SSH key path for git operations (e.g., `~/.ssh/id_ed25519`)
- **SCRIPT_NAME**: Name of the calling script (for cleanup/error messages)

Typical usage in setup scripts:
```bash
export GLOBAL_ENV_DIR="/home/user/my_work_tools/global_env"
export BIN_DIR="/home/user/my_work_tools/bin"
export PROJECT_DIR="$HOME/projects"
export PYTHON_VERSION="3.12"
source "$GLOBAL_ENV_DIR/shell_functions.sh"
```

## Examples
- Setup logging: `info "Starting setup"; warn "Potential issue"; err "Failed"; die "Critical error"`
- Backup and modify: `backup_file config.yml; sed -i 's/old/new/' config.yml`
- UV project init: `uv init; customize_pyproject_toml pyproject.toml "MyProject" "1.0.0" "Description"`
- Copy requirements: `copy_global_requirements /path/to/project`</content>
<parameter name="filePath">/home/jconw483/my_work_tools/global_env/.github/copilot-instructions.md
