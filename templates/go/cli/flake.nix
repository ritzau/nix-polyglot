{
  description = "Go CLI application built with nix-polyglot";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-polyglot.url = "github:your-org/nix-polyglot";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nix-polyglot, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        polyglot = nix-polyglot.lib.go
          {
            inherit nixpkgs;
          }
          {
            inherit pkgs self;
            projectName = "go-project";
            modulePath = "example.com/go-project";
          };
      in
      polyglot.defaultOutputs
    );
}
