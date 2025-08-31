# C++/CMake project builder with dev/release optimization
#
# This function creates development and release builds, shells, apps, and checks
# for C++ projects using CMake with built-in reproducibility and best practices.
#
# Key features:
# - Fast dev builds with debug info, skip expensive checks
# - Reproducible release builds with deterministic output
# - Integrated test execution and quality assurance
# - Universal formatting and linting integration
# - Configurable C++ compiler and version
#
# Usage:
#   cpp = import ./cpp.nix { inherit nixpkgs treefmt-nix git-hooks-nix; };
#   project = cpp { 
#     pkgs = nixpkgs.legacyPackages.${system}; 
#     self = ./.; 
#     buildTarget = "./CMakeLists.txt";
#     ... 
#   };
#   # Use project.defaultOutputs for complete flake integration

{ nixpkgs, treefmt-nix, git-hooks-nix }:

{
  # Required parameters
  pkgs
, # Nixpkgs package set
  self
, # Source path/flake self
  buildTarget
, # Path to CMakeLists.txt

  # Project configuration
  projectName ? "cpp-project"
, version ? "0.1.0"
, # C++ specific parameters
  cppStandard ? "17"
, # C++ standard (11, 14, 17, 20, 23)
  compiler ? "gcc"
, # Compiler choice: gcc, clang
  enableTests ? true
, # Whether to build and run tests

  # Build customization
  extraBuildInputs ? [ ]
, # Additional build dependencies
  extraNativeBuildInputs ? [ ]
, # Additional native build dependencies
  extraCmakeFlags ? [ ]
, # Additional CMake flags

  # Development tools
  extraDevTools ? [ ]
, # Additional development tools

  system
, # System architecture
}:

let
  # Select compiler package based on choice
  compilerPkg = if compiler == "clang" then pkgs.clang else pkgs.gcc;

  # Base configuration shared by both builds
  baseConfig = {
    pname = projectName;
    inherit version;
    src = self;

    nativeBuildInputs = with pkgs; [
      cmake
      compilerPkg
      pkg-config
    ] ++ extraNativeBuildInputs;

    buildInputs = extraBuildInputs;

    # Base CMake configuration
    cmakeFlags = [
      "-DCMAKE_CXX_STANDARD=${cppStandard}"
    ] ++ extraCmakeFlags;

    meta = with pkgs.lib; {
      description = "C++ project built with CMake";
      platforms = platforms.unix;
    };
  };

  # Fast development build - optimized for speed
  devBuildConfig = baseConfig // {
    cmakeFlags = baseConfig.cmakeFlags ++ [
      "-DCMAKE_BUILD_TYPE=Debug"
    ];
    doCheck = false; # Skip tests for speed

    # Minimal environment for fast iteration - use NIX flags for compiler flags
    NIX_CFLAGS_COMPILE = "-DDEBUG_BUILD=1 -g -O0";
  };

  # Reproducible release build - deterministic output
  releaseBuildConfig = baseConfig // {
    cmakeFlags = baseConfig.cmakeFlags ++ [
      "-DCMAKE_BUILD_TYPE=Release"
    ];
    doCheck = enableTests; # Run all tests

    # Full reproducibility controls
    env = {
      TZ = "UTC";
      LC_ALL = "C.UTF-8";
      LANG = "C.UTF-8";
      SOURCE_DATE_EPOCH = toString 1;
      DETERMINISTIC_BUILD = "true";
    };

    # Use NIX flags for compiler flags, not CMake flags
    NIX_CFLAGS_COMPILE = "-DRELEASE_BUILD=1 -O2 -DNDEBUG";
  };

  # Dev build - fast iteration with debug info
  devPackage = pkgs.stdenv.mkDerivation devBuildConfig;

  # Release build - reproducible production build
  releasePackage = pkgs.stdenv.mkDerivation releaseBuildConfig;

  # Development shell with all necessary tools
  devShell = pkgs.mkShell {
    inputsFrom = [ devPackage ];
    packages = with pkgs; [
      # Core development tools
      gdb
      valgrind

      # Code formatting and linting
      clang-tools # includes clang-format, clang-tidy
      cppcheck

      # Documentation
      doxygen

      # Additional dev tools
      ccache # Compiler cache for faster builds
    ] ++ extraDevTools;

    shellHook = ''
      echo "🔧 C++ Development Environment Ready!"
      echo "Compiler: ${compiler} (${compilerPkg.name or compilerPkg.pname})"
      echo "C++ Standard: C++${cppStandard}"
      echo "Project: ${projectName} v${version}"
      echo ""
      echo "Available tools:"
      echo "  cmake                 - Build system"
      echo "  ${compiler}                   - C++ compiler"
      echo "  gdb                   - Debugger"
      echo "  valgrind              - Memory analyzer"
      echo "  clang-format          - Code formatter"
      echo "  clang-tidy            - Static analyzer"
      echo "  cppcheck              - Additional static analysis"
      echo ""
      echo "Build commands:"
      echo "  cmake -B build        - Configure build"
      echo "  cmake --build build   - Build project"
      echo "  cmake --build build --target test - Run tests"
    '';
  };

  # Apps for running built executables
  devApp = {
    type = "app";
    program = "${devPackage}/bin/${projectName}";
  };

  releaseApp = {
    type = "app";
    program = "${releasePackage}/bin/${projectName}";
  };

  # Formatting integration
  projectFormatter = pkgs.writeShellApplication {
    name = "cpp-formatter";
    runtimeInputs = with pkgs; [ clang-tools findutils ];
    text = ''
      echo "🎨 Formatting C++ code..."
      find . -name "*.cpp" -o -name "*.hpp" -o -name "*.c" -o -name "*.h" | \
        xargs clang-format -i
      echo "✅ C++ formatting complete!"
    '';
  };

  # Linting application
  lintApp = pkgs.writeShellApplication {
    name = "cpp-lint";
    runtimeInputs = with pkgs; [ clang-tools cppcheck findutils ];
    text = ''
      echo "🔍 Running C++ linting checks..."
      
      echo "Running clang-tidy..."
      find . -name "*.cpp" | xargs clang-tidy --checks='-*,readability-*,performance-*,modernize-*'
      
      echo "Running cppcheck..."
      cppcheck --enable=all --inconclusive --std=c++${cppStandard} .
      
      echo "✅ C++ linting complete!"
    '';
  };

  # Format checking
  checkFormatApp = pkgs.writeShellApplication {
    name = "cpp-check-format";
    runtimeInputs = with pkgs; [ clang-tools findutils ];
    text = ''
      echo "🔍 Checking C++ code formatting..."
      if find . -name "*.cpp" -o -name "*.hpp" -o -name "*.c" -o -name "*.h" | \
         xargs clang-format --dry-run --Werror; then
        echo "✅ All C++ code is properly formatted!"
      else
        echo "❌ C++ code formatting issues found!"
        exit 1
      fi
    '';
  };

  # Git hooks configuration for pre-commit
  git-hooks = git-hooks-nix.lib.${system}.run {
    src = self;
    hooks = {
      cpp-format = {
        enable = true;
        name = "C++ format";
        entry = "${pkgs.clang-tools}/bin/clang-format --dry-run --Werror";
        files = "\\.(cpp|hpp|c|h)$";
        pass_filenames = true;
      };
      cpp-lint = {
        enable = true;
        name = "C++ lint";
        entry = "${pkgs.cppcheck}/bin/cppcheck --enable=warning,style --error-exitcode=1";
        files = "\\.(cpp|hpp|c|h)$";
        pass_filenames = true;
      };
    };
  };

  # Linting check for CI
  lintCheck = pkgs.runCommand "cpp-lint-check"
    {
      buildInputs = [ pkgs.clang-tools pkgs.cppcheck ];
    } ''
    cd ${self}
    ${lintApp}/bin/cpp-lint
    touch $out
  '';

in
{
  # Individual components
  inherit devPackage releasePackage devShell;
  inherit devApp releaseApp;
  inherit projectFormatter;

  # Complete flake integration - recommended for most users
  defaultOutputs = {
    devShells.default = devShell;
    packages = {
      default = devPackage;
      dev = devPackage;
      release = releasePackage;
    };
    apps = {
      default = devApp;
      dev = devApp;
      release = releaseApp;
      lint = lintApp;
      check-format = checkFormatApp;
    };
    checks = {
      build-dev = devPackage;
      build-release = releasePackage;
      lint-check = lintCheck;
      pre-commit-check = git-hooks;
    };
    formatter = projectFormatter; # For nix fmt integration
  };
}
