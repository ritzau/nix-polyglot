# Nim configuration file
# This file sets up common compiler switches and project settings

switch("path", "$projectDir/src")
switch("path", "$projectDir/tests")

# Development mode settings
when not defined(release):
  switch("debugger", "native")
  switch("checks", "on") 
  switch("assertions", "on")
  switch("verbosity", "1")

# Release mode optimizations  
when defined(release):
  switch("opt", "speed")
  switch("checks", "off")
  switch("assertions", "off")
  switch("debugger", "off")

# Enable helpful warnings
switch("warning[UnusedImport]", "off")
switch("warning[CStringConv]", "off")

# Color output for better readability
switch("colors", "on")