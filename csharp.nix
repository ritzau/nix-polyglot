{ nixpkgs }:

# C# project builder with comprehensive reproducibility and buildDotnetModule integration
#
# This function creates development and release builds, development shells, apps, and checks
# for C# projects with built-in reproducible builds, test integration, and best practices.
#
# Key features:
# - Always-on reproducible builds with deterministic flags and environment isolation
# - Proper buildDotnetModule parameter support for advanced configuration
# - Integrated test execution via doCheck (no separate test derivations)
# - Assembly version control and code signing management
# - Development and release build variants with comprehensive checks
#
# Usage:
#   csharp = import ./csharp.nix { inherit nixpkgs; };
#   project = csharp { pkgs = nixpkgs.legacyPackages.${system}; self = ./.; buildTarget = "MyApp.sln"; };
#   # Use project.mkDefaultOutputs for complete flake integration
#
# Main function that creates C# project outputs for a single system
{
  # Required parameters
  pkgs, # Nixpkgs package set
  self, # Source path/flake self
  buildTarget, # Path to .csproj or .sln file (relative to src root)

  # SDK and build configuration
  sdk ? pkgs.dotnetCorePackages.sdk_8_0,
  nugetDeps ? null, # Path to deps.json or derivation
  selfContainedBuild ? true,

  # Development environment customization
  extraBuildTools ? [ ], # Additional build-time packages
  extraGeneralTools ? [ ], # Additional development packages

  # Test configuration
  enableTests ? true,
  testProject ? null, # Optional explicit test project path (.csproj)
  testFilters ? [ ], # Test filters for dotnet test --filter
  disabledTests ? [ ], # Specific tests to disable

  # Build customization (buildDotnetModule parameters)
  executables ? null, # null = install all, [] = install none, [...] = specific ones
  runtimeDeps ? [ ], # Runtime library dependencies
  dotnetBuildFlags ? [ ], # Additional build flags
  dotnetTestFlags ? [ ], # Additional test flags
  dotnetRestoreFlags ? [ ], # Additional restore flags
  dotnetInstallFlags ? [ ], # Additional install flags
  dotnetPackFlags ? [ ], # Additional pack flags
  dotnetFlags ? [ ], # Flags applied to all dotnet commands

  # Reproducibility controls (always enabled for security/consistency)
  sourceEpoch ? 1, # Timestamp for SOURCE_DATE_EPOCH
  assemblyVersion ? null, # Override assembly version for deterministic builds
  enforceCodeSigning ? false, # Enable code signing (disabled by default for reproducibility)
}:

let
  # Input validation
  _validateBuildTarget =
    assert buildTarget != null && buildTarget != "";
    "buildTarget must be a non-empty string pointing to a .csproj or .sln file";
  _validatePkgs =
    assert pkgs != null;
    "pkgs parameter is required";
  _validateSelf =
    assert self != null;
    "self parameter is required";

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
    inherit testFilters disabledTests;

    # Test configuration - use testProjectFile if provided, otherwise use doCheck
    testProjectFile = if hasTests && testProject != null then testProject else null;

    # Reproducibility controls (always enabled)
    env = {
      # Ensure consistent timezone and locale
      TZ = "UTC";
      LC_ALL = "C.UTF-8";
      LANG = "C.UTF-8";

      # Disable telemetry and user-specific behavior
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      DOTNET_SKIP_FIRST_TIME_EXPERIENCE = "1";
      DOTNET_NOLOGO = "1";
      DOTNET_CLI_UI_LANGUAGE = "en";

      # Force consistent behavior
      DOTNET_GENERATE_ASPNET_CERTIFICATE = "false";
      DOTNET_ADD_GLOBAL_TOOLS_TO_PATH = "false";
      DOTNET_MULTILEVEL_LOOKUP = "0";

      # Reproducible build environment
      SOURCE_DATE_EPOCH = toString sourceEpoch;
      DETERMINISTIC_BUILD = "true";

      # Disable user-specific caches and configs
      NUGET_PACKAGES = "$TMPDIR/nuget-packages";
      DOTNET_CLI_HOME = "$TMPDIR/dotnet-home";
    };

    # Combine user flags with reproducibility flags
    dotnetBuildFlags = [
      "/p:Deterministic=true"
      "/p:ContinuousIntegrationBuild=true"
      "/p:SourceRevisionId=${self.rev or "0000000000000000000000000000000000000000"}"
      "/p:PublishRepositoryUrl=true"
      "/p:EmbedUntrackedSources=true"
    ]
    ++ (nixpkgs.lib.optionals (assemblyVersion != null) [
      "/p:AssemblyVersion=${assemblyVersion}"
      "/p:FileVersion=${assemblyVersion}"
      "/p:InformationalVersion=${assemblyVersion}"
    ])
    ++ (nixpkgs.lib.optionals (!enforceCodeSigning) [
      "/p:SignAssembly=false"
      "/p:DelaySign=false"
    ])
    ++ dotnetBuildFlags;

    dotnetRestoreFlags = [
      "--no-cache"
      "--locked-mode" # Fail if package lock file is out of date
      "--force-evaluate" # Force re-evaluation of all dependencies
    ]
    ++ dotnetRestoreFlags;

    # Other dotnet flags passed through
    inherit
      dotnetTestFlags
      dotnetInstallFlags
      dotnetPackFlags
      dotnetFlags
      ;

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
      doCheck = hasTests;
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
      doCheck = hasTests;
      preBuild = buildHooks.buildPhaseHook + ''
        echo "Building release variant with Release configuration"
      '';
    }
  );

  # Simple test detection: either explicit test project or solution file
  hasTests = enableTests && (testProject != null || nixpkgs.lib.hasSuffix ".sln" buildTarget);

  # Individual components for backward compatibility and extension
  devShell = pkgs.mkShell {
    packages = allGeneralTools ++ allBuildTools;
    inherit shellHook;
  };

  devApp = {
    type = "app";
    program = "${devPackage}/bin/${name}";
    meta = {
      description = "C# application ${name} (Debug build)";
      platforms = nixpkgs.lib.platforms.all;
    };
  };

  releaseApp = {
    type = "app";
    program = "${releasePackage}/bin/${name}";
    meta = {
      description = "C# application ${name} (Release build)";
      platforms = nixpkgs.lib.platforms.all;
    };
  };

  # Include checks - both dev and release builds (tests run via doCheck)
  checks = {
    build-dev = devPackage; # Tests run automatically if hasTests=true
    build-release = releasePackage; # Tests run automatically if hasTests=true
  };

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
  # Individual components for flexible usage
  inherit
    devShell # Development shell with tools
    devPackage # Debug build derivation
    releasePackage # Release build derivation
    devApp # Debug app with meta
    releaseApp # Release app with meta
    checks # Build checks (dev + release with integrated tests)
    ;

  # Complete flake integration - recommended for most users
  # Contains: devShells.default, packages.{default,dev,release}, apps.{default,dev,release}, checks
  inherit mkDefaultOutputs;
}
