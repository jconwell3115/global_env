# Claude Code Instructions - Generic Starter

Copy this into a project's `CLAUDE.md` (or a workspace-root one for a
multi-repo setup) and fill in the bracketed placeholders. Delete any section
that doesn't apply — this is a starting point, not a checklist to satisfy.

## Project Overview

[Provide a concise description of the project, its purpose, and main
technologies used]

## Workspace Layout (Multi-Repo, if applicable)

- [Note if this is a parent workspace containing multiple repos, and where
  each lives]
- [Note where shared tooling config lives, e.g. a workspace-root
  `pyproject.toml` for Ruff/mypy]
- [Note per-repo validation, e.g. "each repo has its own
  `.pre-commit-config.yaml`; run `pre-commit` from that repo's root"]

## Code Style and Standards

### Python

- **Version**: [target Python version]
- **Formatting**: [formatter + line length, e.g. Ruff format, double quotes,
  90-char lines]
- **Linting**: [tools that must pass, e.g. `ruff check`, `mypy --strict`]
- **Imports**: [group order, e.g. stdlib → third-party → framework → local,
  isort-sorted]

### Modern Python Typing (3.10+)

If the project targets 3.10+, these are the modern forms — worth enforcing
via Ruff's `UP` (pyupgrade) rule regardless of project specifics:

| Old (deprecated)     | Modern (3.10+)              |
|-----------------------|------------------------------|
| `Optional[X]`          | `X \| None`                  |
| `Union[X, Y]`          | `X \| Y`                     |
| `List[X]` / `Dict[K,V]` / `Tuple[X,Y]` / `Set[X]` / `Type[X]` | `list[X]` / `dict[K,V]` / `tuple[X,Y]` / `set[X]` / `type[X]` |
| `typing.Callable`, `typing.Sequence`, `typing.Iterator` | `collections.abc.Callable`, etc. |

Still import from `typing` for `Any`, `ClassVar`, `Final`, `Literal`,
`Never`, `Protocol`, `TypeAlias`, `TypeVar`, `overload`, `Self` (3.11+),
`ParamSpec`. Prefer the `type X = ...` statement (3.12+) over `TypeAlias`
where possible.

### Repo-Specific Conventions

[Describe naming patterns and structural conventions specific to this repo —
e.g. a module/file naming prefix, where custom code entrypoints live, which
directories are generated/gitignored]

### Shell / Bash

- `bash` for scripts needing Bash features; POSIX `sh` when portability
  matters. Note the minimum Bash version if using Bash-specific features.
- Shebang: `#!/usr/bin/env bash`.
- Strict mode: `set -euo pipefail` and `IFS=$'\n\t'` unless there's a
  documented reason not to.
- Always quote expansions (`"$var"`) unless intentionally word-splitting.
- Prefer named functions (`function_name() { ... }`) with explicit `return`
  codes over inline blocks.
- Use `getopts` for flags; validate inputs; provide `--help` usage text.
- No `eval` or other arbitrary-input execution. Sanitize external input.
- Errors to stderr (`>&2`), not `echo`; use exit codes for failure states.
- `set -x` only for interactive debugging — never commit it enabled.
- Run `shellcheck`; wire it into `pre-commit` where applicable.
- Don't assume the environment — check for required commands and fail fast
  with a helpful message if missing.
- No secrets in scripts; use environment variables, and mark sensitive
  inputs so they're never logged.

## Documentation Style Guide (Python Docstrings)

A reasonable default if the project doesn't already have its own convention —
reST-flavored docstrings, pydocstyle-compatible (PEP 257 base, D200/D205/
D210/D211/D214/D215/D300/D301 enforced, D203/D212 ignored).

**Convention split:**
- **Modules & classes**: Numpy-style section headings (`Parameters`,
  `Attributes`, `Returns`, `Raises`, `Examples`, `Notes`, `See Also`), each
  preceded by a blank line, underlined with `=` (module title) or `-`
  (subsections).
- **Functions & methods**: reST field lists (`:param name:`, `:type name:`,
  `:returns:`, `:rtype:`), with a `Raises` section heading (Numpy-style) for
  exceptions — blank line before it.

**Universal rules:**
- `"""Triple double quotes"""` only.
- One-line docstrings fit on one line; first line ends with a period,
  imperative mood ("Do X", not "Does X"), capitalized first word.
- Multi-line: summary line → blank line → body / sections.
- Use double backticks for inline code (`` ``variable_name`` ``).
- Document all exceptions, side effects (mutations, I/O, state changes —
  call out with **bold**), and non-obvious edge cases.
- Type annotations in code must match `:type:`/`:rtype:` declarations.
- Cross-reference with `:class:`, `:meth:`, `:mod:`, `:py:meth:`.

**Minimal example (function):**

```python
def normalize_identifier(value: str, aliases: dict[str, str] | None = None) -> str:
    """Normalize an identifier for consistent lookup.

    :param value: Raw identifier as received from the caller.
    :type value: str
    :param aliases: Optional mapping of known aliases to canonical names.
    :type aliases: dict[str, str] | None

    :returns: The normalized, lowercase, alias-resolved identifier.
    :rtype: str

    Raises
    ------
    ValueError
        If ``value`` is empty after stripping whitespace.
    """
```

**Minimal example (module/class heading style):**

```python
"""One-line summary of the module.

module_name
===========

Extended description of purpose and context.

Parameters
----------
param_name : type
    Description, constraints, default.

Returns
-------
On success, returns ...

Raises
------
ValueError
    When ...
"""
```

Follow this same Numpy-heading pattern for class docstrings (`Parameters` for
`__init__`, `Attributes` for public/protected attrs, `Methods` summarizing
each public method).

## Project Structure Pattern

[If the project follows a consistent structural pattern, describe it here.
Example — business logic isolated in a class, `main()`/entrypoint doing only
init/wiring/delegation, private helpers prefixed `_`:]

```python
class ExampleProcessor:
    """One-line summary of what this class processes.

    Parameters
    ----------
    config : dict
        Configuration for this run.
    """

    def __init__(self, config: dict) -> None:
        self.config = config

    def _validate(self) -> None:
        """Validate configuration before running."""

    def run(self) -> dict:
        """Execute the pipeline and return the result."""
        self._validate()
        return {"status": "ok"}


def main() -> None:
    """Entry point: init, instantiate, delegate."""
    config = {}
    result = ExampleProcessor(config).run()
    print(result)


if __name__ == "__main__":
    main()
```

## Best Practices

1. Type-hint every parameter and return value.
2. Document side effects explicitly with **bold** emphasis.
3. Normalize input identifiers (`identifier.strip().lower()`) early, before
   any comparison or dict lookup.
4. Deep-copy when merging data structures (`copy.deepcopy`) to avoid shared
   references.
5. Prefer conservative merges: extend lists, merge dicts recursively,
   preserve existing data over destructive replacement.
6. Use `field(default_factory=list)` / `dict` for mutable dataclass
   defaults — never bare `[]`/`{}`.
7. Log with context (relevant identifiers, operation) at the right level;
   never log secrets. Standard logger setup: `logging.getLogger(__name__)`,
   file + stream handler, `INFO` default.
8. Use specific exceptions, not bare `Exception`/`ValueError`; include
   context in the message (object, identifier, path, etc.).

## Repo Commands

[Fill in the actual commands for this project once known, e.g.:]

```bash
# Lint / type-check
python -m ruff check .
python -m mypy --ignore-missing-imports [package_dir]/

# Format
python -m ruff format .

# Tests
python -m pytest -q
pre-commit run --all-files
```

## Security Considerations

- Never log tokens, passwords, or credentials.
- Mark sensitive parameters so they're excluded from logs (framework
  permitting, e.g. Ansible's `no_log=True`).
- Validate all external input.
- Follow least privilege for any credentials used.
