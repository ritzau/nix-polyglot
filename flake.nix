{
  description = "Polyglot Nix helpers for various programming languages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , treefmt-nix
    , git-hooks-nix
    ,
    }:
    flake-utils.lib.eachDefaultSystem
      (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          # Import core script system
          scripts = import ./lib/scripts.nix { inherit pkgs; };

          # Import template system
          templates = import ./lib/templates.nix { inherit pkgs; };

          # Configure treefmt for universal formatting
          treefmt = treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.nix";
            programs = {
              nixpkgs-fmt.enable = true;
              prettier.enable = true;
            };
            settings = {
              formatter = {
                nixpkgs-fmt.excludes = [ "*.lock" ];
                prettier.excludes = [
                  "*.lock"
                  "deps.json"
                ];
                # Note: C# formatting is handled per-project in generated projects
                # No C# files exist in the main nix-polyglot repo
              };
            };
          };

          # Configure git hooks (pre-commit)
          git-hooks = git-hooks-nix.lib.${system}.run {
            src = ./.;
            hooks = {
              treefmt = {
                enable = true;
                package = treefmt.config.build.wrapper;
              };
              nixpkgs-fmt.enable = true;
              prettier = {
                enable = true;
                excludes = [
                  "deps\\.json"
                  ".*\\.lock$"
                ];
              };
            };
          };
          # Build glot CLI
          glot = pkgs.buildGoModule {
            pname = "glot";
            version = "1.2.0";
            src = ./src/glot;
            vendorHash = "sha256-3khKUpxdVjIRvmMWmEAUPArYgLzkaH2ObD1C9F7XwnQ=";
            buildInputs = [ pkgs.go_1_23 ];
            nativeBuildInputs = [ pkgs.go_1_23 ];
            meta = with pkgs.lib; {
              description = "Nix Polyglot Project Interface CLI";
              homepage = "https://github.com/ritzau/nix-polyglot";
              license = licenses.mit;
              platforms = platforms.unix;
            };
          };
        in
        {
          # Packages
          packages = {
            inherit glot;
            default = glot;
          };

          # Development shell for the nix-polyglot repo itself
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              nixpkgs-fmt
            ];
            shellHook = ''
              echo "Nix Polyglot Development Environment"
              ${git-hooks.shellHook}
            '';
          };

          # Formatter support
          formatter = treefmt.config.build.wrapper;

          # Apps for project setup and maintenance
          apps = {
            # Project creation templates (legacy aliases)
            new-csharp = {
              type = "app";
              program = "${templates.csharp}/bin/new-csharp-console-project";
              meta = {
                description = "Create a new C# console project with nix-polyglot";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            new-rust = {
              type = "app";
              program = "${templates.rust}/bin/new-rust-cli-project";
              meta = {
                description = "Create a new Rust CLI project with nix-polyglot";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            new-python = {
              type = "app";
              program = "${templates.python}/bin/new-python-console-project";
              meta = {
                description = "Create a new Python console project with nix-polyglot";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            new-nim = {
              type = "app";
              program = "${templates.nim}/bin/new-nim-cli-project";
              meta = {
                description = "Create a new Nim CLI project with nix-polyglot";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            new-zig = {
              type = "app";
              program = "${templates.zig}/bin/new-zig-cli-project";
              meta = {
                description = "Create a new Zig CLI project with nix-polyglot";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            new-go = {
              type = "app";
              program = "${templates.go}/bin/new-go-cli-project";
              meta = {
                description = "Create a new Go CLI project with nix-polyglot";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            new-cpp = {
              type = "app";
              program = "${templates.cpp}/bin/new-cpp-cli-project";
              meta = {
                description = "Create a new C++ CLI project with nix-polyglot";
                platforms = nixpkgs.lib.platforms.all;
              };
            };

            # Explicit template apps
            new-csharp-console = {
              type = "app";
              program = "${templates.csharp-console}/bin/new-csharp-console-project";
              meta = {
                description = "Create a new C# console application";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            new-rust-cli = {
              type = "app";
              program = "${templates.rust-cli}/bin/new-rust-cli-project";
              meta = {
                description = "Create a new Rust CLI application";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            new-python-console = {
              type = "app";
              program = "${templates.python-console}/bin/new-python-console-project";
              meta = {
                description = "Create a new Python console application";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            new-nim-cli = {
              type = "app";
              program = "${templates.nim-cli}/bin/new-nim-cli-project";
              meta = {
                description = "Create a new Nim CLI application";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            new-zig-cli = {
              type = "app";
              program = "${templates.zig-cli}/bin/new-zig-cli-project";
              meta = {
                description = "Create a new Zig CLI application";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            new-go-cli = {
              type = "app";
              program = "${templates.go-cli}/bin/new-go-cli-project";
              meta = {
                description = "Create a new Go CLI application";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            new-cpp-cli = {
              type = "app";
              program = "${templates.cpp-cli}/bin/new-cpp-cli-project";
              meta = {
                description = "Create a new C++ CLI application";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            templates = {
              type = "app";
              program = "${templates.listTemplates}/bin/list-nix-polyglot-templates";
              meta = {
                description = "List available project templates";
                platforms = nixpkgs.lib.platforms.all;
              };
            };

            # Project maintenance
            setup = {
              type = "app";
              program = "${scripts.setupScript}/bin/setup-nix-polyglot-project";
              meta = {
                description = "Set up a project to use modern nix-polyglot architecture";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            update-project = {
              type = "app";
              program = "${scripts.updateScript}/bin/update-nix-polyglot-project";
              meta = {
                description = "Update project to latest nix-polyglot functionality";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
            migrate = {
              type = "app";
              program = "${scripts.migrationScript}/bin/migrate-to-nix-polyglot";
              meta = {
                description = "Migrate legacy project to modern nix-polyglot";
                platforms = nixpkgs.lib.platforms.all;
              };
            };

            # Template formatting playbook
            format-templates = {
              type = "app";
              program = "${pkgs.writeShellScript "format-templates" ''
                exec ${./scripts/format-templates.sh} "$@"
              ''}";
              meta = {
                description = "Format all template files using their development environments";
                platforms = nixpkgs.lib.platforms.all;
              };
            };
          };

          # Checks
          checks = {
            pre-commit-check = git-hooks;
          };

          # Templates for nix flake new
          templates = {
            csharp-console = {
              path = ./templates/csharp/console;
              description = "C# console application with .NET SDK";
            };
            rust-cli = {
              path = ./templates/rust/cli;
              description = "Rust CLI application with Cargo";
            };
            python-console = {
              path = ./templates/python/console;
              description = "Python console application with testing";
            };
            nim-cli = {
              path = ./templates/nim/cli;
              description = "Nim CLI application with Nimble";
            };
            zig-cli = {
              path = ./templates/zig/cli;
              description = "Zig CLI application with native build";
            };
            go-cli = {
              path = ./templates/go/cli;
              description = "Go CLI application with Go modules";
            };
            cpp-cli = {
              path = ./templates/cpp/cpp-cli;
              description = "C++ CLI application with CMake";
            };
          };
        }
      )
    // {
      # Expose language helpers globally (not per-system)
      lib = {
        csharp = import ./csharp.nix { inherit nixpkgs treefmt-nix git-hooks-nix; };
        rust = import ./rust.nix { inherit nixpkgs; };
        python = import ./python.nix { inherit nixpkgs treefmt-nix git-hooks-nix; };
        nim = import ./nim.nix { inherit nixpkgs; };
        zig = import ./zig.nix { inherit nixpkgs; };
        go = import ./go.nix { inherit nixpkgs; };
        cpp = import ./cpp.nix { inherit nixpkgs treefmt-nix git-hooks-nix; };

        # Also expose standard tools and hooks for direct use
        standardTools =
          system:
          import ./lib/standard-tools.nix {
            pkgs = import nixpkgs { inherit system; };
          };
        buildHooks =
          system:
          import ./lib/build-hooks.nix {
            pkgs = import nixpkgs { inherit system; };
          };

        # Expose script system for projects to import
        scripts =
          system:
          import ./lib/scripts.nix {
            pkgs = import nixpkgs { inherit system; };
          };

        # Expose treefmt-nix and git-hooks-nix for language modules
        inherit treefmt-nix git-hooks-nix;
      };
    };
}
