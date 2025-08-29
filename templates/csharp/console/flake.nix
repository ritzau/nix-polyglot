{
  description = "C# project with nix-polyglot integration";

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

        # Configure C# project
        csharpProject = nix-polyglot.lib.csharp {
          inherit pkgs self system;
          buildTarget = "./MyApp.csproj";
          nugetDeps = null; # No external dependencies for console app
        };
      in
      # Use the complete project structure
      csharpProject.defaultOutputs
    );
}
