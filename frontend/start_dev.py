#!/usr/bin/env python3
import subprocess
import os
import sys

# Change to frontend directory
frontend_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(frontend_dir)

print(f"Starting frontend development server in: {frontend_dir}")

# Run npm dev server with shell=True to use system PATH
try:
    # Use shell=True to ensure npm is found in PATH
    result = subprocess.run(['npm', 'run', 'dev'], shell=True, check=False)
    if result.returncode != 0:
        print(f"npm dev exited with code: {result.returncode}")
except FileNotFoundError:
    print("Error: npm not found. Make sure Node.js is installed and npm is in PATH.")
    print("You can install Node.js from: https://nodejs.org/")
    sys.exit(1)
except KeyboardInterrupt:
    print("\nFrontend server stopped by user")
except Exception as e:
    print(f"Unexpected error: {e}")