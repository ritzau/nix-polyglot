# MyApp

Python console application created with nix-polyglot.

## Features

- ✅ Modern Python packaging with Poetry
- ✅ Click-based CLI interface
- ✅ Comprehensive testing with pytest
- ✅ Code formatting with black and isort
- ✅ Linting with ruff and type checking with mypy
- ✅ Reproducible builds with Nix
- ✅ Universal development commands with just

## Quick Start

```bash
# Development workflow
just dev          # Enter development environment
just build        # Build project
just run          # Run application
just test         # Run tests

# Quality assurance
just fmt          # Format code
just lint         # Run linting
just check        # Run all checks

# Application usage
nix run           # Run with default options
nix run -- --name Alice    # Greet Alice
nix run -- --count 3       # Multiple greetings
```

## Development

This project uses maintenance-free commands from nix-polyglot. All tools and dependencies are managed through Nix.

### Available Commands

- `nix develop` - Enter development shell
- `nix build .#dev` - Fast development build
- `nix build .#release` - Reproducible release build
- `nix flake check` - Run all tests and checks
- `nix fmt` - Universal code formatting

### Project Structure

```
myapp/
├── myapp/           # Application source code
│   ├── __init__.py
│   └── main.py
├── tests/           # Test suite
│   ├── __init__.py
│   └── test_main.py
├── pyproject.toml   # Project configuration
├── flake.nix        # Nix development environment
└── justfile         # Universal commands
```

## Updating

Keep your project updated with the latest nix-polyglot functionality:

```bash
nix flake update     # Update dependencies
```

This project follows the nix-polyglot architecture for maintenance-free development environments.
