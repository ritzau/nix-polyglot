# Glot CLI Implementation TODO

## Phase 1: Core Implementation for Rust

### Status Legend

- [ ] todo
- [x] done
- [🚧] in progress
- [🚫] blocked
- [⏭️] skipped

### Current Tasks

- [x] Create TODO.md file in nix-polyglot repo for glot CLI implementation
- [x] Create .nix-polyglot/glot.bash implementation file
- [x] Update rust-nix sample with simple .envrc that sources glot.bash
- [x] Create install-hooks nix app for git hook management
- [x] Test basic glot commands in rust-nix sample
- [x] Verify git hooks work properly with new setup

## Phase 2: Enhanced Script Features

### Current Tasks

- [ ] Add completion generation system to glot script
- [ ] Implement `glot completion bash|zsh|fish` command
- [ ] Add `glot install-completions` for automatic shell setup
- [ ] Add `glot version` command showing glot and project versions
- [ ] Add `glot upgrade-glot` command for updating glot implementation
- [ ] Test completion system across bash/zsh shells
- [ ] Add error handling and better user feedback

## Phase 3: Extended Commands (Future)

### Planned Tasks

- [ ] Implement `glot new [template] [name]` with template discovery
- [ ] Add variant support improvements (--variant debug|release)
- [ ] Add cross-compilation support (--platform)
- [ ] Extend to python-nix and csharp-nix samples
- [ ] Create unified template system
- [ ] Documentation and user guides

## Working with this TODO

**For continuing work:**

1. Read this TODO to understand current status
2. Use TodoWrite tool to update task progress as you work
3. Mark tasks as: `pending` → `in_progress` → `completed`
4. Add new tasks if you discover additional work needed
5. Focus on completing Phase 2 before moving to Phase 3

**Current Priority:** Enhance the script-based glot CLI with completion system and self-management features.

**Location:** `/Users/ritzau/src/slask/nix/polyglot/samples/rust-nix/.nix-polyglot/glot`

## Implementation Details

### Core Commands to Implement

```bash
glot build [target] [--variant debug|release]
glot run [target] [--variant debug|release]
glot fmt
glot lint
glot test
glot check
glot clean
glot update
glot info
glot shell
glot help [command]

# Phase 2 additions:
glot completion bash|zsh|fish
glot install-completions
glot version
glot upgrade-glot
```

### File Structure

```
rust-nix/
├── .envrc                    # Simple loader
├── .nix-polyglot/
│   └── glot.bash            # Implementation
└── flake.nix                # With install-hooks app
```

### Git Hooks Strategy

- Pre-commit: `glot fmt` (fast)
- Pre-push: `glot check` (comprehensive, bypassable)
