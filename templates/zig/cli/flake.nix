{
  description = "Zig CLI application built with nix-polyglot";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-polyglot.url = "github:your-org/nix-polyglot";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nix-polyglot, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        polyglot = nix-polyglot.lib.zig
          {
            inherit nixpkgs;
          }
          {
            inherit pkgs self;
            projectName = "zig-project";
          };
      in
      polyglot.defaultOutputs
    );
}
