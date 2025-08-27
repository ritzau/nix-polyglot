{ nixpkgs
, treefmt-nix
, git-hooks-nix
,
}:

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
#   csharp = import ./csharp.nix { inherit nixpkgs treefmt-nix git-hooks-nix; };
#   project = csharp { pkgs = nixpkgs.legacyPackages.${system}; self = ./.; buildTarget = "MyApp.sln"; inherit system; };
#   # Use project.mkDefaultOutputs for complete flake integration
#
# Main function that creates C# project outputs for a single system
{
  # Required parameters
  pkgs
, # Nixpkgs package set
  self
, # Source path/flake self
  buildTarget
, # Path to .csproj or .sln file (relative to src root)

  # SDK and build configuration
  sdk ? pkgs.dotnetCorePackages.sdk_8_0
, nugetDeps ? null
, # Path to deps.json or derivation
  selfContainedBuild ? true
, # Development environment customization
  extraBuildTools ? [ ]
, # Additional build-time packages
  extraGeneralTools ? [ ]
, # Additional development packages

  # Test configuration
  enableTests ? true
, testProject ? null
, # Optional explicit test project path (.csproj)
  testFilters ? [ ]
, # Test filters for dotnet test --filter
  disabledTests ? [ ]
, # Specific tests to disable

  # Build customization (buildDotnetModule parameters)
  executables ? null
, # null = install all, [] = install none, [...] = specific ones
  runtimeDeps ? [ ]
, # Runtime library dependencies
  dotnetBuildFlags ? [ ]
, # Additional build flags
  dotnetTestFlags ? [ ]
, # Additional test flags
  dotnetRestoreFlags ? [ ]
, # Additional restore flags
  dotnetInstallFlags ? [ ]
, # Additional install flags
  dotnetPackFlags ? [ ]
, # Additional pack flags
  dotnetFlags ? [ ]
, # Flags applied to all dotnet commands

  # Reproducibility controls (always enabled for security/consistency)
  sourceEpoch ? 1
, # Timestamp for SOURCE_DATE_EPOCH
  assemblyVersion ? null
, # Override assembly version for deterministic builds
  enforceCodeSigning ? false
, # Enable code signing (disabled by default for reproducibility)

  # Formatting and linting configuration
  enableFormatting ? true
, # Enable treefmt integration for C# formatting
  enableLinting ? true
, # Enable pre-commit hooks with linting
  extraFormatters ? { }
, # Additional formatters to configure in treefmt
  extraPreCommitHooks ? { }
, # Additional pre-commit hooks to configure
  system
, # System architecture (required for treefmt-nix and git-hooks-nix)
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

  # Note: treefmt configuration removed - use main flake's `nix fmt` instead

  # Configure git hooks for C# projects
  git-hooks = nixpkgs.lib.optionalAttrs enableLinting (
    git-hooks-nix.lib.${system}.run {
      src = self;
      hooks = {
        # C# specific hooks
        dotnet-format = {
          enable = true;
          name = "dotnet format";
          entry = "${sdk}/bin/dotnet format --verify-no-changes";
          files = "\\.(cs|vb|fs)$";
          pass_filenames = false;
        };
        # Note: treefmt, nixpkgs-fmt, prettier hooks handled by main flake
      }
      // extraPreCommitHooks;
    }
  );

  # Individual components for backward compatibility and extension
  devShell = pkgs.mkShell {
    packages = allGeneralTools ++ allBuildTools;
    shellHook =
      shellHook
      + nixpkgs.lib.optionalString enableLinting ''
        ${git-hooks.shellHook}
      '';
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

  # Formatting and linting apps (format app removed - use `nix fmt` instead)

  checkFormatApp = nixpkgs.lib.optionalAttrs enableFormatting {
    type = "app";
    program = "${pkgs.writeShellScript "check-format-${name}" ''
      set -euo pipefail
      echo "Checking formatting of ${name} project files..."
      echo "Use 'nix fmt --check' from the project root for universal format checking"
      echo "Checking C# formatting specifically..."
      ${sdk}/bin/dotnet format --verify-no-changes --verbosity diagnostic
      echo "C# formatting check passed!"
    ''}";
    meta = {
      description = "Check C# code formatting";
      platforms = nixpkgs.lib.platforms.all;
    };
  };

  lintApp = {
    type = "app";
    program = "${pkgs.writeShellScript "lint-${name}" ''
      set -euo pipefail
      echo "Running C# linting checks..."
      ${sdk}/bin/dotnet format --verify-no-changes --verbosity diagnostic
      echo "Linting passed!"
    ''}";
    meta = {
      description = "Lint ${name} C# code";
      platforms = nixpkgs.lib.platforms.all;
    };
  };

  # Include checks - both dev and release builds (tests run via doCheck)
  checks = {
    build-dev = devPackage; # Tests run automatically if hasTests=true
    build-release = releasePackage; # Tests run automatically if hasTests=true
  }
  // nixpkgs.lib.optionalAttrs enableLinting {
    lint-check = pkgs.runCommand "lint-check-${name}" { buildInputs = [ sdk ]; } ''
      # Copy source to a writable directory
      cp -r ${self} ./source
      chmod -R +w ./source
      cd ./source

      # Run dotnet format check
      ${sdk}/bin/dotnet format --verify-no-changes --verbosity diagnostic
      touch $out
    '';
    pre-commit-check = git-hooks;
  };

  # Project-specific formatter for C# code
  projectFormatter =
    if enableFormatting then
      (pkgs.writeShellApplication {
        name = "csharp-formatter";
        text = ''
          echo "Formatting C# code..."
          ${sdk}/bin/dotnet format --verbosity minimal
          echo "C# formatting complete!"
        '';
      })
    else
      null;

  # Default flake outputs structure - ready to use
  mkDefaultOutputs = {
    devShells.default = devShell;
    packages.default = devPackage;
    packages.dev = devPackage;
    packages.release = releasePackage;
    apps = {
      default = devApp;
      dev = devApp;
      release = releaseApp;
      lint = lintApp;
    }
    // nixpkgs.lib.optionalAttrs enableFormatting {
      check-format = checkFormatApp;
    };
    inherit checks;
  }
  // nixpkgs.lib.optionalAttrs enableFormatting {
    formatter = projectFormatter;
  };

in
{
  # Individual components for flexible usage
  inherit
    devShell# Development shell with tools
    devPackage# Debug build derivation
    releasePackage# Release build derivation
    devApp# Debug app with meta
    releaseApp# Release app with meta
    lintApp# Linting app
    checks# Build checks (dev + release with integrated tests)
    ;

  # Formatting components (optional) - formatApp removed, use `nix fmt` instead
  checkFormatApp = if enableFormatting then checkFormatApp else null;
  projectFormatter = if enableFormatting then projectFormatter else null;
  # treefmt removed - use main flake's `nix fmt` instead
  git-hooks = if enableLinting then git-hooks else null;

  # Complete flake integration - recommended for most users
  # Contains: devShells.default, packages.{default,dev,release}, apps.{default,dev,release,lint,check-format?}, checks
  # Note: Use `nix fmt` for formatting instead of a dedicated format app
  inherit mkDefaultOutputs;
}
