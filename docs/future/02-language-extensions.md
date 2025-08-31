# Language Extension System

**Status**: Future Enhancement  
**Complexity**: 6/10 (Moderate - requires plugin architecture)  
**Priority**: High (enables ecosystem growth)

## Overview

Design a pluggable language extension system that allows third-party developers to add support for new programming languages without contributing to the core nix-polyglot repository.

## Vision

Enable a rich ecosystem where language communities can create and maintain their own nix-polyglot extensions:

```bash
# Community extensions
glot add-extension github:golang-community/nix-polyglot-go
glot add-extension github:zig-org/nix-polyglot-zig
glot add-extension github:ruby-community/nix-polyglot-ruby

# Then use them seamlessly
glot new go my-web-server
glot new zig my-systems-tool
glot new ruby my-web-app
```

## Architecture Design

### Configuration System

#### Global Configuration File

```toml
# ~/.config/glot/config.toml
[core]
version = "1.2.0"

[extensions]
# Core extensions (built-in)
rust = { source = "builtin", version = "1.2.0" }
python = { source = "builtin", version = "1.2.0" }
csharp = { source = "builtin", version = "1.2.0" }

# Community extensions
go = { source = "github:golang-community/nix-polyglot-go", version = "1.0.0" }
zig = { source = "github:zig-org/nix-polyglot-zig", version = "0.5.0" }
ruby = { source = "github:ruby-community/nix-polyglot-ruby", version = "2.1.0" }

[repositories]
# Extension repositories
golang-community = "github:golang-community/nix-polyglot-extensions"
zig-org = "github:zig-org/nix-polyglot-extensions"
```

#### Project Configuration

```toml
# project/.glot/config.toml (optional project-specific overrides)
[extensions]
# Use specific versions for this project
go = { source = "github:golang-community/nix-polyglot-go", version = "1.0.0", pin = true }
custom-lang = { source = "path:/home/user/my-language-extension" }
```

### Extension Repository Structure

Standard structure for language extension repositories:

```
nix-polyglot-go/                    # Extension repository
├── flake.nix                       # Main extension interface
├── extension.toml                  # Extension metadata
├── lib/
│   ├── go.nix                     # Language implementation
│   ├── commands.nix               # Language-specific commands
│   └── detection.nix              # Project detection logic
├── templates/
│   ├── cli/                       # Go CLI template
│   │   ├── template.nix
│   │   ├── flake.nix
│   │   ├── .envrc
│   │   ├── main.go
│   │   └── go.mod
│   ├── web-server/                # Go web server template
│   └── microservice/              # Go microservice template
├── samples/
│   ├── cli-example/               # Working examples
│   └── web-example/
├── tests/
│   └── integration-test.sh        # Extension tests
├── docs/
│   └── README.md                  # Language-specific documentation
└── README.md                      # Extension overview
```

### Extension Metadata

```toml
# extension.toml - Extension metadata
[extension]
name = "go"
version = "1.0.0"
description = "Go language support for nix-polyglot"
author = "Golang Community"
homepage = "https://github.com/golang-community/nix-polyglot-go"
license = "MIT"

[compatibility]
nix-polyglot = ">=1.2.0"
nix = ">=2.8.0"

[language]
name = "go"
display-name = "Go"
file-extensions = [".go", "go.mod", "go.sum"]
project-files = ["go.mod"]
entry-points = ["main.go", "cmd/*/main.go"]

[features]
cross-compilation = true
hot-reload = false
debugging = true
profiling = true

[templates]
default = "cli"
available = ["cli", "web-server", "microservice"]

[commands]
build = "go build"
run = "go run"
test = "go test ./..."
fmt = "go fmt ./..."
lint = "golangci-lint run"
```

### Extension Interface

```nix
# Extension flake.nix interface
{
  description = "Go language extension for nix-polyglot";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-polyglot.url = "github:ritzau/nix-polyglot";
  };

  outputs = { self, nixpkgs, nix-polyglot, ... }:
    nix-polyglot.lib.mkLanguageExtension {
      # Extension metadata
      name = "go";
      version = "1.0.0";

      # Language implementation
      language = { pkgs, lib, system }: {
        # Project detection
        detect = projectPath:
          builtins.pathExists (projectPath + "/go.mod");

        # Build configuration
        mkProject = { pkgs, self, system, ... }: {
          packages = {
            default = pkgs.buildGoModule {
              name = "go-project";
              src = ./.;
              vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
            };

            release = pkgs.buildGoModule {
              name = "go-project-release";
              src = ./.;
              vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
              CGO_ENABLED = 0;
              ldflags = [ "-s" "-w" ];
            };
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              go
              gopls              # Language server
              golangci-lint      # Linter
              delve             # Debugger
            ];
          };
        };

        # Language-specific commands
        commands = {
          fmt = { command = "go fmt ./..."; description = "Format Go code"; };
          lint = { command = "golangci-lint run"; description = "Lint Go code"; };
          test = { command = "go test ./..."; description = "Run Go tests"; };
          mod-tidy = { command = "go mod tidy"; description = "Clean up go.mod"; };
        };

        # File associations
        fileExtensions = [ ".go" ];
        projectFiles = [ "go.mod" "go.sum" ];

        # Cross-compilation support
        crossCompilation = {
          supported = true;
          targets = [
            "linux/amd64" "linux/arm64"
            "darwin/amd64" "darwin/arm64"
            "windows/amd64"
          ];
        };
      };

      # Templates provided by this extension
      templates = ./templates;

      # Sample projects for testing/examples
      samples = ./samples;
    };
}
```

## Core System Changes

### Extension Management Commands

```bash
# Extension management
glot extensions list                    # List installed extensions
glot extensions search go              # Search available extensions
glot extensions add golang-community/go # Add extension
glot extensions remove go              # Remove extension
glot extensions update go              # Update specific extension
glot extensions update --all           # Update all extensions

# Extension information
glot extensions info go                # Show extension details
glot extensions verify go              # Verify extension integrity
```

### Enhanced Language Detection

```go
// In glot CLI - enhanced language detection
type LanguageDetector struct {
    builtinLanguages map[string]Language
    extensions       map[string]Extension
}

func (d *LanguageDetector) DetectLanguage(projectPath string) (*Language, error) {
    // Check builtin languages first
    for name, lang := range d.builtinLanguages {
        if lang.Detect(projectPath) {
            return &lang, nil
        }
    }

    // Check extension languages
    for name, ext := range d.extensions {
        if ext.Language.Detect(projectPath) {
            return &ext.Language, nil
        }
    }

    return nil, fmt.Errorf("no language detected for project")
}

func loadExtensions() (map[string]Extension, error) {
    config, err := loadGlotConfig()
    if err != nil {
        return nil, err
    }

    extensions := make(map[string]Extension)
    for name, extConfig := range config.Extensions {
        if extConfig.Source == "builtin" {
            continue // Skip builtins
        }

        ext, err := loadExtension(extConfig)
        if err != nil {
            warning("Failed to load extension %s: %v", name, err)
            continue
        }

        extensions[name] = ext
    }

    return extensions, nil
}
```

### Template Discovery Enhancement

```go
// Enhanced template discovery across extensions
func discoverTemplates() ([]Template, error) {
    templates := []Template{}

    // Add builtin templates
    builtins := getBuiltinTemplates()
    templates = append(templates, builtins...)

    // Add extension templates
    extensions, err := loadExtensions()
    if err != nil {
        return nil, err
    }

    for name, ext := range extensions {
        extTemplates, err := ext.GetTemplates()
        if err != nil {
            warning("Failed to load templates from %s: %v", name, err)
            continue
        }

        // Tag templates with their source
        for _, tmpl := range extTemplates {
            tmpl.Source = name
            tmpl.Repository = ext.Repository
        }

        templates = append(templates, extTemplates...)
    }

    return templates, nil
}

// Enhanced template creation with source attribution
func createProject(template, name string) error {
    tmpl, err := findTemplate(template)
    if err != nil {
        return err
    }

    info("Creating %s project: %s", template, name)
    if tmpl.Source != "builtin" {
        info("Using template from: %s", tmpl.Repository)
    }

    return tmpl.Create(name)
}
```

## Extension Registry

### Central Registry Service

```bash
# Public extension registry
https://registry.nix-polyglot.org/

# Registry API endpoints
GET  /api/v1/extensions              # List all extensions
GET  /api/v1/extensions/search?q=go  # Search extensions
GET  /api/v1/extensions/go           # Get extension info
POST /api/v1/extensions              # Submit new extension
```

### Registry Metadata

```json
{
  "name": "go",
  "display_name": "Go",
  "description": "Go language support for nix-polyglot",
  "version": "1.0.0",
  "author": "golang-community",
  "repository": "github:golang-community/nix-polyglot-go",
  "homepage": "https://github.com/golang-community/nix-polyglot-go",
  "license": "MIT",
  "downloads": 1523,
  "stars": 89,
  "compatibility": {
    "nix_polyglot": ">=1.2.0",
    "nix": ">=2.8.0"
  },
  "features": {
    "cross_compilation": true,
    "hot_reload": false,
    "debugging": true
  },
  "templates": [
    {
      "name": "cli",
      "description": "Go CLI application",
      "tags": ["cli", "command-line"]
    },
    {
      "name": "web-server",
      "description": "Go HTTP server",
      "tags": ["web", "http", "server"]
    }
  ],
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-08-30T15:45:00Z"
}
```

## User Experience

### Extension Discovery

```bash
$ glot extensions search go
🔍 Searching extensions for 'go'...

Found 3 extensions:

📦 go (golang-community/nix-polyglot-go)
   Go language support with excellent tooling
   ⭐ 89 stars • 1,523 downloads • MIT license
   Templates: cli, web-server, microservice

📦 go-advanced (go-experts/nix-polyglot-go-advanced)
   Advanced Go features and optimizations
   ⭐ 23 stars • 156 downloads • Apache-2.0 license
   Templates: high-performance, embedded

📦 go-experimental (labs/nix-polyglot-go-experimental)
   Experimental Go features and latest versions
   ⭐ 12 stars • 43 downloads • BSD-3-Clause license
   Templates: bleeding-edge, experimental

Use 'glot extensions add <name>' to install an extension.
```

### Enhanced Template Creation

```bash
$ glot new
🚀 Available templates:

Built-in Languages:
  rust             - Rust CLI application
  python           - Python console application
  csharp           - C# console application

Extension Languages:
  go               - Go application (from golang-community/nix-polyglot-go)
    go/cli         - Go CLI application
    go/web-server  - Go HTTP server
    go/microservice - Go microservice with gRPC
  zig              - Zig application (from zig-org/nix-polyglot-zig)
    zig/cli        - Zig CLI application
    zig/embedded   - Zig embedded system
  ruby             - Ruby application (from ruby-community/nix-polyglot-ruby)
    ruby/cli       - Ruby CLI script
    ruby/web       - Ruby on Rails application

Use 'glot new <template> <name>' to create a project.
Use 'glot extensions search <language>' to find more extensions.
```

### Project with Extensions

```bash
$ cd my-go-project
$ glot info

📋 Project Information:
  Language: go (v1.0.0)
  Extension: golang-community/nix-polyglot-go
  Template: cli

🔧 Available Commands:
  glot build      - Build Go application
  glot run        - Run Go application
  glot test       - Run Go tests
  glot fmt        - Format Go code
  glot lint       - Lint Go code with golangci-lint
  glot mod-tidy   - Clean up go.mod dependencies

📦 Development Tools:
  - go (1.21.0)
  - gopls (language server)
  - golangci-lint
  - delve (debugger)
```

## Security Considerations

### Extension Verification

```bash
# Extension signature verification
glot extensions verify go
✅ Extension signature valid
✅ Repository matches registry
✅ No known security issues
⚠️  Extension has network access permissions

# Trusted publishers
glot config set trusted-publishers golang-community,zig-org
```

### Sandboxing

```nix
# Extensions run in restricted nix evaluation
{
  # Limited access to system resources
  allowedPaths = [ ./. ];
  allowedNetworkHosts = [ "github.com" "api.github.com" ];

  # No access to sensitive environment
  restrictedEnvVars = [ "SSH_KEY" "API_TOKEN" ];
}
```

## Implementation Phases

### Phase 1: Core Infrastructure (3-4 weeks)

- Design extension interface specification
- Implement configuration system
- Add extension loading mechanism
- Basic extension management commands

### Phase 2: Template Integration (2-3 weeks)

- Extend template discovery for extensions
- Update `glot new` with extension templates
- Add source attribution for templates

### Phase 3: Registry System (2-3 weeks)

- Build extension registry service
- Implement search and discovery
- Add extension verification

### Phase 4: Reference Implementation (2-3 weeks)

- Create `nix-polyglot-go` reference extension
- Full documentation and examples
- Community outreach and guidelines

### Phase 5: Advanced Features (2-3 weeks)

- Extension dependency management
- Version conflicts resolution
- Advanced security features

## Extension Guidelines

### Quality Standards

Extensions should provide:

- **Complete documentation** with usage examples
- **Working templates** with sensible defaults
- **Comprehensive tests** for all features
- **Semantic versioning** for stability
- **Security considerations** documented

### Best Practices

```nix
# Extension template structure
{
  # Clear, descriptive metadata
  name = "language-name";
  version = "1.0.0";

  # Robust project detection
  detect = projectPath:
    # Multiple detection strategies
    builtins.pathExists (projectPath + "/language.config") ||
    hasFilesWithExtension projectPath ".lang";

  # Comprehensive tooling
  devShells.default = pkgs.mkShell {
    packages = [
      language-compiler
      language-lsp        # Language server
      language-formatter  # Code formatter
      language-linter     # Static analysis
      language-debugger   # Debugging tools
    ];
  };
}
```

### Community Guidelines

- **Open source**: Extensions should be open source
- **Documentation**: Maintain clear, up-to-date docs
- **Responsiveness**: Respond to issues and PRs promptly
- **Compatibility**: Test with multiple nix-polyglot versions
- **Security**: Follow security best practices

## Benefits

### For Language Communities

- **Ownership**: Communities control their language support
- **Expertise**: Language experts create best practices
- **Flexibility**: Independent release cycles and features
- **Innovation**: Experiment with new approaches

### For Users

- **Choice**: Pick the best extension for each language
- **Consistency**: Same glot interface across all languages
- **Discovery**: Find new languages and tools easily
- **Reliability**: Multiple options reduce single points of failure

### For Core Project

- **Focus**: Core team focuses on platform, not all languages
- **Scalability**: Support unlimited languages through community
- **Innovation**: Community drives new features and approaches
- **Sustainability**: Distributed maintenance burden

## Migration Strategy

### Backward Compatibility

- Built-in languages remain unchanged
- Existing projects continue working
- New extensions are purely additive

### Gradual Adoption

```bash
# Phase 1: Extensions alongside built-ins
glot new rust my-app        # Built-in (unchanged)
glot new go my-web-server   # Extension (new)

# Phase 2: Consider moving built-ins to extensions
# (far future, if beneficial)
```

## Future Possibilities

### Advanced Extension Types

- **Tool extensions**: Add new commands (deploy, monitor)
- **Platform extensions**: Cloud provider integrations
- **Workflow extensions**: CI/CD pipeline generators

### Extension Composition

```bash
# Combine multiple extensions
glot use-extensions go,docker,kubernetes
glot new go/k8s-microservice my-service
```

### IDE Integration

- Extension-aware language servers
- Template discovery in IDEs
- Debugging integration

---

This extension system would transform nix-polyglot from a multi-language tool into a **platform for language tooling**, enabling unlimited growth through community contributions while maintaining consistency and quality.
