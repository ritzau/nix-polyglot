# Cross-Compilation Support

**Status**: Future Enhancement  
**Complexity**: 3/10 (Simple with nix patterns)  
**Priority**: Medium

## Overview

Add cross-compilation support to glot CLI with `--target` flag, enabling builds for different architectures and platforms while maintaining the single binary approach.

## Design Goals

- **Zero breaking changes**: Default behavior unchanged
- **Single glot binary**: Always runs on dev host architecture
- **Standard nix patterns**: Leverage `pkgsCross` and existing tooling
- **Emulation support**: Basic testing of cross-compiled outputs
- **Simple interface**: Just add `--target` flag to build/run commands

## User Interface

### Basic Usage

```bash
# Current behavior (unchanged)
glot build                    # Build for dev host
glot run                      # Run on dev host

# New cross-compilation support
glot build --target=aarch64-linux     # Cross-compile for ARM64 Linux
glot build --target=x86_64-darwin     # Cross-compile for Intel Mac
glot run --target=aarch64-linux       # Run with emulation (if possible)
```

### Supported Targets

Standard nix cross-compilation targets:

```bash
# Linux targets
--target=x86_64-linux         # Intel/AMD Linux
--target=aarch64-linux        # ARM64 Linux
--target=armv7l-linux         # ARM32 Linux

# macOS targets
--target=x86_64-darwin        # Intel Mac
--target=aarch64-darwin       # Apple Silicon Mac

# Windows targets (if supported by language)
--target=x86_64-windows       # Windows x64
--target=i686-windows         # Windows x86
```

### Target Discovery

```bash
glot targets                  # List available targets for current project
glot targets --language=rust # List targets for specific language
```

## Implementation Architecture

### Command Line Changes

```go
// Add target flag to build command
var buildCmd = &cobra.Command{
    Use: "build [target] [flags]",
    RunE: func(cmd *cobra.Command, args []string) error {
        target := cmd.Flag("target").Value.String()
        if target != "" {
            return buildWithTarget(target, args)
        }
        return buildDefault(args)
    },
}

func init() {
    buildCmd.Flags().String("target", "", "Cross-compilation target (e.g., aarch64-linux)")
    runCmd.Flags().String("target", "", "Cross-compilation target for execution")
}
```

### Nix Integration

```nix
# In language modules, add cross-compilation support
{ pkgs, lib, system }:

let
  # Helper to get cross-compilation pkgs
  getCrossPkgs = target:
    if target == null || target == system
    then pkgs
    else pkgs.pkgsCross.${target} or (throw "Unsupported target: ${target}");

  mkProject = { self, target ? null, ... }:
    let
      crossPkgs = getCrossPkgs target;
      targetSuffix = if target == null then "" else "-${target}";
    in {
      packages = {
        "default${targetSuffix}" = crossPkgs.buildRustPackage {
          name = "rust-project${targetSuffix}";
          src = ./.;
          # Cross-compilation happens automatically with crossPkgs
        };
      };
    };
```

### Flake Output Structure

```nix
# Generated outputs for cross-compilation
packages = {
  # Default (host) builds
  default = rustProject;
  dev = rustProject;
  release = rustProjectRelease;

  # Cross-compilation builds (when --target used)
  "default-aarch64-linux" = rustProjectAarch64Linux;
  "default-x86_64-darwin" = rustProjectX86Darwin;
  "release-aarch64-linux" = rustProjectAarch64LinuxRelease;
  # ... other target combinations
};
```

### CLI Target Resolution

```go
func buildWithTarget(target string, args []string) error {
    // Validate target
    if !isValidTarget(target) {
        return fmt.Errorf("unsupported target: %s", target)
    }

    // Build package name with target suffix
    variant := getVariant(args) // "dev" or "release"
    packageName := fmt.Sprintf("%s-%s", variant, target)

    // Execute nix build
    return runNix("build", fmt.Sprintf(".#%s", packageName))
}

func runWithTarget(target string, args []string) error {
    // Check if emulation is available
    if !canEmulate(target) {
        return fmt.Errorf("cannot run %s binaries on %s", target, runtime.GOARCH)
    }

    // Run with emulation (rosetta, qemu, etc.)
    variant := getVariant(args)
    packageName := fmt.Sprintf("%s-%s", variant, target)

    return runNix("run", fmt.Sprintf(".#%s", packageName), "--", args...)
}
```

## Language-Specific Considerations

### Rust

```nix
# Rust has excellent cross-compilation support
rustProject = { target ? null, ... }: {
  packages.default = pkgs.rustPlatform.buildRustPackage {
    name = "rust-app";
    src = ./.;

    # Rust cross-compilation is handled by cargo
    target = target;

    # Some targets may need additional configuration
    CARGO_BUILD_TARGET = target;
  };
};
```

### Python

```nix
# Python cross-compilation is more limited
pythonProject = { target ? null, ... }: {
  packages.default =
    if target != null && target != system
    then throw "Python cross-compilation not fully supported yet"
    else pkgs.python3Packages.buildPythonApplication {
      name = "python-app";
      src = ./.;
    };
};
```

### C#

```nix
# .NET has good cross-compilation support
csharpProject = { target ? null, ... }:
let
  dotnetRuntime = if target == null then pkgs.dotnet-runtime
                  else pkgs.dotnet-runtime.override { inherit target; };
in {
  packages.default = pkgs.buildDotnetModule {
    name = "csharp-app";
    src = ./.;
    runtimeId = target;
  };
};
```

## Configuration

### Project-Level Configuration

```nix
# In project flake.nix - specify supported targets
{
  # Standard nix-polyglot configuration
  language = "rust";

  # Cross-compilation configuration
  crossCompilation = {
    enabled = true;
    targets = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    # Target-specific overrides
    targetOverrides = {
      "aarch64-linux" = {
        # Custom build flags for ARM64
        CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "aarch64-linux-gnu-gcc";
      };
    };
  };
}
```

### Global Configuration

```toml
# ~/.config/glot/config.toml (future)
[cross-compilation]
default-targets = [
    "x86_64-linux",
    "aarch64-linux",
    "x86_64-darwin",
    "aarch64-darwin"
]

[emulation]
enable-qemu = true
enable-rosetta = true
```

## Error Handling

### Unsupported Target

```bash
$ glot build --target=unsupported-arch
❌ Error: Unsupported target 'unsupported-arch'

Available targets for rust projects:
  x86_64-linux    - Intel/AMD Linux
  aarch64-linux   - ARM64 Linux
  x86_64-darwin   - Intel macOS
  aarch64-darwin  - Apple Silicon macOS

Use 'glot targets' to see all available targets.
```

### Language Limitations

```bash
$ glot build --target=aarch64-linux  # In Python project
❌ Error: Cross-compilation not supported for python projects

Python cross-compilation has limited support in nix.
Consider using Docker or language-specific tools for cross-platform builds.
```

## Implementation Phases

### Phase 1: Core Infrastructure (1-2 weeks)

- Add `--target` flag to build/run commands
- Implement target validation and mapping
- Basic nix integration with `pkgsCross`

### Phase 2: Language Integration (2-3 weeks)

- Update Rust support (excellent cross-compilation)
- Add C# support (good cross-compilation)
- Document Python limitations

### Phase 3: Enhanced Features (1-2 weeks)

- Add `glot targets` command
- Emulation detection and support
- Better error messages and guidance

### Phase 4: Configuration & Polish (1 week)

- Project-level target configuration
- Performance optimizations
- Documentation and examples

## Testing Strategy

### Cross-Platform CI

```yaml
# .github/workflows/cross-compile.yml
name: Cross Compilation
on: [push, pull_request]

jobs:
  cross-compile:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        target:
          - x86_64-linux
          - aarch64-linux
          - x86_64-darwin
          - aarch64-darwin

    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v22
      - name: Cross-compile for ${{ matrix.target }}
        run: |
          nix develop --command glot build --target=${{ matrix.target }}

      - name: Test emulation (Linux only)
        if: runner.os == 'Linux' && matrix.target == 'aarch64-linux'
        run: |
          nix develop --command glot run --target=${{ matrix.target }} -- --help
```

### Manual Testing

```bash
# Test matrix for each language
./test-cross-compilation.sh rust
./test-cross-compilation.sh python
./test-cross-compilation.sh csharp

# Test specific target combinations
glot build --target=aarch64-linux
file result/bin/*  # Verify architecture

# Test emulation where available
glot run --target=aarch64-linux -- --version
```

## Benefits

### For Developers

- **Simple interface**: Just add `--target` flag
- **Familiar workflow**: Same commands, different targets
- **Nix reliability**: Leverages battle-tested nix cross-compilation

### For Teams

- **CI/CD integration**: Build for multiple targets in pipeline
- **Deployment flexibility**: Target different production environments
- **Development consistency**: Same tooling for all targets

### For Distribution

- **Multi-platform releases**: Single workflow for all platforms
- **ARM support**: First-class support for ARM64 servers/devices
- **Apple Silicon**: Native builds for M1/M2 Macs

## Future Extensions

### Advanced Targeting

```bash
glot build --target=wasm32-wasi      # WebAssembly
glot build --target=riscv64-linux    # RISC-V
glot build --target=aarch64-android  # Android
```

### Build Matrix

```bash
glot build --all-targets             # Build for all supported targets
glot build --targets=linux           # Build for all Linux targets
```

### Container Integration

```bash
glot build --target=aarch64-linux --container  # Build in container
glot deploy --target=aarch64-linux             # Deploy to target
```

## Documentation Updates Needed

- User Guide: Add cross-compilation section
- API Reference: Document `--target` flag
- Examples: Add cross-compilation workflows
- FAQ: Common cross-compilation issues

## Compatibility

- **Backward compatible**: No changes to existing commands
- **Nix version**: Requires nix with `pkgsCross` support
- **Platform support**: Depends on nix cross-compilation capabilities

---

This design provides a simple, powerful cross-compilation system that fits naturally into the existing glot workflow while leveraging nix's robust cross-compilation infrastructure.
