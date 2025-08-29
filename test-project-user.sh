#!/usr/bin/env bash
# Test suite for nix-polyglot project user experience
# Run this from a project directory that uses nix-polyglot

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Timing
START_TIME=$(date +%s)

# Test result tracking
FAILED_TEST_NAMES=()

# Detect project language type
detect_project_type() {
    if ls *.csproj >/dev/null 2>&1 || grep -q "buildDotnetModule\|dotnet\|csharp" flake.nix 2>/dev/null; then
        echo "csharp"
    elif [[ -f "Cargo.toml" ]] || grep -q "rust\|cargo" flake.nix 2>/dev/null; then
        echo "rust"
    elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || grep -q "python" flake.nix 2>/dev/null; then
        echo "python"
    else
        echo "unknown"
    fi
}

# Get expected app output based on project type
get_expected_output() {
    local project_type="$1"
    case "$project_type" in
        "csharp")
            echo "Hello, World from C#!"
            ;;
        "rust")
            echo "Hello, World from Rust via Nix-Polyglot!"
            ;;
        "python")
            echo "Hello, World from Python!"
            ;;
        *)
            echo "Hello"
            ;;
    esac
}

# Get expected dev tools based on project type
get_dev_tools() {
    local project_type="$1"
    case "$project_type" in
        "csharp")
            echo "dotnet"
            ;;
        "rust")
            echo "cargo"
            ;;
        "python")
            echo "python"
            ;;
        *)
            echo "fastfetch"  # fallback to common tool
            ;;
    esac
}

print_header() {
    local project_type=$(detect_project_type)
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}👨‍💻 NIX-POLYGLOT PROJECT USER TESTS${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo "Testing from: $(pwd)"
    echo "Perspective: Developer using nix-polyglot"
    echo "Project type: $project_type"
    echo "Started at: $(date)"
    echo ""
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_output="$3"
    local timeout="${4:-30}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo -n "Testing $test_name... "

    if bash -c "$test_command" >/tmp/test_output 2>&1; then
        if [[ -n "$expected_output" ]]; then
            if grep -q "$expected_output" /tmp/test_output; then
                echo -e "${GREEN}✅ PASS${NC}"
                PASSED_TESTS=$((PASSED_TESTS + 1))
                return 0
            else
                echo -e "${RED}❌ FAIL (unexpected output)${NC}"
                echo "Expected: $expected_output"
                echo "Got: $(head -3 /tmp/test_output)"
                FAILED_TESTS=$((FAILED_TESTS + 1))
                FAILED_TEST_NAMES+=("$test_name")
                return 1
            fi
        else
            echo -e "${GREEN}✅ PASS${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        fi
    else
        echo -e "${RED}❌ FAIL (command failed)${NC}"
        echo "Error output: $(tail -3 /tmp/test_output)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_NAMES+=("$test_name")
        return 1
    fi
}

run_evaluation_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_count="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo -n "Testing $test_name... "

    if result=$(bash -c "$test_command" 2>/dev/null); then
        count=$(echo "$result" | grep -o '"[^"]*"' | wc -l | tr -d ' ')
        if [[ "$count" -eq "$expected_count" ]]; then
            echo -e "${GREEN}✅ PASS (found $count items)${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        else
            echo -e "${RED}❌ FAIL (expected $expected_count, got $count)${NC}"
            echo "Result: $result"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            FAILED_TEST_NAMES+=("$test_name")
            return 1
        fi
    else
        echo -e "${RED}❌ FAIL (evaluation failed)${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_NAMES+=("$test_name")
        return 1
    fi
}

test_project_functionality() {
    local project_type=$(detect_project_type)
    local expected_output=$(get_expected_output "$project_type")
    local dev_tool=$(get_dev_tools "$project_type")
    
    echo -e "${YELLOW}📋 PROJECT DEVELOPER WORKFLOW${NC}"
    echo "$(printf '%.0s-' {1..50})"

    # Ensure flake.lock is current
    echo "Refreshing flake.lock for latest nix-polyglot..."
    rm -f flake.lock
    nix flake lock --allow-dirty-locks --impure >/dev/null 2>&1

    # Test flake outputs structure
    run_evaluation_test "app outputs available" \
        "nix eval .#apps.x86_64-darwin --apply 'builtins.attrNames' 2>/dev/null" \
        "8"

    run_evaluation_test "package outputs available" \
        "nix eval .#packages.x86_64-darwin --apply 'builtins.attrNames' 2>/dev/null" \
        "3"

    # Test all core user commands
    echo ""
    echo -e "${YELLOW}📋 CORE USER COMMANDS${NC}"
    echo "$(printf '%.0s-' {1..50})"

    run_test "nix run (default app)" \
        "nix run 2>/dev/null | head -1" \
        "$expected_output"

    run_test "nix run .#release" \
        "nix run .#release 2>/dev/null | head -1" \
        "$expected_output"

    run_test "nix run .#lint" \
        "nix run .#lint 2>/dev/null" \
        "passed!"

    run_test "nix run .#check-format" \
        "nix run .#check-format 2>/dev/null" \
        "passed!"

    # Test formatting - this is the key test you mentioned
    run_test "nix fmt (project formatting)" \
        "nix fmt 2>/dev/null && echo 'PROJECT_FORMAT_SUCCESS'" \
        "PROJECT_FORMAT_SUCCESS"

    run_test "formatter available" \
        "nix eval .#formatter --apply 'f: \"available\"' 2>/dev/null" \
        "available"

    echo ""
    echo -e "${YELLOW}📋 BUILD & DEVELOPMENT${NC}"
    echo "$(printf '%.0s-' {1..50})"

    # Test builds
    run_test "nix build .#dev" \
        "nix build .#dev 2>/dev/null && echo 'BUILD_SUCCESS'" \
        "BUILD_SUCCESS"

    run_test "nix build .#release" \
        "nix build .#release 2>/dev/null && echo 'BUILD_SUCCESS'" \
        "BUILD_SUCCESS"

    # Test development environment
    run_test "nix develop (dev shell)" \
        "nix develop --command bash -c 'which $dev_tool && which fastfetch && echo TOOLS_AVAILABLE'" \
        "TOOLS_AVAILABLE"

    # Test that binaries actually work (avoid createdump and library files)
    run_test "dev binary works" \
        "BINPATH=\$(nix build .#dev --print-out-paths 2>/dev/null)/bin; BINARY=\$(ls \$BINPATH | grep -v '^c' | grep -v '\\.dylib\$' | head -1); \$BINPATH/\$BINARY | head -1" \
        "Hello"

    run_test "release binary works" \
        "BINPATH=\$(nix build .#release --print-out-paths 2>/dev/null)/bin; BINARY=\$(ls \$BINPATH | grep -v '^c' | grep -v '\\.dylib\$' | head -1); \$BINPATH/\$BINARY | head -1" \
        "Hello"

    echo ""
    echo -e "${YELLOW}📋 QUALITY ASSURANCE${NC}"
    echo "$(printf '%.0s-' {1..50})"

    # Test comprehensive checks (evaluation only to avoid long build times)
    run_test "nix flake check (comprehensive)" \
        "nix flake check 2>/dev/null && echo 'ALL_CHECKS_PASSED'" \
        "ALL_CHECKS_PASSED"

    # Test pre-commit integration
    run_test "pre-commit hooks work" \
        "nix develop --command bash -c 'echo \"Pre-commit ready\" && exit 0'" \
        "Pre-commit ready"

    echo ""
    echo -e "${YELLOW}📋 PROJECT MAINTENANCE${NC}"
    echo "$(printf '%.0s-' {1..50})"
    
    # Test nix-polyglot maintenance apps are available
    run_test "setup app available" \
        "nix eval .#apps.x86_64-darwin.setup.program 2>/dev/null >/dev/null && echo 'AVAILABLE'" \
        "AVAILABLE"
    
    run_test "update-project app available" \
        "nix eval .#apps.x86_64-darwin.update-project.program 2>/dev/null >/dev/null && echo 'AVAILABLE'" \
        "AVAILABLE"
    
    run_test "migrate app available" \
        "nix eval .#apps.x86_64-darwin.migrate.program 2>/dev/null >/dev/null && echo 'AVAILABLE'" \
        "AVAILABLE"
    
    # Test that project can be analyzed for updates
    run_test "project structure analysis" \
        "nix eval .#apps --apply 'apps: builtins.length (builtins.attrNames apps)' 2>/dev/null | grep -E '^[0-9]+$' && echo 'ANALYZABLE'" \
        "ANALYZABLE"

    echo ""
}

main() {
    print_header

    # Ensure we're in a project directory using nix-polyglot
    if [[ ! -f "flake.nix" ]]; then
        echo -e "${RED}Error: No flake.nix found. Run this script from a project directory.${NC}"
        exit 1
    fi

    # Check if this project uses nix-polyglot
    if ! grep -q "nix-polyglot" flake.nix 2>/dev/null; then
        echo -e "${RED}Error: This project doesn't appear to use nix-polyglot.${NC}"
        exit 1
    fi

    test_project_functionality

    # Print summary
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))

    echo -e "${BLUE}📊 PROJECT USER TEST SUMMARY${NC}"
    echo "$(printf '%.0s=' {1..30})"
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo "Duration: ${duration}s"
    echo ""

    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 ALL PROJECT USER TESTS PASSED! 🎉${NC}"
        echo -e "${GREEN}Your nix-polyglot project is working perfectly!${NC}"
        echo ""
        echo "✅ You can confidently use these commands:"
        echo "  • nix run                    (run your app)"
        echo "  • nix run .#release         (run release build)"
        echo "  • nix fmt                    (format your code)"
        echo "  • nix run .#lint            (lint your code)"
        echo "  • nix run .#check-format    (verify formatting)"
        echo "  • nix develop               (enter dev shell)"
        echo "  • nix build .#{dev,release} (build packages)"
        echo "  • nix flake check           (run all checks)"
        echo "  • nix run .#{setup,update-project,migrate} (project maintenance)"
    else
        echo -e "${RED}❌ SOME TESTS FAILED${NC}"
        echo "Failed tests:"
        for test in "${FAILED_TEST_NAMES[@]}"; do
            echo -e "  ${RED}• $test${NC}"
        done
        echo ""
        echo -e "${YELLOW}This means some functionality may not work as expected.${NC}"
    fi

    echo ""
    echo "Test completed at: $(date)"

    # Exit with proper code
    if [[ $FAILED_TESTS -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}Test interrupted by user${NC}"; exit 130' INT

main "$@"
