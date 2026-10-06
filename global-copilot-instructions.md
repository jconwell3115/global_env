# GitHub Copilot Instructions

Global rules for every workspace. Language-specific detail lives in
`global_env/copilot/*.instructions.md` and loads only for matching files
(Python docstring templates, Ansible module skeleton).

## Workspace Layout (Multi-Repo)

- A workspace is a parent project containing multiple repositories.
- Tooling config (Ruff, mypy) is centralized in the workspace-root `pyproject.toml`.
- Each repo has its own `.pre-commit-config.yaml`; run `pre-commit` from the repo root.

## Python

- **Version**: 3.12+.
- **Formatting**: PEP 8, 90-char lines, double quotes only (Ruff formatter).
- **Linting**: must pass `ruff` (lint + import sorting) and `mypy` (strict,
  `ignore_missing_imports=true`).
- **Imports**: stdlib → third-party → framework (e.g. `ansible.module_utils.*`) → local.

### Modern Typing (enforced by Ruff `UP`)

| Old (deprecated) | Modern |
|---|---|
| `Optional[X]` | `X \| None` |
| `Union[X, Y]` | `X \| Y` |
| `List[X]` / `Dict[K, V]` / `Tuple[X, Y]` | `list[X]` / `dict[K, V]` / `tuple[X, Y]` |
| `Set[X]` / `FrozenSet[X]` / `Type[X]` | `set[X]` / `frozenset[X]` / `type[X]` |
| `typing.Callable` / `Sequence` / `Iterator` / `Generator` / `Mapping` | `collections.abc.*` |
| `X: TypeAlias = ...` | `type X = ...` (3.12+) |

Still import from `typing`: `Any`, `ClassVar`, `Final`, `Literal`, `Never`,
`Protocol`, `Self`, `TypeVar`, `ParamSpec`, `overload`.

### Structure

- Business logic lives in classes; private helpers are prefixed `_`.
- `main()` only restores the SIGINT handler
  (`signal.signal(signal.SIGINT, signal.SIG_DFL)`), parses args / inits the
  module, instantiates the class, and delegates to its `run_module()`.
- Ansible modules: entrypoints in `library/`; use `module.fail_json()` /
  `module.exit_json()`, never `sys.exit()`. Non-Ansible code goes in a package
  at the repo root.
- Packaged, operator-editable YAML lives inside the package and is loaded with
  `importlib.resources.files(__package__).joinpath("rules.yaml")`.

### Docstrings

reST, pydocstyle-compatible (PEP 257; D203/D212 ignored; tests exempt).

- `"""Triple double quotes"""`; summary line in imperative mood, capitalized,
  ends with a period, under 80 chars; blank line after it.
- **Modules/classes**: Numpy-style headings (`Parameters`, `Attributes`,
  `Returns`, `Raises`, `Examples`, `Notes`, `See Also`), `=` underline for the
  module title, `-` for subsections, blank line before every heading.
- **Functions/methods**: reST fields `:param x:` / `:type x:` / `:returns:` /
  `:rtype:`, then a Numpy `Raises` heading (blank line before it).
- Document every exception and every side effect; call out mutations/I/O in
  **bold**. Docstring types must match the annotations.
- Inline code in double backticks; cross-reference with `:class:`, `:meth:`, `:mod:`.

```python
def normalize_identifier(value: str, aliases: dict[str, str] | None = None) -> str:
    """Normalize an identifier for consistent lookup.

    :param value: The raw identifier as received from the caller.
    :type value: str
    :param aliases: An optional mapping of known aliases to canonical names.
    :type aliases: dict[str, str] | None

    :returns: The stripped, lowercase, alias-resolved identifier.
    :rtype: str

    Raises
    ------
    ValueError
        If ``value`` is empty after stripping whitespace.
    """
```

## Shell / Bash

- `#!/usr/bin/env bash`; `set -euo pipefail` and `IFS=$'\n\t'` unless documented otherwise.
- Quote all expansions (`"$var"`); named functions with explicit `return` codes.
- `getopts` for flags, validate inputs, provide `--help`.
- No `eval`; sanitize external input. Errors to stderr (`>&2`) with non-zero exit codes.
- Never commit `set -x`. Must pass `shellcheck`.
- Check for required commands and fail fast with a helpful message.
- Reuse the helpers in `global_env/setup_lib.sh` / `shell_functions.sh`
  (`info`, `warn`, `err`, `die`, `confirm`).

## Rules

- Type-hint every parameter and return value.
- Normalize identifiers early with `value.strip().lower()` before any comparison or lookup.
- Merge conservatively: `copy.deepcopy`, extend lists, merge dicts recursively,
  preserve existing data.
- Dataclass mutable defaults use `field(default_factory=list)`, never `[]`/`{}`.
- Raise specific exceptions (`FileNotFoundError`, `KeyError`, …) with context:
  `"Action failed: {context}. {suggestion}"`. Never swallow exceptions silently.
- Logging: `logging.getLogger(__name__)`, file (`logs/<module>.log`) + stream
  handlers, `INFO` default, format
  `%(asctime)s - %(name)s - %(levelname)s - [%(lineno)d] - %(message)s`.
  Include context (device, platform, rule, operation).
- Security: never log tokens/passwords/credentials; `no_log=True` for sensitive
  Ansible params; validate external input; least privilege.
- Prefer existing code, the stdlib, and installed dependencies over new code.

## Repo Commands

```bash
python -m ruff check . && python -m ruff format --check .
python -m mypy --ignore-missing-imports <package_dir>/
python -m pytest -q
pre-commit run --all-files
```

## Version Control

- Commits: `type(scope): subject` (feat, fix, docs, style, refactor, test, chore).
- Branches: `feature/…`, `bugfix/…`, `hotfix/…`, `docs/…`.

## graphify

- **graphify** (`~/.copilot/skills/graphify/SKILL.md`): turns any input into a knowledge
  graph. Trigger: `/graphify`.
- When the user types `/graphify`, load that skill before doing anything else.
- If `graphify-out/` exists in the repo, answer codebase/architecture questions from
  `graphify-out/GRAPH_REPORT.md` and the graph before grepping files.
