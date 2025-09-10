#!/usr/bin/env python3
import subprocess
import os
import sys

# Change to frontend directory
frontend_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(frontend_dir)

print(f"Starting frontend development server in: {frontend_dir}")

# Use cmd.exe to run npm (more reliable on Windows)
try:
    # Run through cmd.exe for better PATH resolution
    cmd = ['cmd', '/c', 'npm', 'run', 'dev']
    result = subprocess.run(cmd, check=False)
    if result.returncode != 0:
        print(f"npm dev exited with code: {result.returncode}")
except FileNotFoundError:
    print("Error: Could not start npm. Make sure Node.js is installed.")
    sys.exit(1)
except KeyboardInterrupt:
    print("\nFrontend server stopped by user")
except Exception as e:
    print(f"Unexpected error: {e}")