#!/bin/bash

# CodeQT hook script - delegates to the main codeqt-fs.sh script
# This script is typically called from git hooks and needs to pass the repository path

# Get the current repository root directory
REPO_PATH=$(git rev-parse --show-toplevel 2>/dev/null)

# If we can't determine the repo path, use the current directory
if [ -z "$REPO_PATH" ]; then
    REPO_PATH=$(pwd)
fi

echo "CodeQT: Running analysis on repository: $REPO_PATH"

# Path to the main codeqt-fs.sh script
CODEQT_SCRIPT="$HOME/.git-templates/codeqt/codeqt-fs.sh"

# Check if the codeqt-fs.sh script exists
if [ ! -f "$CODEQT_SCRIPT" ]; then
    echo "Error: CodeQT script not found at $CODEQT_SCRIPT"
    echo "Please ensure the codeqt tools are properly installed in your git templates."
    exit 1
fi

# Make sure the script is executable; if not, make it so
if [ ! -x "$CODEQT_SCRIPT" ]; then
    chmod +x "$CODEQT_SCRIPT"
fi

# Execute the main codeqt script with the repository path
echo "CodeQT: Starting analysis..."
exec "$CODEQT_SCRIPT" "$REPO_PATH"