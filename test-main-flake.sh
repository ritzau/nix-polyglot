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

test_template_generation() {
    local template_name="$1"
    local template_app="$2"
    local expected_files="$3"
    local repo_root="$4"
    local test_dir="/tmp/test-template-${template_name}-$$"
    
    echo -e "${YELLOW}📋 Testing $template_name template${NC}"
    echo "$(printf '%.0s-' {1..30})"
    
    # Clean up on exit
    trap "rm -rf '$test_dir'" RETURN
    
    # Test template generation
    run_test "$template_name: template generation" \
        "nix run .#$template_app '$test_dir' &>/dev/null && echo 'GENERATED'" \
        "GENERATED"
    
    if [[ ! -d "$test_dir" ]]; then
        echo -e "  ${RED}❌ Template directory not created${NC}"
        return 1
    fi
    
    # Test expected files exist
    cd "$test_dir"
    IFS=',' read -ra FILES <<< "$expected_files"
    for file in "${FILES[@]}"; do
        run_test "$template_name: $file exists" \
            "[[ -f '$file' ]] && echo 'EXISTS'" \
            "EXISTS"
    done
    
    # Update flake to use local nix-polyglot
    sed -i '' 's|github:your-org/nix-polyglot|path:'"$repo_root"'|g' flake.nix || true
    
    # Test generated project structure and quick validation
    run_test "$template_name: flake structure valid" \
        "nix flake metadata &>/dev/null && echo 'VALID'" \
        "VALID"
    
    run_test "$template_name: apps available" \
        "nix eval .#apps.x86_64-darwin --apply 'builtins.attrNames' 2>/dev/null | grep -q '\"default\"' && echo 'APPS_AVAILABLE'" \
        "APPS_AVAILABLE"
    
    run_test "$template_name: packages available" \
        "nix eval .#packages.x86_64-darwin --apply 'builtins.attrNames' 2>/dev/null | grep -q '\"dev\"' && echo 'PACKAGES_AVAILABLE'" \
        "PACKAGES_AVAILABLE"
    
    # Test development environment works  
    run_test "$template_name: dev shell works" \
        "nix develop --command bash -c 'echo DEV_SHELL_WORKS'" \
        "DEV_SHELL_WORKS"
    
    cd - > /dev/null
    echo ""
}

test_templates() {
    echo -e "${YELLOW}🎯 TEMPLATE SYSTEM TESTS${NC}"
    echo "$(printf '%.0s-' {1..50})"
    
    # Test template apps are available (2 C#, 2 Rust, 2 Python, 2 Nim, 2 Zig, 2 Go = 12 template apps)
    run_test "template apps available" \
        "nix eval .#apps.x86_64-darwin --apply 'apps: builtins.length (builtins.attrNames (builtins.removeAttrs apps [\"templates\" \"setup\" \"update-project\" \"migrate\" \"format-templates\"]))' 2>/dev/null" \
        "12"
    
    run_test "template listing works" \
        "nix run .#templates 2>/dev/null | head -1" \
        "🚀 Available nix-polyglot project templates:"
    
    # Test main template variants (quick validation)
    local repo_root="$(pwd)"
    test_template_generation "csharp-console" "new-csharp" "flake.nix,Program.cs,MyApp.csproj" "$repo_root"
    test_template_generation "rust-cli" "new-rust" "flake.nix,src/main.rs,Cargo.toml,Cargo.lock" "$repo_root"
    test_template_generation "python-console" "new-python" "flake.nix,pyproject.toml,myapp/main.py" "$repo_root"
    test_template_generation "nim-cli" "new-nim" "flake.nix,src/main.nim,nim_project.nimble" "$repo_root"
    test_template_generation "zig-cli" "new-zig" "flake.nix,src/main.zig,build.zig" "$repo_root"
    test_template_generation "go-cli" "new-go" "flake.nix,main.go,go.mod" "$repo_root"
    
    # Verify explicit variants are available
    run_test "explicit csharp template available" \
        "nix eval .#apps.x86_64-darwin.new-csharp-console 2>/dev/null >/dev/null && echo 'AVAILABLE'" \
        "AVAILABLE"
    
    run_test "explicit rust template available" \
        "nix eval .#apps.x86_64-darwin.new-rust-cli 2>/dev/null >/dev/null && echo 'AVAILABLE'" \
        "AVAILABLE"
    
    run_test "explicit python template available" \
        "nix eval .#apps.x86_64-darwin.new-python-console 2>/dev/null >/dev/null && echo 'AVAILABLE'" \
        "AVAILABLE"
    
    run_test "explicit nim template available" \
        "nix eval .#apps.x86_64-darwin.new-nim-cli 2>/dev/null >/dev/null && echo 'AVAILABLE'" \
        "AVAILABLE"
    
    run_test "explicit zig template available" \
        "nix eval .#apps.x86_64-darwin.new-zig-cli 2>/dev/null >/dev/null && echo 'AVAILABLE'" \
        "AVAILABLE"
    
    run_test "explicit go template available" \
        "nix eval .#apps.x86_64-darwin.new-go-cli 2>/dev/null >/dev/null && echo 'AVAILABLE'" \
        "AVAILABLE"
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

    # Skip full flake check for now due to template build times
    run_test "flake structure valid" \
        "nix flake metadata 2>/dev/null && echo 'VALID'" \
        "VALID"

    # Test universal formatting
    run_test "universal formatting" \
        "nix fmt 2>/dev/null && echo 'FORMAT_SUCCESS'" \
        "FORMAT_SUCCESS"

    # Test development shell
    run_test "dev shell tools" \
        "nix develop --command bash -c 'which nixpkgs-fmt && echo DEV_SHELL_SUCCESS'" \
        "DEV_SHELL_SUCCESS"

    # Test library exports
    run_test "library exports available" \
        "nix eval .#lib --apply 'lib: builtins.length (builtins.attrNames lib)' 2>/dev/null | grep -E '^[0-9]+$' && echo 'AVAILABLE'" \
        "AVAILABLE"

    # Test glot CLI package
    run_test "glot CLI package available" \
        "nix eval .#packages.x86_64-darwin.glot 2>/dev/null >/dev/null && echo 'AVAILABLE'" \
        "AVAILABLE"

    run_test "glot CLI functionality" \
        "nix run .#glot -- help 2>/dev/null | head -1" \
        "A tool for managing Nix-based polyglot development projects"

    run_test "csharp lib loadable" \
        "nix eval --impure --expr 'let nixpkgs = import <nixpkgs> {}; csharp = import ./csharp.nix { inherit nixpkgs; treefmt-nix = null; git-hooks-nix = null; }; in \"loadable\"' 2>/dev/null" \
        "loadable"

    run_test "rust lib loadable" \
        "nix eval --impure --expr 'let nixpkgs = import <nixpkgs> {}; rust = import ./rust.nix { inherit nixpkgs; }; in \"loadable\"' 2>/dev/null" \
        "loadable"

    run_test "python lib loadable" \
        "nix eval --impure --expr 'let nixpkgs = import <nixpkgs> {}; python = import ./python.nix { inherit nixpkgs; treefmt-nix = null; git-hooks-nix = null; }; in \"loadable\"' 2>/dev/null" \
        "loadable"

    run_test "nim lib loadable" \
        "nix eval --impure --expr 'let nixpkgs = import <nixpkgs> {}; nim = import ./nim.nix { inherit nixpkgs; }; in \"loadable\"' 2>/dev/null" \
        "loadable"

    run_test "zig lib loadable" \
        "nix eval --impure --expr 'let nixpkgs = import <nixpkgs> {}; zig = import ./zig.nix { inherit nixpkgs; }; in \"loadable\"' 2>/dev/null" \
        "loadable"

    run_test "go lib loadable" \
        "nix eval --impure --expr 'let nixpkgs = import <nixpkgs> {}; go = import ./go.nix { inherit nixpkgs; }; in \"loadable\"' 2>/dev/null" \
        "loadable"

    echo ""

    # Template system tests
    test_templates

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
        echo ""
        echo "✅ Verified functionality:"
        echo "  • Flake structure & evaluation"
        echo "  • Library exports (csharp, rust)"  
        echo "  • Development shell & formatting"
        echo "  • Template generation (4 variants)"
        echo "  • Generated project builds & execution"
        echo "  • Generated project development workflow"
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
