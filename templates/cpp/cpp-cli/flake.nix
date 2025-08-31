{
  description = "C++ CLI application with nix-polyglot";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-polyglot.url = "github:ritzau/nix-polyglot";
  };

  outputs = { self, nixpkgs, flake-utils, nix-polyglot }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        cppProject = nix-polyglot.lib.cpp {
          pkgs = nixpkgs.legacyPackages.${system};
          inherit self system;
          projectName = "hello-cpp";
          buildTarget = "./CMakeLists.txt";

          # C++ configuration
          cppStandard = "17";
          compiler = "gcc"; # or "clang"
          enableTests = true;

          # Optional customizations:
          # extraBuildInputs = [ ];
          # extraNativeBuildInputs = [ ];
          # extraCmakeFlags = [ ];
          # extraDevTools = [ ];
        };
      in
      cppProject.defaultOutputs
    );
}
