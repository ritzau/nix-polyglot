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

  # Simple test detection: either explicit test project or solution file
  hasTests = enableTests && (
    testProject != null || 
    nixpkgs.lib.hasSuffix ".sln" buildTarget
  );

  # Create proper test derivation using buildDotnetModule
  testCheck = if hasTests then
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
      
      preUnpack = buildHooks.systemInfoHook + buildHooks.versionHook { command = "dotnet --version"; label = "Dotnet version"; };
      preBuild = buildHooks.buildPhaseHook;
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
