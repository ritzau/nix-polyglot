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
  rustc ? pkgs.rustc,
  cargo ? pkgs.cargo,
  # Use rustPlatform for consistent toolchain
  rustPlatform ? pkgs.rustPlatform,
  # Binary name - if not provided, will try to extract from Cargo.toml
  binaryName ? null
}:

let
  # Import organizational standard tools and build hooks
  standardTools = import ./lib/standard-tools.nix { inherit pkgs; };
  buildHooks = import ./lib/build-hooks.nix { inherit pkgs; };

  # Use organizational standard tools
  generalTools = standardTools.generalTools;

  # Rust-specific build tools (in addition to standard tools)
  buildTools = [
    rustc
    cargo
  ] ++ standardTools.commonBuildTools;

  # Add Rust-specific development tools - use binary packages when possible
  rustDevTools = with pkgs; [
    rust-analyzer
    # Use the standard stable toolchain components
    rustfmt
    clippy
  ];

  # Combine with user extras
  allBuildTools = buildTools ++ rustDevTools ++ extraBuildTools;
  allGeneralTools = generalTools ++ extraGeneralTools;

  shellHook = ''
    echo "🦀 Rust Development Environment Ready!"
    echo "Available tools: rustc, cargo, clippy, rustfmt, rust-analyzer"
    echo "Project: ${packageName} v${packageVersion}"
  '';

  # Find Cargo.toml file
  cargoFiles = builtins.filter
    (file: file == "Cargo.toml")
    (builtins.attrNames (builtins.readDir self));

  hasCargoToml = builtins.length cargoFiles == 1;
  
  # Parse Cargo.toml to extract package information
  cargoToml = if hasCargoToml
    then builtins.fromTOML (builtins.readFile (self + "/Cargo.toml"))
    else throw "No Cargo.toml found in project root";
  
  # Extract package name and version from Cargo.toml
  packageName = cargoToml.package.name or "rust-project";
  packageVersion = cargoToml.package.version or "0.1.0";
  
  # Determine binary name - use provided binaryName, or first [[bin]] entry, or package name
  detectedBinaryName = 
    if binaryName != null then binaryName
    else if cargoToml ? bin && builtins.length cargoToml.bin > 0
    then (builtins.head cargoToml.bin).name
    else packageName;
  
  # Check if tests are present in the project
  hasTests = 
    let 
      srcFiles = builtins.attrNames (builtins.readDir (self + "/src"));
      hasLibRs = builtins.elem "lib.rs" srcFiles;
      hasTestsDir = builtins.pathExists (self + "/tests");
      hasDocTests = hasLibRs; # Assume lib.rs has doc tests
    in hasTestsDir || hasDocTests || (cargoToml ? dev-dependencies);

  # Build the package using buildRustPackage for proper Cargo handling
  package = if cargoHash == null 
    then throw "cargoHash is required for Rust builds. Generate it with: nix-prefetch-url --unpack <cargo-vendor-tarball>"
    else pkgs.rustPlatform.buildRustPackage {
      pname = packageName;
      version = packageVersion;
      src = self;
      
      inherit cargoHash;
      
      nativeBuildInputs = with pkgs; [ fastfetch ];
      
      # Enable tests if they exist
      doCheck = hasTests;
      
      # Additional check phase configuration for tests
      checkPhase = if hasTests then ''
        echo
        echo Testing
        echo =======
        cargo test --release
      '' else null;
      
      preUnpack = buildHooks.systemInfoHook;

      preBuild = buildHooks.buildPhaseHook + ''
        ${buildHooks.versionHook { command = "${rustc}/bin/rustc --version"; label = "Rust version"; }}
        ${buildHooks.versionHook { command = "${cargo}/bin/cargo --version"; label = "Cargo version"; }}
      '';

      preInstall = buildHooks.installPhaseHook;
    };

  # Create test-only derivation if tests are available
  testCheck = if hasTests then pkgs.rustPlatform.buildRustPackage {
    pname = "${packageName}-tests";
    version = packageVersion;
    src = self;
    inherit cargoHash;
    
    # Only run tests, don't install anything
    dontInstall = true;
    doCheck = true;
    
    checkPhase = ''
      echo
      echo Testing
      echo =======
      ${buildHooks.versionHook { command = "${rustc}/bin/rustc --version"; label = "Rust version"; }}
      ${buildHooks.versionHook { command = "${cargo}/bin/cargo --version"; label = "Cargo version"; }}
      cargo test --release --verbose
    '';
  } else null;

let
  # Individual components for backward compatibility and extension
  devShell = pkgs.mkShell {
    packages = allGeneralTools ++ allBuildTools;
    inherit shellHook;
  };

  app = {
    type = "app";
    program = "${package}/bin/${detectedBinaryName}";
  };
  
  # Comprehensive checks system
  checks = {
    build = package;
  } // (if hasTests then { test = testCheck; } else {});

  # Default flake outputs structure - ready to use
  mkDefaultOutputs = {
    devShells.default = devShell;
    packages.default = package;
    apps.default = app;
    inherit checks;
  };

in
{
  # Backward compatibility - expose individual components
  inherit devShell package app checks;
  
  # New simplified interface
  inherit mkDefaultOutputs;
}