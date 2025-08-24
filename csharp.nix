{ nixpkgs }:

# Main function that creates C# project outputs for a single system
{
  pkgs,           # Pass pkgs directly - no magic!
  self,
  # Optional customizations
  extraBuildTools ? [],
  extraGeneralTools ? [],
  shellHook ? null,
  buildPhase ? null,
  installPhase ? null,
  shell ? "zsh",
  sdk ? pkgs.dotnet-sdk_8
}:

let
  # Define tool lists
  generalTools = with pkgs; [
    tree
    bat
    bottom
    jq
  ];

  buildTools = [
    sdk
    pkgs.fastfetch
    pkgs.tree
    pkgs.figlet
  ];

  # Add .NET runtime packages for self-contained builds
  dotnetRuntimePackages = with pkgs; [
    dotnet-runtime_8
    dotnet-aspnetcore_8
  ];

  # Combine with user extras
  allBuildTools = buildTools ++ dotnetRuntimePackages ++ extraBuildTools;
  allGeneralTools = generalTools ++ extraGeneralTools;

  # Choose shell
  shellPkg = if shell == "zsh" then pkgs.zsh else pkgs.bash;
  shellPath = "${shellPkg}/bin/${shell}";

  # Handle null shellHook and shell setup
  finalShellHook = if shellHook == null
    then ''
      export SHELL=${shellPath}
      echo "C# Development Environment Ready! (using ${shell})"
    ''
    else ''
      export SHELL=${shellPath}
      ${shellHook}
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
    packages = allGeneralTools ++ allBuildTools ++ [ shellPkg ];
    shellHook = finalShellHook;
  };

  package = package;

  app = {
    type = "app";
    program = "${package}/bin/${name}";
  };
}
