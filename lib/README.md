# Organizational Standard Tools

This directory contains shared modules that define organizational standards for development environments.

## Files

### `standard-tools.nix`

Defines the **single source of truth** for development tools used across all language environments.

**Tool Categories:**

- **`generalTools`**: Core utilities available in all environments (tree, bat, bottom, jq, etc.)
- **`commonBuildTools`**: Build utilities that benefit multiple languages (figlet, make, pkg-config, etc.)
- **`securityTools`**: Organizational security and compliance tools
- **`shellTools`**: Shell and terminal enhancements (zsh, bash, tmux, fzf)
- **`docTools`**: Documentation and help utilities (pandoc, man-pages)

**Usage in Language Files:**

```nix
let
  standardTools = import ./lib/standard-tools.nix { inherit pkgs; };
in {
  # Use organizational standard tools
  generalTools = standardTools.generalTools;
  
  # Language-specific tools + common build tools
  buildTools = [
    # language-specific tools here
  ] ++ standardTools.commonBuildTools;
}
```

**Benefits:**

1. **Consistent Experience**: Same tools available across all language projects
2. **Central Updates**: Change tool versions in one place, affects all projects
3. **Organizational Standards**: Enforce company-wide tooling policies
4. **Reduced Duplication**: No copy-paste tool definitions across language files

## Adding New Standard Tools

1. Edit `standard-tools.nix`
2. Add tools to the appropriate category
3. Test with existing language implementations
4. All projects using nix-polyglot automatically get the new tools

## Organizational Policy

- All language environments MUST use `standardTools.generalTools`
- Language-specific tools should extend, not replace, standard tools  
- Changes to standard tools require review (affects all projects)
- Security tools are mandatory and cannot be disabled by individual projects