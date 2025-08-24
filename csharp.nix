{ nixpkgs }:

# Main function that creates C# project outputs for a single system
{
  pkgs,           # Pass pkgs directly - no magic!
  self,
  # Optional customizations
  extraBuildTools ? [],
  extraGeneralTools ? [],
  sdk ? pkgs.dotnet-sdk_8
}:

let
  # Import organizational standard tools
  standardTools = import ./lib/standard-tools.nix { inherit pkgs; };

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
    echo "C# Development Environment Ready!"
  '';

  # Find .csproj file
  csprojFiles = builtins.filter
    (file: nixpkgs.lib.hasSuffix ".csproj" file)
    (builtins.attrNames (builtins.readDir self));

  name = if builtins.length csprojFiles == 1
    then nixpkgs.lib.removeSuffix ".csproj" (builtins.head csprojFiles)
    else throw "Expected exactly one .csproj file in root, found: ${builtins.toString (builtins.length csprojFiles)}";

  # Build the package using buildDotnetModule for proper NuGet handling
  package = pkgs.buildDotnetModule {
    inherit name;
    src = self;

    projectFile = "${name}.csproj";
    # nugetDeps = null; # Try without nugetDeps first
    selfContainedBuild = true;

    buildInputs = [ pkgs.fastfetch ];

    preUnpack = ''
      echo
      echo System Info
      echo ===========
      fastfetch
      echo -n "Dotnet version: "
      dotnet --version
    '';

    preBuild = ''
      echo
      echo Building
      echo ========
    '';

    preInstall = ''
      echo
      echo Installing
      echo ==========
    '';
  };

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
}
