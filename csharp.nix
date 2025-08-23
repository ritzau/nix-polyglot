{ nixpkgs, flake-utils }:

# Main function that creates complete C# project flake outputs
{
  self,
  # Optional customizations
  extraBuildTools ? [],
  extraGeneralTools ? [],
  shellHook ? null,
  buildPhase ? null,
  installPhase ? null,
  shell ? "zsh"
}:

flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import nixpkgs { inherit system; };

    # Define tool lists
    generalTools = with pkgs; [
      tree
      bat
      bottom
      jq
    ];

    buildTools = with pkgs; [
      dotnet-sdk_8
      fastfetch
      tree
      figlet
    ];

    # Combine with user extras
    allBuildTools = buildTools ++ extraBuildTools;
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

    # Build the package
    package = pkgs.stdenv.mkDerivation {
      inherit name;
      src = self;
      buildInputs = allBuildTools;

      preUnpack = ''
        figlet "System Info"
        fastfetch
      '';

      buildPhase = if buildPhase != null then buildPhase else ''
        figlet Building
        runHook preBuild
        dotnet publish -o build --self-contained true ${name}.csproj
        runHook postBuild
      '';

      installPhase = if installPhase != null then installPhase else ''
        figlet Installing
        runHook preInstall
        tree
        mkdir -p $out/bin
        cp -apv build/* $out/bin/
        runHook postInstall
      '';

      postInstall = ''
        figlet "Build successful!"
      '';

      runPhase = ''
        figlet Running
        runHook preRun
        $out/bin/${name}
        runHook postRun
      '';
    };

  in
  {
    devShells.default = pkgs.mkShell {
      packages = allGeneralTools ++ allBuildTools ++ [ shellPkg ];
      shellHook = finalShellHook;
    };

    packages.default = package;

    apps.default = {
      type = "app";
      program = "${package}/bin/${name}";
    };
  })
