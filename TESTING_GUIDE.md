# Testing Guide

**Comprehensive testing procedures for nix-polyglot languages**

This guide explains how to test language implementations, including test architecture, procedures, and automation.

## Test Architecture

nix-polyglot uses a two-tier testing system:

1. **Main Flake Tests** (`test-main-flake.sh`): Library developer perspective
2. **Project User Tests** (`test-project-user.sh`): End-user project perspective

### Test Separation Principles

**Main Flake Tests**: Test the nix-polyglot library itself

- Template generation and structure validation
- Language module loading and exports
- Universal formatting and development shell
- Template apps availability

**Project User Tests**: Test generated projects from user perspective

- Build and execution of generated projects
- Just commands and development workflow
- Integration with existing sample projects
- Real-world usage scenarios

## Main Flake Testing

### Test Structure

```bash
#!/usr/bin/env bash
# test-main-flake.sh - Library developer perspective tests

test_main_functionality() {
    # Core flake functionality
    run_test "flake show" "nix flake show 2>/dev/null" "devShells"
    run_test "flake structure valid" "nix flake metadata && echo VALID" "VALID"
    run_test "universal formatting" "nix fmt && echo SUCCESS" "SUCCESS"

    # Library exports
    run_test "library exports available" \
        "nix eval .#lib --apply 'builtins.attrNames' | wc -w" "3"

    # Language module loading
    run_test "csharp lib loadable" \
        "nix eval --impure --expr 'import ./csharp.nix {...}; \"loadable\"'" "loadable"
}

test_templates() {
    # Template app availability
    run_evaluation_test "template apps available" \
        "nix eval .#apps.x86_64-darwin --apply 'builtins.attrNames'" "8"

    # Template generation for each language
    test_template_generation "csharp-console" "new-csharp" \
        "flake.nix,Program.cs,MyApp.csproj,justfile" "$repo_root"

    test_template_generation "rust-cli" "new-rust" \
        "flake.nix,src/main.rs,Cargo.toml,Cargo.lock,justfile" "$repo_root"
}
```

### Template Generation Testing

Each template must pass comprehensive validation:

```bash
test_template_generation() {
    local template_name="$1"
    local template_app="$2"
    local expected_files="$3"
    local repo_root="$4"
    local test_dir="/tmp/test-template-${template_name}-$$"

    # 1. Template generation succeeds
    run_test "$template_name: template generation" \
        "nix run .#$template_app '$test_dir' && echo 'GENERATED'" \
        "GENERATED"

    # 2. Expected files exist
    cd "$test_dir"
    IFS=',' read -ra FILES <<< "$expected_files"
    for file in "${FILES[@]}"; do
        run_test "$template_name: $file exists" \
            "[[ -f '$file' ]] && echo 'EXISTS'" \
            "EXISTS"
    done

    # 3. Update flake to use local nix-polyglot
    sed -i 's|github:your-org/nix-polyglot|path:'$repo_root'|g' flake.nix

    # 4. Flake structure is valid
    run_test "$template_name: flake structure valid" \
        "nix flake metadata && echo 'VALID'" \
        "VALID"

    # 5. Apps are available
    run_test "$template_name: apps available" \
        "nix eval .#apps.x86_64-darwin --apply 'builtins.attrNames' | grep -q 'default'" \
        ""

    # 6. Packages are available
    run_test "$template_name: packages available" \
        "nix eval .#packages.x86_64-darwin --apply 'builtins.attrNames' | grep -q 'dev'" \
        ""

    # 7. Development shell works
    run_test "$template_name: dev shell works" \
        "nix develop --command echo 'DEV_SHELL_WORKS'" \
        "DEV_SHELL_WORKS"
}
```

## Project User Testing

### Test Structure

```bash
#!/usr/bin/env bash
# test-project-user.sh - End-user project perspective tests

test_project_functionality() {
    # Ensure flake.lock is current
    rm -f flake.lock
    nix flake lock --allow-dirty-locks --impure

    # Test flake outputs
    run_evaluation_test "app outputs available" \
        "nix eval .#apps.x86_64-darwin --apply 'builtins.attrNames'" "8"

    run_evaluation_test "package outputs available" \
        "nix eval .#packages.x86_64-darwin --apply 'builtins.attrNames'" "3"
}

test_core_commands() {
    # Nix run commands
    run_test "nix run (default app)" \
        "nix run 2>/dev/null | head -1" \
        "{expected-output}"

    run_test "nix run .#release" \
        "nix run .#release 2>/dev/null | head -1" \
        "{expected-output}"

    # Quality assurance
    run_test "nix run .#lint" \
        "nix run .#lint 2>/dev/null" \
        "passed!"

    run_test "nix run .#check-format" \
        "nix run .#check-format 2>/dev/null" \
        "passed!"
}

test_just_commands() {
    # Development workflow
    run_test "just build works" \
        "just build 2>/dev/null && echo 'BUILD_SUCCESS'" \
        "BUILD_SUCCESS"

    run_test "just fmt works" \
        "just fmt 2>/dev/null && echo 'FMT_SUCCESS'" \
        "FMT_SUCCESS"

    run_test "just lint works" \
        "just lint 2>/dev/null && echo 'LINT_SUCCESS'" \
        "LINT_SUCCESS"
}

test_build_outputs() {
    # Dev build
    run_test "dev build succeeds" \
        "nix build .#dev 2>/dev/null && echo 'DEV_BUILD_SUCCESS'" \
        "DEV_BUILD_SUCCESS"

    # Release build
    run_test "release build succeeds" \
        "nix build .#release 2>/dev/null && echo 'RELEASE_BUILD_SUCCESS'" \
        "RELEASE_BUILD_SUCCESS"

    # Executable testing
    test_executables
}
```

### Executable Testing

Test that generated binaries work correctly:

```bash
test_executables() {
    echo -e "${YELLOW}📋 EXECUTABLE TESTING${NC}"

    # Build both variants
    nix build .#dev -o result-dev
    nix build .#release -o result-release

    # Find executables (skip system utilities)
    find_executables() {
        find result*/bin -type f -executable | \
        grep -v -E "(createdump|\.dylib)" | \
        head -1
    }

    # Test dev executable
    local dev_exe=$(find_executables | head -1)
    if [[ -n "$dev_exe" ]]; then
        run_test "dev executable runs" \
            "$dev_exe 2>/dev/null | head -1" \
            "{expected-pattern}"
    fi

    # Test release executable
    local release_exe=$(find_executables | tail -1)
    if [[ -n "$release_exe" ]]; then
        run_test "release executable runs" \
            "$release_exe 2>/dev/null | head -1" \
            "{expected-pattern}"
    fi
}
```

## Test Automation

### Running Tests

```bash
# Run all tests
./test-all.sh

# Library developer tests
./test-main-flake.sh

# Project user tests (run from sample projects)
cd samples/{language}-project
../../nix-polyglot/test-project-user.sh
```

### Continuous Integration

Tests run automatically on:

- ✅ Every commit to main branch
- ✅ All pull requests
- ✅ Scheduled weekly validation
- ✅ Before releases

### Test Reporting

Test output format:

```
📚 NIX-POLYGLOT MAIN FLAKE TESTS
=================================
Testing from: /path/to/nix-polyglot
Perspective: Library developer
Started at: [timestamp]

📋 MAIN FLAKE FUNCTIONALITY
--------------------------------------------------
Testing flake show... ✅ PASS
Testing universal formatting... ✅ PASS
Testing library exports... ✅ PASS

🎯 TEMPLATE SYSTEM TESTS
--------------------------------------------------
Testing template apps available... ✅ PASS
📋 Testing csharp-console template
------------------------------
Testing template generation... ✅ PASS
Testing flake.nix exists... ✅ PASS
Testing dev shell works... ✅ PASS

📊 TEST SUMMARY
===============
Total Tests: 25
Passed: 25
Failed: 0
Duration: 45s

🎉 ALL TESTS PASSED! 🎉
```

## Language-Specific Testing

### Adding Tests for New Languages

When adding a new language, implement these test categories:

#### 1. Template Tests

```bash
test_{language}_templates() {
    echo -e "${YELLOW}📋 Testing {language} templates${NC}"

    # Test each template variant
    for template in console library web-api; do
        test_template_generation "{language}-${template}" \
            "new-{language}-${template}" \
            "{template-specific-files}" \
            "$repo_root"
    done

    # Language-specific validation
    test_{language}_specific_features
}
```

#### 2. Build Tests

```bash
test_{language}_builds() {
    local test_project="/tmp/test-{language}-builds"

    # Create test project
    nix run .#new-{language} "$test_project"
    cd "$test_project"

    # Update to use local nix-polyglot
    update_flake_for_local_testing

    # Test dev build
    run_test "{language}: dev build speed" \
        "time nix build .#dev" \
        "30" # Max 30 seconds

    # Test release build
    run_test "{language}: release build reproducible" \
        "nix build .#release && nix build .#release --rebuild && diff result result-2" \
        ""

    # Test executables
    test_{language}_executables
}
```

#### 3. Quality Tests

```bash
test_{language}_quality() {
    # Formatting
    run_test "{language}: formatting works" \
        "nix fmt && git diff --quiet" \
        ""

    # Linting
    run_test "{language}: linting passes" \
        "nix run .#lint" \
        "passed"

    # Pre-commit integration
    run_test "{language}: pre-commit hooks work" \
        "nix develop --command pre-commit run --all-files" \
        ""
}
```

### Performance Testing

Validate build performance meets targets:

```bash
test_performance() {
    local project_type="$1"
    local dev_target="$2"    # seconds
    local release_target="$3" # seconds

    # Clean build timing
    rm -rf result*
    local dev_time=$(time_command "nix build .#dev")
    local release_time=$(time_command "nix build .#release")

    # Validate against targets
    [[ $dev_time -lt $dev_target ]] || fail "Dev build too slow: ${dev_time}s > ${dev_target}s"
    [[ $release_time -lt $release_target ]] || fail "Release build too slow: ${release_time}s > ${release_target}s"

    # Incremental build timing
    touch {some-source-file}
    local incremental_time=$(time_command "nix build .#dev")
    [[ $incremental_time -lt $(($dev_time / 2)) ]] || fail "Incremental build not fast enough"
}
```

### Error Testing

Validate error handling:

```bash
test_error_scenarios() {
    # Invalid template parameters
    run_test "handles invalid template gracefully" \
        "nix run .#new-nonexistent myproject 2>&1 | grep -q 'not found'" \
        ""

    # Missing dependencies
    run_test "reports missing dependencies clearly" \
        "modify_project_to_break_deps && nix build .#dev 2>&1 | grep -q 'dependency'" \
        ""

    # Build failures
    run_test "reports build failures clearly" \
        "introduce_syntax_error && nix build .#dev 2>&1 | grep -q 'error'" \
        ""
}
```

## Testing Best Practices

### Test Development

- ✅ Write tests before implementing features (TDD)
- ✅ Test both success and failure scenarios
- ✅ Use descriptive test names and clear output
- ✅ Make tests fast and deterministic
- ✅ Clean up test artifacts

### Test Maintenance

- ✅ Update tests when changing functionality
- ✅ Remove obsolete tests promptly
- ✅ Keep test code clean and well-documented
- ✅ Use common test utilities to reduce duplication

### Debugging Tests

- ✅ Use `--show-trace` for detailed Nix error information
- ✅ Run single tests in isolation for debugging
- ✅ Preserve test artifacts when tests fail
- ✅ Add verbose output for complex test scenarios

### Test Quality

- ✅ Aim for >90% test coverage of user-facing functionality
- ✅ Test edge cases and error conditions
- ✅ Validate performance characteristics
- ✅ Test across different platforms when possible

## Troubleshooting Tests

### Common Issues

**Template Tests Failing:**

```bash
# Check if templates are git-tracked
git ls-files templates/

# Verify template metadata
nix eval .#templates.{language}-{template}.files --json

# Test template generation manually
nix run .#new-{language} /tmp/debug-template
```

**Build Tests Failing:**

```bash
# Check flake evaluation
nix flake check --show-trace

# Debug build issues
nix build .#dev --show-trace -L

# Check generated flake syntax
nix eval test-project#apps.x86_64-darwin
```

**Performance Tests Failing:**

```bash
# Profile build time
nix build .#dev --profile dev-build-profile
nix path-info --closure-size dev-build-profile

# Check for unnecessary dependencies
nix why-depends result {suspicious-dependency}
```

### Test Environment Setup

Ensure consistent test environment:

```bash
setup_test_environment() {
    # Clean state
    export NIX_CONFIG=""
    unset NIX_PATH

    # Consistent locale
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8
    export TZ=UTC

    # Disable user configs
    export XDG_CONFIG_HOME=/tmp/test-config
    mkdir -p "$XDG_CONFIG_HOME"

    # Clean temporary directory
    export TMPDIR=/tmp/nix-polyglot-tests-$$
    mkdir -p "$TMPDIR"
    trap "rm -rf '$TMPDIR'" EXIT
}
```

---

Following this testing guide ensures comprehensive validation of language implementations and maintains high quality across the nix-polyglot ecosystem.
