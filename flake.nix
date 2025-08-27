{
  description = "Polyglot Nix helpers for various programming languages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
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
                # Add custom C# formatter
                dotnet-format = {
                  command = "${pkgs.dotnetCorePackages.sdk_8_0}/bin/dotnet";
                  options = [
                    "format"
                    "--include"
                  ];
                  includes = [
                    "*.cs"
                    "*.vb"
                    "*.fs"
                  ];
                };
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
        in
        {
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

          # Checks
          checks = {
            pre-commit-check = git-hooks;
          };
        }
      )
    // {
      # Expose language helpers globally (not per-system)
      lib = {
        csharp = import ./csharp.nix { inherit nixpkgs treefmt-nix git-hooks-nix; };
        rust = import ./rust.nix { inherit nixpkgs; };

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

        # Expose treefmt-nix and git-hooks-nix for language modules
        inherit treefmt-nix git-hooks-nix;
      };
    };
}
