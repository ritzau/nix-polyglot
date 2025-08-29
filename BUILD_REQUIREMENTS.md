# Build Requirements Specification

**Development vs Release Build Requirements for nix-polyglot**

This document specifies the exact requirements for dev and release builds, testing procedures, and quality standards.

## Build Type Specifications

### Development Builds (`nix build .#dev`)

**Purpose**: Fast iteration during development with debug information.

**Requirements:**

- ✅ **Speed**: Must complete in <30 seconds for simple projects
- ✅ **Debug Info**: Include debug symbols and source line information
- ✅ **Skip Tests**: Set `doCheck = false` to skip test execution
- ✅ **Build Type**: Use `Debug` configuration or equivalent
- ✅ **Caching**: Enable all available caches for faster builds
- ✅ **Incremental**: Support incremental compilation where possible

**Environment:**

```nix
devBuildConfig = {
  env = {
    # Only essential environment variables
    # Allow user caches and configs for speed
  };
  buildFlags = [
    # Enable debug symbols
    # Skip assembly versioning
    # Minimal validation flags
  ];
  doCheck = false; # Never run tests in dev builds
  buildType = "Debug";
};
```

**Must NOT Include:**

- ❌ Reproducibility controls (`SOURCE_DATE_EPOCH`, `TZ=UTC`)
- ❌ Deterministic build flags
- ❌ `--no-cache` or similar cache-disabling options
- ❌ Test execution (`doCheck = false`)
- ❌ Assembly/binary signing
- ❌ Source revision embedding

### Release Builds (`nix build .#release`)

**Purpose**: Reproducible, production-quality builds with full validation.

**Requirements:**

- ✅ **Reproducible**: Identical output across different machines/times
- ✅ **Deterministic**: Use `SOURCE_DATE_EPOCH` for consistent timestamps
- ✅ **Full Testing**: Set `doCheck = hasTests` to run all tests
- ✅ **Build Type**: Use `Release` configuration or equivalent
- ✅ **Validation**: Include comprehensive quality checks
- ✅ **Documentation**: Embed source revision and repository info

**Environment:**

```nix
releaseBuildConfig = {
  env = {
    # Full reproducibility controls
    TZ = "UTC";
    LC_ALL = "C.UTF-8";
    LANG = "C.UTF-8";
    SOURCE_DATE_EPOCH = toString sourceEpoch;
    DETERMINISTIC_BUILD = "true";

    # Disable user-specific behavior
    # Disable caches for reproducibility
    # Force consistent behavior
  };
  buildFlags = [
    # Deterministic build flags
    # Source revision embedding
    # Assembly versioning
    # Optimization flags
  ];
  doCheck = hasTests; # Run tests if available
  buildType = "Release";
};
```

**Must Include:**

- ✅ Environment isolation (`TZ=UTC`, `LC_ALL=C.UTF-8`)
- ✅ Deterministic timestamps (`SOURCE_DATE_EPOCH`)
- ✅ Source revision tracking
- ✅ Comprehensive validation flags
- ✅ Test execution when available
- ✅ Cache disabling for reproducibility (`--no-cache`, `--locked-mode`)

## Quality Assurance Requirements

### Check Integration (`nix flake check`)

Every language must provide these checks:

```nix
checks = {
  # Build validation
  build-dev = devPackage;      # Dev build succeeds
  build-release = releasePackage; # Release build succeeds

  # Code quality
  lint-check = lintingCheck;   # Code passes linting
  format-check = formatCheck;  # Code is properly formatted

  # Git integration
  pre-commit-check = git-hooks; # Pre-commit hooks work

  # Language-specific checks
  test-execution = testRunner;  # Tests pass (if applicable)
  dependency-audit = depsCheck; # Dependencies are secure
};
```

### Formatting Requirements (`nix fmt`)

**Universal Formatting Integration:**

- ✅ Must integrate with treefmt-nix for universal `nix fmt`
- ✅ Must provide language-specific formatter
- ✅ Must work with `just fmt` command
- ✅ Must support `nix run .#check-format` for validation

**Implementation:**

```nix
# Language formatter
projectFormatter = pkgs.writeShellApplication {
  name = "{language}-formatter";
  text = ''
    echo "🎨 Formatting {Language} code..."
    ${formatter}/bin/{formatter-cmd} ${formatArgs}
    echo "✅ {Language} formatting complete!"
  '';
};

# treefmt integration (if applicable)
treefmt = treefmt-nix.lib.${system}.evalModule {
  projectRootFile = "flake.nix";
  programs.{language-formatter}.enable = true;
  settings.formatter.{language-formatter} = {
    command = "${formatter}/bin/{formatter-cmd}";
    includes = ["*.{ext1}" "*.{ext2}"];
  };
};
```

### Linting Requirements (`nix run .#lint`)

**Pre-commit Integration:**

- ✅ Must integrate with git-hooks-nix for automatic pre-commit linting
- ✅ Must provide standalone linting via `nix run .#lint`
- ✅ Must validate code quality and style
- ✅ Must prevent commits of poorly formatted code

**Implementation:**

```nix
git-hooks = git-hooks-nix.lib.${system}.run {
  src = self;
  hooks = {
    {language}-format = {
      enable = true;
      name = "{language} format";
      entry = "${formatter}/bin/{formatter-cmd} --check";
      files = "\\.(${extensions})$";
      pass_filenames = false;
    };
    {language}-lint = {
      enable = true;
      name = "{language} lint";
      entry = "${linter}/bin/{linter-cmd}";
      files = "\\.(${extensions})$";
    };
  };
};
```

## Testing Standards

### Template Testing

Every template must pass these tests:

```bash
# Template generation
test_template_generation() {
    # 1. Template creates project successfully
    nix run .#new-{language} test-project

    # 2. All expected files exist
    check_files_exist "flake.nix" "{build-file}" "{source-files}"

    # 3. Flake structure is valid
    nix flake metadata test-project

    # 4. Apps are available
    nix eval test-project#apps.x86_64-darwin --apply builtins.attrNames

    # 5. Packages are available
    nix eval test-project#packages.x86_64-darwin --apply builtins.attrNames

    # 6. Development shell works
    nix develop test-project --command echo "shell works"
}
```

### Build Testing

Both build types must pass:

```bash
# Dev build testing
test_dev_build() {
    # 1. Build completes successfully
    nix build test-project#dev

    # 2. Executable runs correctly
    ./result/bin/{app-name}

    # 3. Debug symbols present (language-specific validation)
    check_debug_symbols ./result/bin/{app-name}

    # 4. Build time is reasonable (<30s for simple projects)
    time nix build test-project#dev
}

# Release build testing
test_release_build() {
    # 1. Build completes successfully
    nix build test-project#release

    # 2. Executable runs correctly
    ./result/bin/{app-name}

    # 3. Build is reproducible
    nix build test-project#release --rebuild
    compare_outputs result result-2

    # 4. Tests run if available
    check_tests_executed
}
```

### Integration Testing

Commands must work correctly:

```bash
# justfile commands
test_just_commands() {
    cd test-project

    just --list              # Shows available commands
    just dev                 # Enters development shell
    just build               # Builds project
    just run                 # Runs application
    just release             # Runs release build
    just fmt                 # Formats code
    just lint                # Runs linting
    just test                # Runs tests and checks
    just clean               # Cleans artifacts
}

# Nix commands
test_nix_commands() {
    cd test-project

    nix develop             # Development environment
    nix build .#dev         # Dev build
    nix build .#release     # Release build
    nix run                 # Default app
    nix run .#release       # Release app
    nix flake check         # All checks
    nix fmt                 # Universal formatting
}
```

## Performance Benchmarks

### Build Time Targets

| Project Type         | Dev Build   | Release Build |
| -------------------- | ----------- | ------------- |
| Simple console app   | <10 seconds | <30 seconds   |
| Library project      | <15 seconds | <45 seconds   |
| Web application      | <30 seconds | <90 seconds   |
| Complex multi-module | <60 seconds | <180 seconds  |

### Memory Usage Targets

| Build Type    | Peak Memory | Sustained Memory |
| ------------- | ----------- | ---------------- |
| Dev build     | <2GB        | <1GB             |
| Release build | <4GB        | <2GB             |

### Cache Effectiveness

- ✅ Second dev build (no changes): <5 seconds
- ✅ Second release build (no changes): <10 seconds
- ✅ Incremental dev build (minor changes): <50% of full build time

## Language-Specific Extensions

### Package Managers

For languages with package managers:

**Dev Build:**

- ✅ Use package manager caches
- ✅ Allow loose version constraints
- ✅ Skip security auditing for speed

**Release Build:**

- ✅ Use lock files for reproducibility
- ✅ Run security audits
- ✅ Validate dependency integrity
- ✅ Use `--frozen` or `--locked` modes

### Compilation Flags

**Dev Build Flags:**

```
Debug symbols: ON
Optimizations: OFF
Assertions: ON
Debug logging: ON
Reproducibility: OFF
```

**Release Build Flags:**

```
Debug symbols: MINIMAL
Optimizations: MAX
Assertions: OFF
Debug logging: OFF
Reproducibility: ON
```

## Validation Checklist

Use this checklist when implementing new language support:

### Build System

- [ ] Dev builds complete in target time
- [ ] Release builds are reproducible
- [ ] Both build types produce working executables
- [ ] Debug symbols present in dev builds
- [ ] Optimization applied in release builds

### Quality Integration

- [ ] `nix fmt` formats language code
- [ ] `nix run .#lint` validates code quality
- [ ] Pre-commit hooks prevent bad commits
- [ ] `nix flake check` validates everything

### Template Quality

- [ ] Templates generate working projects
- [ ] All justfile commands work
- [ ] Development shell includes necessary tools
- [ ] Generated projects follow best practices

### Testing Coverage

- [ ] Template generation tested
- [ ] Build success/failure tested
- [ ] Executable functionality tested
- [ ] Performance benchmarks met
- [ ] Integration commands tested

### Documentation

- [ ] Language module documented
- [ ] Template usage explained
- [ ] Build requirements specified
- [ ] Troubleshooting guide provided

---

Following these specifications ensures consistent, high-quality language support across the nix-polyglot ecosystem.
