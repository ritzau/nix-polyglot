# Template Formatting Playbook

This document explains how to format template files in nix-polyglot using their native development environments.

## Problem

Templates need to be properly formatted, but the main nix-polyglot repository doesn't contain the language-specific development environments needed to format each template's code (C#, Rust, etc.). Setting up all possible formatters in the main repo would be complex and unnecessary.

## Solution

We use a **formatting playbook** that:

1. Generates temporary projects from each template
2. Enters each project's `nix develop` environment
3. Runs the project's native formatters (`just fmt`, `nix fmt`)
4. Copies the formatted files back to the template

## Usage

### Using the Flake App (Recommended)

```bash
# Format all templates interactively
nix run .#format-templates

# From outside the repo
nix run github:your-org/nix-polyglot#format-templates
```

### Using the Script Directly

```bash
# Make executable (first time only)
chmod +x scripts/format-templates.sh

# Run the formatting playbook
./scripts/format-templates.sh
```

## What It Does

The playbook:

1. **Discovers all templates** by finding `template.nix` files
2. **Asks for confirmation** before proceeding
3. **For each template:**
   - Creates a temporary project using the template
   - Updates the flake to use local nix-polyglot
   - Enters `nix develop` environment
   - Runs `just fmt` or `nix fmt`
   - Copies formatted files back to the template directory
4. **Shows a summary** of results
5. **Reminds you to commit** the changes

## Supported Templates

- **C# Console**: Formats `.cs`, `.csproj`, and configuration files
- **Rust CLI**: Formats `.rs`, `Cargo.toml`, and configuration files
- **Common files**: `flake.nix`, `justfile`, `.editorconfig`

## Example Output

```
🎨 Template Formatting Playbook
===============================
🔍 Discovering templates...
   Found: csharp/console
   Found: rust/cli
📊 Found 2 templates

🤔 Do you want to format all templates? (y/N): y

🚀 Starting template formatting...

📁 Processing template: csharp/console
   📋 Generating test project...
   🔧 Entering development environment and formatting...
   📝 Running formatter...
   ✅ Formatting completed with just fmt
   📤 Copying formatted files back to template...
   ✅ Template formatting successful

📁 Processing template: rust/cli
   📋 Generating test project...
   🔧 Entering development environment and formatting...
   📝 Running formatter...
   ✅ Formatting completed with just fmt
   📤 Copying formatted files back to template...
   ✅ Template formatting successful

=========================================
📊 Formatting Summary
   Total templates: 2
   Successfully formatted: 2

📝 Remember to commit the formatted template changes!
   git add templates/
   git commit -m "Format template files using development environments"

✅ Template formatting playbook completed!
```

## Integration with CI/CD

You can integrate this into your development workflow:

```bash
# Before committing template changes
nix run .#format-templates

# Check if templates need formatting (exits with error if changes needed)
nix run .#format-templates --check  # Future enhancement
```

## Benefits

1. **Native formatting**: Each template is formatted using its own language tools
2. **No environment pollution**: Main repo doesn't need all language formatters
3. **Maintainable**: Easy to add new languages without touching formatter config
4. **Consistent**: Same formatting that projects will use in development
5. **Interactive**: Shows progress and asks for confirmation
6. **Safe**: Uses temporary directories, doesn't modify templates until confirmed

## Future Enhancements

- `--check` mode for CI to verify formatting
- `--template <name>` to format specific templates only
- Support for more languages as templates are added
- Integration with pre-commit hooks for template directories
