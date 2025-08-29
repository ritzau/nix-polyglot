{
  description = "Rust project with nix-polyglot integration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-polyglot = {
      url = "github:your-org/nix-polyglot"; # Update this URL
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
          cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Update after first build
        };
      in
      # Use the complete project structure
      rustProject.defaultOutputs
    );
}
