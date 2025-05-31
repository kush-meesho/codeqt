#!/bin/bash

set -e

# Check if repo URL is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <repo_url>"
  exit 1
fi

rm -rf ./target
mkdir -p ./target

REPO_URL="$1"
echo "REPO_URL" $REPO_URL
# Extract repo name (e.g., "my-app" from ".../my-app.git")
REPO_NAME=$(basename -s .git "$REPO_URL")

# Define the clone directory
CLONE_DIR="./target/repo/$REPO_NAME"

RESULT_DIR="./target/results"
rm -rf "$RESULT_DIR"
mkdir -p "$RESULT_DIR"

# # Ensure parent directory exists
mkdir -p "$(dirname "$CLONE_DIR")"

# Clone the repository
echo "Cloning $REPO_URL into $CLONE_DIR..."
git clone "$REPO_URL" "$CLONE_DIR"

echo "Repository cloned successfully into $CLONE_DIR."

# Detect language
LANGUAGE=""
if [ -f "$CLONE_DIR/pom.xml" ] || [ -f "$CLONE_DIR/build.gradle" ]; then
    LANGUAGE="java"
elif [ -f "$CLONE_DIR/go.mod" ]; then
    LANGUAGE="go"
    echo "Downloading Go dependencies and creating vendor directory..."
    cd "$CLONE_DIR"
    # First download all dependencies
    go mod download
    # Then create vendor directory
    go mod vendor
    cd - > /dev/null
else
    echo "Error: Could not detect language. Repository must be either Java or Go."
    exit 1
fi

echo "Detected language: $LANGUAGE"

echo "REPO_NAME" $REPO_NAME

# Run build commands based on language
echo "Building project..."
# Store current directory
CURRENT_DIR=$(pwd)
cd "$CLONE_DIR"
if [ "$LANGUAGE" = "java" ]; then
    echo "Building Java project with Maven..."
    mvn clean package -DskipTests
elif [ "$LANGUAGE" = "go" ]; then
    echo "Building Go project..."
    go build ./...
fi
# Return to original directory
cd "$CURRENT_DIR"


echo "Running CodeQL Analyzer"
chmod +x ./tools-scripts/codeql/codeql-analyzer.sh 
./tools-scripts/codeql/codeql-analyzer.sh $REPO_NAME $LANGUAGE