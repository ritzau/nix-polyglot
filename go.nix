{ nixpkgs }:

# Main function that creates Go project outputs for a single system
{ pkgs
, # Pass pkgs directly - no magic!
  self
, # Required for dependency management
  extraBuildTools ? [ ]
, extraGeneralTools ? [ ]
, go ? pkgs.go
, # Build configuration - "debug" or "release"
  buildMode ? "debug"
, # Project name override
  projectName ? null
, # Go module path (e.g., "github.com/user/project")
  modulePath ? null
, # Go version constraint
  goVersion ? "1.22"
,
}:

let
  # Import organizational standard tools and build hooks
  standardTools = import ./lib/standard-tools.nix { inherit pkgs; };
  buildHooks = import ./lib/build-hooks.nix { inherit pkgs; };

  # Use organizational standard tools
  generalTools = standardTools.generalTools;

  # Go-specific build tools (in addition to standard tools)
  buildTools = [
    go
    pkgs.gopls # Go language server
    pkgs.golangci-lint # Go linter
    pkgs.gotools # Go tools (goimports, godoc, etc.)
  ]
  ++ standardTools.commonBuildTools;

  # Add Go-specific development tools
  goDevTools = with pkgs; [
    # Debugging tools
    delve # Go debugger
    # Testing and profiling
    gotest # Better test output
    # Documentation
    gotools
  ];

  # Combine with user extras
  allBuildTools = buildTools ++ goDevTools ++ extraBuildTools;
  allGeneralTools = generalTools ++ extraGeneralTools;

  shellHook = ''
    echo "🐹 Go Development Environment"
    echo ""
    echo "Go version: $(go version)"
    echo ""
    echo "Development commands:"
    echo "  go build           - Build project"
    echo "  go run .           - Run project"
    echo "  go test ./...      - Run tests"
    echo "  go mod tidy        - Tidy dependencies"
    echo "  gofmt -w .         - Format source code"
    echo "  golangci-lint run  - Lint code"
    echo ""
    echo "Available tools:"
    ${pkgs.lib.concatStringsSep "\n" (map (tool: "echo \"  ${tool.pname or tool.name or "unknown"} - ${tool.meta.description or ""}\"") allBuildTools)}
    echo ""
  '';

  # Development shell with comprehensive Go toolchain
  devShell = pkgs.mkShell {
    packages = allBuildTools ++ allGeneralTools ++ [
      # Add glot CLI from self
      self.packages.${pkgs.system}.glot
    ];
    inherit shellHook;
  };

  # Detect project name from go.mod
  detectProjectName = projectPath:
    let
      goModPath = projectPath + "/go.mod";
    in
    if builtins.pathExists goModPath
    then "go-project" # Default name - could be enhanced to parse go.mod
    else "go-project";

  # Actual project name to use
  actualProjectName =
    if projectName != null
    then projectName
    else detectProjectName ./.;

  # Detect module path from go.mod
  actualModulePath =
    if modulePath != null
    then modulePath
    else "example.com/${actualProjectName}";

  # Base build arguments
  baseBuildArgs = {
    pname = actualProjectName;
    version = "0.1.0";
    src = ./.;

    nativeBuildInputs = [ go ];

    # Go build system integration
    buildPhase = ''
      runHook preBuild
      export GOCACHE=$TMPDIR/go-cache
      export GOPATH="$TMPDIR/go"
      export GOPROXY=direct
      export GOSUMDB=off
      
      go build -v -o ${actualProjectName} ${if buildMode == "release" then "-ldflags='-s -w'" else ""}
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp ${actualProjectName} $out/bin/
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Go project built with nix-polyglot";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };

  # Development build - fast compilation, debug info
  devBuild = pkgs.buildGoModule (baseBuildArgs // {
    pname = "${actualProjectName}-dev";
    vendorHash = null; # Let Nix handle vendoring automatically
  });

  # Release build - optimized
  releaseBuild = pkgs.buildGoModule (baseBuildArgs // {
    pname = "${actualProjectName}-release";
    vendorHash = null;
    # Release optimizations are handled in buildPhase
  });

in
{
  # Standard nix-polyglot outputs
  defaultOutputs = {
    packages = {
      default = devBuild;
      dev = devBuild;
      release = releaseBuild;

      # Also expose glot CLI
      glot = self.packages.${pkgs.system}.glot;
    };

    devShells = {
      default = devShell;
    };

    # Apps for running the built programs
    apps = {
      default = {
        type = "app";
        program = "${devBuild}/bin/${actualProjectName}";
      };

      dev = {
        type = "app";
        program = "${devBuild}/bin/${actualProjectName}";
      };

      release = {
        type = "app";
        program = "${releaseBuild}/bin/${actualProjectName}";
      };
    };

    # Use system formatter for Nix files
    formatter = pkgs.nixpkgs-fmt;
  };

  # Language-specific information for glot CLI
  languageInfo = {
    name = "go";
    extensions = [ ".go" ];
    projectFiles = [ "go.mod" "go.sum" ];

    # Commands for glot CLI integration
    commands = {
      build = "go build";
      run = "go run .";
      test = "go test ./...";
      fmt = "gofmt -w .";
      lint = "golangci-lint run";
      clean = "go clean";
    };

    # Project detection
    detect = projectPath:
      builtins.pathExists (projectPath + "/go.mod");
  };
}
