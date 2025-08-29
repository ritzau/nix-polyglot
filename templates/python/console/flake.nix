{
  description = "Python project with nix-polyglot integration";

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

        # Configure Python project
        pythonProject = nix-polyglot.lib.python {
          inherit pkgs self system;
          buildTarget = "./pyproject.toml";
          buildSystem = "poetry";
          mainModule = "myapp.main";
          enableTests = true;
          testRunner = "pytest";
        };
      in
      # Use the complete project structure
      pythonProject.mkDefaultOutputs
    );
}
