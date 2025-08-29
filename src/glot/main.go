package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
)

const version = "1.2.0"

// Color codes for output
const (
	colorReset  = "\033[0m"
	colorRed    = "\033[31m"
	colorGreen  = "\033[32m"
	colorYellow = "\033[33m"
	colorBlue   = "\033[34m"
)

// Output helpers
func success(msg string) {
	fmt.Printf("✅ %s\n", msg)
}

func info(msg string) {
	fmt.Printf("ℹ️  %s\n", msg)
}

func warning(msg string) {
	fmt.Fprintf(os.Stderr, "⚠️  %s\n", msg)
}

func errorMsg(msg string) {
	fmt.Fprintf(os.Stderr, "❌ Error: %s\n", msg)
}

// Check if nix and flake.nix exist
func checkNix() error {
	if _, err := exec.LookPath("nix"); err != nil {
		return fmt.Errorf("Nix is not installed or not in PATH. Please install Nix first")
	}
	if _, err := os.Stat("flake.nix"); os.IsNotExist(err) {
		return fmt.Errorf("No flake.nix found in current directory. Are you in a nix polyglot project?")
	}
	return nil
}

// Execute nix command
func runNix(args ...string) error {
	cmd := exec.Command("nix", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}

// Execute command in nix develop shell
func runInDevShell(command ...string) error {
	args := append([]string{"develop", "--command"}, command...)
	return runNix(args...)
}

// Build command
func buildCommand(args []string) error {
	if err := checkNix(); err != nil {
		errorMsg(err.Error())
		return err
	}

	variant := "debug"
	target := ""

	// Parse arguments
	for _, arg := range args {
		switch arg {
		case "--release":
			variant = "release"
		default:
			if !strings.HasPrefix(arg, "--") && target == "" {
				target = arg
			} else if strings.HasPrefix(arg, "--") {
				errorMsg(fmt.Sprintf("unknown flag: %s", arg))
				return fmt.Errorf("unknown flag")
			}
		}
	}

	info(fmt.Sprintf("Building (%s variant)...", variant))
	
	var buildTarget string
	if variant == "release" {
		buildTarget = ".#release"
	} else {
		buildTarget = ".#dev"
	}

	if err := runNix("build", buildTarget); err != nil {
		errorMsg(fmt.Sprintf("%s build failed", strings.Title(variant)))
		return err
	}

	success(fmt.Sprintf("%s build completed", strings.Title(variant)))
	return nil
}

// Run command
func runCommand(args []string) error {
	if err := checkNix(); err != nil {
		errorMsg(err.Error())
		return err
	}

	variant := "debug"
	runArgs := []string{}
	
	// Parse arguments
	parseLoop:
	for i, arg := range args {
		switch arg {
		case "--release":
			variant = "release"
		case "--":
			runArgs = args[i+1:]
			break parseLoop
		default:
			if !strings.HasPrefix(arg, "--") {
				runArgs = append(runArgs, arg)
			} else {
				errorMsg(fmt.Sprintf("unknown flag: %s", arg))
				return fmt.Errorf("unknown flag")
			}
		}
	}

	info(fmt.Sprintf("Running (%s variant)...", variant))
	
	var runTarget string
	if variant == "release" {
		runTarget = ".#release"
	} else {
		runTarget = ".#dev"
	}

	nixArgs := append([]string{"run", runTarget}, runArgs...)
	return runNix(nixArgs...)
}

// Version command
func versionCommand() {
	fmt.Printf("Glot version: %s\n\n", version)
	
	// Show project version if available
	if _, err := os.Stat("Cargo.toml"); err == nil {
		fmt.Println("Project information:")
		cmd := exec.Command("nix", "develop", "--command", "bash", "-c", 
			"cargo metadata --no-deps --format-version 1 | jq -r '.packages[0] | \"Name: \" + .name + \"\\nVersion: \" + .version + \"\\nEdition: \" + .edition'")
		cmd.Stdout = os.Stdout
		if err := cmd.Run(); err != nil {
			fmt.Println("Project version not available")
		}
	} else if _, err := os.Stat("flake.nix"); err == nil {
		fmt.Println("Nix flake project detected")
	}
	
	fmt.Println("\nEnvironment:")
	if cmd := exec.Command("nix", "--version"); cmd.Run() == nil {
		cmd.Stdout = os.Stdout
		cmd.Run()
	} else {
		fmt.Println("Nix: Not available")
	}
	wd, _ := os.Getwd()
	fmt.Printf("Working directory: %s\n", wd)
}

// Help command
func helpCommand(subcmd string) {
	if subcmd != "" {
		switch subcmd {
		case "build":
			fmt.Println("glot build [target] [--release]")
			fmt.Println("")
			fmt.Println("Build the project or specific target.")
			fmt.Println("")
			fmt.Println("Options:")
			fmt.Println("  --release           Build release variant (default: debug)")
		case "run":
			fmt.Println("glot run [target] [--release] [-- args...]")
			fmt.Println("")
			fmt.Println("Run the project or specific target.")
			fmt.Println("")
			fmt.Println("Options:")
			fmt.Println("  --release           Run release variant (default: debug)")
			fmt.Println("  --                  Pass remaining args to program")
		default:
			fmt.Printf("No detailed help available for: %s\n", subcmd)
		}
		return
	}

	fmt.Println("Glot - Nix Polyglot Project Interface")
	fmt.Println("")
	fmt.Println("Usage: glot <command> [options]")
	fmt.Println("")
	fmt.Println("Commands:")
	fmt.Println("  build [target] [--release]                  Build project")
	fmt.Println("  run [target] [--release] [-- args...]       Run project")
	fmt.Println("  fmt                                          Format code")
	fmt.Println("  lint                                         Lint code")
	fmt.Println("  test                                         Run tests")
	fmt.Println("  check                                        Run all checks")
	fmt.Println("  clean                                        Clean artifacts")
	fmt.Println("  update                                       Update dependencies")
	fmt.Println("  info                                         Show project info")
	fmt.Println("  shell                                        Enter dev environment")
	fmt.Println("  version                                      Show version information")
	fmt.Println("  help [command]                               Show help")
	fmt.Println("")
	fmt.Println("Use 'glot help <command>' for detailed help on specific commands.")
}

func main() {
	if len(os.Args) < 2 {
		helpCommand("")
		return
	}

	command := os.Args[1]
	args := os.Args[2:]

	switch command {
	case "build":
		if err := buildCommand(args); err != nil {
			os.Exit(1)
		}
	case "run":
		if err := runCommand(args); err != nil {
			os.Exit(1)
		}
	case "fmt", "format":
		if err := checkNix(); err != nil {
			errorMsg(err.Error())
			os.Exit(1)
		}
		info("Formatting code...")
		if err := runNix("fmt"); err != nil {
			errorMsg("Code formatting failed")
			os.Exit(1)
		}
		success("Code formatting completed")
	case "lint":
		if err := checkNix(); err != nil {
			errorMsg(err.Error())
			os.Exit(1)
		}
		info("Running Rust linting (clippy)...")
		if err := runInDevShell("cargo", "clippy", "--", "-D", "warnings"); err != nil {
			errorMsg("Linting failed")
			os.Exit(1)
		}
		success("Linting completed")
	case "test":
		if err := checkNix(); err != nil {
			errorMsg(err.Error())
			os.Exit(1)
		}
		info("Running Rust tests...")
		if err := runInDevShell("cargo", "test"); err != nil {
			errorMsg("Tests failed")
			os.Exit(1)
		}
		success("Tests completed")
	case "check":
		if err := checkNix(); err != nil {
			errorMsg(err.Error())
			os.Exit(1)
		}
		info("Running comprehensive checks...")
		if err := runNix("fmt"); err != nil ||
		   runInDevShell("cargo", "clippy", "--", "-D", "warnings") != nil ||
		   runInDevShell("cargo", "test") != nil ||
		   runNix("build") != nil {
			errorMsg("Some checks failed. Please review the output above.")
			os.Exit(1)
		}
		success("All checks passed!")
	case "clean":
		info("Cleaning build artifacts...")
		targets := []string{"target/", "result", "result-*", ".cargo/"}
		for _, target := range targets {
			if matches, _ := filepath.Glob(target); len(matches) > 0 {
				for _, match := range matches {
					os.RemoveAll(match)
				}
			}
		}
		success("Clean completed!")
	case "update":
		if err := checkNix(); err != nil {
			errorMsg(err.Error())
			os.Exit(1)
		}
		info("Updating dependencies...")
		if err := runNix("flake", "update"); err != nil {
			errorMsg("Failed to update flake dependencies")
			os.Exit(1)
		}
		if err := runInDevShell("cargo", "update"); err != nil {
			warning("Failed to update cargo dependencies")
		}
		success("Dependencies updated!")
	case "info":
		if err := checkNix(); err != nil {
			errorMsg(err.Error())
			os.Exit(1)
		}
		fmt.Println("📋 Project Information")
		fmt.Println("======================")
		wd, _ := os.Getwd()
		fmt.Printf("Working directory: %s\n", wd)
		fmt.Println()
		fmt.Println("Project type: rust")
		fmt.Println()
		fmt.Println("Flake status:")
		if err := runNix("flake", "show"); err != nil {
			errorMsg("Flake validation failed")
		} else {
			success("Flake is valid")
		}
	case "shell":
		if err := checkNix(); err != nil {
			errorMsg(err.Error())
			os.Exit(1)
		}
		info("Entering development shell...")
		cmd := exec.Command("nix", "develop")
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		cmd.Stdin = os.Stdin
		if err := cmd.Run(); err != nil {
			if exitError, ok := err.(*exec.ExitError); ok {
				if status, ok := exitError.Sys().(syscall.WaitStatus); ok {
					os.Exit(status.ExitStatus())
				}
			}
			os.Exit(1)
		}
	case "version":
		versionCommand()
	case "help", "--help", "-h":
		subcmd := ""
		if len(args) > 0 {
			subcmd = args[0]
		}
		helpCommand(subcmd)
	default:
		fmt.Fprintf(os.Stderr, "glot: unknown command '%s'\n", command)
		fmt.Fprintf(os.Stderr, "Try 'glot help' for usage information.\n")
		os.Exit(1)
	}
}