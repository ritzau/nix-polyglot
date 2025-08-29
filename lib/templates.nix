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
  # C# templates
  csharp-console = mkTemplateFromDir ../templates/csharp/console;

  # Rust templates  
  rust-cli = mkTemplateFromDir ../templates/rust/cli;

  # Python templates
  python-console = mkTemplateFromDir ../templates/python/console;

  # Legacy aliases for backward compatibility
  csharp = mkTemplateFromDir ../templates/csharp/console;
  rust = mkTemplateFromDir ../templates/rust/cli;
  python = mkTemplateFromDir ../templates/python/console;

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
      echo "Usage:"
      echo "  nix run nix-polyglot#new-csharp myproject"
      echo "  nix run nix-polyglot#new-rust myproject"
      echo "  nix run nix-polyglot#new-python myproject"
      echo "  nix run nix-polyglot#new-csharp-console myproject"
      echo "  nix run nix-polyglot#new-rust-cli myproject"
      echo "  nix run nix-polyglot#new-python-console myproject"
      echo ""
      echo "Each template includes:"
      echo "  • Complete flake.nix with nix-polyglot integration"
      echo "  • Modern justfile with maintenance-free commands"  
      echo "  • Pre-configured development environment"
      echo "  • Universal formatting and linting setup"
      echo "  • Git repository initialization"
      echo ""
      echo "📁 Templates are stored in templates/ directory for easy customization!"
    '';
  };
}
