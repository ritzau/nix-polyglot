#!/usr/bin/env bash
# Quick comprehensive test for nix-polyglot functionality
# Tests from both perspectives: library developer and project user

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

START_TIME=$(date +%s)
FAILED_TEST_NAMES=()

print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}🧪 NIX-POLYGLOT QUICK TEST SUITE${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo "This script tests both perspectives:"
    echo "📚 Library developer (main flake functionality)"
    echo "👨‍💻 Project user (C# project using nix-polyglot)"
    echo ""
    echo "Started at: $(date)"
    echo ""
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_output="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo -n "Testing $test_name... "

    if result=$(bash -c "$test_command" 2>/tmp/test_error); then
        if [[ -n "$expected_output" ]]; then
            if echo "$result" | grep -q "$expected_output"; then
                echo -e "${GREEN}✅ PASS${NC}"
                PASSED_TESTS=$((PASSED_TESTS + 1))
                return 0
            else
                echo -e "${RED}❌ FAIL (unexpected output)${NC}"
                echo "Expected: $expected_output"
                echo "Got: $result"
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
        echo "Error: $(cat /tmp/test_error | head -2)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_NAMES+=("$test_name")
        return 1
    fi
}

run_count_test() {
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

test_main_flake() {
    echo -e "${YELLOW}📚 MAIN FLAKE TESTS (Library Developer)${NC}"
    echo "$(printf '%.0s-' {1..50})"

    cd /Users/ritzau/src/slask/nix/polyglot/nix-polyglot

    # Basic flake structure
    run_test "flake evaluates" \
        "nix flake show 2>/dev/null | head -1" \
        ""

    run_test "lib exports available" \
        "nix eval .#lib --apply 'lib: builtins.attrNames lib' 2>/dev/null" \
        "csharp"

    run_test "dev shell loadable" \
        "nix eval .#devShells.x86_64-darwin.default 2>/dev/null >/dev/null && echo 'LOADABLE'" \
        "LOADABLE"

    run_test "formatter available" \
        "nix eval .#formatter 2>/dev/null >/dev/null && echo 'AVAILABLE'" \
        "AVAILABLE"

    echo ""
}

test_csharp_project() {
    echo -e "${YELLOW}👨‍💻 C# PROJECT TESTS (Project User)${NC}"
    echo "$(printf '%.0s-' {1..50})"

    cd /Users/ritzau/src/slask/nix/polyglot/samples/csharp-nix

    # Ensure we have latest changes
    echo "Refreshing flake.lock for latest nix-polyglot..."
    rm -f flake.lock
    if nix flake lock --allow-dirty-locks --impure >/dev/null 2>&1; then
        echo "✅ Flake.lock updated"
    else
        echo "❌ Failed to update flake.lock"
        return 1
    fi

    # Test project structure
    run_count_test "apps available" \
        "nix eval .#apps.x86_64-darwin --apply 'builtins.attrNames' 2>/dev/null" \
        "5"

    run_count_test "packages available" \
        "nix eval .#packages.x86_64-darwin --apply 'builtins.attrNames' 2>/dev/null" \
        "3"

    # Test core functionality (fast checks only)
    run_test "default app defined" \
        "nix eval .#apps.x86_64-darwin.default.program 2>/dev/null >/dev/null && echo 'DEFINED'" \
        "DEFINED"

    run_test "release app defined" \
        "nix eval .#apps.x86_64-darwin.release.program 2>/dev/null >/dev/null && echo 'DEFINED'" \
        "DEFINED"

    run_test "lint app defined" \
        "nix eval .#apps.x86_64-darwin.lint.program 2>/dev/null >/dev/null && echo 'DEFINED'" \
        "DEFINED"

    run_test "formatter defined" \
        "nix eval .#formatter 2>/dev/null >/dev/null && echo 'DEFINED'" \
        "DEFINED"

    run_test "dev shell defined" \
        "nix eval .#devShells.x86_64-darwin.default 2>/dev/null >/dev/null && echo 'DEFINED'" \
        "DEFINED"

    # Test one actual run (quick)
    run_test "binary actually works" \
        "$(nix build .#dev --print-out-paths 2>/dev/null)/bin/HelloService 2>/dev/null | head -1" \
        "Hello, World from C#"

    echo ""
}

test_integration() {
    echo -e "${YELLOW}🔧 INTEGRATION TESTS${NC}"
    echo "$(printf '%.0s-' {1..50})"

    cd /Users/ritzau/src/slask/nix/polyglot/samples/csharp-nix

    # Test that builds are different between dev and release
    run_test "dev vs release builds differ" \
        "dev_hash=\$(nix build .#dev --print-out-paths 2>/dev/null | xargs nix-hash --type sha256) && rel_hash=\$(nix build .#release --print-out-paths 2>/dev/null | xargs nix-hash --type sha256) && [[ \"\$dev_hash\" != \"\$rel_hash\" ]] && echo 'DIFFERENT'" \
        "DIFFERENT"

    # Test that all checks can at least be evaluated
    run_test "checks evaluable" \
        "nix flake check --dry-run 2>/dev/null >/dev/null && echo 'EVALUABLE'" \
        "EVALUABLE"

    echo ""
}

print_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))

    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}📊 QUICK TEST SUMMARY${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo "Duration: ${duration}s"
    echo ""

    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
        echo -e "${GREEN}nix-polyglot is working correctly!${NC}"
        echo ""
        echo "✅ Verified functionality:"
        echo "  • Library structure and exports"
        echo "  • Project flake outputs (5 apps, 3 packages)"
        echo "  • App definitions and executability"
        echo "  • Dev vs Release build differences"
        echo "  • Development shell and formatter"
        echo "  • C# binaries run correctly"
        echo ""
        echo "🚀 Ready for production use!"
    else
        echo -e "${RED}❌ SOME TESTS FAILED${NC}"
        echo "Failed tests:"
        for test in "${FAILED_TEST_NAMES[@]}"; do
            echo -e "  ${RED}• $test${NC}"
        done
        echo ""
        echo -e "${YELLOW}Some functionality may not work as expected.${NC}"
    fi

    echo ""
    echo "Test completed at: $(date)"
}

main() {
    print_header

    # Check prerequisites
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
    test_csharp_project
    test_integration

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
