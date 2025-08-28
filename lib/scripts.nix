# Core Script System Templates
# Provides maintenance-free scripts as flake outputs that projects can reference
# Updates propagate automatically via `nix flake update`

{ pkgs, lib ? pkgs.lib }:

let
  # Helper to create a justfile command that delegates to nix
  mkNixCommand = { name, nixCommand, description, emoji ? "" }:
    ''
      # ${description}
      ${name}:
          @echo "${emoji} ${description}..."
          ${nixCommand}
    '';

  # Helper to create conditional commands based on project type
  mkConditionalCommand = { name, commands, description, emoji ? "" }:
    let
      commandChain = lib.concatStringsSep " || " (commands ++ [ "echo \"${description} not configured for this project\"" ]);
    in
    ''
      # ${description}
      ${name}:
          @echo "${emoji} ${description}..."
          @${commandChain}
    '';

in
rec {
  # Core justfile template that uses nix commands instead of fallbacks  
  modernJustfile = pkgs.writeText "modern-justfile" ''
    # Modern Nix-Polyglot Justfile
    # This file delegates to nix commands - updates automatically with flake updates
    # No manual maintenance required - core functionality comes from nix-polyglot

    # Default recipe - shows available commands
    default:
        @just --list

    ${mkNixCommand {
      name = "dev";
      nixCommand = "nix develop";
      description = "Start development environment";
      emoji = "🚀";
    }}

    ${mkNixCommand {
      name = "build";
      nixCommand = "nix build";
      description = "Build project";
      emoji = "🔨";
    }}

    ${mkNixCommand {
      name = "run";
      nixCommand = "nix run";
      description = "Run project";
      emoji = "▶️";
    }}

    ${mkNixCommand {
      name = "release";
      nixCommand = "nix run .#release";
      description = "Run release version";
      emoji = "🎯";
    }}

    ${mkNixCommand {
      name = "test";
      nixCommand = "nix flake check";
      description = "Run all tests and checks";
      emoji = "🧪";
    }}

    ${mkNixCommand {
      name = "fmt";
      nixCommand = "nix fmt";
      description = "Format all code (universal formatter)";
      emoji = "🎨";
    }}

    ${mkNixCommand {
      name = "fmt-check";
      nixCommand = "nix fmt -- --fail-on-change";
      description = "Check formatting without changes";
      emoji = "🔍";
    }}

    ${mkNixCommand {
      name = "lint";
      nixCommand = "nix run .#lint";
      description = "Run linting checks";
      emoji = "🔍";
    }}

    ${mkNixCommand {
      name = "check-format";
      nixCommand = "nix run .#check-format";
      description = "Verify code formatting";
      emoji = "✅";
    }}

    # Comprehensive check - build + test + lint + format
    check: build test lint fmt-check
        @echo "✅ All checks passed!"

    ${mkNixCommand {
      name = "clean";
      nixCommand = "nix-collect-garbage && rm -rf result result-*";
      description = "Clean build artifacts";
      emoji = "🧹";
    }}

    ${mkNixCommand {
      name = "update";
      nixCommand = "nix flake update";
      description = "Update all dependencies";
      emoji = "📦";
    }}

    ${mkNixCommand {
      name = "info";
      nixCommand = "nix flake show";
      description = "Show project information";
      emoji = "📋";
    }}

    # Legacy commands that still work but are deprecated
    ${mkConditionalCommand {
      name = "docs";
      commands = [ 
        "nix run .#docs 2>/dev/null"
        "nix develop --command bash -c 'cargo doc || dotnet build --configuration Release'"
      ];
      description = "Generate documentation";
      emoji = "📚";
    }}

    ${mkConditionalCommand {
      name = "watch";
      commands = [
        "nix run .#watch 2>/dev/null"
        "nix develop --command bash -c 'cargo watch -x build || dotnet watch run'"
      ];
      description = "Watch for changes and rebuild";
      emoji = "👀";
    }}

    ${mkConditionalCommand {
      name = "bench";
      commands = [
        "nix run .#bench 2>/dev/null"
        "nix develop --command bash -c 'cargo bench || dotnet run --configuration Release'"
      ];
      description = "Run benchmarks";
      emoji = "⚡";
    }}

    ${mkConditionalCommand {
      name = "security";
      commands = [
        "nix run .#security 2>/dev/null"
        "nix develop --command bash -c 'cargo audit || npm audit'"
      ];
      description = "Run security checks";
      emoji = "🔒";
    }}
  '';

  # Setup script that configures a project to use modern nix-polyglot architecture
  setupScript = pkgs.writeShellApplication {
    name = "setup-nix-polyglot-project";
    text = ''
      set -euo pipefail
      
      echo "🚀 Setting up nix-polyglot project..."
      
      # Check if we're in a project directory
      if [[ ! -f flake.nix ]]; then
        echo "❌ No flake.nix found. Please run this from a nix-polyglot project directory."
        exit 1
      fi
      
      # Backup existing justfile if it exists
      if [[ -f justfile ]]; then
        echo "📋 Backing up existing justfile to justfile.backup..."
        cp justfile justfile.backup
      fi
      
      # Install modern justfile
      echo "📝 Installing modern justfile..."
      cp ${modernJustfile} justfile
      
      echo "🎣 Configuring git hooks..."
      # Git hooks are configured automatically via nix develop
      if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "✅ Git repository detected - pre-commit hooks will be active in 'nix develop'"
      else
        echo "⚠️  No git repository - initialize with 'git init' to enable pre-commit hooks"
      fi
      
      echo ""
      echo "✅ Setup complete!"
      echo ""
      echo "📋 Next steps:"
      echo "  1. Try: just dev          # Enter development shell"
      echo "  2. Try: just build        # Build your project"
      echo "  3. Try: just fmt          # Format all code"
      echo "  4. Try: just test         # Run tests and checks"
      echo ""
      echo "🔄 Your project now uses maintenance-free commands from nix-polyglot."
      echo "   Commands update automatically when you run 'nix flake update'."
    '';
  };

  # Maintenance script for updating projects
  updateScript = pkgs.writeShellApplication {
    name = "update-nix-polyglot-project";
    text = ''
      set -euo pipefail
      
      echo "📦 Updating nix-polyglot project..."
      
      # Update flake inputs
      echo "🔄 Updating flake inputs..."
      nix flake update
      
      # Update justfile if using old template
      if [[ -f justfile ]] && grep -q "fallback chains" justfile 2>/dev/null; then
        echo "📝 Updating justfile to modern version..."
        if [[ -f justfile.backup ]]; then
          mv justfile justfile.old
        else
          cp justfile justfile.backup
        fi
        cp ${modernJustfile} justfile
        echo "✅ Justfile updated to modern version"
      fi
      
      # Run checks to verify everything works
      echo "🧪 Running checks..."
      nix flake check
      
      echo ""
      echo "✅ Update complete!"
      echo "📋 Your project is now using the latest nix-polyglot functionality."
    '';
  };

  # Migration script for converting legacy projects
  migrationScript = pkgs.writeShellApplication {
    name = "migrate-to-nix-polyglot";
    text = ''
      set -euo pipefail
      
      echo "🔄 Migrating project to modern nix-polyglot architecture..."
      
      # Detect old patterns
      if [[ -f justfile ]] && grep -q "cargo test || dotnet test" justfile; then
        echo "📋 Detected legacy fallback chains in justfile"
        echo "🔄 Converting to modern nix-based commands..."
        
        # Backup old justfile
        cp justfile justfile.legacy-backup
        
        # Install modern justfile
        cp ${modernJustfile} justfile
        
        echo "✅ Justfile migrated to modern version"
      fi
      
      # Check flake.nix for old patterns
      if [[ -f flake.nix ]] && ! grep -q "nix-polyglot" flake.nix; then
        echo "⚠️  flake.nix doesn't reference nix-polyglot - manual migration needed"
        echo "   Please update your flake.nix to use nix-polyglot as input"
      fi
      
      echo ""
      echo "✅ Migration complete!"
      echo "📋 Benefits of the new architecture:"
      echo "   • No more fallback chains to maintain"
      echo "   • Commands update automatically via 'nix flake update'"
      echo "   • Universal formatting with 'nix fmt'"
      echo "   • Integrated pre-commit hooks"
      echo ""
      echo "🧪 Testing migration..."
      nix flake check
      echo "✅ Migration successful!"
    '';
  };

  # Project template files that can be imported
  templates = {
    # Modern .editorconfig for consistent formatting
    editorconfig = pkgs.writeText "editorconfig-template" ''
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

      [*.{rs,toml}]
      indent_size = 4

      [*.{py,pyi}]
      indent_size = 4

      [*.{js,ts,jsx,tsx,json,html,css,scss,yaml,yml}]
      indent_size = 2

      [*.go]
      indent_style = tab

      [*.md]
      trim_trailing_whitespace = false

      [Makefile]
      indent_style = tab

      [*.{bat,cmd}]
      end_of_line = crlf
    '';

    # Basic gitignore template
    gitignore = pkgs.writeText "gitignore-template" ''
      # Nix
      result
      result-*

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

    # VS Code settings for optimal nix-polyglot experience
    vscodeSettings = pkgs.writeText "vscode-settings-template" ''
      {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
          "source.fixAll": true
        },
        "files.watcherExclude": {
          "**/result/**": true,
          "**/result-*/**": true,
          "**/nix/store/**": true
        },
        "search.exclude": {
          "**/result/**": true,
          "**/result-*/**": true
        },
        "[nix]": {
          "editor.defaultFormatter": "jnoortheen.nix-ide"
        },
        "nix.enableLanguageServer": true
      }
    '';
  };
}
