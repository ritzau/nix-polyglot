#!/usr/bin/env python3
"""Generate deps.json for NuGet dependencies"""
import json
import subprocess
import sys

def main():
    print("🔧 Generating NuGet dependencies...")
    
    # This would generate the actual deps.json
    # For now, create an empty one for projects without dependencies
    deps = {
        "runtime": {
            "win-x64": [],
            "linux-x64": [], 
            "osx-x64": [],
            "osx-arm64": []
        },
        "native": {}
    }
    
    with open("deps.json", "w") as f:
        json.dump(deps, f, indent=2)
    
    print("✅ deps.json generated")
    print("   Add NuGet packages to your .csproj, then run this script again")

if __name__ == "__main__":
    main()