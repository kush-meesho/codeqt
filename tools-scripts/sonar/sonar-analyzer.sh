#!/bin/bash
set -e

# Check if required parameters are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Repository URL and language are required"
    echo "Usage: $0 <repository-url> <language>"
    exit 1
fi

REPO_NAME=$1
LANGUAGE=$2


IMAGE_NAME="codeqt-sonar-analyzer:latest"
SERVICE_NAME="sonarqube-analyzer"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"



echo "Inside Sonar Analyzer"
echo "Script directory: $SCRIPT_DIR"

# Check if image exists locally
if [[ "$(docker images -q "$IMAGE_NAME" 2> /dev/null)" == "" ]]; then
    echo "Docker image '$IMAGE_NAME' not found locally. Building it..."
    cd "$SCRIPT_DIR" && REPO_NAME="$REPO_NAME" LANGUAGE="$LANGUAGE" docker-compose build "$SERVICE_NAME"
else
    echo "Docker image '$IMAGE_NAME' already exists. Skipping build."
fi

# Run the container interactively
echo "Starting the container..."
cd "$SCRIPT_DIR" && REPO_NAME="$REPO_NAME" LANGUAGE="$LANGUAGE" docker-compose up --force-recreate --exit-code-from "$SERVICE_NAME" "$SERVICE_NAME"

docker wait codeqt-sonar-analyzer-1 > /dev/null 2>&1 &

docker rm -f sonarqube > /dev/null 2>&1 &