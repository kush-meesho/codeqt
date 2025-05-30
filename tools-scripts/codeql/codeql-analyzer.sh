#!/bin/bash
set -e

IMAGE_NAME="codeql-codeql-analyzer:latest"
SERVICE_NAME="codeql-analyzer"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Inside CodeQL Analyzer"
echo "Script directory: $SCRIPT_DIR"

# Check if image exists locally
if [[ "$(docker images -q "$IMAGE_NAME" 2> /dev/null)" == "" ]]; then
    echo "Docker image '$IMAGE_NAME' not found locally. Building it..."
    cd "$SCRIPT_DIR" && docker-compose build "$SERVICE_NAME"
else
    echo "Docker image '$IMAGE_NAME' already exists. Skipping build."
fi

# Run the container interactively
echo "Starting the container..."
cd "$SCRIPT_DIR" && docker-compose run "$SERVICE_NAME"
