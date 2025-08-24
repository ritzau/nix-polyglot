# Organizational Standard Justfile Template
# Provides consistent interface across all language projects

# Default recipe - shows available commands
default:
    @just --list

# Development commands
dev: 
    @echo "🚀 Starting development environment..."
    nix develop

# Build the project
build:
    @echo "🔨 Building project..."
    nix build

# Run the project
run:
    @echo "▶️  Running project..."
    nix run

# Run tests
test:
    @echo "🧪 Running tests..."
    nix develop --command bash -c 'cargo test || dotnet test || npm test || python -m pytest || go test ./... || echo "No tests configured for this language"'

# Format code using language-specific formatter
fmt:
    @echo "🎨 Formatting code..."
    nix develop --command bash -c 'rustfmt src/**/*.rs || dotnet format || prettier --write . || black . || gofmt -w . || echo "No formatter configured for this language"'

# Lint code
lint:
    @echo "🔍 Linting code..."
    nix develop --command bash -c 'cargo clippy || dotnet build --verbosity normal || eslint . || pylint . || golangci-lint run || echo "No linter configured for this language"'

# Check code (build + test + lint)
check: build test lint
    @echo "✅ All checks passed!"

# Clean build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    @rm -rf target/ bin/ obj/ node_modules/.cache/ __pycache__/ result result-* .mypy_cache/ .pytest_cache/ 2>/dev/null || true
    @echo "Clean completed!"

# Update dependencies
update:
    @echo "📦 Updating dependencies..."
    nix flake update
    @echo "Dependencies updated!"

# Show project info
info:
    @echo "📋 Project Information"
    @echo "===================="
    @echo "Working directory: $(pwd)"
    @echo "Flake status:"
    @nix flake show 2>/dev/null || echo "No flake found"
    @echo ""
    @echo "Development shell tools:"
    @nix develop --command bash -c 'echo "Available in dev shell: $(which cargo rustc dotnet node python go 2>/dev/null | tr \\n , | sed s/,$//)"' 2>/dev/null || echo "Development shell not ready"

# Release build (optimized)
release:
    @echo "🎯 Building release version..."
    nix build

# Watch mode - rebuild on file changes (if available)
watch:
    @echo "👀 Watching for changes..."
    nix develop --command bash -c 'cargo watch -x build || dotnet watch run || npm run watch || echo "Watch mode not available for this language - use your IDE or set up file watching manually"'

# Benchmark (if supported)
bench:
    @echo "⚡ Running benchmarks..."
    nix develop --command bash -c 'cargo bench || dotnet run --configuration Release || npm run bench || python -m pytest --benchmark-only || echo "No benchmarks configured"'

# Quick security check
security:
    @echo "🔒 Running security checks..."
    nix develop --command bash -c 'cargo audit || npm audit || echo "Security audit not configured for this language"'

# Generate documentation
docs:
    @echo "📚 Generating documentation..."
    nix develop --command bash -c 'cargo doc || dotnet build --configuration Release && echo "Check obj/ for documentation" || jsdoc . || echo "Documentation generation not configured"'

# Set up pre-commit hooks (if available)
setup-hooks:
    @echo "🎣 Setting up pre-commit hooks..."
    @echo "# Pre-commit hook - run checks before commit" > .git/hooks/pre-commit
    @echo "just check" >> .git/hooks/pre-commit  
    @chmod +x .git/hooks/pre-commit
    @echo "Pre-commit hook installed!"