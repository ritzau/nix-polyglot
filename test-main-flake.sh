#!/usr/bin/env bash
# Test suite for nix-polyglot main flake (library developer perspective)

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
    echo -e "${BLUE}📚 NIX-POLYGLOT MAIN FLAKE TESTS${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo "Testing from: $(pwd)"
    echo "Perspective: Library developer"
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

main() {
    print_header

    # Ensure we're in the main flake directory
    if [[ ! -f "flake.nix" ]] || [[ ! -f "csharp.nix" ]]; then
        echo -e "${RED}Error: Run this script from the nix-polyglot main directory${NC}"
        exit 1
    fi

    echo -e "${YELLOW}📋 MAIN FLAKE FUNCTIONALITY${NC}"
    echo "$(printf '%.0s-' {1..50})"

    # Test basic flake operations
    run_test "flake show" \
        "nix flake show 2>/dev/null" \
        "devShells"

    run_test "flake check evaluation" \
        "nix flake check 2>/dev/null" \
        ""

    # Test universal formatting
    run_test "universal formatting" \
        "nix fmt 2>/dev/null && echo 'FORMAT_SUCCESS'" \
        "FORMAT_SUCCESS"

    # Test development shell
    run_test "dev shell tools" \
        "nix develop --command bash -c 'which nixpkgs-fmt && echo DEV_SHELL_SUCCESS'" \
        "DEV_SHELL_SUCCESS"

    # Test library exports
    run_evaluation_test "library exports" \
        "nix eval --impure --expr 'let lib = (import ./flake.nix).lib; in builtins.attrNames lib'" \
        "4"

    run_test "csharp lib loadable" \
        "nix eval --impure --expr 'let nixpkgs = import <nixpkgs> {}; csharp = import ./csharp.nix { inherit nixpkgs; treefmt-nix = null; git-hooks-nix = null; }; in \"loadable\"' 2>/dev/null" \
        "loadable"

    run_test "rust lib loadable" \
        "nix eval --impure --expr 'let nixpkgs = import <nixpkgs> {}; rust = import ./rust.nix { inherit nixpkgs; }; in \"loadable\"' 2>/dev/null" \
        "loadable"

    echo ""

    # Print summary
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))

    echo -e "${BLUE}📊 MAIN FLAKE TEST SUMMARY${NC}"
    echo "$(printf '%.0s=' {1..30})"
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo "Duration: ${duration}s"
    echo ""

    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 ALL MAIN FLAKE TESTS PASSED! 🎉${NC}"
        echo -e "${GREEN}The nix-polyglot library is working correctly!${NC}"
    else
        echo -e "${RED}❌ SOME TESTS FAILED${NC}"
        echo "Failed tests:"
        for test in "${FAILED_TEST_NAMES[@]}"; do
            echo -e "  ${RED}• $test${NC}"
        done
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
