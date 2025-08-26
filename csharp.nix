{ nixpkgs }:

# Main function that creates C# project outputs for a single system
{
  pkgs, # Pass pkgs directly - no magic!
  self,
  # Optional customizations
  extraBuildTools ? [ ],
  extraGeneralTools ? [ ],
  sdk ? pkgs.dotnetCorePackages.sdk_8_0,
  # Build target - path to .csproj or .sln file (relative to src root)
  buildTarget,
  # NuGet dependencies and build options
  nugetDeps ? null,
  selfContainedBuild ? true,
  # Test configuration
  enableTests ? true,
  testProject ? null, # Optional explicit test project path
  # Advanced buildDotnetModule parameters
  executables ? null, # null = install all, [] = install none, [...] = specific ones
  runtimeDeps ? [ ],
  dotnetBuildFlags ? [ ],
  dotnetTestFlags ? [ ],
  dotnetRestoreFlags ? [ ],
  dotnetInstallFlags ? [ ],
  dotnetPackFlags ? [ ],
  dotnetFlags ? [ ],
  testFilters ? [ ],
  disabledTests ? [ ],
}:

let
  # Import organizational standard tools and hooks
  standardTools = import ./lib/standard-tools.nix { inherit pkgs; };
  buildHooks = import ./lib/build-hooks.nix { inherit pkgs; };

  # Use organizational standard tools
  generalTools = standardTools.generalTools;

  # C#-specific build tools (in addition to standard tools)
  buildTools = [
    sdk
  ]
  ++ standardTools.commonBuildTools;

  # Combine with user extras
  allBuildTools = buildTools ++ extraBuildTools;
  allGeneralTools = generalTools ++ extraGeneralTools;

  shellHook = ''
    echo "🚀 C# Development Environment Ready!"
  '';

  # Derive name from the build target file - remove extension if present
  baseName = builtins.baseNameOf buildTarget;
  name =
    if nixpkgs.lib.hasSuffix ".csproj" baseName then
      nixpkgs.lib.removeSuffix ".csproj" baseName
    else if nixpkgs.lib.hasSuffix ".sln" baseName then
      nixpkgs.lib.removeSuffix ".sln" baseName
    else
      baseName;

  # Common build configuration
  commonBuildConfig = {
    inherit name;
    src = self;
    projectFile = buildTarget;
    dotnet-sdk = sdk;
    inherit selfContainedBuild;
    inherit nugetDeps;
    # Pass through buildDotnetModule parameters
    inherit executables runtimeDeps;
    inherit dotnetBuildFlags dotnetTestFlags dotnetRestoreFlags;
    inherit dotnetInstallFlags dotnetPackFlags dotnetFlags;
    inherit testFilters disabledTests;
    buildInputs = [ pkgs.fastfetch ];
    preUnpack =
      buildHooks.systemInfoHook
      + buildHooks.versionHook {
        command = "dotnet --version";
        label = "Dotnet version";
      };
    preBuild = buildHooks.buildPhaseHook;
    preInstall = buildHooks.installPhaseHook;
  };

  # Dev build - uses dotnet build with Debug configuration
  devPackage = pkgs.buildDotnetModule (
    commonBuildConfig
    // {
      name = "${name}-dev";
      buildType = "Debug";
      preBuild = buildHooks.buildPhaseHook + ''
        echo "Building dev variant with Debug configuration"
      '';
    }
  );

  # Release build - uses dotnet build with Release configuration
  releasePackage = pkgs.buildDotnetModule (
    commonBuildConfig
    // {
      name = "${name}-release";
      buildType = "Release";
      preBuild = buildHooks.buildPhaseHook + ''
        echo "Building release variant with Release configuration"
      '';
    }
  );

  # Simple test detection: either explicit test project or solution file
  hasTests = enableTests && (testProject != null || nixpkgs.lib.hasSuffix ".sln" buildTarget);

  # Create proper test derivation using buildDotnetModule
  testCheck =
    if hasTests then
      pkgs.buildDotnetModule {
        name = "${name}-tests";
        src = self;

        # Use explicit test project or the solution file
        projectFile = if testProject != null then testProject else buildTarget;

        dotnet-sdk = sdk;
        inherit nugetDeps selfContainedBuild;

        # Enable testing - this runs tests during the build phase
        doCheck = true;

        # Don't try to install anything - we just want the tests to run
        installPhase = ''
          echo "Tests completed successfully"
          mkdir -p $out
          touch $out/test-success
        '';

        buildInputs = [ pkgs.fastfetch ];

        preUnpack =
          buildHooks.systemInfoHook
          + buildHooks.versionHook {
            command = "dotnet --version";
            label = "Dotnet version";
          };
        preBuild = buildHooks.buildPhaseHook;
      }
    else
      null;

  # Individual components for backward compatibility and extension
  devShell = pkgs.mkShell {
    packages = allGeneralTools ++ allBuildTools;
    inherit shellHook;
  };

  devApp = {
    type = "app";
    program = "${devPackage}/bin/${name}";
  };

  releaseApp = {
    type = "app";
    program = "${releasePackage}/bin/${name}";
  };

  # Include checks - both dev and release builds, plus tests if enabled
  checks = {
    build-dev = devPackage;
    build-release = releasePackage;
  }
  // (if hasTests then { test = testCheck; } else { });

  # Default flake outputs structure - ready to use
  mkDefaultOutputs = {
    devShells.default = devShell;
    packages.default = devPackage;
    packages.dev = devPackage;
    packages.release = releasePackage;
    apps.default = devApp;
    apps.dev = devApp;
    apps.release = releaseApp;
    inherit checks;
  };

in
{
  # Backward compatibility - expose individual components
  inherit devShell checks;
  # Also expose dev and release variants
  inherit
    devPackage
    releasePackage
    devApp
    releaseApp
    ;

  # New simplified interface
  inherit mkDefaultOutputs;
}
