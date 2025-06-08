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

# Create all result directories
mkdir -p ./target/results/{codeql,sonar,gitleaks,trufflehog,owasp,grype,semgrep}

# Make all analyzer scripts executable
chmod +x ./tools-scripts/codeql/codeql-analyzer.sh
chmod +x ./tools-scripts/sonar/sonar-analyzer.sh
chmod +x ./tools-scripts/gitleaks/gitleaks-analyzer.sh
chmod +x ./tools-scripts/trufflehog-scan/trufflehog-analyzer.sh
chmod +x ./tools-scripts/owasp/owasp-analyzer.sh
chmod +x ./tools-scripts/grype/grype-analyzer.sh
chmod +x ./tools-scripts/semgrep/semgrep-analyzer.sh

# Run all analyzers in parallel
echo "Starting all analyzers in parallel..."

# # Start CodeQL Analyzer
# echo "Starting CodeQL Analyzer..."
# ./tools-scripts/codeql/codeql-analyzer.sh $REPO_NAME $LANGUAGE &
# CODEQL_PID=$!

# # Start SonarQube Analyzer
# echo "Starting SonarQube Analyzer..."
# ./tools-scripts/sonar/sonar-analyzer.sh $REPO_NAME $LANGUAGE &
# SONAR_PID=$!

# # Start Gitleaks Analyzer
# echo "Starting Gitleaks Analyzer..."
# ./tools-scripts/gitleaks/gitleaks-analyzer.sh $REPO_NAME $LANGUAGE &
# GITLEAKS_PID=$!

# # Start Trufflehog Analyzer
# echo "Starting Trufflehog Analyzer..."
# ./tools-scripts/trufflehog-scan/trufflehog-analyzer.sh $REPO_NAME $LANGUAGE &
# TRUFFLEHOG_PID=$!

# echo "Starting Owasp Analyzer..."
# ./tools-scripts/owasp/owasp-analyzer.sh $REPO_NAME $LANGUAGE &
# OWASP_PID=$!

# echo "Starting Grype Analyzer..."
# ./tools-scripts/grype/grype-analyzer.sh $REPO_NAME $LANGUAGE &
# GRYPE_PID=$!

echo "Starting Semgrep Analyzer..."
./tools-scripts/semgrep/semgrep-analyzer.sh $REPO_NAME $LANGUAGE &
SEMGREP_PID=$!

# Wait for all analyzers to complete
echo "Waiting for all analyzers to complete..."
# wait $CODEQL_PID
# wait $SONAR_PID
# wait $GITLEAKS_PID
# wait $TRUFFLEHOG_PID
# wait $OWASP_PID
# wait $GRYPE_PID
wait $SEMGREP_PID
wait

echo "All analyzers have completed! Wait for the results to be generated..."