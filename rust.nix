{ nixpkgs }:

# Main function that creates Rust project outputs for a single system
{ pkgs
, # Pass pkgs directly - no magic!
  self
, # Required for dependency management
  cargoHash ? null
, # Optional customizations
  extraBuildTools ? [ ]
, extraGeneralTools ? [ ]
, rustc ? pkgs.rustc
, cargo ? pkgs.cargo
, # Use rustPlatform for consistent toolchain
  rustPlatform ? pkgs.rustPlatform
, # Binary name - if not provided, will try to extract from Cargo.toml
  binaryName ? null
, # Build configuration - "dev" or "release"
  buildType ? "dev"
,
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
  ]
  ++ standardTools.commonBuildTools;

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
  cargoFiles = builtins.filter (file: file == "Cargo.toml") (
    builtins.attrNames (builtins.readDir self)
  );

  hasCargoToml = builtins.length cargoFiles == 1;

  # Parse Cargo.toml to extract package information
  cargoToml =
    if hasCargoToml then
      builtins.fromTOML (builtins.readFile (self + "/Cargo.toml"))
    else
      throw "No Cargo.toml found in project root";

  # Extract package name and version from Cargo.toml
  packageName = cargoToml.package.name or "rust-project";
  packageVersion = cargoToml.package.version or "0.1.0";

  # Determine binary name - use provided binaryName, or first [[bin]] entry, or package name
  detectedBinaryName =
    if binaryName != null then
      binaryName
    else if cargoToml ? bin && builtins.length cargoToml.bin > 0 then
      (builtins.head cargoToml.bin).name
    else
      packageName;

  # Check if tests are present in the project
  hasTests =
    let
      srcFiles = builtins.attrNames (builtins.readDir (self + "/src"));
      hasLibRs = builtins.elem "lib.rs" srcFiles;
      hasTestsDir = builtins.pathExists (self + "/tests");
      hasDocTests = hasLibRs; # Assume lib.rs has doc tests
    in
    hasTestsDir || hasDocTests || (cargoToml ? dev-dependencies);

  # Common build configuration
  commonBuildConfig =
    if cargoHash == null then
      throw "cargoHash is required for Rust builds. Generate it with: nix-prefetch-url --unpack <cargo-vendor-tarball>"
    else
      {
        pname = packageName;
        version = packageVersion;
        src = self;
        inherit cargoHash;
        nativeBuildInputs = with pkgs; [ fastfetch ];
        preUnpack = buildHooks.systemInfoHook;
        preInstall = buildHooks.installPhaseHook;
      };

  # Dev build - uses debug profile (default cargo build)
  devPackage =
    if cargoHash == null then
      throw "cargoHash is required for Rust builds"
    else
      pkgs.rustPlatform.buildRustPackage (
        commonBuildConfig
        // {
          pname = "${packageName}-dev";

          # Enable tests if they exist
          doCheck = hasTests;

          # Override the default buildPhase to use debug profile
          buildPhase = ''
            runHook preBuild
            echo "Building with debug profile (unoptimized)"
            cargo build -j $NIX_BUILD_CORES --target ${pkgs.rust.toRustTarget pkgs.stdenv.hostPlatform} --frozen --offline
            runHook postBuild
          '';

          # Override install phase to install from debug target directory
          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            cp target/${pkgs.rust.toRustTarget pkgs.stdenv.hostPlatform}/debug/${detectedBinaryName} $out/bin/
            runHook postInstall
          '';

          # Additional check phase configuration for tests
          checkPhase =
            if hasTests then
              ''
                echo
                echo Testing
                echo =======
                cargo test
              ''
            else
              null;

          preBuild = buildHooks.buildPhaseHook + ''
            echo "Building dev variant with debug profile"
            ${buildHooks.versionHook {
              command = "${rustc}/bin/rustc --version";
              label = "Rust version";
            }}
            ${buildHooks.versionHook {
              command = "${cargo}/bin/cargo --version";
              label = "Cargo version";
            }}
          '';
        }
      );

  # Release build - uses release profile (optimized)
  releasePackage =
    if cargoHash == null then
      throw "cargoHash is required for Rust builds"
    else
      pkgs.rustPlatform.buildRustPackage (
        commonBuildConfig
        // {
          pname = "${packageName}-release";

          # Enable tests if they exist
          doCheck = hasTests;

          # Release builds use release profile (this is the default for buildRustPackage)
          # cargoCheckFlags and cargoBuildFlags are left as default (includes --release)

          # Additional check phase configuration for tests
          checkPhase =
            if hasTests then
              ''
                echo
                echo Testing
                echo =======
                cargo test --release
              ''
            else
              null;

          preBuild = buildHooks.buildPhaseHook + ''
            echo "Building release variant with release profile"
            ${buildHooks.versionHook {
              command = "${rustc}/bin/rustc --version";
              label = "Rust version";
            }}
            ${buildHooks.versionHook {
              command = "${cargo}/bin/cargo --version";
              label = "Cargo version";
            }}
          '';
        }
      );

  # Select package based on buildType parameter
  package = if buildType == "release" then releasePackage else devPackage;

  # Create test-only derivation if tests are available
  testCheck =
    if hasTests then
      pkgs.rustPlatform.buildRustPackage
        {
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
            ${buildHooks.versionHook {
              command = "${rustc}/bin/rustc --version";
              label = "Rust version";
            }}
            ${buildHooks.versionHook {
              command = "${cargo}/bin/cargo --version";
              label = "Cargo version";
            }}
            cargo test --release --verbose
          '';
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
    program = "${devPackage}/bin/${detectedBinaryName}";
  };

  releaseApp = {
    type = "app";
    program = "${releasePackage}/bin/${detectedBinaryName}";
  };

  # Select app based on buildType parameter
  app = if buildType == "release" then releaseApp else devApp;

  # Linting and formatting apps
  lintApp = {
    type = "app";
    program = "${pkgs.writeShellScript "lint-${packageName}" ''
      set -euo pipefail
      echo "Running Rust linting checks..."
      
      echo "🦀 Running clippy..."
      ${pkgs.clippy}/bin/cargo-clippy clippy -- -D warnings
      
      echo "Rust linting passed!"
    ''}";
    meta = {
      description = "Lint ${packageName} Rust code";
      platforms = nixpkgs.lib.platforms.all;
    };
  };

  checkFormatApp = {
    type = "app";
    program = "${pkgs.writeShellScript "check-format-${packageName}" ''
      set -euo pipefail
      echo "Checking formatting of ${packageName} Rust files..."
      
      echo "🦀 Checking with rustfmt..."
      ${pkgs.rustfmt}/bin/rustfmt --check src/**/*.rs
      
      echo "Rust formatting check passed!"
    ''}";
    meta = {
      description = "Check Rust code formatting";
      platforms = nixpkgs.lib.platforms.all;
    };
  };

  # Import script system for project templates and maintenance
  scripts = import ./lib/scripts.nix { inherit pkgs; };

  # Comprehensive checks system
  checks = {
    build-dev = devPackage;
    build-release = releasePackage;
    format-check = pkgs.runCommand "format-check-${packageName}"
      {
        buildInputs = [ pkgs.rustfmt ];
      } ''
      # Copy source to writable directory
      cp -r ${self} ./source
      chmod -R +w ./source
      cd ./source

      # Check Rust formatting
      ${pkgs.rustfmt}/bin/rustfmt --check src/**/*.rs
      
      touch $out
    '';
    lint-check = pkgs.runCommand "lint-check-${packageName}"
      {
        buildInputs = [ pkgs.clippy ];
        inherit cargoHash;
      } ''
      # Copy source to writable directory
      cp -r ${self} ./source
      chmod -R +w ./source  
      cd ./source

      # Run clippy linting
      ${pkgs.clippy}/bin/cargo-clippy clippy -- -D warnings
      
      touch $out
    '';
  }
  // (if hasTests then { test = testCheck; } else { });

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
      check-format = checkFormatApp;

      # Project management and maintenance apps
      setup = {
        type = "app";
        program = "${scripts.setupScript}/bin/setup-nix-polyglot-project";
        meta = {
          description = "Set up project with modern nix-polyglot architecture";
          platforms = nixpkgs.lib.platforms.all;
        };
      };
      update-project = {
        type = "app";
        program = "${scripts.updateScript}/bin/update-nix-polyglot-project";
        meta = {
          description = "Update project to latest nix-polyglot functionality";
          platforms = nixpkgs.lib.platforms.all;
        };
      };
      migrate = {
        type = "app";
        program = "${scripts.migrationScript}/bin/migrate-to-nix-polyglot";
        meta = {
          description = "Migrate legacy project to modern architecture";
          platforms = nixpkgs.lib.platforms.all;
        };
      };
    };
    inherit checks;
  };

in
{
  # Backward compatibility - expose individual components
  inherit
    devShell
    package
    app
    checks
    ;
  # Also expose dev and release variants
  inherit
    devPackage
    releasePackage
    devApp
    releaseApp
    ;

  # Formatting and linting components
  inherit
    lintApp
    checkFormatApp
    ;

  # Script system for maintenance-free project management
  inherit scripts;

  # New simplified interface
  inherit mkDefaultOutputs;
}
