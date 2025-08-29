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
    rm -rf result result-* __pycache__ .pytest_cache .mypy_cache .coverage

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