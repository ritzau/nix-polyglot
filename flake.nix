{
  description = "Polyglot Nix helpers for various programming languages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        # Development shell for the nix-polyglot repo itself
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixpkgs-fmt
          ];
          shellHook = ''
            echo "Nix Polyglot Development Environment"
          '';
        };
      }) // {
        # Expose language helpers globally (not per-system)
        lib = {
          csharp = import ./csharp.nix { inherit nixpkgs; };
          rust = import ./rust.nix { inherit nixpkgs; };
          
          # Also expose standard tools and hooks for direct use
          standardTools = system: import ./lib/standard-tools.nix { 
            pkgs = import nixpkgs { inherit system; };
          };
          buildHooks = system: import ./lib/build-hooks.nix { 
            pkgs = import nixpkgs { inherit system; };
          };
        };
      };
}
