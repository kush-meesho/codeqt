#!/bin/bash

set -e

source ./detect-language.sh
source ./extract-repo-name.sh
source ./setup-repo.sh

# Check if repo URL is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <repo_url>"
  exit 1
fi

rm -rf ./target
mkdir -p ./target

REPO_URL="$1"
echo "REPO_URL" $REPO_URL
REPO_NAME=$(extract_repo_name $REPO_URL)
echo $REPO_NAME
CLONE_DIR=$(setup_and_clone_repo $REPO_URL)
echo "CLONE_DIR" $CLONE_DIR
LANGUAGE=$(detect_language $CLONE_DIR)

echo "Detected language: $LANGUAGE"

echo "REPO_NAME" $REPO_NAME

# Run build commands based on language
echo "Building project..."
# Store current directory

cd $CLONE_DIR
if [ $LANGUAGE = "java" ]; then
    echo "Building Java project with Maven..."
    # mvn clean install -DskipTests
elif [ $LANGUAGE = "go" ]; then
    echo "Building Go project..."
    echo "Downloading Go dependencies and creating vendor directory..."
    go mod download
    go mod vendor

else
    echo "Error: Unsupported language '$LANGUAGE'. Only Java and Go are supported."
    exit 1
fi
# Return to original directory
cd - > /dev/null


# echo "Running CodeQL Analyzer"
# chmod +x ./tools-scripts/codeql/codeql-analyzer.sh 
# mkdir -p ./target/results/codeql
# ./tools-scripts/codeql/codeql-analyzer.sh $REPO_NAME $LANGUAGE

# echo "Running SonarQube Analyzer"
# chmod +x ./tools-scripts/sonar/sonar-analyze.sh
# mkdir -p ./target/results/sonar
# ./tools-scripts/sonar/sonar-analyze.sh $REPO_NAME $LANGUAGE

echo "Running Gitleaks Analyzer"
chmod +x ./tools-scripts/gitleaks/gitleaks-analyzer.sh 
mkdir -p ./target/results/gitleaks
./tools-scripts/gitleaks/gitleaks-analyzer.sh $REPO_NAME $LANGUAGE