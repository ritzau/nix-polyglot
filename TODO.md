# Glot CLI Implementation TODO

## Phase 4: Examples Repository & Language Expansion 🚧 IN PROGRESS

### Current Tasks (August 31, 2025)

**GitHub Issues Integration**: ✅ All tasks now tracked as GitHub Issues for better project management

- [x] Research GitHub Issues API integration for task management
- [x] Clean up completed phases from TODO.md
- [🚧] Create glot-examples repository next to samples directory → [Issue #1](https://github.com/ritzau/nix-polyglot/issues/1)
- [ ] Initialize git repository in glot-examples with proper structure → [Issue #1](https://github.com/ritzau/nix-polyglot/issues/1)
- [ ] Copy existing samples (rust, python, csharp) to glot-examples subdirectories → [Issue #1](https://github.com/ritzau/nix-polyglot/issues/1)
- [ ] Create root flake.nix in glot-examples to build all examples → [Issue #1](https://github.com/ritzau/nix-polyglot/issues/1)
- [ ] Add Nim language support following nixpkgs guidelines → [Issue #2](https://github.com/ritzau/nix-polyglot/issues/2)
- [ ] Add Zig language support following nixpkgs guidelines → [Issue #3](https://github.com/ritzau/nix-polyglot/issues/3)
- [ ] Add Go language support following nixpkgs guidelines → [Issue #4](https://github.com/ritzau/nix-polyglot/issues/4)
- [ ] Update documentation to reflect new examples and language support → [Issue #5](https://github.com/ritzau/nix-polyglot/issues/5)

### Future Language Support Pipeline

Languages to implement following https://nixos.org/manual/nixpkgs/stable/#chap-language-support:

- [ ] Nim - Static typed systems language
- [ ] Zig - Low-level systems language
- [ ] Go - Concurrent programming language

### Implementation Strategy

1. **Repository Structure**: Create separate glot-examples repo for community samples
2. **Language Integration**: Follow nixpkgs language support patterns for each new language
3. **Template Creation**: Create glot CLI templates for each new language
4. **Root Flake**: Unified build system for all examples
5. **Documentation**: Update guides to include new languages and examples

---

## ✅ COMPLETED PHASES (Phase 1-3)

### Phase 1: Core Implementation ✅ COMPLETE

- Go-based glot CLI implementation (~200 lines)
- Template system integration
- Smart caching with automatic version synchronization

### Phase 2: Enhanced Features ✅ COMPLETE

- Shell completion system (bash/zsh/fish)
- Version management and upgrade system
- Cross-platform binary with proper error handling

### Phase 3: Multi-Language Support ✅ COMPLETE

- Template system modernization (replaced justfiles)
- Complete documentation suite (User Guide, API Reference, FAQ, Developer Guide)
- Future directions specifications (cross-compilation, language extensions)

### Optional Future Enhancements

- [ ] Add cross-compilation support (--target flag)
- [ ] Add `glot watch` command for continuous building
- [ ] Add `glot bench` command for performance testing
- [ ] Add `glot docs` command for documentation generation
- [ ] Integration with IDE/editor configurations

## Cross-Compilation Design (Future Reference)

**Approach:** Single glot CLI with optional `--target` flag for cross-compilation.

**Key Insights:**

- Keep one glot binary (always dev host architecture)
- Add optional `--target` parameter: `glot build --target=aarch64-linux`
- Default behavior unchanged: `glot build` works as before
- Leverage standard nix cross-compilation patterns
- Use emulation (rosetta/qemu) for basic testing of cross-compiled outputs

**Implementation Strategy:**

1. Add `--target` flag to build/run commands
2. Map targets to nix cross-compilation expressions (e.g., `pkgsCross.aarch64-linux`)
3. Handle emulation detection for run command
4. Document supported targets (linux/amd64, darwin/arm64, etc.)

**Benefits:** Zero breaking changes, minimal complexity, leverages existing nix patterns.
**Complexity:** 3/10 (much simpler than initially assessed)

## Working with this TODO

**For continuing work:**

1. Read this TODO to understand current status
2. Use TodoWrite tool to update task progress as you work
3. Mark tasks as: `pending` → `in_progress` → `completed`
4. Add new tasks if you discover additional work needed
5. Focus on completing Phase 2 before moving to Phase 3

**Current Status:** Phase 1, 2 & 3 FULLY COMPLETE! ✅ Go-based glot CLI fully operational with complete template system integration.

**Current Priority:** All core tasks complete. Optional: documentation and future enhancements (cross-compilation, watch mode, etc.)

**Implementation Location:**

- Central: `/Users/ritzau/src/slask/nix/polyglot/nix-polyglot/src/glot/main.go`
- Sample: `/Users/ritzau/src/slask/nix/polyglot/samples/rust-nix/.cache/bin/glot` (auto-cached)

## Implementation Details

### Current Implemented Commands ✅

```bash
# Core commands (all implemented)
glot build [target] [--release]           # Simplified interface
glot run [target] [--release] [-- args...]
glot fmt
glot lint
glot test
glot check
glot clean
glot update
glot info
glot shell
glot help [command]

# Enhanced features (all implemented)
glot completion bash|zsh|fish
glot install-completions
glot version
glot upgrade-glot         # Shows upgrade instructions

# Template system (newly implemented)
glot new                  # List available templates
glot new rust myproject   # Create project from template
glot new python myapp     # Works with all template types
```

### Current Architecture ✅

```
# Central implementation
nix-polyglot/
├── src/glot/
│   ├── main.go              # Go implementation (~200 lines)
│   └── go.mod
└── flake.nix                # Exposes packages.glot

# Project structure
rust-nix/
├── .envrc                   # Smart caching with timestamp check
├── .cache/bin/glot          # Auto-cached binary (ignored by git)
├── .gitignore               # Excludes .cache/
└── flake.nix                # References nix-polyglot.packages.glot
```

### Git Hooks Strategy

- Pre-commit: `glot fmt` (fast)
- Pre-push: `glot check` (comprehensive, bypassable)
