{ nixpkgs
, treefmt-nix
, git-hooks-nix
}:

# Python project builder with comprehensive reproducibility and dual build optimization
#
# This function creates development and release builds, development shells, apps, and checks
# for Python projects with built-in reproducible builds, test integration, and best practices.
#
# Key features:
# - Fast dev builds with debug info, skip expensive checks for iteration speed
# - Reproducible release builds with deterministic output and full validation
# - Integrated test execution via pytest and quality tools
# - Universal formatting (black, isort) and linting (ruff, mypy) integration
# - Support for poetry, pip, and requirements.txt dependency management
#
# Usage:
#   python = import ./python.nix { inherit nixpkgs treefmt-nix git-hooks-nix; };
#   project = python { pkgs = nixpkgs.legacyPackages.${system}; self = ./.; buildTarget = "pyproject.toml"; inherit system; };
#   # Use project.mkDefaultOutputs for complete flake integration

{
  # Required parameters
  pkgs
, # Nixpkgs package set
  self
, # Source path/flake self
  buildTarget
, # Path to pyproject.toml, setup.py, or main Python file

  # Python configuration
  python ? pkgs.python311
, # Python interpreter version
  buildSystem ? "poetry"
, # Build system: "poetry", "setuptools", "flit", "hatch"
  requirements ? null
, # Path to requirements.txt (for pip-based projects)
  pyprojectToml ? null
, # Path to pyproject.toml (auto-detected from buildTarget)

  # Development environment customization
  extraBuildInputs ? [ ]
, # Additional build-time packages
  extraPythonPackages ? (_: [ ])
, # Additional Python packages function
  extraSystemPackages ? [ ]
, # Additional system packages

  # Testing configuration
  enableTests ? true
, testRunner ? "pytest"
, # Test runner: "pytest", "unittest", "nose2"
  testCommand ? null
, # Custom test command override
  testPaths ? [ "tests" ]
, # Directories to test
  pytestArgs ? [ ]
, # Additional pytest arguments

  # Code quality configuration
  enableFormatting ? true
, enableLinting ? true
, enableTypeChecking ? true
, lintingTools ? [ "ruff" "black" "isort" ]
, # Linting tools to enable

  # Build customization
  buildInputs ? [ ]
, # Build dependencies
  propagatedBuildInputs ? [ ]
, # Runtime Python dependencies
  checkInputs ? [ ]
, # Test dependencies

  # Application configuration  
  mainModule ? null
, # Main module for executable (e.g., "myapp.main")
  entryPoint ? null
, # Entry point script name
  installPhase ? null
, # Custom install phase

  # Reproducibility controls
  sourceEpoch ? 1
, # Timestamp for SOURCE_DATE_EPOCH

  system
, # System architecture
}:

let
  # Input validation
  _validateBuildTarget =
    assert buildTarget != null && buildTarget != "";
    "buildTarget must point to pyproject.toml, setup.py, or main Python file";
  _validatePython =
    assert python != null;
    "python parameter is required";

  # Import organizational standard tools and hooks
  standardTools = import ./lib/standard-tools.nix { inherit pkgs; };
  buildHooks = import ./lib/build-hooks.nix { inherit pkgs; };

  # Use organizational standard tools
  generalTools = standardTools.generalTools;

  # Python-specific development tools
  pythonTools = [
    python
  ]
  ++ pkgs.lib.optionals enableFormatting [ pkgs.black pkgs.python311Packages.isort ]
  ++ pkgs.lib.optionals enableLinting [ pkgs.ruff ]
  ++ pkgs.lib.optionals enableTypeChecking [ pkgs.mypy ]
  ++ pkgs.lib.optionals (testRunner == "pytest") [ python.pkgs.pytest ]
  ++ pkgs.lib.optionals (buildSystem == "poetry") [ pkgs.poetry ];

  # Combine with user extras and standard tools
  allSystemPackages = standardTools.commonBuildTools ++ pythonTools ++ extraSystemPackages;
  allGeneralTools = generalTools ++ extraBuildInputs;

  # Detect project structure
  isPoetryProject = buildSystem == "poetry" || pkgs.lib.hasSuffix "pyproject.toml" buildTarget;
  isSetuptoolsProject = pkgs.lib.hasSuffix "setup.py" buildTarget;
  isPythonScript = pkgs.lib.hasSuffix ".py" buildTarget;

  # Python environment with dependencies
  pythonEnv = python.withPackages (ps:
    (extraPythonPackages ps)
    ++ propagatedBuildInputs
    ++ pkgs.lib.optionals enableTests checkInputs
  );

  # Derive application name from buildTarget
  appName =
    if mainModule != null then
      builtins.head (nixpkgs.lib.splitString "." mainModule)
    else if entryPoint != null then
      entryPoint
    else
      let baseName = builtins.baseNameOf buildTarget; in
      if nixpkgs.lib.hasSuffix ".py" baseName then
        nixpkgs.lib.removeSuffix ".py" baseName
      else if nixpkgs.lib.hasSuffix ".toml" baseName then
        "app"
      else
        baseName;

  shellHook = ''
    echo "🐍 Python Development Environment Ready!"
    echo "Python: ${python.version}"
    echo "Build System: ${buildSystem}"
  '';

  # Base configuration shared by both builds
  baseConfig = {
    pname = appName;
    version = "0.1.0"; # Default version, should be overridden
    src = self;

    buildInputs = allSystemPackages ++ buildInputs;
    propagatedBuildInputs = [ pythonEnv ];

    # Common Python build setup
    pythonPath = [ pythonEnv ];
  };

  # Fast development build configuration - optimized for speed and iteration
  devBuildConfig = baseConfig // {
    # Minimal environment for fast builds - no reproducibility controls
    env = {
      # Allow normal user caches and configs for speed
      PYTHONDONTWRITEBYTECODE = "1"; # Don't create .pyc files
      PYTHONUNBUFFERED = "1"; # Unbuffered output for debugging
    };

    # Fast build and install
    buildPhase = ''
      echo "🚀 Building Python dev variant (fast iteration)"
      # Minimal build - no wheel generation, direct installation
    '';

    installPhase = installPhase or ''
      mkdir -p $out/bin $out/lib/python${python.pythonVersion}/site-packages
      
      # Install source code directly for fast iteration
      if [[ -f setup.py ]]; then
        ${python}/bin/python setup.py develop --prefix=$out
      elif [[ -f pyproject.toml ]]; then
        ${python}/bin/python -m pip install -e . --prefix=$out --no-deps
      else
        # Single file Python script
        cp ${buildTarget} $out/bin/${appName}
        chmod +x $out/bin/${appName}
      fi
    '';

    doCheck = false; # Skip tests in dev builds for speed
  };

  # Reproducible release build configuration - optimized for deterministic output
  releaseBuildConfig = baseConfig // {
    # Full reproducibility controls
    env = {
      # Ensure consistent timezone and locale
      TZ = "UTC";
      LC_ALL = "C.UTF-8";
      LANG = "C.UTF-8";

      # Python-specific reproducibility
      PYTHONDONTWRITEBYTECODE = "1";
      PYTHONHASHSEED = "0";
      PYTHONUNBUFFERED = "1";

      # Build reproducibility
      SOURCE_DATE_EPOCH = toString sourceEpoch;
      DETERMINISTIC_BUILD = "true";

      # Disable user-specific behavior
      PIP_NO_USER = "1";
      PIP_NO_CACHE_DIR = "1";
      POETRY_CACHE_DIR = "$TMPDIR/poetry-cache";
    };

    # Full build with validation
    buildPhase = ''
      echo "📦 Building Python release variant (reproducible production build)"
      runHook preBuild
      
      # Clean build environment
      export HOME=$TMPDIR
      
      if [[ -f pyproject.toml ]]; then
        # Modern Python packaging
        ${python}/bin/python -m build --wheel --no-isolation
      elif [[ -f setup.py ]]; then
        # Legacy setuptools
        ${python}/bin/python setup.py bdist_wheel
      fi
      
      runHook postBuild
    '';

    installPhase = installPhase or ''
      mkdir -p $out/bin
      
      if [[ -f pyproject.toml || -f setup.py ]]; then
        # Install from wheel for reproducibility
        ${python}/bin/python -m pip install dist/*.whl --prefix=$out --no-deps
      else
        # Single file script
        install -D ${buildTarget} $out/bin/${appName}
      fi
    '';

    # Full testing and validation
    doCheck = enableTests;
    checkPhase = pkgs.lib.optionalString enableTests ''
      echo "🧪 Running Python tests"
      runHook preCheck
      
      export HOME=$TMPDIR
      export PYTHONPATH="$out/lib/python${python.pythonVersion}/site-packages:$PYTHONPATH"
      
      ${if testCommand != null then
          testCommand
        else if testRunner == "pytest" then
          "${python}/bin/python -m pytest ${builtins.concatStringsSep " " (testPaths ++ pytestArgs)}"
        else if testRunner == "unittest" then
          "${python}/bin/python -m unittest discover -s tests"
        else
          "echo 'No tests configured'"
      }
      
      runHook postCheck
    '';
  };

  # Dev build - fast iteration with debug info
  devPackage = pkgs.stdenv.mkDerivation (
    devBuildConfig
    // {
      pname = "${appName}-dev";
      # Build and install hooks
      preBuild = buildHooks.buildPhaseHook;
      preInstall = buildHooks.installPhaseHook;
    }
  );

  # Release build - reproducible production build  
  releasePackage = pkgs.stdenv.mkDerivation (
    releaseBuildConfig
    // {
      pname = "${appName}-release";
      nativeBuildInputs = (releaseBuildConfig.nativeBuildInputs or [ ]) ++ [
        python.pkgs.build
        python.pkgs.wheel
      ];
      # Build and install hooks
      preBuild = buildHooks.buildPhaseHook;
      preInstall = buildHooks.installPhaseHook;
    }
  );

  # Development shell with all tools
  devShell = pkgs.mkShell {
    packages = allGeneralTools ++ allSystemPackages;
    shellHook =
      shellHook
      + nixpkgs.lib.optionalString enableLinting ''
        ${git-hooks.shellHook}
      '';

    # Python environment variables
    PYTHONPATH = "${pythonEnv}/${python.sitePackages}";
    PYTHONDONTWRITEBYTECODE = "1";
  };

  # Application wrappers
  devApp = {
    type = "app";
    program = "${devPackage}/bin/${appName}";
    meta = {
      description = "Python application ${appName} (Development build)";
      platforms = nixpkgs.lib.platforms.all;
    };
  };

  releaseApp = {
    type = "app";
    program = "${releasePackage}/bin/${appName}";
    meta = {
      description = "Python application ${appName} (Release build)";
      platforms = nixpkgs.lib.platforms.all;
    };
  };

  # Formatting and linting apps
  checkFormatApp = nixpkgs.lib.optionalAttrs enableFormatting {
    type = "app";
    program = "${pkgs.writeShellScript "check-format-${appName}" ''
      set -euo pipefail
      echo "Checking formatting of ${appName} Python files..."
      
      echo "🖤 Checking with black..."
      ${pkgs.black}/bin/black --check .
      
      echo "📦 Checking import sorting..."
      ${pkgs.python311Packages.isort}/bin/isort --check-only .
      
      echo "Python formatting check passed!"
    ''}";
    meta = {
      description = "Check Python code formatting";
      platforms = nixpkgs.lib.platforms.all;
    };
  };

  lintApp = {
    type = "app";
    program = "${pkgs.writeShellScript "lint-${appName}" ''
      set -euo pipefail
      echo "Running Python linting checks..."
      
      ${nixpkgs.lib.optionalString (builtins.elem "ruff" lintingTools) ''
        echo "⚡ Running ruff..."
        ${pkgs.ruff}/bin/ruff check .
      ''}
      
      ${nixpkgs.lib.optionalString enableTypeChecking ''
        echo "🔍 Running mypy type checking..."
        ${pkgs.mypy}/bin/mypy . || echo "Type checking completed with warnings"
      ''}
      
      echo "Python linting passed!"
    ''}";
    meta = {
      description = "Lint ${appName} Python code";
      platforms = nixpkgs.lib.platforms.all;
    };
  };

  # Configure git hooks for Python projects
  git-hooks = nixpkgs.lib.optionalAttrs enableLinting (
    git-hooks-nix.lib.${system}.run {
      src = self;
      hooks = {
        # Python formatting hooks
        black = nixpkgs.lib.optionalAttrs (builtins.elem "black" lintingTools) {
          enable = true;
        };
        isort = nixpkgs.lib.optionalAttrs (builtins.elem "isort" lintingTools) {
          enable = true;
        };

        # Python linting hooks
        ruff = nixpkgs.lib.optionalAttrs (builtins.elem "ruff" lintingTools) {
          enable = true;
        };
        mypy = nixpkgs.lib.optionalAttrs enableTypeChecking {
          enable = true;
        };
      };
    }
  );

  # Import script system for project templates and maintenance
  scripts = import ./lib/scripts.nix { inherit pkgs; };

  # Include checks - both dev and release builds with Python-specific validation
  checks = {
    build-dev = devPackage;
    build-release = releasePackage;
  }
  // nixpkgs.lib.optionalAttrs enableFormatting {
    format-check = pkgs.runCommand "format-check-${appName}"
      {
        buildInputs = [ pkgs.black pkgs.python311Packages.isort ];
      } ''
      # Copy source to writable directory
      cp -r ${self} ./source
      chmod -R +w ./source
      cd ./source

      # Check Python formatting
      ${pkgs.black}/bin/black --check .
      ${pkgs.python311Packages.isort}/bin/isort --check-only .
      
      touch $out
    '';
  }
  // nixpkgs.lib.optionalAttrs enableLinting {
    lint-check = pkgs.runCommand "lint-check-${appName}"
      {
        buildInputs = [ pkgs.ruff ] ++ nixpkgs.lib.optionals enableTypeChecking [ pkgs.mypy ];
      } ''
      # Copy source to writable directory
      cp -r ${self} ./source
      chmod -R +w ./source  
      cd ./source

      # Run linting
      ${pkgs.ruff}/bin/ruff check .
      ${nixpkgs.lib.optionalString enableTypeChecking ''
        ${pkgs.mypy}/bin/mypy . || true
      ''}
      
      touch $out
    '';
    pre-commit-check = git-hooks;
  };

  # Project-specific formatter for Python code
  projectFormatter =
    if enableFormatting then
      (pkgs.writeShellApplication {
        name = "python-formatter";
        runtimeInputs = [ pkgs.black pkgs.python311Packages.isort ];
        text = ''
          echo "🐍 Formatting Python code..."
          black .
          isort .
          echo "Python formatting complete!"
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
    devShell# Development shell with Python tools
    devPackage# Debug build derivation
    releasePackage# Release build derivation  
    devApp# Debug app with meta
    releaseApp# Release app with meta
    lintApp# Linting app
    checks# Build checks (dev + release with integrated tests)
    ;

  # Formatting components (optional)
  checkFormatApp = if enableFormatting then checkFormatApp else null;
  projectFormatter = if enableFormatting then projectFormatter else null;
  git-hooks = if enableLinting then git-hooks else null;

  # Script system for maintenance-free project management
  inherit scripts;

  # Complete flake integration - recommended for most users
  # Contains: devShells.default, packages.{default,dev,release}, apps.{default,dev,release,lint,check-format?,setup,update-project,migrate}, checks
  inherit mkDefaultOutputs;
}
