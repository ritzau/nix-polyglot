# Glot CLI Developer Guide

Guide for contributing to glot CLI and nix-polyglot.

## Development Environment Setup

### Prerequisites

- **Nix** with flakes enabled
- **Git** for version control
- **Go 1.23+** (provided by nix development shell)
- **direnv** (recommended)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/ritzau/nix-polyglot.git
cd nix-polyglot

# Enter development environment
direnv allow  # Or: nix develop

# Build glot CLI
nix build .#glot

# Test the build
./result/bin/glot --help
```

### Development Workflow

```bash
# Make changes to src/glot/main.go
# Build and test
nix build .#glot
./result/bin/glot new rust test-project

# Run tests
./test-quick.sh        # Quick smoke tests
./test-all.sh         # Comprehensive tests

# Format code
nix fmt

# Before committing
nix flake check       # Run all checks
```

## Architecture

### Project Structure

```
nix-polyglot/
├── src/glot/          # Glot CLI source (Go)
│   ├── main.go        # Main CLI implementation
│   ├── go.mod         # Go module definition
│   └── go.sum         # Go module checksums
├── lib/               # Nix library functions
│   ├── languages/     # Language-specific configurations
│   └── templates.nix  # Template system
├── templates/         # Project templates
│   ├── rust/cli/      # Rust CLI template
│   ├── python/console/# Python console template
│   └── csharp/console/# C# console template
├── samples/           # Example projects
│   ├── rust-nix/      # Rust sample project
│   ├── python-nix/    # Python sample project
│   └── csharp-nix/    # C# sample project
├── docs/              # Documentation
├── flake.nix          # Main nix flake
└── flake.lock         # Locked dependencies
```

### Core Components

#### Glot CLI (`src/glot/main.go`)

- **Framework**: Uses [cobra](https://github.com/spf13/cobra) for CLI structure
- **Commands**: Each major command (build, run, fmt, etc.) is a separate cobra command
- **Error handling**: Consistent error messages with colored output
- **Nix integration**: Calls nix commands with proper argument handling

#### Template System (`lib/templates.nix`)

- **Dynamic generation**: Templates are generated from directory structure
- **File mapping**: Each template defines which files to include
- **Git integration**: Automatically initializes git repos with proper commits
- **Help text**: Generates consistent help and next-steps guidance

#### Language Modules (`lib/languages/`)

- **Language-specific**: Each supported language has its own module
- **Build configuration**: Defines how to build debug/release versions
- **Development shells**: Configures development environments
- **Tool integration**: Integrates language-specific formatters, linters, etc.

### Key Design Decisions

#### Why Go for the CLI?

- **Performance**: ~5ms startup time vs 200ms+ for bash
- **Cross-platform**: Works on all nix-supported platforms
- **Maintainability**: Strong typing and tooling vs shell scripting
- **Library ecosystem**: Cobra for CLI, built-in flag handling

#### Why Nix for builds?

- **Reproducibility**: Guaranteed consistent environments
- **Caching**: Automatic build result caching
- **Language agnostic**: Same interface for all languages
- **Declarative**: Configuration as code

#### Smart Caching Strategy

- **CLI caching**: `.cache/bin/glot` rebuilt when dependencies change
- **Build caching**: Nix store provides automatic result caching
- **Template caching**: Nix builds are cached and reused
- **Timestamp checking**: `.envrc` checks `flake.lock` vs cached binary

## Adding New Features

### Adding a New Command

1. **Define the command** in `main.go`:

```go
var myCmd = &cobra.Command{
    Use:   "mycmd",
    Short: "Description of my command",
    RunE: func(cmd *cobra.Command, args []string) error {
        // Command implementation
        return nil
    },
}
```

2. **Add to root command**:

```go
rootCmd.AddCommand(buildCmd, runCmd, ..., myCmd)
```

3. **Test the command**:

```bash
nix build .#glot
./result/bin/glot mycmd
```

### Adding a New Language

1. **Create language module** in `lib/languages/newlang.nix`:

```nix
{ pkgs, lib, system }:

{
  # Build configuration
  mkProject = { self, ... }: {
    packages = {
      default = pkgs.stdenv.mkDerivation {
        name = "newlang-project";
        src = ./.;
        buildPhase = "# Build command here";
        installPhase = "# Install command here";
      };
    };

    devShells.default = pkgs.mkShell {
      packages = [ pkgs.newlang-compiler ];
    };
  };
}
```

2. **Create template** in `templates/newlang/console/`:

```
templates/newlang/console/
├── template.nix       # Template configuration
├── flake.nix          # Nix flake template
├── .envrc             # Development environment
├── .gitignore         # Language-specific ignores
├── .editorconfig      # Editor configuration
└── src/               # Source code template
    └── main.newlang
```

3. **Update template system** in `lib/templates.nix`:

```nix
{
  # Add new template
  newlang-console = mkTemplateFromDir ../templates/newlang/console;

  # Add to legacy aliases if needed
  newlang = mkTemplateFromDir ../templates/newlang/console;
}
```

4. **Add flake apps** in `flake.nix`:

```nix
apps = {
  new-newlang = {
    type = "app";
    program = "${templates.newlang}/bin/new-newlang-console-project";
  };
};
```

5. **Create sample project** in `samples/newlang-nix/`

6. **Test the integration**:

```bash
# Test template creation
nix build
./result/bin/glot new newlang test-project

# Test sample project
cd samples/newlang-nix
direnv allow
glot build
glot run
```

### Adding Shell Completions

Completions are automatically generated by cobra. To add completions for new commands or flags:

1. **Commands**: Automatically included when added to cobra
2. **Dynamic completions**: Use cobra's completion functions:

```go
var myCmd = &cobra.Command{
    Use: "mycmd",
    ValidArgsFunction: func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
        // Return completion options
        return []string{"option1", "option2"}, cobra.ShellCompDirectiveDefault
    },
}
```

3. **Test completions**:

```bash
# Generate completion script
./result/bin/glot completion bash

# Test in shell
eval "$(./result/bin/glot completion bash)"
glot <TAB><TAB>
```

## Testing

### Test Structure

```
nix-polyglot/
├── test-quick.sh      # Fast smoke tests (~30s)
├── test-all.sh        # Comprehensive tests (~5min)
├── test-project-user.sh # User workflow simulation
└── samples/           # Integration test projects
    └── */test.sh      # Per-language test scripts
```

### Running Tests

```bash
# Quick verification
./test-quick.sh

# Full test suite
./test-all.sh

# Specific language
cd samples/rust-nix && ./test.sh

# Manual testing
./result/bin/glot new rust test-manual
cd test-manual && direnv allow
glot build && glot run
```

### Test Guidelines

- **Fast feedback**: Quick tests should run in under 30 seconds
- **Real scenarios**: Test actual user workflows, not just unit tests
- **Cross-platform**: Tests should work on Linux and macOS
- **Clean state**: Each test should start from a clean environment
- **Error cases**: Test error handling, not just happy paths

### Adding New Tests

1. **Add to quick test** for basic functionality:

```bash
# In test-quick.sh
echo "Testing new feature..."
./result/bin/glot new-feature || exit 1
```

2. **Add comprehensive test** for full workflows:

```bash
# In test-all.sh
echo "=== Testing New Feature ==="
cd /tmp && ./result/bin/glot new rust test-new-feature
cd test-new-feature && direnv allow
glot build && glot run && glot check
```

3. **Add language-specific test** in sample projects:

```bash
# In samples/rust-nix/test.sh
echo "Testing new Rust feature..."
glot new-rust-feature || exit 1
```

## Release Process

### Version Management

Versions are managed through git tags:

```bash
# Create release
git tag v1.3.0
git push origin v1.3.0

# Nix automatically picks up new tags
nix run github:ritzau/nix-polyglot/v1.3.0#glot -- --version
```

### Release Checklist

1. **Update documentation**: Ensure all docs are current
2. **Run full tests**: `./test-all.sh` must pass
3. **Update examples**: Verify all examples work
4. **Check flake**: `nix flake check` must pass
5. **Test installation**: `nix run github:ritzau/nix-polyglot#glot`
6. **Update TODO.md**: Mark completed items
7. **Create release notes**: Document changes
8. **Tag release**: Use semantic versioning

### Continuous Integration

The project uses GitHub Actions for CI:

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v22
      - run: nix flake check
      - run: ./test-all.sh
```

## Debugging

### Common Development Issues

**Go build errors:**

```bash
# Check Go version
nix develop --command go version

# Check dependencies
cd src/glot && go mod tidy
```

**Nix build errors:**

```bash
# Verbose build
nix build --print-build-logs .#glot

# Check flake
nix flake check --print-build-logs
```

**Template issues:**

```bash
# Test template creation directly
nix run .#new-rust test-debug

# Check template files are tracked by git
git ls-files templates/
```

### Debugging Tools

```bash
# Debug nix evaluation
nix eval --json .#glot

# Debug template apps
nix run .#templates

# Debug flake inputs
nix flake metadata

# Debug development shell
nix develop --command env | grep -E "(PATH|GOROOT)"
```

### Performance Profiling

```bash
# Time glot execution
time ./result/bin/glot build

# Profile nix build
nix build --option builders "" .#glot

# Check cache usage
nix path-info --closure-size ./result
```

## Code Style

### Go Code Style

- **Follow standard Go conventions**: Use `gofmt`, follow effective Go
- **Error handling**: Always check and handle errors appropriately
- **Cobra patterns**: Use cobra best practices for CLI structure
- **Consistent naming**: Use descriptive variable and function names

Example:

```go
func runNix(args ...string) error {
    cmd := exec.Command("nix", args...)
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr

    if err := cmd.Run(); err != nil {
        return fmt.Errorf("nix command failed: %w", err)
    }

    return nil
}
```

### Nix Code Style

- **Use nixpkgs-fmt**: Format with `nix fmt`
- **Descriptive names**: Clear variable and function names
- **Comments for complex logic**: Explain non-obvious code
- **Consistent indentation**: 2 spaces, no tabs

Example:

```nix
mkProject = { pkgs, self, system }: {
  packages = {
    default = pkgs.buildGoModule {
      name = "glot";
      src = ./.;

      vendorHash = "sha256-...";

      meta = with pkgs.lib; {
        description = "Unified CLI for nix-polyglot projects";
        license = licenses.mit;
      };
    };
  };
}
```

### Documentation Style

- **User-focused**: Write for end users
- **Working examples**: All code examples must work
- **Clear structure**: Use headings and tables effectively
- **Cross-references**: Link between related sections

## Contributing Guidelines

### Pull Request Process

1. **Fork** the repository
2. **Create feature branch**: `git checkout -b feature-name`
3. **Make changes** with tests
4. **Run tests**: `./test-all.sh`
5. **Format code**: `nix fmt`
6. **Commit changes** with clear messages
7. **Push branch**: `git push origin feature-name`
8. **Create PR** with description

### Commit Messages

Use conventional commits format:

```
feat: add support for Go language templates
fix: resolve template path resolution issue
docs: update API reference for new commands
test: add integration tests for Python projects
```

### Review Process

All PRs require:

- **Tests pass**: CI must be green
- **Code review**: At least one maintainer approval
- **Documentation**: User-facing changes need doc updates
- **No breaking changes**: Or clearly documented migration path

## Getting Help

### Community

- **GitHub Discussions**: For questions and ideas
- **GitHub Issues**: For bugs and feature requests
- **Matrix/Discord**: Real-time chat (if available)

### Maintainers

Current maintainers:

- **@ritzau**: Project creator and lead maintainer

### Resources

- **Nix Manual**: https://nixos.org/manual/nix/stable/
- **Go Documentation**: https://golang.org/doc/
- **Cobra CLI**: https://cobra.dev/
- **Flake Utils**: https://github.com/numtide/flake-utils

---

Thank you for contributing to glot! Your help makes the project better for everyone. 🚀
