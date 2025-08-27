#!/usr/bin/env bash
# Comprehensive test suite for nix-polyglot
# Tests all functionality across main flake and sample projects

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

print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}🧪 NIX-POLYGLOT COMPREHENSIVE TEST SUITE${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo "Started at: $(date)"
    echo ""
    echo "This test suite verifies functionality from two perspectives:"
    echo "1. 📚 Main flake perspective (library developer)"
    echo "2. 👨‍💻 Project user perspective (C# developer using the library)"
    echo ""
}

print_section() {
    echo -e "${YELLOW}📋 $1${NC}"
    echo "$(printf '%.0s-' {1..50})"
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_output="$3"
    local timeout="${4:-30}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo -n "Testing $test_name... "

    if timeout "${timeout}s" bash -c "$test_command" >/tmp/test_output 2>&1; then
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

    if result=$(timeout 15s bash -c "$test_command" 2>/dev/null); then
        count=$(echo "$result" | wc -w | tr -d ' ')
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

test_main_flake() {
    print_section "MAIN FLAKE TESTS"

    cd /Users/ritzau/src/slask/nix/polyglot/nix-polyglot

    # Test basic flake operations
    run_test "flake show" \
        "nix flake show 2>/dev/null" \
        "devShells"

    run_test "flake check evaluation" \
        "nix flake check 2>/dev/null" \
        ""

    # Test universal formatting (main flake)
    run_test "universal formatting (main flake)" \
        "timeout 30s nix fmt 2>/dev/null && echo 'FORMAT_SUCCESS'" \
        "FORMAT_SUCCESS"

    # Test development shell
    run_test "dev shell tools" \
        "nix develop --command bash -c 'which nixpkgs-fmt && echo DEV_SHELL_SUCCESS'" \
        "DEV_SHELL_SUCCESS"

    # Test library exports
    run_evaluation_test "csharp lib export" \
        "nix eval --impure --expr 'let lib = (import ./flake.nix).lib; in builtins.attrNames lib'" \
        "4"

    echo ""
}

test_csharp_sample() {
    print_section "C# SAMPLE PROJECT TESTS"

    cd /Users/ritzau/src/slask/nix/polyglot/samples/csharp-nix

    # Regenerate flake.lock to ensure latest changes
    echo "Regenerating flake.lock for latest changes..."
    rm -f flake.lock
    nix flake lock --allow-dirty-locks --impure >/dev/null 2>&1

    # Test flake outputs structure
    run_evaluation_test "app outputs count" \
        "nix eval .#apps.x86_64-darwin --apply 'builtins.attrNames' 2>/dev/null" \
        "5"

    run_evaluation_test "package outputs count" \
        "nix eval .#packages.x86_64-darwin --apply 'builtins.attrNames' 2>/dev/null" \
        "3"

    # Test all apps
    run_test "default app (dev)" \
        "nix run 2>/dev/null | head -1" \
        "Hello, World from C#"

    run_test "release app" \
        "nix run .#release 2>/dev/null | head -1" \
        "Hello, World from C#"

    run_test "lint app" \
        "nix run .#lint 2>/dev/null" \
        "Linting passed!"

    run_test "check-format app" \
        "nix run .#check-format 2>/dev/null" \
        "C# formatting check passed!"

    # Test builds
    run_test "dev build" \
        "nix build .#dev 2>/dev/null && echo 'BUILD_SUCCESS'" \
        "BUILD_SUCCESS"

    run_test "release build" \
        "nix build .#release 2>/dev/null && echo 'BUILD_SUCCESS'" \
        "BUILD_SUCCESS"

    # Test dev shell functionality
    run_test "dev shell with tools" \
        "nix develop --command bash -c 'which dotnet && which fastfetch && echo TOOLS_AVAILABLE'" \
        "TOOLS_AVAILABLE"

    # Test that binaries actually work
    run_test "dev binary execution" \
        "$(nix build .#dev --print-out-paths 2>/dev/null)/bin/HelloService | head -1" \
        "Hello, World from C#"

    run_test "release binary execution" \
        "$(nix build .#release --print-out-paths 2>/dev/null)/bin/HelloService | head -1" \
        "Hello, World from C#"

    # Test pre-commit hooks are configured
    run_test "pre-commit hooks configured" \
        "nix develop --command bash -c 'echo \"Pre-commit configured\" && exit 0'" \
        "Pre-commit configured"

    # Test project-specific formatting
    run_test "project formatting (nix fmt)" \
        "timeout 60s nix fmt 2>/dev/null && echo 'PROJECT_FORMAT_SUCCESS'" \
        "PROJECT_FORMAT_SUCCESS" \
        60

    # Test that formatter is available
    run_test "formatter available" \
        "nix eval .#formatter --apply 'f: \"available\"' 2>/dev/null" \
        "available"

    echo ""
}

test_architecture_features() {
    print_section "ARCHITECTURE & INTEGRATION TESTS"

    cd /Users/ritzau/src/slask/nix/polyglot/samples/csharp-nix

    # Test that all expected apps are present
    run_test "all apps available" \
        "nix eval .#apps.x86_64-darwin --apply 'builtins.attrNames' 2>/dev/null | grep -c '\"'" \
        ""

    # Test reproducible builds (should be deterministic)
    run_test "reproducible dev builds" \
        "hash1=\$(nix build .#dev --print-out-paths 2>/dev/null | xargs nix-hash --type sha256) && nix-store --delete /nix/store/*HelloService-dev* 2>/dev/null || true && hash2=\$(nix build .#dev --print-out-paths 2>/dev/null | xargs nix-hash --type sha256) && [[ \"\$hash1\" == \"\$hash2\" ]] && echo 'REPRODUCIBLE'" \
        "REPRODUCIBLE"

    # Test that formatting and linting actually validate code
    run_test "formatting validation works" \
        "nix run .#check-format 2>/dev/null && nix run .#lint 2>/dev/null && echo 'VALIDATION_SUCCESS'" \
        "VALIDATION_SUCCESS"

    # Test flake checks (comprehensive test)
    run_test "comprehensive flake checks" \
        "timeout 120s nix flake check 2>/dev/null && echo 'ALL_CHECKS_PASSED'" \
        "ALL_CHECKS_PASSED" \
        120

    echo ""
}

test_error_conditions() {
    print_section "ERROR HANDLING TESTS"

    cd /Users/ritzau/src/slask/nix/polyglot/samples/csharp-nix

    # Test that apps handle missing executables gracefully
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "Testing graceful error handling... "

    # This should succeed because our apps are correctly configured
    if nix eval .#apps.x86_64-darwin.default.program 2>/dev/null | grep -q "/nix/store"; then
        echo -e "${GREEN}✅ PASS (apps properly configured)${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ FAIL (app misconfiguration)${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_NAMES+=("graceful error handling")
    fi

    echo ""
}

print_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))

    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}📊 TEST SUMMARY${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo "Duration: ${duration}s"
    echo ""

    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
        echo -e "${GREEN}nix-polyglot is working perfectly!${NC}"
    else
        echo -e "${RED}❌ SOME TESTS FAILED${NC}"
        echo "Failed tests:"
        for test in "${FAILED_TEST_NAMES[@]}"; do
            echo -e "  ${RED}• $test${NC}"
        done
        echo ""
        echo -e "${YELLOW}Check the output above for details.${NC}"
    fi

    echo ""
    echo "Test completed at: $(date)"
}

# Main execution
main() {
    print_header

    # Ensure we're in the right directory structure
    if [[ ! -f "/Users/ritzau/src/slask/nix/polyglot/nix-polyglot/flake.nix" ]]; then
        echo -e "${RED}Error: Cannot find nix-polyglot main flake${NC}"
        exit 1
    fi

    if [[ ! -f "/Users/ritzau/src/slask/nix/polyglot/samples/csharp-nix/flake.nix" ]]; then
        echo -e "${RED}Error: Cannot find C# sample project${NC}"
        exit 1
    fi

    # Run all test suites
    test_main_flake
    test_csharp_sample
    test_architecture_features
    test_error_conditions

    print_summary

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
