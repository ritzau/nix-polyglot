# Nix Polyglot

A collection of Nix helpers for building projects in various programming languages with ready-to-use templates.

## Quick Start

Generate a new project using one of our templates:

```bash
nix flake new -t github:ritzau/nix-polyglot#rust-cli my-rust-project
nix flake new -t github:ritzau/nix-polyglot#go-cli my-go-project
nix flake new -t github:ritzau/nix-polyglot#python-console my-python-project
```

## Structure

- Language-specific build helpers for 6 programming languages
- Ready-to-use project templates with development environments
- Comprehensive tooling including LSPs, linters, and debuggers

## Supported Languages

### C#

- **Template**: `csharp-console`
- **Features**: .NET SDK, development tools, automatic .csproj detection
- **Tools**: OmniSharp, dotnet CLI, MSBuild

### Rust

- **Template**: `rust-cli`
- **Features**: Cargo integration, clippy linting, rustfmt formatting
- **Tools**: rust-analyzer, cargo tools, clippy

### Python

- **Template**: `python-console`
- **Features**: Poetry/pip support, virtual environment management
- **Tools**: pylsp, black, pytest, mypy

### Go

- **Template**: `go-cli`
- **Features**: Go modules, testing framework, comprehensive tooling
- **Tools**: gopls, golangci-lint, delve debugger, go tools

### Nim

- **Template**: `nim-cli`
- **Features**: Nimble package management, testing support
- **Tools**: nimlsp, nim compiler and tools

### Zig

- **Template**: `zig-cli`
- **Features**: Native build system, cross-compilation support
- **Tools**: zls (Zig Language Server), zig compiler

## Available Templates

| Language | Template Name    | Description                         |
| -------- | ---------------- | ----------------------------------- |
| C#       | `csharp-console` | Console application with .NET SDK   |
| Rust     | `rust-cli`       | Command-line application with Cargo |
| Python   | `python-console` | Console application with testing    |
| Go       | `go-cli`         | CLI application with Go modules     |
| Nim      | `nim-cli`        | Command-line tool with Nimble       |
| Zig      | `zig-cli`        | CLI application with native build   |

## Template Usage

Create a new project from a template:

```bash
# Create a new Rust CLI project
nix flake new -t github:ritzau/nix-polyglot#rust-cli my-project
cd my-project

# Enter development environment
nix develop

# Build and run (example for Rust)
cargo build
cargo run -- --help
```

## Library Usage

Use language helpers directly in your flake:

```nix
{
  description = "My project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nix-polyglot.url = "github:ritzau/nix-polyglot";
  };

  outputs = { self, nixpkgs, nix-polyglot }:
    let
      # Available: csharpProject, rustProject, pythonProject,
      #           goProject, nimProject, zigProject
      project = nix-polyglot.lib.rustProject;
    in
      project {
        inherit self;
        # Optional customizations:
        # extraBuildTools = [ ];
        # extraGeneralTools = [ ];
        # shellHook = "echo \"Custom shell hook\"";
      };
}
```

## Development

This repository uses Nix flakes. Run `nix develop` to enter the development shell with all tools needed for contributing to this project.
