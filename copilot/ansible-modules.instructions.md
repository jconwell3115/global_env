---
applyTo: "**/library/*.py"
description: "Ansible custom module skeleton and validation"
---

# Ansible Custom Modules

Logic lives in a class; `main()` only restores SIGINT, builds the
`AnsibleModule`, instantiates the class, and delegates. Errors go through
`module.fail_json()`, never `sys.exit()` once the module exists.

```python
"""Short summary of the module.

pn_example_module
=================

Description of what the module does.
"""

import signal
import sys
from typing import Any

try:
    from ansible.module_utils.basic import AnsibleModule  # type: ignore
except ImportError as e:
    print(f"Error importing Ansible modules: {e}", file=sys.stderr)
    sys.exit(1)


class ExampleModuleProcessor:
    """Process module logic for Ansible."""

    def __init__(self, result: dict[str, Any], module: AnsibleModule) -> None:
        self.result = result
        self.module = module
        self.param1: str = module.params["param1"].strip().lower()

    def _validate_input(self) -> None:
        """Validate module parameters."""
        if not self.param1:
            raise ValueError("param1 cannot be empty")

    def run_module(self) -> None:
        """Run the pipeline and exit via ``module.exit_json()``."""
        self._validate_input()
        self.result["changed"] = True
        self.module.exit_json(**self.result)


def main() -> None:
    """Restore SIGINT, build the module, and delegate."""
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    module_args = {
        "param1": {"type": "str", "required": True},
        "secret": {"type": "str", "required": False, "no_log": True},
    }
    result: dict[str, Any] = {"changed": False}
    module = AnsibleModule(argument_spec=module_args, supports_check_mode=False)
    try:
        ExampleModuleProcessor(result, module).run_module()
    except Exception as e:  # noqa: BLE001 - report every failure through Ansible
        module.fail_json(msg=f"Module failed: {e}", **result)


if __name__ == "__main__":
    main()
```

Playbook conventions: 2-space YAML, snake_case variables with a project
prefix, tags on every task, explicit `failed_when` / `changed_when`.

Validate:

```bash
ansible-lint <playbook_pattern>*.yml
ansible-playbook --syntax-check <playbook_pattern>*.yml
python -m mypy --ignore-missing-imports library/
```
