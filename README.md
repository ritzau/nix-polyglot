# Nix Polyglot

A collection of Nix helpers for building projects in various programming
languages.

## Structure

- `languages/` - Language-specific build helpers
- `lib/` - Higher-level project builders and utilities

## Supported Languages

### C#

The C# helpers provide:

- Development shell with .NET SDK and tools
- Package builder with automatic .csproj detection
- Customizable build and install phases

#### Usage

```nix
{
  description = "My C# project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-polyglot.url = "github:youruser/nix-polyglot";  # Update with actual repo
  };

  outputs = { self, nixpkgs, flake-utils, nix-polyglot }:
    let
      csharpProject = nix-polyglot.lib.csharpProject;
    in
      csharpProject {
        inherit self;
        # Optional customizations:
        # extraBuildTools = [ ];
        # extraGeneralTools = [ ];
        # shellHook = "echo \"Custom shell hook\"";
      };
}
```

## Development

This repository uses Nix flakes. Run `nix develop` to enter the development
shell.
