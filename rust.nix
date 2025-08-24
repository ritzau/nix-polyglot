{ nixpkgs }:

# Main function that creates Rust project outputs for a single system
{
  pkgs,           # Pass pkgs directly - no magic!
  self,
  # Required for dependency management
  cargoHash ? null,
  # Optional customizations
  extraBuildTools ? [],
  extraGeneralTools ? [],
  shellHook ? null,
  buildPhase ? null,
  installPhase ? null,
  shell ? "zsh",
  rustc ? pkgs.rustc,
  cargo ? pkgs.cargo,
  # Binary name - if not provided, will try to extract from Cargo.toml
  binaryName ? null
}:

let
  # Import organizational standard tools
  standardTools = import ./lib/standard-tools.nix { inherit pkgs; };

  # Use organizational standard tools
  generalTools = standardTools.generalTools;

  # Rust-specific build tools (in addition to standard tools)
  buildTools = [
    rustc
    cargo
  ] ++ standardTools.commonBuildTools;

  # Add Rust-specific development tools
  rustDevTools = with pkgs; [
    rust-analyzer
    clippy
    rustfmt
  ];

  # Combine with user extras
  allBuildTools = buildTools ++ rustDevTools ++ extraBuildTools;
  allGeneralTools = generalTools ++ extraGeneralTools;

  # Choose shell
  shellPkg = if shell == "zsh" then pkgs.zsh else pkgs.bash;
  shellPath = "${shellPkg}/bin/${shell}";

  # Handle null shellHook and shell setup
  finalShellHook = if shellHook == null
    then ''
      export SHELL=${shellPath}
      echo "Rust Development Environment Ready! (using ${shell})"
      echo "Available tools: cargo, clippy, rustfmt, rust-analyzer"
    ''
    else ''
      export SHELL=${shellPath}
      ${shellHook}
    '';

  # Find Cargo.toml file
  cargoFiles = builtins.filter
    (file: file == "Cargo.toml")
    (builtins.attrNames (builtins.readDir self));

  hasCargoToml = builtins.length cargoFiles == 1;
  
  # Extract package name from Cargo.toml if possible, otherwise use directory name
  # For now, we'll use a simple approach and let buildRustPackage handle it
  name = if hasCargoToml 
    then "rust-project"  # buildRustPackage will extract the real name
    else throw "No Cargo.toml found in project root";

  # Build the package using buildRustPackage for proper Cargo handling
  package = if cargoHash == null 
    then throw "cargoHash is required for Rust builds. Generate it with: nix-prefetch-url --unpack <cargo-vendor-tarball>"
    else pkgs.rustPlatform.buildRustPackage {
      pname = "rust-project";
      version = "0.1.0";
      src = self;
      
      inherit cargoHash;
      
      nativeBuildInputs = [ pkgs.fastfetch ];
      
      preUnpack = ''
        echo
        echo System Info  
        echo ===========
        if command -v fastfetch >/dev/null 2>&1; then
          fastfetch
        else
          echo "System info tools not available in this phase"
        fi
        if command -v rustc >/dev/null 2>&1; then
          echo -n "Rust version: "
          rustc --version
          echo -n "Cargo version: "
          cargo --version
        else
          echo "Rust toolchain info not available in this phase"
        fi
      '';

      preBuild = if buildPhase == null then ''
        echo
        echo Building
        echo ========
      '' else null;

      preInstall = if installPhase == null then ''
        echo  
        echo Installing
        echo ==========
      '' else null;

      # Allow custom build/install phases
      buildPhase = buildPhase;
      installPhase = installPhase;
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
    program = "${package}/bin/${if binaryName != null then binaryName else package.pname}";
  };
}