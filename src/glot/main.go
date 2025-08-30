package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"

	"github.com/spf13/cobra"
	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

const version = "1.2.0"

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
func buildCommand(release bool, _ string) error {
	if err := checkNix(); err != nil {
		errorMsg(err.Error())
		return err
	}

	variant := "debug"
	if release {
		variant = "release"
	}

	info(fmt.Sprintf("Building (%s variant)...", variant))
	
	var buildTarget string
	if variant == "release" {
		buildTarget = ".#release"
	} else {
		buildTarget = ".#dev"
	}

	caser := cases.Title(language.English)
	if err := runNix("build", buildTarget); err != nil {
		errorMsg(fmt.Sprintf("%s build failed", caser.String(variant)))
		return err
	}

	success(fmt.Sprintf("%s build completed", caser.String(variant)))
	return nil
}

// Run command
func runCommand(release bool, _ string, runArgs []string) error {
	if err := checkNix(); err != nil {
		errorMsg(err.Error())
		return err
	}

	variant := "debug"
	if release {
		variant = "release"
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



func main() {
	var rootCmd = &cobra.Command{
		Use:     "glot",
		Short:   "Nix Polyglot Project Interface",
		Long:    "A tool for managing Nix-based polyglot development projects",
		Version: version,
	}

	var buildCmd = &cobra.Command{
		Use:   "build [target]",
		Short: "Build project",
		Long:  "Build the project or specific target.",
		RunE: func(cmd *cobra.Command, args []string) error {
			release, _ := cmd.Flags().GetBool("release")
			target := ""
			if len(args) > 0 {
				target = args[0]
			}
			return buildCommand(release, target)
		},
	}
	buildCmd.Flags().Bool("release", false, "Build release variant (default: debug)")

	var runCmd = &cobra.Command{
		Use:   "run [target] [-- args...]",
		Short: "Run project",
		Long:  "Run the project or specific target.",
		RunE: func(cmd *cobra.Command, args []string) error {
			release, _ := cmd.Flags().GetBool("release")
			target := ""
			runArgs := []string{}
			
			// Find -- separator
			for i, arg := range args {
				if arg == "--" {
					runArgs = args[i+1:]
					args = args[:i]
					break
				}
			}
			
			if len(args) > 0 {
				target = args[0]
			}
			
			return runCommand(release, target, runArgs)
		},
	}
	runCmd.Flags().Bool("release", false, "Run release variant (default: debug)")

	var fmtCmd = &cobra.Command{
		Use:     "fmt",
		Aliases: []string{"format"},
		Short:   "Format code",
		Long:    "Format code using nix fmt.",
		RunE: func(cmd *cobra.Command, args []string) error {
			if err := checkNix(); err != nil {
				errorMsg(err.Error())
				return err
			}
			info("Formatting code...")
			if err := runNix("fmt"); err != nil {
				errorMsg("Code formatting failed")
				return err
			}
			success("Code formatting completed")
			return nil
		},
	}

	var lintCmd = &cobra.Command{
		Use:   "lint",
		Short: "Lint code",
		Long:  "Run Rust linting (clippy) on the codebase.",
		RunE: func(cmd *cobra.Command, args []string) error {
			if err := checkNix(); err != nil {
				errorMsg(err.Error())
				return err
			}
			info("Running Rust linting (clippy)...")
			if err := runInDevShell("cargo", "clippy", "--", "-D", "warnings"); err != nil {
				errorMsg("Linting failed")
				return err
			}
			success("Linting completed")
			return nil
		},
	}

	var testCmd = &cobra.Command{
		Use:   "test",
		Short: "Run tests",
		Long:  "Run Rust tests for the project.",
		RunE: func(cmd *cobra.Command, args []string) error {
			if err := checkNix(); err != nil {
				errorMsg(err.Error())
				return err
			}
			info("Running Rust tests...")
			if err := runInDevShell("cargo", "test"); err != nil {
				errorMsg("Tests failed")
				return err
			}
			success("Tests completed")
			return nil
		},
	}

	var checkCmd = &cobra.Command{
		Use:   "check",
		Short: "Run all checks",
		Long:  "Run comprehensive checks including format, lint, test, and build.",
		RunE: func(cmd *cobra.Command, args []string) error {
			if err := checkNix(); err != nil {
				errorMsg(err.Error())
				return err
			}
			info("Running comprehensive checks...")
			if err := runNix("fmt"); err != nil ||
				runInDevShell("cargo", "clippy", "--", "-D", "warnings") != nil ||
				runInDevShell("cargo", "test") != nil ||
				runNix("build") != nil {
				errorMsg("Some checks failed. Please review the output above.")
				return fmt.Errorf("checks failed")
			}
			success("All checks passed!")
			return nil
		},
	}

	var cleanCmd = &cobra.Command{
		Use:   "clean",
		Short: "Clean artifacts",
		Long:  "Clean build artifacts and temporary files.",
		RunE: func(cmd *cobra.Command, args []string) error {
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
			return nil
		},
	}

	var updateCmd = &cobra.Command{
		Use:   "update",
		Short: "Update dependencies",
		Long:  "Update both Nix flake and Cargo dependencies, plus refresh glot CLI.",
		RunE: func(cmd *cobra.Command, args []string) error {
			if err := checkNix(); err != nil {
				errorMsg(err.Error())
				return err
			}
			
			info("Updating project dependencies...")
			if err := runNix("flake", "update"); err != nil {
				errorMsg("Failed to update flake dependencies")
				return err
			}
			if err := runInDevShell("cargo", "update"); err != nil {
				warning("Failed to update cargo dependencies")
			}
			success("Project dependencies updated!")
			
			// Self-update: remove cached glot CLI to force rebuild
			info("Refreshing glot CLI...")
			cacheFile := ".cache/bin/glot"
			if _, err := os.Stat(cacheFile); err == nil {
				if err := os.Remove(cacheFile); err != nil {
					warning("Could not remove cached glot CLI - you may need to run 'direnv reload'")
				} else {
					success("Cached glot CLI cleared - will be rebuilt automatically on next use")
				}
			} else {
				info("No cached glot CLI found - will be built automatically on next use")
			}
			
			success("Update completed! Glot CLI will be refreshed automatically.")
			return nil
		},
	}

	var infoCmd = &cobra.Command{
		Use:   "info",
		Short: "Show project info",
		Long:  "Display information about the current project.",
		RunE: func(cmd *cobra.Command, args []string) error {
			if err := checkNix(); err != nil {
				errorMsg(err.Error())
				return err
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
				return err
			} else {
				success("Flake is valid")
			}
			return nil
		},
	}

	var shellCmd = &cobra.Command{
		Use:   "shell",
		Short: "Enter dev environment",
		Long:  "Enter the Nix development shell.",
		RunE: func(cmd *cobra.Command, args []string) error {
			if err := checkNix(); err != nil {
				errorMsg(err.Error())
				return err
			}
			info("Entering development shell...")
			nixCmd := exec.Command("nix", "develop")
			nixCmd.Stdout = os.Stdout
			nixCmd.Stderr = os.Stderr
			nixCmd.Stdin = os.Stdin
			if err := nixCmd.Run(); err != nil {
				if exitError, ok := err.(*exec.ExitError); ok {
					if status, ok := exitError.Sys().(syscall.WaitStatus); ok {
						os.Exit(status.ExitStatus())
					}
				}
				return err
			}
			return nil
		},
	}

	rootCmd.AddCommand(buildCmd, runCmd, fmtCmd, lintCmd, testCmd, checkCmd, cleanCmd, updateCmd, infoCmd, shellCmd)

	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}