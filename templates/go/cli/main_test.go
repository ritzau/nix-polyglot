package main

import (
	"bytes"
	"io"
	"os"
	"strings"
	"testing"
)

// captureOutput captures stdout during function execution
func captureOutput(fn func()) string {
	// Backup the original stdout
	originalStdout := os.Stdout

	// Create a pipe to capture output
	r, w, _ := os.Pipe()
	os.Stdout = w

	// Create a channel to receive the output
	outputChan := make(chan string)

	// Start a goroutine to read from the pipe
	go func() {
		var buf bytes.Buffer
		io.Copy(&buf, r)
		outputChan <- buf.String()
	}()

	// Execute the function
	fn()

	// Close the writer and restore stdout
	w.Close()
	os.Stdout = originalStdout

	// Get the captured output
	output := <-outputChan
	return output
}

func TestGreet(t *testing.T) {
	tests := []struct {
		name     string
		gname    string
		count    int
		expected []string
	}{
		{
			name:     "single greeting",
			gname:    "Alice",
			count:    1,
			expected: []string{"Hello, Alice! (#1)"},
		},
		{
			name:     "multiple greetings",
			gname:    "Bob",
			count:    3,
			expected: []string{"Hello, Bob! (#1)", "Hello, Bob! (#2)", "Hello, Bob! (#3)"},
		},
		{
			name:     "zero count",
			gname:    "Charlie",
			count:    0,
			expected: []string{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			output := captureOutput(func() {
				greet(tt.gname, tt.count)
			})

			lines := strings.Split(strings.TrimSpace(output), "\n")
			if len(lines) == 1 && lines[0] == "" {
				lines = []string{}
			}

			if len(lines) != len(tt.expected) {
				t.Errorf("Expected %d lines, got %d", len(tt.expected), len(lines))
				return
			}

			for i, expected := range tt.expected {
				if lines[i] != expected {
					t.Errorf("Line %d: expected %q, got %q", i+1, expected, lines[i])
				}
			}
		})
	}
}

func TestGreetOutput(t *testing.T) {
	output := captureOutput(func() {
		greet("Test", 2)
	})

	expected := "Hello, Test! (#1)\nHello, Test! (#2)\n"
	if output != expected {
		t.Errorf("Expected %q, got %q", expected, output)
	}
}

func BenchmarkGreet(b *testing.B) {
	for i := 0; i < b.N; i++ {
		// Redirect to /dev/null for benchmark
		devNull, _ := os.Open(os.DevNull)
		originalStdout := os.Stdout
		os.Stdout = devNull

		greet("BenchmarkName", 10)

		os.Stdout = originalStdout
		devNull.Close()
	}
}

func Example_greet() {
	greet("World", 2)
	// Output:
	// Hello, World! (#1)
	// Hello, World! (#2)
}