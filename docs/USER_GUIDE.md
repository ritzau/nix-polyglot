# Glot CLI User Guide

**Glot** is a fast, intelligent CLI tool for nix-polyglot projects that provides unified commands across multiple programming languages (Rust, Python, C#). It replaces language-specific tooling with a consistent interface while leveraging Nix for reproducible builds.

## Quick Start

### Creating a New Project

```bash
# List available templates
glot new

# Create a new Rust project
glot new rust my-rust-app
cd my-rust-app
direnv allow  # Sets up development environment

# Build and run your project
glot build
glot run
```

### Working with Existing Projects

```bash
cd your-nix-polyglot-project
direnv allow  # If not already done

# Common development workflow
glot fmt     # Format code
glot lint    # Run linter
glot test    # Run tests
glot build   # Build project
glot run     # Run project
```

## Installation & Setup

### Prerequisites

- **Nix** with flakes enabled
- **direnv** (recommended for automatic environment setup)
- **Git** (for project templates)

### Getting Glot

Glot is automatically available in nix-polyglot projects through the `.envrc` file. No separate installation needed!

For system-wide installation:

```bash
# Install from nix-polyglot
nix profile install github:ritzau/nix-polyglot#glot

# Or run directly
nix run github:ritzau/nix-polyglot#glot -- --help
```

## Core Commands

### Project Creation

```bash
glot new                    # List available templates
glot new <template> <name>  # Create new project
```

**Available Templates:**

- `rust` / `rust-cli` - Rust CLI application
- `python` / `python-console` - Python console app with Poetry
- `csharp` / `csharp-console` - C# console app with .NET 8

### Build & Run

```bash
glot build              # Build debug version
glot build --release    # Build optimized release version
glot run                # Run debug version
glot run --release      # Run release version
glot run -- arg1 arg2   # Pass arguments to your program
```

### Code Quality

```bash
glot fmt               # Format code (language-specific)
glot lint              # Run linter/static analysis
glot test              # Run test suite
glot check             # Run all checks (fmt + lint + test + build)
```

### Project Management

```bash
glot clean             # Clean build artifacts
glot update            # Update dependencies and glot CLI
glot info              # Show project information
glot shell             # Enter development shell
```

### Shell Integration

```bash
glot completion bash       # Generate bash completions
glot completion zsh        # Generate zsh completions
glot completion fish       # Generate fish completions
glot install-completions   # Auto-install for your shell
glot version              # Show version information
```

## Language-Specific Features

### Rust Projects

```bash
# Build commands map to cargo
glot build        # → nix build .#dev
glot build --release  # → nix build .#release
glot test         # → cargo test (in nix develop)
glot fmt          # → nix fmt (rustfmt + nixpkgs-fmt)
glot lint         # → cargo clippy
```

**Template includes:**

- Cargo.toml with basic dependencies
- src/main.rs with hello world
- Complete flake.nix with nix-polyglot integration

### Python Projects

```bash
# Build commands map to Poetry
glot build        # → poetry build
glot run          # → poetry run python -m myapp.main
glot test         # → pytest
glot fmt          # → black + ruff
```

**Template includes:**

- pyproject.toml with Poetry configuration
- myapp/ module with main.py
- tests/ directory with pytest setup
- Complete flake.nix with Python + Poetry

### C# Projects

```bash
# Build commands map to dotnet
glot build        # → dotnet build
glot run          # → dotnet run
glot test         # → dotnet test
glot fmt          # → dotnet format
```

**Template includes:**

- MyApp.csproj with .NET 8 configuration
- Program.cs with hello world
- Complete flake.nix with .NET SDK

## Advanced Usage

### Release Builds

All projects support optimized release builds:

```bash
glot build --release    # Build optimized version
glot run --release      # Run optimized version
```

### Development Workflow

Typical development session:

```bash
# Start new feature
glot shell              # Enter dev environment (optional)
# ... edit code ...
glot fmt               # Format code
glot lint              # Check for issues
glot test              # Run tests
glot build             # Verify build
git add -A && git commit -m "Feature complete"

# Before pushing
glot check             # Run comprehensive checks
git push
```

### Integration with IDEs

Projects work seamlessly with:

- **VS Code**: Use nix-ide extension + direnv integration
- **JetBrains IDEs**: Import as standard language projects
- **Vim/Neovim**: Use LSP with nix-developed language servers
- **Emacs**: Use lsp-mode with nix integration

### Continuous Integration

Example GitHub Actions workflow:

```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v22
        with:
          github_access_token: ${{ secrets.GITHUB_TOKEN }}
      - run: nix develop --command glot check
```

## Project Structure

### Generated Project Layout

```
my-project/
├── .envrc              # Direnv configuration (auto-setup)
├── .gitignore          # Language-specific ignores
├── .editorconfig       # Editor configuration
├── flake.nix           # Nix flake with nix-polyglot
├── flake.lock          # Locked dependencies
├── .cache/
│   └── bin/glot        # Cached glot binary (auto-managed)
├── src/                # Source code (language-specific)
└── tests/              # Test files (if applicable)
```

### Smart Caching

The `.envrc` file automatically:

- Downloads and caches the glot CLI binary
- Rebuilds glot when dependencies change
- Sets up shell completions
- Installs git hooks
- Configures development environment

## Troubleshooting

### Common Issues

**"glot: command not found"**

- Ensure you've run `direnv allow` in the project directory
- Check that `.envrc` exists and is executable
- Try `nix develop` manually to enter dev shell

**"Build failed" errors**

- Run `glot update` to refresh dependencies
- Clear cache: `rm -rf .cache result`
- Check `nix develop --command bash` works

**Template creation fails**

- Ensure you have internet connection (may fetch from GitHub)
- Check nix flakes are enabled: `nix --experimental-features "nix-command flakes" --version`
- Try running with full path: `nix run github:ritzau/nix-polyglot#glot new rust myapp`

**Completions not working**

- Run `glot install-completions` manually
- Restart your shell
- Check completion files exist in `~/.config/<shell>/completions/`

### Getting Help

```bash
glot --help            # General help
glot <command> --help  # Command-specific help
glot version           # Version and build info
```

### Performance Tips

- Use `glot build --release` for production builds
- Run `glot clean` periodically to free disk space
- Keep `flake.lock` committed for reproducible builds
- Use `direnv` for automatic environment switching

## Shell Integration

### Bash

Add to `~/.bashrc`:

```bash
eval "$(glot completion bash)"
```

### Zsh

Add to `~/.zshrc`:

```bash
eval "$(glot completion zsh)"
```

### Fish

Add to `~/.config/fish/config.fish`:

```bash
glot completion fish | source
```

Or use the automatic installer:

```bash
glot install-completions  # Auto-detects your shell
```

## Migration Guide

### From Just/Make

Replace your build scripts:

```bash
# Old way
just build
just run
just test

# New way
glot build
glot run
glot test
```

Benefits:

- Consistent interface across languages
- Automatic caching and optimization
- Built-in nix integration
- No need to maintain separate justfiles

### From Language-Specific Tools

Glot wraps and enhances language tools:

```bash
# Instead of: cargo build, poetry build, dotnet build
glot build

# Instead of: cargo run, poetry run, dotnet run
glot run

# Instead of: cargo test, pytest, dotnet test
glot test
```

## Best Practices

1. **Always use `direnv allow`** after cloning projects
2. **Run `glot check`** before committing changes
3. **Keep `flake.lock` committed** for reproducibility
4. **Use `--release` for production** builds
5. **Set up shell completions** for better UX
6. **Pin nix-polyglot version** in production projects

## What's Next?

- Read the [API Reference](API_REFERENCE.md) for detailed command documentation
- See [Examples](examples/) for real-world project samples
- Check [FAQ](FAQ.md) for answers to common questions
- Report issues on [GitHub](https://github.com/ritzau/nix-polyglot/issues)

---

Happy coding with glot! 🚀
