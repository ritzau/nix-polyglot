package main

import (
	"flag"
	"fmt"
	"os"
)

// greet generates greeting messages
func greet(name string, count int) {
	for i := 1; i <= count; i++ {
		fmt.Printf("Hello, %s! (#%d)\n", name, i)
	}
}

// showHelp displays usage information
func showHelp() {
	fmt.Print(`Go CLI Application

Usage:
  go-project [options] <name>
  
Options:
  -c, -count <n>     Number of greetings (default: 1)
  -h, -help          Show this help message
  
Examples:
  go-project Alice                    # Greet Alice once
  go-project -count 3 Bob            # Greet Bob three times
  go-project -c 2 "World"            # Greet World twice
  
This project was created with nix-polyglot for reproducible development.
Use 'glot build' to build and 'glot run' to run.
`)
}

func main() {
	var (
		count int
		help  bool
	)

	// Define flags
	flag.IntVar(&count, "count", 1, "Number of greetings")
	flag.IntVar(&count, "c", 1, "Number of greetings (shorthand)")
	flag.BoolVar(&help, "help", false, "Show help message")
	flag.BoolVar(&help, "h", false, "Show help message (shorthand)")

	// Custom usage function
	flag.Usage = showHelp

	// Parse flags
	flag.Parse()

	// Show help if requested
	if help {
		showHelp()
		return
	}

	// Get remaining arguments (non-flag arguments)
	args := flag.Args()

	// Check if name was provided
	if len(args) == 0 {
		fmt.Println("Error: no name provided")
		showHelp()
		os.Exit(1)
	}

	// Check for multiple names
	if len(args) > 1 {
		fmt.Println("Error: multiple names provided")
		showHelp()
		os.Exit(1)
	}

	// Validate count
	if count <= 0 {
		fmt.Printf("Error: count must be positive, got %d\n", count)
		os.Exit(1)
	}

	name := args[0]
	greet(name, count)
}