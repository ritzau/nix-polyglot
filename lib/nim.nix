# Nim language support for nix-polyglot
{ pkgs, lib, self }:
{
  # Create a Nim project with standard nix-polyglot structure
  inherit pkgs lib self;

  packages = {
    default = pkgs.buildNimPackage {
      pname = "nim-polyglot";
      version = "0.1.0";

      src = ./.;

      # Standard Nim build configuration
      nimRelease = false; # Development build by default
      nimDefines = [ ];
      nimFlags = [ ];
      nimDoc = false;

      # Lockfile will be generated when template is created
      lockFile = null; # Will be generated with nim_lk

      meta = with lib; {
        description = "Nim project created with nix-polyglot";
        license = licenses.mit;
        platforms = platforms.all;
      };
    };

    release = pkgs.buildNimPackage {
      pname = "nim-polyglot";
      version = "0.1.0";

      src = ./.;

      # Release build configuration
      nimRelease = true;
      nimDefines = [ "release" ];
      nimFlags = [ "-d:release" "--opt:speed" ];
      nimDoc = false;

      # Lockfile will be generated when template is created
      lockFile = null; # Will be generated with nim_lk

      meta = with lib; {
        description = "Nim project created with nix-polyglot (release)";
        license = licenses.mit;
        platforms = platforms.all;
      };
    };

    glot = self.packages.${pkgs.system}.glot;
  };

  devShells.default = pkgs.mkShell {
    packages = with pkgs; [
      # Nim toolchain
      nim
      nimble

      # Development tools
      self.packages.${pkgs.system}.glot

      # Common development utilities
      git
      direnv

      # Debugging and profiling
      gdb
      valgrind
    ];

    shellHook = ''
      echo "🎯 Nim Development Environment"
      echo ""
      echo "Nim version: $(nim --version | head -n 1)"
      echo "Available commands:"
      echo "  glot build    - Build Nim project"
      echo "  glot run      - Run Nim project" 
      echo "  glot test     - Run tests"
      echo "  glot fmt      - Format Nim code"
      echo "  glot lint     - Run Nim checks"
      echo ""
      echo "Nim tools:"
      echo "  nim c <file>  - Compile Nim file"
      echo "  nimble build  - Build with Nimble"
      echo "  nimble test   - Run Nimble tests"
      echo ""
    '';
  };

  # Language-specific commands for glot CLI integration
  commands = {
    build = "nim c";
    run = "nim c -r";
    test = "nimble test";
    fmt = "nimpretty";
    lint = "nim check";
    clean = "rm -rf nimcache";
  };

  # File patterns for Nim projects
  fileExtensions = [ ".nim" ".nims" ".cfg" ".nimble" ];
  projectFiles = [ "config.nims" "nim.cfg" "*.nimble" ];

  # Project detection logic
  detect = projectPath:
    let
      hasNimble = builtins.pathExists (projectPath + "/*.nimble");
      hasNimConfig = builtins.pathExists (projectPath + "/nim.cfg") ||
        builtins.pathExists (projectPath + "/config.nims");
      hasNimFiles = lib.filesystem.pathExists (projectPath + "/*.nim");
    in
    hasNimble || hasNimConfig || hasNimFiles;

  # Standard outputs that work with nix-polyglot patterns
  defaultOutputs = {
    inherit packages devShells;

    # Standard apps
    apps.default = {
      type = "app";
      program = "${packages.default}/bin/nim-polyglot";
    };

    apps.release = {
      type = "app";
      program = "${packages.release}/bin/nim-polyglot";
    };

    # Formatting
    formatter = pkgs.nixpkgs-fmt;
  };
}
