{ nixpkgs }:

# Main function that creates Nim project outputs for a single system
{ pkgs
, # Pass pkgs directly - no magic!
  self
, # Required for dependency management  
  lockFile ? null
, # Optional customizations
  extraBuildTools ? [ ]
, extraGeneralTools ? [ ]
, nim ? pkgs.nim
, nimble ? pkgs.nimble
, # Binary name - if not provided, will try to detect from nimble file
  binaryName ? null
, # Build configuration
  nimRelease ? false
, nimDefines ? [ ]
, nimFlags ? [ ]
, nimDoc ? false
,
}:

let
  # Import organizational standard tools and build hooks
  standardTools = import ./lib/standard-tools.nix { inherit pkgs; };
  buildHooks = import ./lib/build-hooks.nix { inherit pkgs; };

  # Use organizational standard tools
  generalTools = standardTools.generalTools;

  # Nim-specific build tools (in addition to standard tools)
  buildTools = [
    nim
    nimble
  ]
  ++ standardTools.commonBuildTools;

  # Add Nim-specific development tools
  nimDevTools = with pkgs; [
    # Debugging tools
    gdb
    # Additional build tools might be needed
  ];

  # Combine with user extras
  allBuildTools = buildTools ++ nimDevTools ++ extraBuildTools;
  allGeneralTools = generalTools ++ extraGeneralTools;

  shellHook = ''
    echo "🎯 Nim Development Environment"
    echo ""
    echo "Nim version: $(nim --version | head -n 1)"
    echo ""
    echo "Development commands:"
    echo "  nim c <file>     - Compile Nim file"
    echo "  nim c -r <file>  - Compile and run Nim file"
    echo "  nimble build     - Build project with Nimble"
    echo "  nimble test      - Run tests"
    echo "  nimble install   - Install dependencies"
    echo ""
    echo "Available tools:"
    ${pkgs.lib.concatStringsSep "\n" (map (tool: "echo \"  ${tool.pname or tool.name or "unknown"} - ${tool.meta.description or ""}\"") allBuildTools)}
    echo ""
  '';

  # Development shell with comprehensive Nim toolchain
  devShell = pkgs.mkShell {
    packages = allBuildTools ++ allGeneralTools ++ [
      # Add glot CLI from self
      self.packages.${pkgs.system}.glot
    ];
    inherit shellHook;
  };

  # Function to detect binary name from nimble file
  detectBinaryName = projectPath:
    let
      nimbleFiles = builtins.attrNames (builtins.readDir projectPath);
      nimbleFile = builtins.head (builtins.filter (name: pkgs.lib.hasSuffix ".nimble" name) nimbleFiles);
    in
    if nimbleFile != null
    then pkgs.lib.removeSuffix ".nimble" (baseNameOf nimbleFile)
    else "nim-project";

  # Actual binary name to use
  actualBinaryName =
    if binaryName != null
    then binaryName
    else detectBinaryName ./.;

  # Base build arguments
  baseBuildArgs = {
    pname = actualBinaryName;
    version = "0.1.0";
    src = ./.;

    inherit nim nimble;
    inherit nimDefines nimFlags nimDoc;
    nimRelease = false; # Development build

    # Use provided lockfile or generate one
    lockFile = if lockFile != null then lockFile else null;

    meta = with pkgs.lib; {
      description = "Nim project built with nix-polyglot";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };

  # Development build - fast compilation, debug info
  devBuild = pkgs.buildNimPackage (baseBuildArgs // {
    pname = "${actualBinaryName}-dev";
    nimRelease = false;
    nimFlags = nimFlags ++ [ "--debugger:native" ];
  });

  # Release build - optimized
  releaseBuild = pkgs.buildNimPackage (baseBuildArgs // {
    pname = "${actualBinaryName}-release";
    nimRelease = true;
    nimFlags = nimFlags ++ [ "-d:release" "--opt:speed" ];
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
        program = "${devBuild}/bin/${actualBinaryName}";
      };

      dev = {
        type = "app";
        program = "${devBuild}/bin/${actualBinaryName}";
      };

      release = {
        type = "app";
        program = "${releaseBuild}/bin/${actualBinaryName}";
      };
    };

    # Use system formatter for Nix files
    formatter = pkgs.nixpkgs-fmt;
  };

  # Language-specific information for glot CLI
  languageInfo = {
    name = "nim";
    extensions = [ ".nim" ".nims" ".cfg" ".nimble" ];
    projectFiles = [ "*.nimble" "nim.cfg" "config.nims" ];

    # Commands for glot CLI integration
    commands = {
      build = "nimble build";
      run = if lockFile != null then "nimble run" else "nim c -r src/${actualBinaryName}.nim";
      test = "nimble test";
      fmt = "nimpretty --indent:2";
      lint = "nim check";
      clean = "rm -rf nimcache";
    };

    # Project detection
    detect = projectPath:
      let
        hasNimble = builtins.any
          (name: pkgs.lib.hasSuffix ".nimble" name)
          (builtins.attrNames (builtins.readDir projectPath));
        hasNimConfig =
          builtins.pathExists (projectPath + "/nim.cfg") ||
          builtins.pathExists (projectPath + "/config.nims");
        hasNimSrc = builtins.pathExists (projectPath + "/src");
      in
      hasNimble || hasNimConfig || hasNimSrc;
  };
}
