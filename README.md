# global_env — Development environment setup

This repository contains shell scripts to automate creating and configuring a Linux development environment. The scripts:

- create common directories (work tools and project environments),
- manage SSH keys,
- clone and configure shared "work tools" repositories,
- copy vetted configuration files into projects,
- and migrate Python projects to the UV package manager.

### Main scripts
- `environment_setup.sh` — Orchestrates a full environment setup (directories, SSH keys, cloning repos, configuring git, installing pre-commit hooks, setting up UV for shared and project environments).
- `shell_functions.sh` — Shared utilities used by the other scripts (logging, cloning/pulling, file backups, UV helpers, diagnostics).
- `new_uv_setup.sh` — Automates migration from Pipenv / requirements files / pyproject.toml to UV, installs a Python version, and installs commonly used global UV tools.

### Prerequisites
- Bash (POSIX-compatible shell).
- Required commands: `git`, `ssh-keygen`, `curl`. The scripts will exit if these are missing.
- `uv` (UV package manager) is optional; `new_uv_setup.sh` will attempt to install UV automatically if not present.

### Quick overview — what `environment_setup.sh` does
1. Prompts for:
   - Project name (required)
   - Repo name (optional — leave blank to only create the project directory)
   - Repo owner (press Enter to default to "Network-DevOps")
   - Project version & description (used to customize `pyproject.toml`)
2. Validates required system tools.
3. Cleans up old virtual environments for the project name.
4. Ensures directories:
   - `$HOME/my_work_tools` (work tools)
   - `$HOME/Work_Environments` (project area)
5. Copies configuration files (templates) from this repo into target directories, backing up differing files.
6. Sets up or syncs a UV environment for shared tools (`my_work_tools`) and for the project:
   - If `uv.lock` exists, runs `uv sync`.
   - Otherwise runs `new_uv_setup.sh` to initialize/migrate to UV.
7. Offers to create / renew an SSH key (ed25519 by default) and prints the public key for upload to Git host.
8. Clones configured work repositories (example: `git@git.marriott.com:jconw483/global_env.git` and `bin.git`) and installs `pre-commit` when a directory is a git repo.
9. Copies the repo `mybashrc` into `~/.bashrc` (review this before running).
10. Configures a few global Git settings (user.name, user.email, credential helper, alias.bc, pull.rebase).
11. Generates diagnostics and log files to help validate the setup.

### Defaults and configuration variables
The top of `environment_setup.sh` contains defaults that you can change before running:
- `WORK_ENV_DIR` (default: `$HOME/Work_Environments`)
- `WORK_TOOLS_DIR` (default: `$HOME/my_work_tools`)
- `BIN_DIR` (default: `$WORK_TOOLS_DIR/bin/`)
- `GLOBAL_ENV_DIR` (default: `$WORK_TOOLS_DIR/global_env`)
- `CONDA_DIR`, `PIPCONF_DIR`, `SSH_DIR`, `USERNAME`, `EMAIL`, `KEY_NAME`, `KEY_TYPE`, `KEY_SIZE`, etc.

If you prefer not to edit the script, run it interactively and provide values at the prompts.

### mybashrc
- Location: The script copies the `mybashrc` file from the repo (expected at `$GLOBAL_ENV_DIR/mybashrc`) to your home as `~/.bashrc`.
- Behavior: `environment_setup.sh` performs `cat "$GLOBAL_ENV_DIR/mybashrc" > "$HOME/.bashrc"` and then `source "$HOME/.bashrc"`, so the profile is overwritten and immediately applied for the running shell session.
- Contents: `mybashrc` is intended to provide PATH updates, environment variables, and helper aliases/functions used by these setup scripts and the UV workflow. Review the file to ensure there are no conflicts with your existing shell customizations.
- Recommendations:
  - Back up your existing bash profile before running the script:
    ```bash
    cp -p ~/.bashrc ~/.bashrc.pre_global_env_bak.$(date +%Y%m%d_%H%M%S)
    ```
  - Inspect and edit `mybashrc` in this repo to add or remove environment tweaks before running `environment_setup.sh`.
  - If you want the changes to apply only to future sessions, avoid sourcing the file immediately and instead open a new shell after the copy, or manually merge entries.
- Reverting: Restore your previous profile with:
  ```bash
  mv ~/.bashrc.pre_global_env_bak.<TIMESTAMP> ~/.bashrc
  source ~/.bashrc
  ```
  or edit ~/.bashrc to remove or adjust the lines you don't want.

### Using the scripts

#### 1) Full interactive setup
From the directory containing `environment_setup.sh` (or after cloning this repo into your work tools dir):
```bash
./environment_setup.sh
```
Follow the prompts.

#### 2) Migrate a project to UV (manual use)
Change into the project directory and run:
```bash
./new_uv_setup.sh
```
Environment variables you can set to influence behavior:
- `PYTHON_VERSION` (default: `3.12`)
- `UV_CACHE_DIR` (default: `$HOME/.uv-cache`)
- `UV_GLOBAL_TOOLS` (space-separated list; default includes `black ruff mypy bandit pydocstyle ansible-lint yamllint djlint pre-commit`)
- `UV_CHANNEL` (install script URL for UV)

Examples:
```bash
UV_GLOBAL_TOOLS="black ruff mypy" ./new_uv_setup.sh
PYTHON_VERSION=3.12 ./new_uv_setup.sh
```

### What `new_uv_setup.sh` does
- Detects project shape: `Pipfile`, `requirements.txt`, `requirements-dev.txt`, `requirements.yml`, or `pyproject.toml`.
- Migrates Pipenv or requirements-based projects into a UV-managed `pyproject.toml` and deterministic `uv.lock`.
- Runs `uv venv` and `uv sync` to create and populate the virtual environment.
- Installs ansible-galaxy roles from `requirements.yml` if Ansible is available inside the UV environment.
- Installs configured global tools via `uv tool install`.
- Creates a dependency snapshot file like `uv-dependencies-YYYYMMDD.txt` on success.

### Key behaviors from `shell_functions.sh`
- `copy_config_files`: copies templates (`requirements*`, `pyproject.toml`, `.pre-commit-config.yaml`, `.gitignore`, etc.) from the `global_env` repo to a target folder and backs up differing files (`.bak.TIMESTAMP`).
- `setup_uv_if_needed`: runs `uv sync` when `uv.lock` exists, otherwise delegates to `new_uv_setup.sh`.
- `generate_uv_diagnostics`: writes a timestamped diagnostics file with system, UV, Python and project details.
- Other utilities: `create_dir_if_not_exists`, `clone_or_pull`, `create_log_files`, `backup_file`, `remove_file`, `countfiles`, `extract`, `findreplace`, etc.

### Logs and diagnostics
- `create_log_files` creates `logs/` files for several linters and formatters (ansible-lint, yamllint, ruff, black, mypy, bandit, djlint, pydocstyle).
- `generate_uv_diagnostics` produces a detailed diagnostic file `uv-setup-diagnostics-YYYYMMDD_HHMMSS.txt` in the current directory.

### Safety, backups and notes
- Files that will be overwritten are backed up with `filename.bak.TIMESTAMP` unless they match the repo template.
- SSH key generation: defaults to `~/.ssh/id_ed25519` and prints the public key; the script will pause to let you add it to your Git host.
- `environment_setup.sh` exits if required tools are missing.
- The scripts assume SSH-based repo cloning (e.g., `git@git.marriott.com:...`). Update URLs or configure SSH keys accordingly.
- `environment_setup.sh` may copy `mybashrc` to `~/.bashrc` — inspect that file if you have a custom shell environment.

### Troubleshooting
- If `uv` is not found, `new_uv_setup.sh` attempts to install it.
- If `pre-commit` fails to install, ensure the target directory is a git repo and that Python/UV environment is available.
- Check `logs/`, `uv-setup-diagnostics-*.txt` and the script output for detailed error information.

### Customization and contribution
- Edit `shell_functions.sh` to change copying rules, templates, or add/remove global tools.
- Update defaults in `environment_setup.sh` to match your preferred layout and identity settings.
- Modify the UV configuration injected in `customize_pyproject_toml()` if you need to add private package indexes or extra build dependencies.

### Author / License
- Author: Jonathan Conwell
- This repository is a personal environment bootstrap. Review and adapt before running on production machines.
