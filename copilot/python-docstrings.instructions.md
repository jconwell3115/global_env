---
applyTo: "**/*.py"
description: "Python docstring templates (module, class, function)"
---

# Python Docstring Templates

Extends the docstring rules in `global-copilot-instructions.md`. Use these
shapes; include optional sections only when they add information.

## Module

Required: one-line summary, module-name heading (`=` underline), description,
`Key features`, `Parameters`, `Return value`, `Examples`, `Notes`.
Optional: `Raises`, `See Also`.

```python
"""Merge compliance results from multiple collectors.

compliance_merge
================

Combines per-device results into one report, resolving conflicts with
conservative merge semantics.

Key features
------------
- Deep-copies inputs so callers' data is never mutated.
- Extends lists and recursively merges dicts instead of replacing them.

Parameters
----------
results : list[dict[str, Any]]
    The per-collector result mappings. Must be non-empty.

Return value
------------
A ``dict`` keyed by normalized device name.

Examples
--------
Basic usage::

    report = merge_results([first, second])

Notes
-----
- O(n × m) for n results of average depth m.
"""
```

## Class

Required: summary, description, `Parameters` (for `__init__`), `Attributes`
(mark mutable ones and which methods **mutate** them), `Methods` (one line
each). Optional: `Examples`, `Notes` (thread safety, reuse), `See Also`.

```python
class ComplianceProcessor:
    """Evaluate device configs against compliance rules.

    Loads rules once and evaluates any number of devices against them.

    Parameters
    ----------
    result : dict[str, Any]
        The mutable result mapping returned to the caller.
    rules_path : Path
        The path to the rules YAML file.

    Attributes
    ----------
    result : dict[str, Any]
        **Mutated** by :meth:`run_module`.
    _rules : list[Rule]
        Parsed rules (internal).

    Methods
    -------
    run_module()
        Evaluate all devices and populate ``result``. Complexity: O(d × r).

    Notes
    -----
    - Not thread-safe; use one instance per thread.
    """
```

## Function / Method

reST fields for params/returns, Numpy headings for everything else, a blank
line before each heading. Optional headings: `Examples`, `Complexity`,
`Side effects`, `Warnings`, `Notes`, `See Also`.

```python
def merge_into(self, data: dict[str, Any], mode: str = "append") -> None:
    """Merge ``data`` into the internal state using ``mode``.

    :param data: The mapping to merge. Keys must be strings.
    :type data: dict[str, Any]
    :param mode: One of ``"append"`` (extend lists, default), ``"replace"``,
        or ``"merge"`` (recursive, preserve existing scalars).
    :type mode: str

    :returns: None
    :rtype: None

    Side effects
    ------------
    - **Mutates** ``self.state`` in place.
    - **Appends** an entry to ``self.history``.

    Raises
    ------
    ValueError
        When ``mode`` is not a supported value.

    Examples
    --------
    >>> obj.state = {"k": [1]}
    >>> obj.merge_into({"k": [2]})
    >>> obj.state
    {'k': [1, 2]}
    """
```

Parameter descriptions start with an article (a/an/the), state constraints
("non-empty", "positive"), and include units (e.g. "timeout in seconds").
