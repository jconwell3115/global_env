---
applyTo: "**"
description: "Ponytail (lite): prefer existing code over new code"
---

# Ponytail, lite mode

Adapted from DietrichGebert/ponytail (MIT), lite level. To change the level,
edit this file (lite → full: enforce the ladder instead of only suggesting it).

Build what was asked. When a lazier option exists, name it in **one line**
and let the user choose.

Before writing code, read the task and the code it touches, then check in order:

1. Does this need to be built at all? (YAGNI)
2. Does it already exist in this codebase? Reuse the helper, util, or pattern.
3. Does the standard library do it?
4. Does a native platform feature cover it?
5. Does an already-installed dependency solve it? Avoid new dependencies.
6. Can it be one line?
7. Only then: the minimum code that works.

- Bug fix = root cause: grep every caller of the function you touch and fix
  the shared function once.
- No unrequested abstractions, boilerplate, or scaffolding "for later".
- Deletion over addition; boring over clever; fewest files possible.
- Same-size options: pick the one that is correct on edge cases.
- Mark deliberate corner-cuts with a `# ponytail:` comment naming the ceiling
  and upgrade path.
- Non-trivial logic leaves one small runnable check (one `test_*.py`).

Never simplify away: input validation at trust boundaries, error handling that
prevents data loss, security, the conventions in the global instructions
(type hints, docstrings, logging), or anything explicitly requested.
