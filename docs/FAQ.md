# Glot CLI FAQ

Frequently asked questions about the glot CLI and nix-polyglot integration.

## General Questions

### What is glot?

Glot is a unified CLI tool for nix-polyglot projects that provides consistent commands across multiple programming languages (Rust, Python, C#). It replaces language-specific build tools with a single, fast interface while leveraging Nix for reproducible builds and environments.

### Why use glot instead of cargo/poetry/dotnet directly?

**Benefits of glot:**

- **Unified interface**: Same commands across all languages
- **Reproducible builds**: Guaranteed consistent environments via Nix
- **Smart caching**: Automatic optimization and dependency management
- **Zero configuration**: Works out-of-the-box with sensible defaults
- **Team consistency**: Everyone uses the same tools and versions

### How fast is glot?

Glot itself executes in ~5ms. Build times depend on your project and nix cache status:

- **Cache hit**: Near-instant (symlink to existing build)
- **Incremental build**: Same as native tools (cargo, poetry, etc.)
- **Full rebuild**: Initial compilation time + nix overhead

### Is glot just a wrapper around existing tools?

Yes and no. Glot orchestrates language-specific tools through Nix, but adds:

- Smart dependency management
- Automatic environment setup
- Cross-language consistency
- Enhanced caching and reproducibility

## Installation & Setup

### Do I need to install glot separately?

No! Glot is automatically available in nix-polyglot projects through the `.envrc` file. When you run `direnv allow`, it downloads and caches the glot binary automatically.

For system-wide use:

```bash
nix profile install github:ritzau/nix-polyglot#glot
```

### Why do I need to run `direnv allow`?

The `direnv allow` command:

- Activates the `.envrc` configuration
- Downloads and caches the glot CLI
- Sets up your development environment
- Configures shell completions and git hooks
- Adds glot to your PATH

### What if I don't want to use direnv?

You can use nix directly:

```bash
# Enter development shell manually
nix develop

# Run glot through nix
nix run .#glot -- build
nix run .#glot -- run
```

But direnv provides the best user experience with automatic setup.

### Can I use glot with existing projects?

Glot is designed for nix-polyglot projects. To add nix-polyglot to existing projects:

1. Add nix-polyglot to your `flake.nix`
2. Configure your language-specific build in the flake
3. Add the provided `.envrc` template
4. Run `direnv allow`

See the migration guide in the [User Guide](USER_GUIDE.md).

## Project Creation

### What templates are available?

Current templates:

- **Rust**: `rust` or `rust-cli` - Command-line application with Cargo
- **Python**: `python` or `python-console` - Console application with Poetry
- **C#**: `csharp` or `csharp-console` - Console application with .NET 8

### Can I customize templates?

Templates are stored in the nix-polyglot repository. You can:

1. Fork nix-polyglot and modify templates
2. Create your own template system
3. Use existing templates as starting points and modify manually

### Why does template creation sometimes fetch from GitHub?

Glot tries multiple sources for templates:

1. **Local development version** (if you're working on nix-polyglot)
2. **Hardcoded development path** (for maintainers)
3. **GitHub fallback** (ensures it always works)

This provides reliability while supporting local development.

### Can I create templates for other languages?

Yes! Nix-polyglot is designed to support any language. To add a new language:

1. Create a language module in `lib/languages/`
2. Add template files in `templates/<language>/`
3. Update the template system in `lib/templates.nix`
4. Test with the existing samples and test scripts

## Build & Development

### Why are builds sometimes slow?

Possible reasons:

- **First build**: Nix downloads dependencies and builds from scratch
- **Cache miss**: Dependencies changed, triggering rebuild
- **No binary cache**: Building from source instead of using cached binaries

Mitigation:

- Keep `flake.lock` committed for consistency
- Use nix binary caches when available
- Run `glot clean` to free space, but not frequently

### How do I debug build failures?

1. **Check the error message** - glot shows detailed build output
2. **Run manually**: `nix develop --command cargo build` (or equivalent)
3. **Update dependencies**: `glot update`
4. **Clean cache**: `rm -rf result .cache/bin/glot`
5. **Check environment**: `glot info`

### Can I use glot with my IDE?

Yes! IDEs work normally with nix-polyglot projects:

- **VS Code**: Install nix-ide extension + direnv integration
- **JetBrains**: Import as standard language projects
- **Vim/Neovim**: Use language servers from nix development shell
- **Emacs**: Configure lsp-mode with nix integration

The development environment provides all necessary tools.

### How does glot handle different build variants?

Glot supports debug and release builds:

- **Debug**: `glot build` (fast compilation, debug symbols)
- **Release**: `glot build --release` (optimized, slower compilation)

This maps to language-specific optimization flags through nix configurations.

## Shell Integration

### How do completions work?

Shell completions are provided by the cobra framework in Go:

- Generated dynamically based on available commands
- Installed automatically by project `.envrc` files
- Support bash, zsh, and fish shells

### Why aren't my completions working?

Troubleshooting:

1. **Restart your shell** after running `glot install-completions`
2. **Check installation**: Look for completion files in `~/.config/<shell>/completions/`
3. **Manual install**: Run `glot install-completions` again
4. **Shell configuration**: Ensure your shell loads completions from config directory

### Can I disable automatic completion installation?

Edit your project's `.envrc` file and remove or comment out the completion installation section:

```bash
# Comment out this section in .envrc
# if command -v glot >/dev/null 2>&1; then
#     # ... completion installation code ...
# fi
```

## Performance & Caching

### How does glot caching work?

Multiple layers of caching:

1. **Nix store cache**: Build outputs cached by hash
2. **Binary cache**: Remote cache for common builds
3. **Local glot cache**: `.cache/bin/glot` updated when dependencies change
4. **Language tool cache**: cargo/poetry/dotnet native caching

### When does glot rebuild itself?

The cached glot binary (`.cache/bin/glot`) rebuilds when:

- `flake.lock` is newer than the cached binary
- The cache doesn't exist (first run)
- Manual removal (`rm .cache/bin/glot`)

### How much disk space does glot use?

- **Glot binary**: ~10MB (cached per project)
- **Nix dependencies**: Shared across projects in `/nix/store`
- **Build outputs**: Varies by project, cleaned with `glot clean`

Total usage is typically much less than language-specific tools due to nix deduplication.

### Can I share cache between team members?

Yes! Commit your `flake.lock` file to ensure everyone uses the same dependencies. Consider setting up a shared nix binary cache for your organization.

## Troubleshooting

### "glot: command not found"

**Solutions:**

1. Run `direnv allow` in the project directory
2. Check that `.envrc` exists and is executable
3. Try `nix develop` to enter the shell manually
4. Verify nix and direnv are installed

### Build fails with "derivation failed"

**Common causes:**

1. **Dependencies changed**: Run `glot update`
2. **Disk space**: Check available space, run `glot clean`
3. **Network issues**: Check internet connection for downloads
4. **Nix configuration**: Verify flakes are enabled

### "No flake.nix found"

This error means you're not in a nix-polyglot project directory.

**Solutions:**

1. Navigate to your project directory
2. Create a new project with `glot new`
3. Convert existing project to use nix-polyglot

### Template creation fails

**Debugging:**

1. Check internet connection (GitHub fallback)
2. Verify nix flakes enabled: `nix --version` should show flake support
3. Try manual creation: `nix run github:ritzau/nix-polyglot#new-rust myproject`

### Permission denied errors

**Usually caused by:**

1. **Missing direnv allow**: Run `direnv allow`
2. **Executable permissions**: `chmod +x .envrc`
3. **File ownership**: Check file permissions in project directory

## Advanced Usage

### Can I use glot in CI/CD?

Yes! Example GitHub Actions:

```yaml
- uses: cachix/install-nix-action@v22
  with:
    github_access_token: ${{ secrets.GITHUB_TOKEN }}
- run: nix develop --command glot check
```

Or install glot system-wide:

```yaml
- run: nix profile install github:ritzau/nix-polyglot#glot
- run: glot check
```

### How do I pin glot to a specific version?

In your `flake.nix`, pin the nix-polyglot input:

```nix
inputs = {
  nix-polyglot = {
    url = "github:ritzau/nix-polyglot/v1.2.0";  # Specific tag
    # url = "github:ritzau/nix-polyglot/abc123"; # Specific commit
  };
};
```

### Can I extend glot with custom commands?

Glot is designed to be complete for common workflows. For custom commands:

1. **Shell aliases**: Add to your shell configuration
2. **Project scripts**: Add to your `flake.nix` apps
3. **Nix run**: Use `nix run .#my-custom-app`

### How do I contribute to glot?

1. **Report issues**: Use GitHub issues for bugs/feature requests
2. **Documentation**: Improve guides and examples
3. **Code contributions**: Fork, create feature branch, submit PR
4. **Templates**: Contribute new language templates

See the development guide in the repository.

## Comparison with Other Tools

### vs. Just/Make

| Feature          | Just/Make                 | Glot                    |
| ---------------- | ------------------------- | ----------------------- |
| Language support | Manual setup per language | Built-in multi-language |
| Reproducibility  | Depends on system         | Guaranteed via Nix      |
| Caching          | Manual                    | Automatic               |
| Dependencies     | System-dependent          | Self-contained          |
| Learning curve   | Low                       | Medium                  |

### vs. Nix directly

| Feature         | Raw Nix | Glot           |
| --------------- | ------- | -------------- |
| Ease of use     | Complex | Simple         |
| Command length  | Long    | Short          |
| Discoverability | Low     | High           |
| Consistency     | Varies  | Standardized   |
| Performance     | Same    | Same + caching |

### vs. Language-specific tools

| Feature           | Lang Tools | Glot       |
| ----------------- | ---------- | ---------- |
| Familiarity       | High       | Medium     |
| Cross-language    | No         | Yes        |
| Reproducibility   | Limited    | Guaranteed |
| Environment setup | Manual     | Automatic  |
| Team consistency  | Varies     | Enforced   |

## Still Have Questions?

1. **Check the [User Guide](USER_GUIDE.md)** for comprehensive documentation
2. **Review [API Reference](API_REFERENCE.md)** for detailed command info
3. **Search [GitHub Issues](https://github.com/ritzau/nix-polyglot/issues)** for similar problems
4. **Ask questions** by opening a new GitHub issue
5. **Join discussions** in the repository discussions section

---

_This FAQ is actively maintained. If you have questions not covered here, please open an issue so we can add them!_
