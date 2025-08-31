## Main module for the Nim CLI application
##
## This is a simple CLI application template that demonstrates:
## - Command line argument parsing
## - Basic error handling
## - Project structure best practices
## 
## Created with nix-polyglot for reproducible development

import std/[os, strutils, strformat]

proc greet(name: string, count: int = 1): void =
  ## Generate a greeting message
  for i in 1..count:
    echo fmt"Hello, {name}! (#{i})"

proc showHelp(): void =
  ## Display help information
  echo """
Nim CLI Application

Usage:
  main [options] <name>
  
Options:
  -c, --count <n>    Number of greetings (default: 1)
  -h, --help         Show this help message
  
Examples:
  main Alice                    # Greet Alice once
  main --count 3 Bob           # Greet Bob three times
  main -c 2 "World"            # Greet World twice
  
This project was created with nix-polyglot for reproducible development.
Use 'glot build' to build and 'glot run' to run.
"""

proc main(): void =
  ## Main entry point
  let args = commandLineParams()
  
  if args.len == 0 or "--help" in args or "-h" in args:
    showHelp()
    quit(0)
  
  var name = ""
  var count = 1
  var i = 0
  
  # Simple argument parsing
  while i < args.len:
    case args[i]
    of "-c", "--count":
      if i + 1 >= args.len:
        echo "Error: --count requires a value"
        quit(1)
      try:
        count = parseInt(args[i + 1])
        if count <= 0:
          echo "Error: count must be positive"
          quit(1)
        inc i, 2
      except ValueError:
        echo fmt"Error: invalid count value '{args[i + 1]}'"
        quit(1)
    else:
      if name != "":
        echo "Error: multiple names provided"
        showHelp()
        quit(1)
      name = args[i]
      inc i
  
  if name == "":
    echo "Error: no name provided"
    showHelp()
    quit(1)
  
  greet(name, count)

when isMainModule:
  main()