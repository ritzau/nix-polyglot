{
  description = "Nim CLI Application via Nix-Polyglot";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-polyglot.url = "github:ritzau/nix-polyglot";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , nix-polyglot
    ,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        nimLib = nix-polyglot.lib.nim;

        project = nimLib {
          inherit pkgs self;
          binaryName = "nim-project";
        };

      in
      project.defaultOutputs // {
        # Add packages - merge with existing packages from defaultOutputs
        packages = project.defaultOutputs.packages // {
          glot = nix-polyglot.packages.${system}.glot;
        };
      }
    );
}
