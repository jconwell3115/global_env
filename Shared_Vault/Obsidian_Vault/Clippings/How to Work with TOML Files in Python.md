---
title: "How to Work with TOML Files in Python"
source: "https://www.freecodecamp.org/news/how-to-work-with-toml-files-in-python/"
author:
  - "[[Bala Priya C]]"
published: 2025-10-24
created: 2025-10-26
description: "TOML (Tom's Obvious Minimal Language) has become the modern standard for configuration files in Python projects. It's more expressive than INI files and cleaner than JSON or YAML. Since Python 3.11, the standard library includes the tomllib module fo..."
tags:
  - "clippings"
---
TOML (Tom's Obvious Minimal Language) has become the modern standard for configuration files in Python projects. It's more expressive than INI files and cleaner than JSON or YAML.

Since Python 3.11, the standard library includes the [tomllib](https://docs.python.org/3/library/tomllib.html) module for reading and parsing TOML files. TOML offers several advantages over other configuration formats. It supports complex data types like arrays and nested tables while remaining human-readable. Many Python projects, including [Poetry](https://python-poetry.org/) and [setuptools](https://pypi.org/project/setuptools/), use `pyproject.toml` for configuration.

And in this tutorial, we’ll learn how to parse TOML files in Python.

🔗 [**Here’s the code on GitHub**](https://github.com/balapriyac/python-basics/tree/main/config-management-basics/parsing-toml-files).

## Prerequisites

To follow along with this tutorial, you'll need:

- **Python 3.11 or higher**: The `tomllib` module is part of the standard library starting from Python 3.11
- **Basic Python knowledge**: Familiarity with dictionaries, file I/O, and basic syntax
- **A text editor or IDE**: Any editor to create and edit TOML and Python files
1. [Understanding the TOML Format](https://www.freecodecamp.org/news/how-to-work-with-toml-files-in-python/#heading-understanding-the-toml-format)
2. [How to Read TOML Files with tomllib](https://www.freecodecamp.org/news/how-to-work-with-toml-files-in-python/#heading-how-to-read-toml-files-with-tomllib)
3. [How to Work with TOML Data Types](https://www.freecodecamp.org/news/how-to-work-with-toml-files-in-python/#heading-how-to-work-with-toml-data-types)
4. [How to Build a TOML Config Manager](https://www.freecodecamp.org/news/how-to-work-with-toml-files-in-python/#heading-how-to-build-a-toml-config-manager)
5. [How to Handle Missing Values Safely](https://www.freecodecamp.org/news/how-to-work-with-toml-files-in-python/#heading-how-to-handle-missing-values-safely)

## Understanding the TOML Format

TOML files organize data into tables (similar to INI sections) but with more powerful features. Let's create a sample configuration to understand the syntax.

Create `config.toml`:

```
# Application configuration
title = "My Application"
version = "1.0.0"

[database]
host = "localhost"
port = 5432
username = "app_user"
password = "secure_password"
databases = ["myapp_db", "myapp_cache"]
pool_size = 10
ssl_enabled = true

[server]
host = "0.0.0.0"
port = 8000
debug = false
allowed_hosts = ["localhost", "127.0.0.1", "example.com"]

[logging]
level = "INFO"
format = "%(asctime)s - %(levelname)s - %(message)s"
handlers = ["console", "file"]

[cache]
enabled = true
ttl = 3600
max_size = 1000

[features]
enable_api = true
enable_webhooks = false
rate_limit = 100
```

This TOML file shows key features: simple key-value pairs, tables (sections in brackets), arrays (square brackets with comma-separated values), and different data types including strings, integers, booleans, and arrays.

## How to Read TOML Files with tomllib

The `tomllib` module is part of Python's standard library starting from version 3.11. It provides a simple interface for loading TOML files like so:

```python
import tomllib

with open('config.toml', 'rb') as f:
    config = tomllib.load(f)

# Access values
app_title = config['title']
db_host = config['database']['host']
db_port = config['database']['port']

print(f"Application: {app_title}")
print(f"Database: {db_host}:{db_port}")
print(f"Config keys: {config.keys()}")
```

Output:

```
Application: My Application
Database: localhost:5432
Config keys: dict_keys(['title', 'version', 'database', 'server', 'logging', 'cache', 'features'])
```

Note that `tomllib` requires opening files in binary mode (`'rb'`). The `load()` function parses the TOML file and returns a regular Python dictionary.

Values are automatically converted to appropriate Python types: strings remain strings, integers become ints, booleans become True/False, and arrays become lists. Next, let’s take a closer look at working with different data types.

## How to Work with TOML Data Types

TOML's type system maps cleanly to Python's built-in types. Here's how to work with different value types:

```python
import tomllib

with open('config.toml', 'rb') as f:
    config = tomllib.load(f)

# Strings
app_title = config['title']

# Integers
db_port = config['database']['port']
cache_ttl = config['cache']['ttl']

# Booleans
debug_mode = config['server']['debug']
cache_enabled = config['cache']['enabled']

# Arrays (become Python lists)
databases = config['database']['databases']
allowed_hosts = config['server']['allowed_hosts']

print(f"Databases: {databases}")
print(f"Type of databases: {type(databases)}")
print(f"Debug mode: {debug_mode}, type: {type(debug_mode)}")
```

With `tomllib`, you don't need special getter methods like `ConfigParser`. The returned dictionary contains properly typed Python objects ready to use as seen:

```
Databases: ['myapp_db', 'myapp_cache']
Type of databases: <class 'list'>
Debug mode: False, type: <class 'bool'>
```

## How to Build a TOML Config Manager

For production applications, wrapping TOML loading in a configuration class provides better error handling and validation. Here’s how you can do it:

```python
import tomllib
from pathlib import Path

class TOMLConfig:
    def __init__(self, config_file='config.toml'):
        self.config_file = Path(config_file)

        if not self.config_file.exists():
            raise FileNotFoundError(f"Config file not found: {config_file}")

        with open(self.config_file, 'rb') as f:
            self.config = tomllib.load(f)

    def get(self, key, default=None):
        """Get a top-level configuration value"""
        return self.config.get(key, default)

    def get_section(self, section):
        """Get an entire configuration section"""
        if section not in self.config:
            raise ValueError(f"Section '{section}' not found")
        return self.config[section]
```

You can use the `TOMLConfig` class like so:

```python
config = TOMLConfig('config.toml')

# Get top-level values
app_title = config.get('title')
version = config.get('version')

# Get entire sections
db_config = config.get_section('database')
server_config = config.get_section('server')

print(f"{app_title} v{version}")
print(f"Database config: {db_config}")
```

This configuration class provides a clean interface to your TOML file. It validates that the file exists before trying to parse it and provides methods to safely access configuration values.

Running the above code gives this output:

```
My Application v1.0.0
Database config: {'host': 'localhost', 'port': 5432, 'username': 'app_user', 'password': 'secure_password', 'databases': ['myapp_db', 'myapp_cache'], 'pool_size': 10, 'ssl_enabled': True}
```

## How to Handle Missing Values Safely

Your code needs to handle missing configuration gracefully. Here's how to provide defaults and validate required values:

```python
import tomllib

def load_config_safe(config_file='config.toml'):
    try:
        with open(config_file, 'rb') as f:
            return tomllib.load(f)
    except FileNotFoundError:
        print(f"Config file {config_file} not found, using defaults")
        return {}
    except tomllib.TOMLDecodeError as e:
        print(f"Error parsing TOML: {e}")
        raise

config = load_config_safe('config.toml')

# Get with defaults
db_host = config.get('database', {}).get('host', 'localhost')
db_port = config.get('database', {}).get('port', 5432)
debug = config.get('server', {}).get('debug', False)

print(f"Database: {db_host}:{db_port}")
print(f"Debug: {debug}")
```

Output:

```
Database: localhost:5432
Debug: False
```

This pattern uses chained `.get()` calls with defaults. If a section or key doesn't exist, you get the default value instead of a KeyError.

## Conclusion

When working with TOML files in Python, follow these guidelines:

- Always open in binary mode: The `tomllib` module requires binary mode (`'rb'`) when opening files.
- Use nested tables for organization: Take advantage of TOML's ability to nest tables for complex configurations.
- Provide defaults for optional settings: Use `.get()` with default values to make your application more flexible.

Consider using TOML for new projects. If you're starting fresh, TOML is a great choice for Python configuration. Happy coding!