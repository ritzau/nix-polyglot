# Language Support Guide

**Adding new programming languages to nix-polyglot**

This guide explains how to add support for new programming languages to the nix-polyglot system, including requirements, testing, and best practices.

## Overview

nix-polyglot provides maintenance-free, reproducible development environments for multiple programming languages. Each language follows a consistent architecture:

- **Language Module** (`{language}.nix`): Core build and development logic
- **Templates** (`templates/{language}/*`): Project templates for different use cases
- **Tests** (`test-*.sh`): Comprehensive testing of functionality
- **Documentation**: Clear usage and contribution guidelines

## Architecture Principles

### 1. Dual Build System

Every language must support two distinct build configurations:

- **Dev Builds**: Fast iteration, debug symbols, skip expensive checks
- **Release Builds**: Reproducible, deterministic, full quality assurance

### 2. Universal Interface

All languages provide the same user interface:

```bash
# Project creation
nix run nix-polyglot#new-{language} myproject

# Development workflow
just dev          # Enter development shell
just build        # Build project (dev)
just run          # Run application
just release      # Run release build
just test         # Run tests and checks
just fmt          # Format all code
just lint         # Run linting

# Core nix commands
nix develop       # Development environment
nix build .#dev   # Fast dev build
nix build .#release # Reproducible release build
nix flake check   # All checks and tests
nix fmt           # Universal formatting
```

### 3. Complete Integration

Languages integrate with:

- **Formatting**: treefmt-nix integration for universal `nix fmt`
- **Linting**: git-hooks-nix for pre-commit quality checks
- **Testing**: Comprehensive test coverage in `nix flake check`
- **Templates**: Multiple project variants for different use cases

## Adding a New Language

### Step 1: Create Language Module

Create `{language}.nix` in the project root:

```nix
{ nixpkgs, treefmt-nix, git-hooks-nix }:

# Language project builder with dev/release optimization
#
# This function creates development and release builds, shells, apps, and checks
# for {Language} projects with built-in reproducibility and best practices.
#
# Key features:
# - Fast dev builds with debug info, skip expensive checks
# - Reproducible release builds with deterministic output
# - Integrated test execution and quality assurance
# - Universal formatting and linting integration
#
# Usage:
#   {language} = import ./{language}.nix { inherit nixpkgs treefmt-nix git-hooks-nix; };
#   project = {language} { pkgs = nixpkgs.legacyPackages.${system}; self = ./.; ... };
#   # Use project.defaultOutputs for complete flake integration

{
  # Required parameters
  pkgs,           # Nixpkgs package set
  self,           # Source path/flake self
  buildTarget,    # Path to main build file

  # Language-specific parameters
  # ... (document all parameters)

  system,         # System architecture
}:

let
  # Base configuration shared by both builds
  baseConfig = {
    # Common settings
  };

  # Fast development build - optimized for speed
  devBuildConfig = baseConfig // {
    # Minimal environment for fast iteration
    # No reproducibility overhead
    # Enable caching and incremental builds
  };

  # Reproducible release build - deterministic output
  releaseBuildConfig = baseConfig // {
    # Full reproducibility controls
    # Deterministic timestamps and environment
    # Comprehensive validation
  };

  # Dev build - fast iteration with debug info
  devPackage = pkgs.build{Language}Package (
    devBuildConfig // {
      buildType = "Debug";
      doCheck = false; # Skip tests for speed
    }
  );

  # Release build - reproducible production build
  releasePackage = pkgs.build{Language}Package (
    releaseBuildConfig // {
      buildType = "Release";
      doCheck = hasTests; # Run all tests
    }
  );

in {
  # Individual components
  inherit devPackage releasePackage;

  # Complete flake integration - recommended for most users
  defaultOutputs = {
    devShells.default = devShell;
    packages = {
      default = devPackage;
      dev = devPackage;
      release = releasePackage;
    };
    apps = {
      default = devApp;
      dev = devApp;
      release = releaseApp;
      lint = lintApp;
      check-format = checkFormatApp;
      # Project management apps
      setup = setupApp;
      update-project = updateApp;
      migrate = migrateApp;
    };
    checks = {
      build-dev = devPackage;
      build-release = releasePackage;
      lint-check = lintCheck;
      pre-commit-check = git-hooks;
    };
    formatter = projectFormatter; # For nix fmt integration
  };
}
```

### Step 2: Integration Points

#### Build Requirements

**Dev Builds Must:**

- Build quickly with minimal overhead
- Include debug symbols and information
- Skip expensive reproducibility controls
- Allow normal user caches and configs
- Set `doCheck = false` to skip tests
- Use `buildType = "Debug"` or equivalent

**Release Builds Must:**

- Be fully reproducible and deterministic
- Set `SOURCE_DATE_EPOCH` for consistent timestamps
- Use `--no-cache` and strict dependency locking
- Include comprehensive validation
- Set `doCheck = hasTests` to run all tests
- Use `buildType = "Release"` or equivalent
- Embed source revision and repository information

#### Quality Assurance

**Formatting Integration:**

```nix
# In your language.nix
projectFormatter = pkgs.writeShellApplication {
  name = "{language}-formatter";
  text = ''
    echo "Formatting {Language} code..."
    {formatter-command} --fix
    echo "{Language} formatting complete!"
  '';
};

# Provide treefmt integration
treefmt = treefmt-nix.lib.${system}.evalModule {
  projectRootFile = "flake.nix";
  programs.{language-formatter}.enable = true;
};
```

**Linting Integration:**

```nix
# git-hooks configuration
git-hooks = git-hooks-nix.lib.${system}.run {
  src = self;
  hooks = {
    {language}-format = {
      enable = true;
      name = "{language} format";
      entry = "${formatter}/bin/{formatter} --check";
      files = "\\{language-extensions}$";
    };
    {language}-lint = {
      enable = true;
      name = "{language} lint";
      entry = "${linter}/bin/{linter}";
      files = "\\{language-extensions}$";
    };
  };
};
```

#### Testing Requirements

**Test Coverage Must Include:**

- Dev and release builds succeed
- Generated executables run correctly
- Formatting and linting work
- Pre-commit hooks function
- Template generation and building
- Development shell functionality

### Step 3: Create Templates

Create `templates/{language}/` directory structure:

```
templates/
└── {language}/
    ├── {template-name}/
    │   ├── template.nix          # Template metadata
    │   ├── flake.nix            # Flake configuration
    │   ├── justfile             # Universal commands
    │   ├── {build-file}         # Main build configuration
    │   ├── {main-source}        # Application entry point
    │   ├── .editorconfig        # IDE configuration
    │   └── .gitignore           # Git ignore patterns
    └── {another-template}/
        └── ...
```

#### Template Metadata (`template.nix`)

```nix
# {Language} {Template Type} Template
{
  name = "{language}-{template}";
  description = "{Language} {template description}";

  # Template metadata
  language = "{language}";
  category = "{template-type}";

  # Files to create in new project
  files = {
    "flake.nix" = ./flake.nix;
    "{build-file}" = ./{build-file};
    "{main-source}" = ./{main-source};
    "justfile" = ./justfile;
    ".gitignore" = ./.gitignore;
    ".editorconfig" = ./.editorconfig;
  };
}
```

#### Universal Justfile

Every template must include this `justfile`:

```make
# Universal nix-polyglot commands
# These commands work across all supported languages

# Development workflow
dev:
    @echo "🚀 Enter development environment..."
    nix develop

build:
    @echo "🔨 Build project (dev)..."
    nix build .#dev

run:
    @echo "▶️  Run application..."
    nix run

release:
    @echo "🚀 Run release build..."
    nix run .#release

# Quality assurance
fmt:
    @echo "🎨 Format all code..."
    nix fmt

fmt-check:
    @echo "🔍 Check code formatting..."
    nix run .#check-format

lint:
    @echo "🔍 Run linting checks..."
    nix run .#lint

test:
    @echo "🧪 Run tests and checks..."
    nix flake check

# Project maintenance
clean:
    @echo "🧹 Clean build artifacts..."
    rm -rf result result-*

update:
    @echo "📦 Update dependencies..."
    nix flake update

info:
    @echo "📋 Project information..."
    nix flake show

# Comprehensive validation
check:
    @echo "✅ Run all checks..."
    just build && just test && just lint && just fmt-check
```

### Step 4: Add to Main Flake

Update the main `flake.nix`:

```nix
# In outputs function
let
  # Import new language
  {language}Lib = import ./{language}.nix {
    inherit nixpkgs treefmt-nix git-hooks-nix;
  };
in {
  # Export in lib
  lib = {
    # ... existing languages
    {language} = {language}Lib;
  };

  # Add template apps
  apps = pkgs.lib.recursiveUpdate existingApps (
    import ./lib/templates.nix { inherit pkgs; }
  );
}
```

### Step 5: Testing Requirements

Create comprehensive tests in `test-main-flake.sh`:

```bash
# Language-specific test section
test_{language}_templates() {
    echo -e "${YELLOW}📋 Testing {language} templates${NC}"
    echo "$(printf '%.0s-' {1..30})"

    # Test each template variant
    test_template_generation "{language}-{template}" "new-{language}" \
        "{expected-files}" "$repo_root"

    # Verify builds work
    run_test "{language}: dev build works" \
        "cd test-project && nix build .#dev" \
        ""

    run_test "{language}: release build works" \
        "cd test-project && nix build .#release" \
        ""

    # Test executables
    run_test "{language}: dev executable runs" \
        "cd test-project && ./result/bin/{app-name}" \
        "{expected-output}"
}
```

### Step 6: Update Documentation

Update the main `TODO.md` and `README.md`:

````markdown
## Supported Languages

- **C#**: Console apps, web APIs, libraries (.NET 8)
- **Rust**: CLI tools, libraries, web services
- **{Language}**: {supported-project-types}

## Quick Start

```bash
# Create new projects
nix run nix-polyglot#new-csharp myapp
nix run nix-polyglot#new-rust myapp
nix run nix-polyglot#new-{language} myapp

# Universal development workflow
cd myapp
just dev          # Enter development shell
just build        # Build project
just run          # Run application
```
````

## Quality Standards

Every language implementation must:

✅ **Dual Build System**: Fast dev builds, reproducible release builds  
✅ **Universal Interface**: Same commands work across all languages  
✅ **Complete Testing**: Comprehensive test coverage  
✅ **Template System**: Multiple project variants  
✅ **Quality Integration**: Formatting, linting, pre-commit hooks  
✅ **Documentation**: Clear usage and contribution guides

## Architecture Validation

Use this checklist when adding new languages:

- [ ] Language module follows dual build pattern
- [ ] Dev builds are optimized for speed (`doCheck = false`)
- [ ] Release builds are reproducible with full validation
- [ ] Templates generate working projects
- [ ] Universal justfile commands work
- [ ] Formatting integrates with `nix fmt`
- [ ] Linting works via pre-commit hooks
- [ ] Tests cover all functionality
- [ ] Documentation is complete and accurate

## Best Practices

### Performance Optimization

- Dev builds must complete in <30 seconds for simple projects
- Use incremental compilation and caching where possible
- Skip expensive validation in dev builds
- Only run tests in release builds

### Reproducibility

- Release builds must be deterministic across machines
- Use `SOURCE_DATE_EPOCH` for consistent timestamps
- Lock all dependencies with version files
- Disable user-specific caches and configs

### Developer Experience

- Development shell includes all necessary tools
- Format-on-save works in VS Code via .editorconfig
- Pre-commit hooks prevent commit of unformatted code
- Error messages are clear and actionable

### Template Quality

- Templates represent real-world project structures
- Include comprehensive .gitignore files
- Provide example code demonstrating best practices
- Document project-specific setup steps

---

This systematic approach ensures consistent quality and maintainability across all supported languages.
