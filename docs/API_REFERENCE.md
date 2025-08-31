# Glot CLI API Reference

Complete reference for all glot commands and options.

## Command Syntax

```
glot [global-options] <command> [command-options] [arguments]
```

## Global Options

| Flag         | Description                            |
| ------------ | -------------------------------------- |
| `-h, --help` | Show help for glot or specific command |
| `--version`  | Show version information               |

## Commands

### Project Creation

#### `glot new [template] [name]`

Create a new project from a template.

**Usage:**

```bash
glot new                    # List available templates
glot new <template>         # Show usage for specific template
glot new <template> <name>  # Create project
```

**Templates:**

- `rust`, `rust-cli` - Rust command-line application
- `python`, `python-console` - Python console application with Poetry
- `csharp`, `csharp-console` - C# console application with .NET 8

**Examples:**

```bash
glot new                           # Show all templates
glot new rust                      # Show usage for rust template
glot new rust my-cli-tool          # Create rust project "my-cli-tool"
glot new python data-processor     # Create python project "data-processor"
glot new csharp web-service        # Create C# project "web-service"
```

**Output:**

- Creates project directory with name `<name>`
- Initializes git repository with initial commit
- Sets up complete nix-polyglot integration
- Provides next steps guidance

---

### Build Commands

#### `glot build [target] [flags]`

Build the project using nix.

**Flags:**

- `--release` - Build optimized release version (default: debug)

**Arguments:**

- `target` - Optional build target (defaults to main application)

**Examples:**

```bash
glot build                    # Build debug version
glot build --release          # Build optimized version
glot build my-lib             # Build specific target
glot build my-lib --release   # Build specific target optimized
```

**Nix Integration:**

- Debug builds: `nix build .#dev`
- Release builds: `nix build .#release`
- Results available in `./result/` symlink

---

#### `glot run [target] [flags] [-- args...]`

Run the built application.

**Flags:**

- `--release` - Run optimized release version (default: debug)

**Arguments:**

- `target` - Optional run target (defaults to main application)
- `args...` - Arguments passed to the application (after `--`)

**Examples:**

```bash
glot run                          # Run debug version
glot run --release                # Run release version
glot run -- --help                # Run with --help argument
glot run --release -- config.json # Run release with config file
glot run my-tool -- input.txt     # Run specific target with argument
```

**Behavior:**

- Automatically builds if needed
- Runs from nix store for reproducibility
- Passes through all arguments after `--`

---

### Code Quality

#### `glot fmt`

Format code using language-specific formatters.

**Usage:**

```bash
glot fmt
```

**Language Mapping:**

- **Rust**: `rustfmt` + `nixpkgs-fmt` (via `nix fmt`)
- **Python**: `black` + `ruff` format
- **C#**: `dotnet format`

**Examples:**

```bash
glot fmt                    # Format all code in project
```

**Notes:**

- Modifies files in-place
- Follows language conventions and project .editorconfig
- Also formats nix files in the project

---

#### `glot lint`

Run static analysis and linting.

**Usage:**

```bash
glot lint
```

**Language Mapping:**

- **Rust**: `cargo clippy` with warnings-as-errors
- **Python**: `ruff check` + `mypy` type checking
- **C#**: Built-in compiler warnings + analyzers

**Examples:**

```bash
glot lint                   # Run all linters
```

**Exit Codes:**

- `0` - No issues found
- `1` - Linting issues found
- `2` - Command failed

---

#### `glot test`

Run the project's test suite.

**Usage:**

```bash
glot test
```

**Language Mapping:**

- **Rust**: `cargo test`
- **Python**: `pytest`
- **C#**: `dotnet test`

**Examples:**

```bash
glot test                   # Run all tests
```

**Features:**

- Runs in isolated nix environment
- Includes integration tests where configured
- Reports coverage when available

---

#### `glot check`

Run comprehensive checks (format + lint + test + build).

**Usage:**

```bash
glot check
```

**Equivalent to:**

```bash
glot fmt --check  # Verify formatting (fail if not formatted)
glot lint         # Run linter
glot test         # Run tests
glot build        # Verify build
```

**Use Cases:**

- Pre-commit validation
- CI/CD pipelines
- Release readiness verification

**Exit Codes:**

- `0` - All checks passed
- `1` - One or more checks failed

---

### Project Management

#### `glot clean`

Clean build artifacts and cache.

**Usage:**

```bash
glot clean
```

**Removes:**

- `result*` symlinks (nix build outputs)
- `target/` directory (Rust)
- `dist/` directory (Python)
- `bin/`, `obj/` directories (C#)
- Language-specific cache directories

**Examples:**

```bash
glot clean                  # Clean all artifacts
```

**Notes:**

- Does not remove `.cache/bin/glot` (managed automatically)
- Safe to run anytime
- Useful for freeing disk space

---

#### `glot update`

Update project dependencies and glot CLI.

**Usage:**

```bash
glot update
```

**Actions:**

1. Updates nix flake dependencies (`nix flake update`)
2. Clears cached glot CLI binary
3. Forces rebuild on next use

**Examples:**

```bash
glot update                 # Update everything
```

**Notes:**

- Updates `flake.lock` file
- May require `direnv reload` in some shells
- Commit `flake.lock` changes for team consistency

---

#### `glot info`

Display project information and diagnostics.

**Usage:**

```bash
glot info
```

**Output:**

- Project type and language
- Nix flake status and outputs
- Available build targets
- Development shell information
- Git repository status

**Examples:**

```bash
glot info                   # Show project info
```

**Use Cases:**

- Debugging project setup
- Understanding available targets
- Verifying nix-polyglot integration

---

#### `glot shell`

Enter the development shell environment.

**Usage:**

```bash
glot shell
```

**Equivalent to:**

```bash
nix develop
```

**Examples:**

```bash
glot shell                  # Enter development shell
```

**Features:**

- Full development environment
- Language-specific tools available
- Same environment as used by other glot commands
- Exit with `exit` or Ctrl+D

---

### Shell Integration

#### `glot completion <shell>`

Generate shell completion scripts.

**Usage:**

```bash
glot completion bash        # Bash completions
glot completion zsh         # Zsh completions
glot completion fish        # Fish completions
```

**Examples:**

```bash
# Bash
eval "$(glot completion bash)"

# Zsh
eval "$(glot completion zsh)"

# Fish
glot completion fish | source
```

**Output:**

- Shell-specific completion script to stdout
- Can be saved to file or sourced directly

---

#### `glot install-completions`

Automatically install completions for your shell.

**Usage:**

```bash
glot install-completions
```

**Behavior:**

- Detects current shell ($SHELL)
- Installs to appropriate completion directory
- Creates directories if needed
- Follows XDG Base Directory specification

**Installation Paths:**

- **Bash**: `~/.config/bash_completion.d/glot`
- **Zsh**: `~/.config/zsh/completions/_glot`
- **Fish**: `~/.config/fish/completions/glot.fish`

**Examples:**

```bash
glot install-completions    # Auto-install for current shell
```

---

#### `glot version`

Show version and build information.

**Usage:**

```bash
glot version
```

**Output:**

- Glot CLI version
- Go version used for build
- Build timestamp
- Git commit hash (if available)
- Platform information

**Examples:**

```bash
glot version                # Show version info
```

**Use Cases:**

- Bug reports
- Compatibility verification
- Build debugging

---

## Exit Codes

| Code  | Meaning                                          |
| ----- | ------------------------------------------------ |
| `0`   | Success                                          |
| `1`   | General error (build failed, tests failed, etc.) |
| `2`   | Command line usage error                         |
| `125` | Command not found in development shell           |

## Environment Variables

### Recognized Variables

| Variable          | Purpose                          | Example     |
| ----------------- | -------------------------------- | ----------- |
| `SHELL`           | Detected by completion commands  | `/bin/bash` |
| `XDG_CONFIG_HOME` | Used for completion installation | `~/.config` |

### Set by Glot

| Variable | Purpose                               | Scope            |
| -------- | ------------------------------------- | ---------------- |
| `PATH`   | Includes `.cache/bin` for glot access | Project `.envrc` |

## Error Messages

### Common Error Patterns

**Build Errors:**

```
❌ Error: Debug build failed
```

- Check `nix develop --command <build-tool>` manually
- Verify dependencies in `flake.nix`
- Run `glot update` to refresh

**Missing flake.nix:**

```
❌ Error: No flake.nix found. This command requires a nix-polyglot project.
```

- Ensure you're in a project directory
- Use `glot new` to create a new project

**Template Creation:**

```
❌ Error: Failed to create project with template 'rust'
```

- Check internet connection (may fetch from GitHub)
- Verify nix flakes are enabled
- Try with full GitHub path

### Debug Mode

For verbose output, run nix commands directly:

```bash
# Debug build issues
nix develop --command bash -c 'cargo build --verbose'

# Debug template issues
nix run github:ritzau/nix-polyglot#new-rust myproject

# Debug environment
nix develop --command env | grep -E "(PATH|NIX)"
```

## Configuration Files

### Project Configuration

| File            | Purpose                 | Format         |
| --------------- | ----------------------- | -------------- |
| `flake.nix`     | Nix flake configuration | Nix expression |
| `flake.lock`    | Locked dependencies     | JSON           |
| `.envrc`        | Direnv configuration    | Shell script   |
| `.editorconfig` | Editor configuration    | INI format     |

### No Global Configuration

Glot intentionally has no global configuration file. All configuration is project-specific through the nix flake system.

## Integration with Nix

### Command Mapping

| Glot Command           | Nix Equivalent        |
| ---------------------- | --------------------- |
| `glot build`           | `nix build .#dev`     |
| `glot build --release` | `nix build .#release` |
| `glot run`             | `nix run .#dev`       |
| `glot fmt`             | `nix fmt`             |
| `glot shell`           | `nix develop`         |
| `glot update`          | `nix flake update`    |

### Flake Outputs Expected

Glot expects these flake outputs:

- `packages.default` - Main application
- `packages.dev` - Debug build (optional)
- `packages.release` - Release build (optional)
- `devShells.default` - Development environment
- `formatter` - Code formatter

### Cache Behavior

- Build outputs cached in `/nix/store`
- Binary cache used when available
- Local `result` symlinks for quick access
- `.cache/bin/glot` managed automatically

---

For more examples and tutorials, see the [User Guide](USER_GUIDE.md).
