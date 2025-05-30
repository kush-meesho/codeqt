#!/bin/bash

set -e

# Check if repo URL is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <repo_url>"
  exit 1
fi

REPO_URL="$1"

# Extract repo name (e.g., "my-app" from ".../my-app.git")
REPO_NAME=$(basename -s .git "$REPO_URL")

# Define the clone directory
CLONE_DIR="./target/repo/$REPO_NAME"

RESULT_DIR="./target/results"
mkdir -p "$RESULT_DIR"

# Remove existing repo directory if it exists
if [ -d "$CLONE_DIR" ]; then
  echo "Removing existing directory $CLONE_DIR..."
  rm -rf "$CLONE_DIR"
fi

# # Ensure parent directory exists
mkdir -p "$(dirname "$CLONE_DIR")"

# Clone the repository
echo "Cloning $REPO_URL into $CLONE_DIR..."
git clone "$REPO_URL" "$CLONE_DIR"

echo "Repository cloned successfully into $CLONE_DIR."

echo "Running CodeQL Analyzer"
chmod +x ./tools-scripts/codeql/codeql-analyzer.sh 
./tools-scripts/codeql/codeql-analyzer.sh 