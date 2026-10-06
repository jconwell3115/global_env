# global_env — Development environment setup

This repository contains shell scripts to automate creating and configuring a Linux development environment. The scripts:

- create common directories (work tools and project environments),
- manage SSH keys,
- clone and configure shared "work tools" repositories,
- copy vetted configuration files into projects,
- and migrate Python projects to the UV package manager.

### Main scripts

- `environment_setup.sh` — One-time machine bootstrap: package repos and shell tools, SSH key, cloning `global_env` and `bin`, the shared `my_work_tools` UV environment, pre-commit hooks, `~/.bashrc` and `~/.gitconfig`. Safe to re-run.
- `setup_project.sh` — Sets up a project under `$WORK_ENV_DIR` on an already-bootstrapped machine: clones one or more repos, links the shared pre-commit config and Copilot instructions, and sets up UV.
- `paths.sh` — The one place work-tools paths are defined (`WORK_TOOLS_DIR`, `WORK_ENV_DIR`, `GLOBAL_ENV_DIR`, `BIN_DIR`, `SSH_DIR`, `GITHUB_OWNER`). Sourced by `mybashrc` and the scripts; values already in the environment win.
- `setup_lib.sh` — Shared helpers for the setup scripts (logging, prompts, cloning, config linking, UV helpers, diagnostics).
- `shell_functions.sh` — Interactive shell helpers (`extract`, `mkcd`, `serve`, podman helpers, ...). Sourced by `mybashrc`; it also loads `setup_lib.sh` so helpers like `copy_precommit_config` work as shell commands.
- `setup_ai_token_tools.sh` — Installs user-level tools that cut Claude Code / Copilot token use (Graphify, Ponytail) and links the global instruction files. See [AI token-reduction tools](#ai-token-reduction-tools).
- `new_uv_setup.sh` — Automates migration from Pipenv / requirements files / pyproject.toml to UV, installs a Python version, and installs commonly used global UV tools.

### Prerequisites

- Bash 4.4+ (RHEL/Fedora with `dnf` for automatic package installs).
- Required commands: `git`, `ssh-keygen`, `curl`. The scripts exit if these are missing.
- `sudo` access (asked for once, up front) for package repos and tool installs.

### What `environment_setup.sh` does

1. If run on its own (downloaded with curl), clones `global_env` over HTTPS into `~/my_work_tools/global_env` and re-runs from there.
2. Validates required tools, enables package repos (EPEL, VS Code, GitHub CLI, Starship COPR) and installs missing shell tools.
3. Creates or renews the SSH key (`~/.ssh/id_ed25519`, optional passphrase), prints it for upload to GitHub, and checks GitHub SSH access. Once SSH works, a HTTPS-cloned `global_env` is switched to its SSH remote.
4. Clones or fast-forwards `global_env` and `bin` into `~/my_work_tools`.
5. Sets up the shared UV environment in `~/my_work_tools` (`uv sync` if `uv.lock` exists, otherwise `new_uv_setup.sh`).
6. Links the shared `.pre-commit-config.yaml` into `bin` and installs pre-commit hooks in both repos.
7. Adds a loader line for `mybashrc` to `~/.bashrc` (see below) and adds an `[include]` of `global_git_config` to `~/.gitconfig`.
8. Validates the result and offers to run `setup_project.sh`.

### What `setup_project.sh` does

1. Takes the project name, repo names, owner, version and description from options or prompts. Project and repo names are validated (letters, digits, `.`, `_`, `-`).
2. Lists old Pipenv virtualenvs named `<project>` or `<project>-*` and deletes them only if you confirm (never with `-y`).
3. Creates `$WORK_ENV_DIR/<project>` and clones each repo into it.
4. In each repo, symlinks `.pre-commit-config.yaml` and `.github/copilot-instructions.md` to the shared copies in `global_env`, installs pre-commit hooks, and adds these files and `logs/` to `.git/info/exclude` so `git status` stays clean. A repo that tracks its own `.pre-commit-config.yaml` keeps it.
5. Links the `requirements*` files and copies `pyproject.toml` (never overwriting an existing one) into the project directory, then sets up UV.

### mybashrc and global_git_config

- `~/.bashrc` gets one line that sources `$GLOBAL_ENV_DIR/mybashrc`, so a `git pull` in `global_env` updates your shell for new sessions. An old full copy of `mybashrc` in `~/.bashrc` is replaced by that line after confirmation (with a timestamped backup); any other `~/.bashrc` is kept and the line is appended.
- `~/.gitconfig` gets `[include] path = $GLOBAL_ENV_DIR/global_git_config` at the top, so settings in `~/.gitconfig` override the shared ones. An old identical copy of the template is replaced by the include; a customized one is backed up and kept below it.

### Private overlay (optional)

Machine-specific or private additions live in a separate repo cloned at `$GLOBAL_ENV_OVERLAY_DIR` (default `~/my_work_tools/global_env_work`). Everything below is skipped when that directory does not exist, so this repo works the same without it:

- `shell.d/*.sh`: sourced by `mybashrc` after `shell_functions.sh`
- `mybashrc.local`: sourced last by `mybashrc`, so its aliases/exports override the defaults
- `gitconfig`: included by `global_git_config` (e.g. a work email); github.com repos always use `~/.gitconfig-public`
- `pyproject.uv.toml`: appended to new projects' `pyproject.toml` (private package indexes)
- `requirements-work.txt`: symlinked into projects alongside the global requirements
- `setup.sh`: run by `environment_setup.sh`

Clone it during setup with `OVERLAY_REPO=<git url> ./environment_setup.sh`. A private scripts repo (bin's counterpart) can be cloned at `$BIN_WORK_DIR` (default `~/my_work_tools/bin_work`) with `BIN_OVERLAY_REPO=<git url>`; the overlay's `mybashrc.local` puts it on `PATH`.

### Using the scripts

#### 1) New machine

```bash
curl -fsSL https://github.com/jconwell3115/global_env/raw/roadhouse/environment_setup.sh -o environment_setup.sh
chmod +x environment_setup.sh
./environment_setup.sh        # add -y for an unattended run with defaults
```

#### 2) New project

```bash
setup_project.sh                                  # prompts for everything
setup_project.sh -n my_proj -r "repo1 repo2" -y   # no prompts; owner defaults to $GITHUB_OWNER
```

#### 3) Migrate a project to UV (manual use)

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

### AI token-reduction tools

`setup_ai_token_tools.sh [-o graphify|ponytail|links] [-u] [-y]` sets these up for the user, so every
repo gets them. It is safe to re-run.

- **Ponytail** (`DietrichGebert/ponytail`) cuts generated code. It makes the agent reuse existing
  code, the stdlib and installed deps before writing new code. The default level is `lite`, which
  names the lazier option instead of forcing it.
  - Installed as a Claude Code plugin (`claude plugin list`).
  - Level set in `~/.config/ponytail/config.json` and `PONYTAIL_DEFAULT_MODE` in `mybashrc`.
  - Commands: `/ponytail lite|full|ultra|off`, `/ponytail-review`, `/ponytail-gain`.
  - `claude plugin details ponytail@ponytail` shows its always-on cost (~1k tokens).
- **Graphify** (PyPI `graphifyy`) cuts file reads. It builds a knowledge graph of a repo that the
  agent queries instead of grepping, and is worth it on large repos.
  - Installed as a `uv tool` plus the global skill `~/.claude/skills/graphify/`.
  - Per repo: `/graphify .`, then optionally `graphify hook install` to rebuild on
    commit/checkout. The `graphify-out/` output is globally git-ignored.
  - It parses code locally, but sends docs, PDFs and images to Claude for concept extraction.
    Keep it to code on sensitive repos.
  - `graphify install` appends a `# graphify` block to `CLAUDE.md` through the symlink. Leave
    the heading as is, because the installer uses it to stay idempotent.
- **Instruction files** cut always-on context. `global-copilot-instructions.md` is the lean core
  (~5 KB, down from ~40 KB). Language detail lives in `copilot/*.instructions.md` and loads only
  for matching files (`applyTo`). `CLAUDE.md` is the Claude equivalent.
- **Links**: `~/.claude/CLAUDE.md`, `~/.github/copilot-instructions.md` and
  `~/.copilot/copilot-instructions.md` link back here. `~/.copilot/instructions/` gets one link per
  `copilot/*.instructions.md`, plus the work overlay's `copilot/` files when present (overlay wins
  on a name clash). Links to deleted files are pruned on each run.
  `~/.copilot/` is where current VS Code Copilot Chat and Copilot CLI read user instructions.
  `chat.instructionsFilesLocations` is deprecated and only used by the VS Code Local agent.

Copilot Chat in VS Code can't run plugins, so it gets the Ponytail rules from
`copilot/ponytail.instructions.md`. That folder is registered in `chat.instructionsFilesLocations`
(see `vscode_settings.json`). Copilot CLI steps are skipped until `copilot` is installed. Re-run the
script after installing it.

Remove everything with `setup_ai_token_tools.sh -u` (or `-u -o <tool>`).

### Key behaviors from `setup_lib.sh`

- Logging: `info`, `warn`, `err`, `die`, `section`. Prompts: `confirm` and `ask`, which honor `ASSUME_YES=1` (set by `-y`).
- `copy_config_files`: symlinks `requirements*` from `global_env` into a target folder (backing up differing plain files as `.bak.TIMESTAMP`) and copies `pyproject.toml` only if missing.
- `copy_precommit_config` / `copy_copilot_instructions`: symlink the shared files into a git repo and add them to `.git/info/exclude`.
- `setup_uv_if_needed`: runs `uv sync` when `uv.lock` exists (warning on failure), otherwise delegates to `new_uv_setup.sh`.
- `generate_uv_diagnostics`: writes `logs/uv-setup-diagnostics-YYYYMMDD_HHMMSS.txt` with system, UV, Python and project details.

### Logs and diagnostics

- `create_log_files` creates `logs/` files for the linters and formatters run by pre-commit.
- `generate_uv_diagnostics` writes its diagnostics file into `logs/` of the current directory.

### Safety, backups and notes

- Files that get replaced are backed up as `filename.bak.TIMESTAMP` unless they match the repo template. A renewed SSH key's old pair is kept as `id_ed25519.bak.TIMESTAMP`.
- Repos are cloned over SSH (`git@github.com:`); only the very first `global_env` clone uses HTTPS.
- `git pull` uses `--ff-only`; a repo with local changes or a diverged branch is left alone with a warning.

### Troubleshooting

- If `uv` is not found, `new_uv_setup.sh` attempts to install it.
- If `pre-commit` fails to install, ensure the target directory is a git repo and that Python/UV environment is available.
- Check `logs/` (including `logs/uv-setup-diagnostics-*.txt`) and the script output for detailed error information.

### Customization and contribution

- Edit `setup_lib.sh` to change copying rules or the `SHELL_TOOLS` list.
- Edit `paths.sh` (or export the variables before running) to change the directory layout or GitHub owner.
- Modify the UV configuration injected in `customize_pyproject_toml()` if you need to add private package indexes or extra build dependencies.

### Author / License

- Author: Jonathan Conwell
- This repository is a personal environment bootstrap. Review and adapt before running on production machines.
