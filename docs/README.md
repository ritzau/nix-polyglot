# Glot CLI Documentation

Complete documentation for the glot CLI tool and nix-polyglot integration.

## Documentation Overview

### For Users

- **[User Guide](USER_GUIDE.md)** - Complete guide to using glot CLI
  - Quick start and installation
  - Core commands and workflows
  - Language-specific features
  - Integration with IDEs and CI/CD
  - Best practices and troubleshooting

- **[API Reference](API_REFERENCE.md)** - Detailed command reference
  - Complete command syntax and options
  - Exit codes and error handling
  - Environment variables
  - Integration with nix ecosystem

- **[FAQ](FAQ.md)** - Frequently asked questions
  - Common issues and solutions
  - Performance and caching questions
  - Comparison with other tools
  - Advanced usage scenarios

### For Developers

- **[Developer Guide](DEVELOPER_GUIDE.md)** - Contributing to glot
  - Development environment setup
  - Architecture and design decisions
  - Adding new languages and features
  - Testing and release process

### Quick Links

| I want to...             | Read this                                                         |
| ------------------------ | ----------------------------------------------------------------- |
| Get started with glot    | [User Guide - Quick Start](USER_GUIDE.md#quick-start)             |
| Create a new project     | [User Guide - Project Creation](USER_GUIDE.md#project-creation)   |
| Understand all commands  | [API Reference](API_REFERENCE.md)                                 |
| Troubleshoot an issue    | [FAQ - Troubleshooting](FAQ.md#troubleshooting)                   |
| Set up shell completions | [User Guide - Shell Integration](USER_GUIDE.md#shell-integration) |
| Use in CI/CD             | [FAQ - Advanced Usage](FAQ.md#advanced-usage)                     |
| Contribute code          | [Developer Guide](DEVELOPER_GUIDE.md)                             |
| Report a bug             | [GitHub Issues](https://github.com/ritzau/nix-polyglot/issues)    |

## Examples

### Basic Workflow

```bash
# Create new project
glot new rust my-app
cd my-app
direnv allow

# Development cycle
glot fmt    # Format code
glot test   # Run tests
glot build  # Build project
glot run    # Run application

# Before commit
glot check  # Run all checks
```

### Template Creation

```bash
# List templates
glot new

# Create different project types
glot new rust cli-tool
glot new python data-processor
glot new csharp web-service
```

### Shell Integration

```bash
# Install completions
glot install-completions

# Or manually for your shell
eval "$(glot completion bash)"   # Bash
eval "$(glot completion zsh)"    # Zsh
glot completion fish | source    # Fish
```

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User runs     │    │   Glot CLI      │    │   Nix/Language  │
│   glot build    │───▶│   (Go binary)   │───▶│   Tools         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Smart Cache   │
                       │   & Results     │
                       └─────────────────┘
```

**Key Components:**

- **Glot CLI**: Fast Go binary with unified command interface
- **Nix Integration**: Reproducible builds and environments
- **Smart Caching**: Automatic optimization and dependency management
- **Language Modules**: Language-specific build configurations
- **Template System**: Project scaffolding with best practices

## Contributing

We welcome contributions! Here's how to get started:

1. **Documentation**: Improve guides, fix typos, add examples
2. **Bug Reports**: Use GitHub issues with detailed reproduction steps
3. **Feature Requests**: Discuss in GitHub issues before implementing
4. **Code**: See [Developer Guide](DEVELOPER_GUIDE.md) for setup

### Documentation Guidelines

- **User-focused**: Write for end users, not developers
- **Examples**: Include working code examples
- **Current**: Keep documentation in sync with code
- **Clear**: Use simple language and avoid jargon
- **Tested**: Verify examples work with current version

### Style Guide

- Use **bold** for important concepts
- Use `code` for commands and file names
- Use tables for structured information
- Include real examples, not placeholders
- Link between related sections

## Feedback

Your feedback helps improve glot! Please:

- **Report bugs** with reproduction steps
- **Suggest improvements** to documentation
- **Share usage patterns** we should support
- **Ask questions** to help identify gaps

All feedback can be submitted via [GitHub Issues](https://github.com/ritzau/nix-polyglot/issues).

---

_Documentation version: 1.2.0_  
_Last updated: August 30, 2025_
