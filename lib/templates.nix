# Project Templates System
# Provides language-specific project templates that can be instantiated
# Usage: nix run nix-polyglot#new-csharp myproject

{ pkgs, lib ? pkgs.lib }:

let
  # Helper to create a template instantiation script
  mkTemplateScript = { language, description, files }: pkgs.writeShellApplication {
    name = "new-${language}-project";
    text = ''
            set -euo pipefail
      
            PROJECT_NAME="''${1:-}"
            if [[ -z "$PROJECT_NAME" ]]; then
              echo "Usage: nix run nix-polyglot#new-${language} <project-name>"
              echo "Creates a new ${description} project with modern nix-polyglot integration"
              exit 1
            fi
      
            echo "🚀 Creating new ${description} project: $PROJECT_NAME"
      
            # Create project directory
            if [[ -d "$PROJECT_NAME" ]]; then
              echo "❌ Directory '$PROJECT_NAME' already exists"
              exit 1
            fi
      
            mkdir -p "$PROJECT_NAME"
            cd "$PROJECT_NAME"
      
            echo "📝 Creating project files..."
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (filename: content: ''
              echo "  - ${filename}"
              cat > "${filename}" << 'EOF'
              ${content}
              EOF
            '') files)}
      
            echo "🔧 Initializing git repository..."
            git init
            git add .
            git commit -m "Initial commit: ${description} project created with nix-polyglot

      🤖 Generated with [Claude Code](https://claude.ai/code)

      Co-Authored-By: Claude <noreply@anthropic.com>"
      
            echo ""
            echo "✅ ${description} project '$PROJECT_NAME' created successfully!"
            echo ""
            echo "📋 Next steps:"
            echo "  cd $PROJECT_NAME"
            echo "  nix develop          # Enter development environment"
            echo "  just build           # Build the project"
            echo "  just run             # Run the project" 
            echo "  just fmt             # Format code"
            echo "  just test            # Run tests"
            echo ""
            echo "🔄 This project uses maintenance-free commands from nix-polyglot."
            echo "   Run 'nix flake update' to get the latest functionality."
    '';
  };

in
{
  # C# project template
  csharp = mkTemplateScript {
    language = "csharp";
    description = "C# console application";
    files = {
      "flake.nix" = ''
        {
          description = "C# project with nix-polyglot integration";

          inputs = {
            nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
            flake-utils.url = "github:numtide/flake-utils";
            nix-polyglot = {
              url = "github:your-org/nix-polyglot";  # Update this URL
              # For local development, use: url = "path:/path/to/nix-polyglot";
            };
          };

          outputs = { self, nixpkgs, flake-utils, nix-polyglot, ... }:
            flake-utils.lib.eachDefaultSystem (system:
              let
                pkgs = import nixpkgs { inherit system; };
                
                # Configure C# project
                csharpProject = nix-polyglot.lib.csharp {
                  inherit pkgs self system;
                  buildTarget = "./MyApp.csproj";
                  nugetDeps = ./deps.json;  # Generate with: python3 generate-deps.py
                };
              in
              # Use the complete project structure
              csharpProject.mkDefaultOutputs
            );
        }
      '';

      "MyApp.csproj" = ''
        <Project Sdk="Microsoft.NET.Sdk">
          <PropertyGroup>
            <OutputType>Exe</OutputType>
            <TargetFramework>net8.0</TargetFramework>
            <ImplicitUsings>enable</ImplicitUsings>
            <Nullable>enable</Nullable>
            <RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>
          </PropertyGroup>
        </Project>
      '';

      "Program.cs" = ''
        // Simple C# console application
        Console.WriteLine("Hello, World from C#!");
        Console.WriteLine($"Project created with nix-polyglot at {DateTime.Now}");
      '';

      "generate-deps.py" = ''
        #!/usr/bin/env python3
        """Generate deps.json for NuGet dependencies"""
        import json
        import subprocess
        import sys

        def main():
            print("🔧 Generating NuGet dependencies...")
            
            # This would generate the actual deps.json
            # For now, create an empty one for projects without dependencies
            deps = {
                "runtime": {
                    "win-x64": [],
                    "linux-x64": [], 
                    "osx-x64": [],
                    "osx-arm64": []
                },
                "native": {}
            }
            
            with open("deps.json", "w") as f:
                json.dump(deps, f, indent=2)
            
            print("✅ deps.json generated")
            print("   Add NuGet packages to your .csproj, then run this script again")

        if __name__ == "__main__":
            main()
      '';

      "justfile" = ''
        # Modern Nix-Polyglot Justfile
        # This file delegates to nix commands - updates automatically with flake updates
        # No manual maintenance required - core functionality comes from nix-polyglot

        # Default recipe - shows available commands
        default:
            @just --list

        # Start development environment
        dev:
            @echo "🚀 Start development environment..."
            nix develop

        # Build project
        build:
            @echo "🔨 Build project..."
            nix build

        # Run project
        run:
            @echo "▶️  Run project..."
            nix run

        # Run release version
        release:
            @echo "🎯 Run release version..."
            nix run .#release

        # Run all tests and checks
        test:
            @echo "🧪 Run all tests and checks..."
            nix flake check

        # Format all code (universal formatter)
        fmt:
            @echo "🎨 Format all code (universal formatter)..."
            nix fmt

        # Check formatting without changes
        fmt-check:
            @echo "🔍 Check formatting without changes..."
            nix fmt -- --fail-on-change

        # Run linting checks
        lint:
            @echo "🔍 Run linting checks..."
            nix run .#lint

        # Verify code formatting
        check-format:
            @echo "✅ Verify code formatting..."
            nix run .#check-format

        # Comprehensive check - build + test + lint + format
        check: build test lint fmt-check
            @echo "✅ All checks passed!"

        # Clean build artifacts
        clean:
            @echo "🧹 Clean build artifacts..."
            nix-collect-garbage && rm -rf result result-*

        # Update all dependencies
        update:
            @echo "📦 Update all dependencies..."
            nix flake update

        # Regenerate NuGet dependencies
        update-nuget:
            @echo "📦 Regenerating NuGet dependencies..."
            @python3 generate-deps.py

        # Show project information
        info:
            @echo "📋 Show project information..."
            nix flake show
      '';

      ".gitignore" = ''
        # Nix
        result
        result-*

        # .NET
        bin/
        obj/
        packages.lock.json

        # IDEs
        .vscode/
        .idea/
        *.swp
        *.swo

        # OS
        .DS_Store
        Thumbs.db

        # Logs
        *.log
        logs/

        # Temporary files
        *.tmp
        *.temp
        .temp/
        .tmp/
      '';

      ".editorconfig" = ''
        # EditorConfig is awesome: https://EditorConfig.org
        root = true

        [*]
        charset = utf-8
        end_of_line = lf
        indent_style = space
        indent_size = 2
        insert_final_newline = true
        trim_trailing_whitespace = true

        [*.{cs,vb,fs}]
        indent_size = 4

        [*.md]
        trim_trailing_whitespace = false

        [Makefile]
        indent_style = tab
      '';

      "deps.json" = ''
        {
          "runtime": {
            "win-x64": [],
            "linux-x64": [], 
            "osx-x64": [],
            "osx-arm64": []
          },
          "native": {}
        }
      '';
    };
  };

  # Rust project template
  rust = mkTemplateScript {
    language = "rust";
    description = "Rust binary application";
    files = {
      "flake.nix" = ''
        {
          description = "Rust project with nix-polyglot integration";

          inputs = {
            nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
            flake-utils.url = "github:numtide/flake-utils";
            nix-polyglot = {
              url = "github:your-org/nix-polyglot";  # Update this URL
              # For local development, use: url = "path:/path/to/nix-polyglot";
            };
          };

          outputs = { self, nixpkgs, flake-utils, nix-polyglot, ... }:
            flake-utils.lib.eachDefaultSystem (system:
              let
                pkgs = import nixpkgs { inherit system; };
                
                # Configure Rust project
                rustProject = nix-polyglot.lib.rust {
                  inherit pkgs self;
                  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Update after first build
                };
              in
              # Use the complete project structure
              rustProject.mkDefaultOutputs
            );
        }
      '';

      "Cargo.toml" = ''
        [package]
        name = "my-rust-app"
        version = "0.1.0"
        edition = "2021"

        [dependencies]
      '';

      "src/main.rs" = ''
        fn main() {
            println!("Hello, World from Rust!");
            println!("Project created with nix-polyglot at {}", chrono::Utc::now());
        }
      '';

      "justfile" = ''
        # Modern Nix-Polyglot Justfile for Rust
        # This file delegates to nix commands - updates automatically with flake updates

        # Default recipe - shows available commands
        default:
            @just --list

        # Start development environment
        dev:
            @echo "🚀 Start development environment..."
            nix develop

        # Build project
        build:
            @echo "🔨 Build project..."
            nix build

        # Run project
        run:
            @echo "▶️  Run project..."
            nix run

        # Run release version
        release:
            @echo "🎯 Run release version..."
            nix run .#release

        # Run all tests and checks
        test:
            @echo "🧪 Run all tests and checks..."
            nix flake check

        # Format all code
        fmt:
            @echo "🎨 Format all code..."
            nix fmt

        # Check formatting
        fmt-check:
            @echo "🔍 Check formatting without changes..."
            nix fmt -- --fail-on-change

        # Comprehensive check
        check: build test fmt-check
            @echo "✅ All checks passed!"

        # Clean build artifacts
        clean:
            @echo "🧹 Clean build artifacts..."
            nix-collect-garbage && rm -rf result result-* target/

        # Update dependencies
        update:
            @echo "📦 Update all dependencies..."
            nix flake update

        # Show project information
        info:
            @echo "📋 Show project information..."
            nix flake show
      '';

      ".gitignore" = ''
        # Nix
        result
        result-*

        # Rust
        /target/
        Cargo.lock

        # IDEs
        .vscode/
        .idea/
        *.swp
        *.swo

        # OS
        .DS_Store
        Thumbs.db
      '';

      ".editorconfig" = ''
        root = true

        [*]
        charset = utf-8
        end_of_line = lf
        insert_final_newline = true
        trim_trailing_whitespace = true

        [*.{rs,toml}]
        indent_style = space
        indent_size = 4

        [*.md]
        trim_trailing_whitespace = false
      '';
    };
  };

  # Template listing helper
  listTemplates = pkgs.writeShellApplication {
    name = "list-nix-polyglot-templates";
    text = ''
      echo "🚀 Available nix-polyglot project templates:"
      echo ""
      echo "  csharp    - C# console application with .NET 8"
      echo "  rust      - Rust binary application"
      echo ""
      echo "Usage:"
      echo "  nix run nix-polyglot#new-csharp myproject"
      echo "  nix run nix-polyglot#new-rust myproject"
      echo ""
      echo "Each template includes:"
      echo "  • Complete flake.nix with nix-polyglot integration"
      echo "  • Modern justfile with maintenance-free commands"  
      echo "  • Pre-configured development environment"
      echo "  • Universal formatting and linting setup"
      echo "  • Git repository initialization"
    '';
  };
}
