# Package

version       = "0.1.0"
author        = "Your Name"
description   = "A new CLI application built with Nim and nix-polyglot"
license       = "MIT"
srcDir        = "src"
bin           = @["main"]

# Dependencies

requires "nim >= 2.0.0"

# Tasks

task test, "Run tests":
  exec "nim c -r tests/test_main.nim"

task docs, "Generate documentation":
  exec "nim doc --project --outdir:docs src/main.nim"

task clean, "Clean build artifacts":
  rmDir "nimcache"
  rmDir "htmldocs"