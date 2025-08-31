# Project Templates System - Directory Based
# Templates are now stored in the templates/ directory for easy maintenance
# Usage: nix run nix-polyglot#new-csharp myproject

{ pkgs, lib ? pkgs.lib }:

let
  # Helper to create a template instantiation script from a template directory
  mkTemplateFromDir = templatePath:
    let
      templateConfig = import (templatePath + "/template.nix");
    in
    pkgs.writeShellApplication {
      name = "new-${templateConfig.name}-project";
      text = ''
                set -euo pipefail
        
                PROJECT_NAME="''${1:-}"
                if [[ -z "$PROJECT_NAME" ]]; then
                  echo "Usage: nix run nix-polyglot#new-${templateConfig.language} <project-name>"
                  echo "Creates a new ${templateConfig.description} project with modern nix-polyglot integration"
                  exit 1
                fi
        
                echo "🚀 Creating new ${templateConfig.description} project: $PROJECT_NAME"
        
                # Create project directory
                if [[ -d "$PROJECT_NAME" ]]; then
                  echo "❌ Directory '$PROJECT_NAME' already exists"
                  exit 1
                fi
        
                mkdir -p "$PROJECT_NAME"
                cd "$PROJECT_NAME"
        
                echo "📝 Creating project files..."
        
                # Copy each file from the template
                ${lib.concatStringsSep "\n" (lib.mapAttrsToList (filename: sourcePath: ''
                  echo "  - ${filename}"
                  mkdir -p "$(dirname "${filename}")"
                  cp "${sourcePath}" "${filename}"
                '') templateConfig.files)}
        
                echo "🔧 Initializing git repository..."
                git init
                git add .
                git commit -m "Initial commit: ${templateConfig.description} project created with nix-polyglot

        🤖 Generated with [Claude Code](https://claude.ai/code)

        Co-Authored-By: Claude <noreply@anthropic.com>"
        
                echo ""
                echo "✅ ${templateConfig.description} project '$PROJECT_NAME' created successfully!"
                echo ""
                echo "📋 Next steps:"
                echo "  cd $PROJECT_NAME"
                echo "  direnv allow         # Allow .envrc (sets up glot CLI)"
                echo "  glot build           # Build the project"
                echo "  glot run             # Run the project" 
                echo "  glot fmt             # Format code"
                echo "  glot test            # Run tests"
                echo ""
                echo "🔄 This project uses maintenance-free commands from nix-polyglot."
                echo "   Run 'nix flake update' to get the latest functionality."
      '';
    };

in
{
  # C# templates
  csharp-console = mkTemplateFromDir ../templates/csharp/console;

  # Rust templates  
  rust-cli = mkTemplateFromDir ../templates/rust/cli;

  # Python templates
  python-console = mkTemplateFromDir ../templates/python/console;

  # Nim templates
  nim-cli = mkTemplateFromDir ../templates/nim/cli;

  # Zig templates
  zig-cli = mkTemplateFromDir ../templates/zig/cli;

  # Go templates
  go-cli = mkTemplateFromDir ../templates/go/cli;

  # C++ templates  
  cpp-cli = mkTemplateFromDir ../templates/cpp/cpp-cli;

  # Legacy aliases for backward compatibility
  csharp = mkTemplateFromDir ../templates/csharp/console;
  rust = mkTemplateFromDir ../templates/rust/cli;
  python = mkTemplateFromDir ../templates/python/console;
  nim = mkTemplateFromDir ../templates/nim/cli;
  zig = mkTemplateFromDir ../templates/zig/cli;
  go = mkTemplateFromDir ../templates/go/cli;
  cpp = mkTemplateFromDir ../templates/cpp/cpp-cli;

  # Template listing helper
  listTemplates = pkgs.writeShellApplication {
    name = "list-nix-polyglot-templates";
    text = ''
      echo "🚀 Available nix-polyglot project templates:"
      echo ""
      echo "  C# Templates:"
      echo "    csharp         - C# console application with .NET 8"
      echo "    csharp-console - C# console application (explicit)"
      echo ""
      echo "  Rust Templates:"  
      echo "    rust           - Rust CLI application"
      echo "    rust-cli       - Rust CLI application (explicit)"
      echo ""
      echo "  Python Templates:"
      echo "    python         - Python console application with Poetry"
      echo "    python-console - Python console application (explicit)"
      echo ""
      echo "  Nim Templates:"
      echo "    nim            - Nim CLI application"
      echo "    nim-cli        - Nim CLI application (explicit)"
      echo ""
      echo "  Zig Templates:"
      echo "    zig            - Zig CLI application"
      echo "    zig-cli        - Zig CLI application (explicit)"
      echo ""
      echo "  Go Templates:"
      echo "    go             - Go CLI application"
      echo "    go-cli         - Go CLI application (explicit)"
      echo ""
      echo "  C++ Templates:"
      echo "    cpp            - C++ CLI application with CMake"
      echo "    cpp-cli        - C++ CLI application (explicit)"
      echo ""
      echo "Usage:"
      echo "  nix run nix-polyglot#new-csharp myproject"
      echo "  nix run nix-polyglot#new-rust myproject"
      echo "  nix run nix-polyglot#new-python myproject"
      echo "  nix run nix-polyglot#new-nim myproject"
      echo "  nix run nix-polyglot#new-zig myproject"
      echo "  nix run nix-polyglot#new-go myproject"
      echo "  nix run nix-polyglot#new-cpp myproject"
      echo "  nix run nix-polyglot#new-csharp-console myproject"
      echo "  nix run nix-polyglot#new-rust-cli myproject"
      echo "  nix run nix-polyglot#new-python-console myproject"
      echo "  nix run nix-polyglot#new-nim-cli myproject"
      echo "  nix run nix-polyglot#new-zig-cli myproject"
      echo "  nix run nix-polyglot#new-go-cli myproject"
      echo "  nix run nix-polyglot#new-cpp-cli myproject"
      echo ""
      echo "Each template includes:"
      echo "  • Complete flake.nix with nix-polyglot integration"
      echo "  • Smart .envrc with glot CLI caching"  
      echo "  • Pre-configured development environment"
      echo "  • Universal formatting and linting setup"
      echo "  • Git repository initialization"
      echo ""
      echo "📁 Templates are stored in templates/ directory for easy customization!"
    '';
  };
}
