#!/usr/bin/env bash
# Template Formatting Playbook
# This script formats all template files using their respective development environments
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATES_DIR="${REPO_ROOT}/templates"

echo "🎨 Template Formatting Playbook"
echo "==============================="
echo "This script formats template files using their native development environments"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

format_template() {
    local template_path="$1"
    local template_name="$(basename "$(dirname "$template_path")")/$(basename "$template_path")"
    
    echo -e "${BLUE}📁 Processing template: ${template_name}${NC}"
    
    # Create temporary directory for testing
    local temp_dir=$(mktemp -d)
    local test_project="${temp_dir}/test-format-project"
    
    trap "rm -rf ${temp_dir}" EXIT
    
    # Generate project from template
    echo "   📋 Generating test project..."
    if ! nix run "${REPO_ROOT}#new-$(basename "$(dirname "$template_path")")-$(basename "$template_path")" "$test_project" &>/dev/null; then
        echo -e "   ${RED}❌ Failed to generate project${NC}"
        return 1
    fi
    
    # Update flake to use local nix-polyglot for development
    sed -i '' 's|github:your-org/nix-polyglot|path:'"$REPO_ROOT"'|g' "$test_project/flake.nix"
    
    cd "$test_project"
    
    # Enter nix develop and run formatting
    echo "   🔧 Entering development environment and formatting..."
    if nix develop --command bash -c "
        set -e
        echo '   📝 Running formatter...'
        if command -v glot >/dev/null 2>&1; then
            if glot fmt 2>/dev/null; then
                echo '   ✅ Formatting completed with glot fmt'
            else
                echo '   ⚠️  glot fmt failed, trying nix fmt...'
                nix fmt 2>/dev/null || echo '   ⚠️  nix fmt not available'
            fi
        elif command -v just >/dev/null 2>&1; then
            if just fmt 2>/dev/null; then
                echo '   ✅ Formatting completed with just fmt'
            else
                echo '   ⚠️  just fmt failed, trying nix fmt...'
                nix fmt 2>/dev/null || echo '   ⚠️  nix fmt not available'
            fi
        else
            echo '   📝 Using nix fmt directly...'
            nix fmt 2>/dev/null || echo '   ⚠️  nix fmt not available'
        fi
    "; then
        echo -e "   ${GREEN}✅ Template formatting successful${NC}"
        
        # Copy formatted files back to template
        echo "   📤 Copying formatted files back to template..."
        
        # Language-specific file copying
        case "$(basename "$(dirname "$template_path")")" in
            "csharp")
                if [[ -f "Program.cs" ]]; then
                    cp "Program.cs" "$template_path/"
                fi
                if [[ -f "MyApp.csproj" ]]; then
                    cp "MyApp.csproj" "$template_path/"
                fi
                ;;
            "rust")
                if [[ -f "src/main.rs" ]]; then
                    cp "src/main.rs" "$template_path/src/"
                fi
                if [[ -f "Cargo.toml" ]]; then
                    cp "Cargo.toml" "$template_path/"
                fi
                ;;
        esac
        
        # Copy common files
        for file in justfile flake.nix .editorconfig; do
            if [[ -f "$file" ]]; then
                cp "$file" "$template_path/"
            fi
        done
        
    else
        echo -e "   ${YELLOW}⚠️  Formatting had issues but continuing${NC}"
    fi
    
    cd "$REPO_ROOT"
}

# Main execution
main() {
    if [[ ! -d "$TEMPLATES_DIR" ]]; then
        echo -e "${RED}❌ Templates directory not found: $TEMPLATES_DIR${NC}"
        exit 1
    fi
    
    echo "🔍 Discovering templates..."
    local template_count=0
    
    # Find all template directories (containing template.nix)
    while IFS= read -r -d '' template_file; do
        template_dir="$(dirname "$template_file")"
        echo "   Found: $(basename "$(dirname "$template_dir")")/$(basename "$template_dir")"
        ((template_count++))
    done < <(find "$TEMPLATES_DIR" -name "template.nix" -print0)
    
    echo -e "${BLUE}📊 Found $template_count templates${NC}"
    echo ""
    
    # Ask for confirmation
    read -p "🤔 Do you want to format all templates? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "👋 Aborted by user"
        exit 0
    fi
    
    echo ""
    echo "🚀 Starting template formatting..."
    echo ""
    
    local success_count=0
    local total_count=0
    
    # Process each template
    while IFS= read -r -d '' template_file; do
        template_dir="$(dirname "$template_file")"
        ((total_count++))
        
        if format_template "$template_dir"; then
            ((success_count++))
        fi
        echo ""
    done < <(find "$TEMPLATES_DIR" -name "template.nix" -print0)
    
    # Summary
    echo "========================================="
    echo -e "${BLUE}📊 Formatting Summary${NC}"
    echo "   Total templates: $total_count"
    echo -e "   ${GREEN}Successfully formatted: $success_count${NC}"
    if (( success_count < total_count )); then
        echo -e "   ${YELLOW}Had issues: $((total_count - success_count))${NC}"
    fi
    
    if (( success_count > 0 )); then
        echo ""
        echo -e "${YELLOW}📝 Remember to commit the formatted template changes!${NC}"
        echo "   git add templates/"
        echo "   git commit -m \"Format template files using development environments\""
    fi
    
    echo ""
    echo -e "${GREEN}✅ Template formatting playbook completed!${NC}"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi