#!/bin/bash
set -e

# Check if required parameters are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Repository URL and language are required"
    echo "Usage: $0 <repository-url> <language>"
    exit 1
fi

REPO_NAME=$1


echo "REPO_NAME" $REPO_NAME
REPO_DIR="../../target/repo/$REPO_NAME"
RESULTS_DIR="../../target/results/trufflehog"
mkdir -p $RESULTS_DIR

IMAGE_NAME="codeq-trufflhog-analyzer:latest"
SERVICE_NAME="trufflehog-analyzer"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Inside Trufflehog Analyzer"
echo "Script directory: $SCRIPT_DIR"

SERVICE_NAME="trufflehog-analyzer"

# Check if image exists locally
if [[ "$(docker images -q "$IMAGE_NAME" 2> /dev/null)" == "" ]]; then
    echo "Docker image '$IMAGE_NAME' not found locally. Building it..."
    cd "$SCRIPT_DIR" && REPO_NAME="$REPO_NAME" LANGUAGE="$LANGUAGE" docker-compose build "$SERVICE_NAME"
else
    echo "Docker image '$IMAGE_NAME' already exists. Skipping build."
fi

# Run the container interactively
echo "Starting the container..."
cd "$SCRIPT_DIR" && REPO_NAME="$REPO_NAME" LANGUAGE="$LANGUAGE" docker-compose up  -d --force-recreate $SERVICE_NAME


