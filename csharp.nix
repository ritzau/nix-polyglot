{ nixpkgs }:

# Main function that creates C# project outputs for a single system
{
  pkgs,           # Pass pkgs directly - no magic!
  self,
  # Optional customizations
  extraBuildTools ? [],
  extraGeneralTools ? [],
  sdk ? pkgs.dotnet-sdk_8,
  # Build target - path to .csproj or .sln file (relative to src root)
  buildTarget,
  # NuGet dependencies and build options
  nugetDeps ? null,
  selfContainedBuild ? true,
  # Test configuration
  enableTests ? true,
  testProject ? null  # Optional explicit test project path
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
  ] ++ standardTools.commonBuildTools;

  # Combine with user extras
  allBuildTools = buildTools ++ extraBuildTools;
  allGeneralTools = generalTools ++ extraGeneralTools;

  shellHook = ''
    echo "🚀 C# Development Environment Ready!"
  '';

  # Derive name from the build target file - remove extension if present
  baseName = builtins.baseNameOf buildTarget;
  name = if nixpkgs.lib.hasSuffix ".csproj" baseName then
    nixpkgs.lib.removeSuffix ".csproj" baseName
  else if nixpkgs.lib.hasSuffix ".sln" baseName then
    nixpkgs.lib.removeSuffix ".sln" baseName
  else
    baseName;

  # Build the package using buildDotnetModule for proper NuGet handling
  package = pkgs.buildDotnetModule {
    inherit name;
    src = self;

    projectFile = buildTarget;
    dotnet-sdk = sdk;
    inherit nugetDeps selfContainedBuild;

    buildInputs = [ pkgs.fastfetch ];

    preUnpack = buildHooks.systemInfoHook + buildHooks.versionHook { command = "dotnet --version"; label = "Dotnet version"; };
    preBuild = buildHooks.buildPhaseHook;
    preInstall = buildHooks.installPhaseHook;
  };

  # Auto-detect test projects if enableTests is true
  hasTests = enableTests && (testProject != null || builtins.pathExists (self + "/tests") || nixpkgs.lib.hasSuffix ".sln" buildTarget);

  # Create test check if tests are detected
  testCheck = if hasTests then
    pkgs.writeShellApplication {
      name = "${name}-tests";
      runtimeInputs = [ sdk ];
      text = ''
        echo "Running ${name} unit tests..."
        cd ${self}
        
        # If explicit test project specified
        if [ -n "${if testProject != null then testProject else ""}" ]; then
          echo "Running explicit test project: ${if testProject != null then testProject else ""}"
          dotnet test "${if testProject != null then testProject else ""}" --logger "console;verbosity=detailed"
        # If tests directory exists
        elif [ -d "tests" ]; then
          echo "Running tests from tests/ directory..."
          # Find test projects in tests directory
          for test_proj in tests/*.csproj tests/*/*.csproj; do
            if [ -f "$test_proj" ]; then
              echo "Running test project: $test_proj"
              dotnet test "$test_proj" --logger "console;verbosity=detailed"
            fi
          done
        # If solution file, run all tests in solution
        elif [[ "${buildTarget}" == *.sln ]]; then
          echo "Running all tests in solution: ${buildTarget}"
          dotnet test "${buildTarget}" --logger "console;verbosity=detailed"
        else
          echo "No test configuration found"
          exit 1
        fi
        
        echo "✅ All ${name} tests completed successfully!"
      '';
    }
  else
    null;

in
{
  devShell = pkgs.mkShell {
    packages = allGeneralTools ++ allBuildTools;
    inherit shellHook;
  };

  package = package;

  app = {
    type = "app";
    program = "${package}/bin/${name}";
  };

  # Include checks - build check always present, test check if tests detected
  checks = {
    build = package;
  } // (if hasTests then { test = testCheck; } else {});
}
