# Global Claude Code Instructions

Symlinked to `~/.claude/CLAUDE.md`, so it applies to every project. Keep it
short: it's loaded into every session. Project-specific rules belong in the
project's own `CLAUDE.md`. The Copilot equivalent is
`global_env/global-copilot-instructions.md`; keep the two in sync.

## Workspace Layout

- Workspaces are parent projects containing multiple repos under `$WORK_ENV_DIR`.
- Ruff/mypy config is centralized in the workspace-root `pyproject.toml`.
- Each repo has its own `.pre-commit-config.yaml`; run `pre-commit` from the repo root.

## Python

- 3.12+; Ruff format, double quotes, 90-char lines; must pass `ruff check` and
  `mypy --strict --ignore-missing-imports`.
- Imports: stdlib → third-party → framework (`ansible.module_utils.*`) → local.
- Modern typing only (Ruff `UP`): `X | None`, `X | Y`, `list`/`dict`/`tuple`/
  `set`/`type[X]`, `collections.abc.Callable`/`Sequence`/`Iterator`, and
  `type X = ...` aliases. Import from `typing` only for `Any`, `ClassVar`,
  `Final`, `Literal`, `Never`, `Protocol`, `Self`, `TypeVar`, `ParamSpec`,
  `overload`.
- Structure: logic in classes, private helpers prefixed `_`; `main()` only
  restores SIGINT, inits args/module, instantiates, and delegates to
  `run_module()`. Ansible modules live in `library/` and use
  `module.fail_json()`/`exit_json()`.

### Docstrings

reST, pydocstyle (PEP 257; D203/D212 ignored). Summary in imperative mood, ends
with a period, blank line after it. Modules/classes use Numpy headings
(`Parameters`, `Attributes`, `Returns`, `Raises`, `Examples`, `Notes`,
`See Also`). Functions use `:param:`/`:type:`/`:returns:`/`:rtype:` plus a Numpy
`Raises` heading. Blank line before every heading. Document exceptions and side
effects (mutations/I/O in **bold**). Types must match annotations. Full
templates: `global_env/copilot/python-docstrings.instructions.md`.

## Shell / Bash

- `#!/usr/bin/env bash`, `set -euo pipefail`, `IFS=$'\n\t'`; quote expansions.
- Named functions with explicit `return`; `getopts` + `--help`; no `eval`.
- Errors to stderr with non-zero exit; never commit `set -x`; pass `shellcheck`.
- Check for required commands up front. Reuse the `global_env/setup_lib.sh`
  helpers (`info`, `warn`, `err`, `die`, `confirm`).

## Rules

- Type-hint everything. Normalize identifiers early (`.strip().lower()`).
- Conservative merges: `copy.deepcopy`, extend lists, merge dicts recursively.
- `field(default_factory=list)` for mutable dataclass defaults.
- Specific exceptions with context; never swallow them silently.
- `logging.getLogger(__name__)`, file (`logs/<module>.log`) + stream, `INFO`.
- Never log secrets; `no_log=True` for sensitive Ansible params; validate input.

## Repo Commands

```bash
python -m ruff check . && python -m ruff format --check .
python -m mypy --ignore-missing-imports <package_dir>/
python -m pytest -q
pre-commit run --all-files
```

Commits: `type(scope): subject` (feat, fix, docs, style, refactor, test, chore).

<!-- pyml disable md022 -->

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
