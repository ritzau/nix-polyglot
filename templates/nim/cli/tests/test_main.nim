## Test suite for the main module
##
## This demonstrates basic unit testing patterns in Nim
## Run with: nim c -r tests/test_main.nim

import std/[unittest, strutils, os]
import main

suite "Main module tests":
  
  setup:
    # Setup code that runs before each test
    discard
  
  teardown:
    # Cleanup code that runs after each test
    discard
  
  test "greeting function works correctly":
    # Test the basic greeting functionality
    # Since greet() outputs to stdout, we'll test it indirectly
    # by checking that it doesn't crash
    expect(void):
      greet("Test", 1)
  
  test "greeting with multiple counts":
    # Test multiple greetings
    expect(void):
      greet("Test", 3)
  
  test "greeting with zero count":
    # Test edge case - zero count should work (empty loop)
    expect(void):
      greet("Test", 0)

# Additional integration-style tests could go here
suite "CLI integration tests":
  
  test "help message is available":
    # This tests that showHelp doesn't crash
    expect(void):
      showHelp()

echo "✅ All tests completed!"