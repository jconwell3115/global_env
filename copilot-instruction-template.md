# GitHub Copilot Instructions - Generic Template

## Project Overview

[Provide a concise description of the project, its purpose, and main technologies used]

## Code Style and Standards

### Language-Specific Guidelines

#### Python

- **Version**: [Specify minimum Python version, e.g., Python 3.12+]
- **Type Hints**: All functions, methods, and classes must include complete type
  hints using `typing` module (Dict, List, Optional, Union, Any)
- **Formatting**: Follow PEP 8 with line length of [88/100/120] characters
- **Linting**: Code must pass `mypy`, `pylint`, `ruff` [specify tools and any ignore flags]
- **Imports**: Group imports as: stdlib, third-party, local modules (use `isort` for sorting)

## Documentation Style Guide

### Python Docstrings

All Python modules, classes, methods, and functions must use reStructuredText
(reST) format with the following enhanced structure:

#### Module Docstrings

Module docstrings should be comprehensive and serve as the primary reference documentation.

**Required sections:**

- Module name as heading with `=` underline
- One-line summary
- Detailed description with context and use cases
- **Key features** (bulleted list with specific, measurable benefits)
- **Parameters** (with type hints and default values)
- **Return value** (with structure details)
- **Examples** (with realistic, runnable code)
- **Notes** (gotchas, performance considerations, limitations)

**Enhanced sections to add:**

- **Raises** (document expected exceptions)
- **See Also** (links to related modules/classes)
- **Version history** (when applicable)

Example:

```python
"""module_name
==============

A brief one-line description of what this module does.

Extended description explaining the module's purpose, architectural context,
and how it fits into the larger system. Include any important background
information that users need to understand before using the module.

Key features
------------
- First key feature with specific, measurable benefit.
- Second key feature explaining what problem it solves.
- Third feature with performance or usability advantages.
- Additional features as needed with clear value proposition.

Parameters
----------
param_name : type
    Description of the parameter, including constraints, valid ranges,
    and default values. Start with an article (a/an/the) for clarity.
    Include units where applicable (e.g., timeout in seconds).
another_param : type, optional
    Description of optional parameter with default value mentioned.
    Explain when this parameter should or should not be used.

Return value
------------
On success [describe what success means]. The returned [type] contains
the following keys/attributes:

- ``key_name`` : type
    Description of this return value component with structure details.
- ``another_key`` : type
    Description with any important constraints or special values.

Examples
--------
Basic usage::

    # Example code showing typical usage
    result = function_call(param1="value1", param2=42)
    print(result)

Advanced usage with error handling::

    try:
        result = function_call(param1="value1")
        process_result(result)
    except ValueError as e:
        handle_error(e)

Notes
-----
- Important gotcha or limitation that users should know.
- Performance consideration (e.g., O(n²) complexity on large inputs).
- Thread safety or concurrency constraints.
- Compatibility notes or version requirements.

Raises
------
ExceptionType
    When this specific error condition occurs.
AnotherException
    When this different error condition is encountered.

See Also
--------
:mod:`related_module` : Description of how it relates
:class:`RelatedClass` : Description of relationship
"""
```

#### Class Docstrings

Class docstrings should provide a complete API reference for users.

**Required sections:**

- One-line summary (what the class does)
- Extended description (architectural context, design rationale)
- **Parameters** (for `__init__`, with types and constraints)
- **Attributes** (all public/protected attributes with types and purposes)
- **Methods** (brief summary of each public method)

**Enhanced sections to add:**

- **Examples** (show typical instantiation and usage patterns)
- **Thread safety** (if relevant)
- **Inheritance** (if subclassing is expected)

**Improvements:**

1. Add type information to all Parameters and Attributes
2. Distinguish between mutable and immutable attributes
3. Document attribute lifecycle (when set, when modified)
4. Include complexity notes for methods

Example:

```python
class ClassName:
    """Brief one-line description of what this class does.

    Extended description explaining the class's purpose, design patterns
    used (e.g., factory, singleton, pipeline), and architectural context.
    Explain when and why users would instantiate this class.

    Parameters
    ----------
    init_param : type
        Description of initialization parameter with any constraints.
        Note if this is stored as an attribute or only used during init.
        
        **Warning**: Mention any important caveats or side effects.
        
    optional_param : type, optional
        Description of optional parameter with default behavior.

    Attributes
    ----------
    attribute_name : type
        Description of this attribute and its purpose.
        Modified by [method names] or [when it changes].
        
    mutable_attribute : type
        Description emphasizing that this is mutable.
        **Mutated** by these methods: :meth:`method1`, :meth:`method2`.
        
    _protected_attr : type
        Description of protected attribute (internal use).
        Users should not access this directly.

    Methods
    -------
    public_method(param1, param2)
        Brief one-line description. Complexity: O(n).
        
    another_method()
        Brief description. Side effects: modifies state.
        
    _private_method()
        Internal helper method, not for public use.

    Examples
    --------
    Basic instantiation and usage::

        obj = ClassName(init_param="value")
        result = obj.public_method(param1=1, param2=2)
        print(result)

    Advanced usage with context manager::

        with ClassName(init_param="value") as obj:
            obj.process_data(data)

    Notes
    -----
    - This class is not thread-safe. Use separate instances per thread.
    - All methods except :meth:`run` are designed to be called in
      sequence. Calling them individually may produce incomplete results.
    - The class maintains internal state. Do not reuse instances.
    
    See Also
    --------
    :class:`RelatedClass` : Similar class with different behavior
    """
```

#### Method/Function Docstrings

Method docstrings should provide complete operational documentation.

**Required sections:**

- One-line summary (imperative mood: "Do X" not "Does X")
- Extended description (algorithm, approach, edge cases)
- **Parameters** (`:param name:` and `:type name:`)
- **Returns** (`:returns:` and `:rtype:`)

**Enhanced sections to add:**

- **Raises** (document all exceptions that can be raised)
- **Examples** (show typical usage and edge cases)
- **Complexity** (Big-O notation for non-trivial algorithms)
- **Side effects** (all mutations, I/O, state changes)
- **Warnings** (common pitfalls, gotchas)

**Improvements:**

1. Add concrete examples showing inputs and outputs
2. Document all possible return values explicitly
3. Add type constraints beyond basic type (e.g., "non-empty string")
4. Include performance characteristics
5. Document thread safety explicitly

Example (basic function):

```python
def function_name(param1: str, param2: int = 10) -> List[str]:
    """Brief one-line summary in imperative mood (verb + object).

    Extended description explaining what the function does, the algorithm
    or approach used, and any important edge cases or special handling.
    Describe the overall flow and logic.

    :param param1: Description starting with article (a/an/the).
        Include constraints like "non-empty string" or "must be positive".
        Mention units where applicable.
    :type param1: str
    
    :param param2: Description of this parameter with default value noted.
        Explain what the default means and when to override it.
    :type param2: int

    :returns: Description of what is returned. For complex structures,
        describe the format, keys, or elements. Mention special values
        like None or empty list and what they signify.
    :rtype: list of str

    Raises
    ------
    ValueError
        When param1 is empty or param2 is negative.
    TypeError
        When param1 is not a string.

    Examples
    --------
    Basic usage::

        >>> result = function_name("input", param2=5)
        >>> print(result)
        ['output1', 'output2', 'output3']

    Edge case with default parameter::

        >>> result = function_name("test")
        >>> len(result)
        10

    Complexity
    ----------
    O(n) where n is the value of param2.

    Notes
    -----
    - This function is thread-safe and can be called concurrently.
    - For best performance, keep param2 below 1000.
    
    See Also
    --------
    :func:`related_function` : Similar function with different behavior
    """
```

Example (complex method with side effects):

```python
def method_with_side_effects(
    self,
    data: Dict[str, Any],
    mode: str = "append"
) -> None:
    """Process and merge data into internal state with specified mode.

    Extended description explaining the merge algorithm, how conflicts
    are resolved, and what transformations are applied to the data.
    Describe the method's role in the class's overall workflow.

    :param data: Mapping of keys to values to be merged. Keys must be
        strings matching the expected schema. Values can be nested dicts,
        lists, or scalars. See **Merge semantics** for details.
    :type data: dict of {str: Any}
    
    :param mode: Merge mode controlling behavior. Valid values:
        
        - ``'append'`` -- Add data, extending lists (default)
        - ``'replace'`` -- Replace existing data completely
        - ``'merge'`` -- Deep merge, preserving existing values
        
    :type mode: str

    Merge semantics
    ---------------
    Behavior varies by mode and data types:
    
    **Append mode**
        - Lists are extended with new elements
        - Dicts are updated with new keys
        - Scalars replace existing values
        
    **Replace mode**
        - All existing data under matching keys is replaced
        - No preservation of previous values
        
    **Merge mode**
        - Dicts are recursively merged
        - Lists are extended if both exist, else replaced
        - Scalars preserve existing values

    Side effects
    ------------
    - **Mutates** ``self.internal_state`` in-place based on mode.
    - **Appends** entries to ``self.history`` for audit trail.
    - Performs **deep copying** to prevent shared references.
    - May **trigger** validation callbacks if registered.

    :returns: None -- All modifications are performed via side effects.
    :rtype: None

    Raises
    ------
    ValueError
        When mode is not one of the valid values.
    TypeError
        When data is not a dict or contains invalid types.
    KeyError
        When required keys are missing from data dict.

    Examples
    --------
    Appending new data::

        >>> obj.internal_state = {"key1": [1, 2]}
        >>> obj.method_with_side_effects({"key1": [3, 4]}, mode="append")
        >>> obj.internal_state
        {"key1": [1, 2, 3, 4]}

    Replacing existing data::

        >>> obj.internal_state = {"key1": [1, 2]}
        >>> obj.method_with_side_effects({"key1": [3, 4]}, mode="replace")
        >>> obj.internal_state
        {"key1": [3, 4]}

    Complexity
    ----------
    O(n × m) where:
    
    - n = number of keys in data
    - m = average depth of nested structures
    
    Deep copying adds overhead proportional to data size.

    Warnings
    --------
    - Modifies state in-place. Create a snapshot if original needed.
    - Replace mode is destructive and cannot be undone.
    - Thread-safety: Not safe for concurrent calls on same instance.

    Notes
    -----
    - Empty data dict is a no-op but still validates mode.
    - None values in data are treated as explicit removals.
    - Nested mutations trigger validation only after full merge.

    See Also
    --------
    :meth:`validate_state` : Called after merging to check consistency
    :meth:`get_snapshot` : Create immutable copy before mutations
    """
```

### Formatting Rules

**Strict requirements:**

- Use double backticks for inline code: \`\`variable_name\`\`
- Use 4-space indentation for continuation lines in bulleted lists
- Section headings use title case
- Section underlines: `=` for module title, `-` for all subsections
- Code examples use `::` followed by 8-space indented blocks
- Multi-line return descriptions align with first line
- Type annotations in code must match `:type:` and `:rtype:` directives
- Blank line required before and after each section heading

**Enhanced rules:**

- Use consistent tense: present tense for descriptions, imperative for summaries
- Begin parameter descriptions with articles (a/an/the) for clarity
- Include units in parameter descriptions (e.g., "timeout in seconds")
- Use Oxford commas in lists
- Capitalize Python types: List, Dict, Optional, etc.
- Use "Returns None" not "Returns nothing" or "Returns: None"
- Document mutations explicitly with **bold** emphasis

**Cross-referencing:**

- Use `:class:`ClassName`` for class references
- Use `:meth:`method_name`` for method references
- Use `:mod:`module_name`` for module references
- Use `:py:meth:`full.path.method`` for external references
- Add **See Also** sections with related references

**Examples section requirements:**

- Show realistic, executable examples
- Include expected output when helpful
- Cover common use cases and edge cases
- Use `>>>` for interactive Python examples
- Use `::` for other code examples
- Comment complex examples inline

### Quality Checklist

Before finalizing docstrings, verify:

- [ ] One-line summary is imperative and under 80 characters
- [ ] All parameters documented with type and description
- [ ] All return values documented with type and structure details
- [ ] All exceptions documented in Raises section
- [ ] All side effects explicitly documented
- [ ] Examples provided for non-trivial functionality
- [ ] Complexity documented for algorithms
- [ ] Cross-references to related functions/classes
- [ ] Warnings for common mistakes or gotchas
- [ ] Thread safety explicitly stated if relevant
- [ ] Type hints in code match docstring types

## Project-Specific Conventions

### Naming Conventions

[Define project-specific naming patterns]

- Module names: [pattern, e.g., lowercase_with_underscores]
- Class names: [pattern, e.g., PascalCase with prefix]
- Function names: [pattern, e.g., lowercase_with_underscores]
- Constants: [pattern, e.g., UPPER_CASE_WITH_UNDERSCORES]
- Private members: [pattern, e.g., _leading_underscore]

### Domain-Specific Patterns

[Describe any domain-specific patterns, idioms, or conventions]

Example:

- Always normalize identifiers using `identifier.strip().lower()`
- Use conservative merge semantics: extend lists, merge dicts
- Prefer immutable data structures for public APIs

### Error Handling

[Define error handling strategy]

- Use specific exceptions, not generic `Exception`
- Always provide context in error messages (what, why, how to fix)
- Log errors at appropriate levels (debug, info, warning, error)
- Document all exceptions in docstring `Raises` section

### Testing

[Define testing requirements and patterns]

- Minimum test coverage: [percentage]%
- Test framework: [pytest, unittest, etc.]
- Mock external dependencies
- Test edge cases: None, empty, single item, many items
- Verify type hints with mypy

## File Organization

[Describe the project's directory structure]

```shell
project-root/
├── src/                 # Source code
├── tests/               # Test files
├── docs/                # Documentation
├── scripts/             # Utility scripts
├── requirements.txt     # Dependencies
└── README.md           # Project overview
```

## Common Patterns

### [Pattern Name 1]

[Describe a common pattern used in the codebase with example]

```python
# Example code showing the pattern
```

### [Pattern Name 2]

[Describe another common pattern]

```python
# Example code
```

## Best Practices

1. **Practice 1** - Description of best practice and why it matters
2. **Practice 2** - Another important practice with rationale
3. **Practice 3** - Additional guidance for code quality
4. **Practice 4** - Performance or security considerations
5. **Practice 5** - Maintainability and readability guidelines

## Dependencies and Integration

[Document key dependencies and how to integrate with external systems]

### Required Dependencies

- [Dependency 1]: [version] - [purpose]
- [Dependency 2]: [version] - [purpose]

### External Integrations

[Describe any external systems, APIs, or services the project integrates with]

## Security Considerations

[List security best practices specific to this project]

- Never log sensitive data (tokens, passwords, keys)
- Use parameter `no_log=True` for sensitive inputs
- Validate all external input
- Use parameterized queries for database access
- Follow principle of least privilege

## Performance Guidelines

[Provide performance-related guidance]

- Complexity targets: [e.g., O(n) preferred, avoid O(n²) for large datasets]
- Caching strategy: [when and how to cache]
- Batch operations when possible
- Profile before optimizing

## Version Control

[Define commit message format and branching strategy]

### Commit Messages

Format: `type(scope): subject`

Types: feat, fix, docs, style, refactor, test, chore

Example: `feat(auth): add OAuth2 support`

### Branch Naming

- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `hotfix/description` - Urgent production fixes
- `docs/description` - Documentation updates
