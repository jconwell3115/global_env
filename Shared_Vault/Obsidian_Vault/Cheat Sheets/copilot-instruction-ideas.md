  # What You Can Control in copilot-instructions.md

Your `.github/copilot-instructions.md` file can control several aspects of how AI coding agents interact with your codebase. Here are additional sections and approaches you can use:

# Content You Can Add

### **Prohibited Actions / Don't Do This**
Explicitly tell agents what NOT to do:
```markdown
## Restrictions
- **Never** modify production config files without creating timestamped backups
- **Don't** use `subprocess.run()` without timeout parameters
- **Avoid** hardcoding credentials - always use environment variables
- **Don't** modify `global_env/` templates without updating all dependent projects
```



## **Code Style Preferences**
Beyond what linters enforce:
- Prefer f-strings over `.format()` or `%` formatting
- Use pathlib for path operations instead of os.path
- Import order: stdlib, third-party, local (enforced by ruff isort)
- Maximum function complexity: 10 (McCabe)
- Prefer explicit over implicit: use `if x is not None` not `if x`

## **Testing Requirements**
- Run `python script.py --help` to verify argparse setup
- Test error paths: missing files, invalid env vars, network timeouts
- Use `ansible-playbook --check` before actual runs
- Validate generated files exist in `output/` directory

## **Decision Trees**
> Help agents make choices autonomously:
- **New script needed?** → Copy `base_python_script.py`, don't start from scratch
- **Modifying configs?** → Check if it's in `global_env/` (affects all projects) vs local
- **Adding dependency?** → Check if it's in Marriott Artifactory first, then PyPI
- **Ansible task failing?** → Add `-vvv` for debug, check `ansible.cfg` settings

## **Environments**
- **Dev**: `dev-mind-pulse.cld.marriott.com` (safe for testing)
- **Perf**: Performance testing only, may have stale data
- **Prod**: `mind-pulse.cld.marriott.com` (require explicit confirmation for changes)

## **Troubleshooting**
- **UV sync fails**: Check `extra-build-dependencies` for packages needing setuptools
- **Ansible module errors**: Run with `ANSIBLE_MODULE_ARGS` env var for local debug
- **Import errors**: Ensure virtualenv activated and `uv sync` completed
- **Confluence 401**: Verify `CONFLUENCE_API_TOKEN` is set and not expired

## **File Placement**
- Scripts with CLI args → `bin/`
- Ansible modules → `ansible-work-tools/library/`
- Shared configs → `global_env/`
- Generated reports → `ansible-work-tools/output/` (gitignored)
- Logs → `logs/` subdirectories (gitignored)
- Templates → `bin/templates/` or playbook-specific dirs

## **Agent Behavior**
- Be concise: show code first, explain only when complex
- Prefer working code over explanations
- When backing up files, just do it - don't ask permission
- If uncertain about Marriott-specific tools, ask rather than guess

## **Compatibility**
- Python: 3.12+ required (uses `match` statements, type hints)
- Ansible: <2.18 (pinned in pyproject.toml)
- UV: Latest stable (auto-update via `curl -LsSf https://astral.sh/uv/install.sh | sh`)
- Confluence API: REST API v2 (not deprecated v1)

## **Reference Documentation**
- [Confluence REST API](https://developer.atlassian.com/cloud/confluence/rest/v2/intro/)
- [UV Documentation](https://docs.astral.sh/uv/)
- [Ruff Rules](https://docs.astral.sh/ruff/rules/)
- [Ansible Module Development](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html)
- Internal: Marriott Artifactory PyPI index

## **Priorities**
When making trade-offs, prefer:
1. Reliability over performance (network automation context)
2. Explicit error messages over silent failures
3. Backup/safety over speed (timestamped backups are cheap)
4. Type safety (mypy strict mode) over dynamic flexibility

## **Output Standards**
- Console: Use colored output via `shell_functions.sh` (`info`, `warn`, `err`)
- Reports: Excel format (openpyxl), saved to `output/` with ISO date suffix
- Logs: Timestamped, one per tool in `logs/` directory
- Confluence: Markdown or Excel attachments with descriptive filenames

## What You Can't Control

- The agent's underlying model capabilities
- Token limits or context windows
- Whether the agent will always follow instructions (they're guidance, not guarantees)
- Real-time access to Marriott internal systems (agents work with code/docs you provide)

## Best Practices for Your File

1. **Be specific**: "Use [requests](vscode-file://vscode-app/c:/Users/jconw483/AppData/Local/Programs/Microsoft%20VS%20Code/resources/app/out/vs/code/electron-browser/workbench/workbench.html) with 30s timeout" vs "handle timeouts properly"
2. **Include examples**: Show actual code snippets from your codebase
3. **Keep it current**: Update when patterns change (you can version-control this file)
4. **Test it**: Ask agents to do common tasks and see if they follow the instructions
5. **Prioritize**: Put most important/frequently-violated rules at the top
