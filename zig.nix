{ nixpkgs }:

# Main function that creates Zig project outputs for a single system
{ pkgs
, # Pass pkgs directly - no magic!
  self
, # Required for dependency management
  extraBuildTools ? [ ]
, extraGeneralTools ? [ ]
, zig ? pkgs.zig
, # Build configuration - "debug" or "release"
  buildMode ? "Debug"
, # Project name override
  projectName ? null
,
}:

let
  # Import organizational standard tools and build hooks
  standardTools = import ./lib/standard-tools.nix { inherit pkgs; };
  buildHooks = import ./lib/build-hooks.nix { inherit pkgs; };

  # Use organizational standard tools
  generalTools = standardTools.generalTools;

  # Zig-specific build tools (in addition to standard tools)
  buildTools = [
    zig
  ]
  ++ standardTools.commonBuildTools;

  # Add Zig-specific development tools
  zigDevTools = with pkgs; [
    # Language server (if available)
    zls
    # Additional debugging tools
    gdb
    lldb
  ];

  # Combine with user extras
  allBuildTools = buildTools ++ zigDevTools ++ extraBuildTools;
  allGeneralTools = generalTools ++ extraGeneralTools;

  shellHook = ''
    echo "⚡ Zig Development Environment"
    echo ""
    echo "Zig version: $(zig version)"
    echo ""
    echo "Development commands:"
    echo "  zig build          - Build project"
    echo "  zig run            - Run project" 
    echo "  zig test           - Run tests"
    echo "  zig fmt            - Format source code"
    echo ""
    echo "Available tools:"
    ${pkgs.lib.concatStringsSep "\n" (map (tool: "echo \"  ${tool.pname or tool.name or "unknown"} - ${tool.meta.description or ""}\"") allBuildTools)}
    echo ""
  '';

  # Development shell with comprehensive Zig toolchain
  devShell = pkgs.mkShell {
    packages = allBuildTools ++ allGeneralTools ++ [
      # Add glot CLI from self
      self.packages.${pkgs.system}.glot
    ];
    inherit shellHook;
  };

  # Detect project name from build.zig
  detectProjectName = projectPath:
    let
      buildZigPath = projectPath + "/build.zig";
    in
    if builtins.pathExists buildZigPath
    then "zig-project" # Default name - could be enhanced to parse build.zig
    else "zig-project";

  # Actual project name to use
  actualProjectName =
    if projectName != null
    then projectName
    else detectProjectName ./.;

  # Base build arguments
  baseBuildArgs = {
    pname = actualProjectName;
    version = "0.1.0";
    src = ./.;

    nativeBuildInputs = [ zig ];

    # Zig build system integration
    configurePhase = ''
      runHook preConfigure
      # Zig build system doesn't need explicit configure
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      zig build -Doptimize=${buildMode}
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      # Copy the binary from zig-out/bin to $out/bin
      if [ -d zig-out/bin ]; then
        cp -r zig-out/bin/* $out/bin/
      fi
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Zig project built with nix-polyglot";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };

  # Development build - fast compilation, debug info
  devBuild = pkgs.stdenv.mkDerivation (baseBuildArgs // {
    pname = "${actualProjectName}-dev";
    # Use Debug mode for development builds
    buildMode = "Debug";
  });

  # Release build - optimized
  releaseBuild = pkgs.stdenv.mkDerivation (baseBuildArgs // {
    pname = "${actualProjectName}-release";
    # Use ReleaseFast for release builds
    buildMode = "ReleaseFast";
  });

in
{
  # Standard nix-polyglot outputs
  defaultOutputs = {
    packages = {
      default = devBuild;
      dev = devBuild;
      release = releaseBuild;

      # Also expose glot CLI
      glot = self.packages.${pkgs.system}.glot;
    };

    devShells = {
      default = devShell;
    };

    # Apps for running the built programs
    apps = {
      default = {
        type = "app";
        program = "${devBuild}/bin/${actualProjectName}";
      };

      dev = {
        type = "app";
        program = "${devBuild}/bin/${actualProjectName}";
      };

      release = {
        type = "app";
        program = "${releaseBuild}/bin/${actualProjectName}";
      };
    };

    # Use system formatter for Nix files
    formatter = pkgs.nixpkgs-fmt;
  };

  # Language-specific information for glot CLI
  languageInfo = {
    name = "zig";
    extensions = [ ".zig" ];
    projectFiles = [ "build.zig" "build.zig.zon" ];

    # Commands for glot CLI integration
    commands = {
      build = "zig build";
      run = "zig build run";
      test = "zig build test";
      fmt = "zig fmt src/";
      lint = "zig build test"; # Zig's compiler includes good static analysis
      clean = "rm -rf zig-cache zig-out";
    };

    # Project detection
    detect = projectPath:
      builtins.pathExists (projectPath + "/build.zig");
  };
}
