#!/bin/bash

set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

source ./detect-language.sh
source ./extract-repo-name.sh
source ./setup-repo.sh

# Check if repo path is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <repo_path>"
  exit 1
fi

rm -rf ./target
mkdir -p ./target


REPO_PATH="$1"
echo "REPO_PATH" $REPO_PATH
REPO_NAME=$(basename $REPO_PATH)
echo $REPO_NAME
mkdir -p "./target/repo"
cp -r $REPO_PATH "./target/repo/$REPO_NAME"
CLONE_DIR="./target/repo/$REPO_NAME"
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
    mvn clean install -DskipTests
elif [ $LANGUAGE = "go" ]; then
    echo "Building Go project..."
    echo "Downloading Go dependencies and creating vendor directory..."
    go mod download
    go build ./...

else
    echo "Error: Unsupported language '$LANGUAGE'. Only Java and Go are supported."
    exit 1
fi
# Return to original directory
cd - > /dev/null

# Create all result directories
mkdir -p ./target/results/{codeql,sonar}

# Make all analyzer scripts executable
chmod +x ./tools-scripts/codeql/codeql-analyzer.sh
chmod +x ./tools-scripts/sonar/sonar-analyzer.sh

# Run all analyzers in parallel
echo "Starting all analyzers in parallel..."

# Start CodeQL Analyzer
echo "Starting CodeQL Analyzer..."
./tools-scripts/codeql/codeql-analyzer.sh $REPO_NAME $LANGUAGE &
CODEQL_PID=$!

# Start SonarQube Analyzer
echo "Starting SonarQube Analyzer..."
./tools-scripts/sonar/sonar-analyzer.sh $REPO_NAME $LANGUAGE &
SONAR_PID=$!

# Wait for all analyzers to complete
echo "Waiting for all analyzers to complete..."
wait $CODEQL_PID
wait $SONAR_PID
wait

echo "All analyzers have completed! Wait for the results to be generated..."

# Get current branch name from the repository
cd $CLONE_DIR
BRANCH_NAME=$(git branch --show-current)
if [ -z "$BRANCH_NAME" ]; then
    BRANCH_NAME="main"
fi
cd - > /dev/null

echo "Current branch: $BRANCH_NAME"

# Create timestamp for results directory
TIMESTAMP=$(date +%s)
RESULTS_DEST_DIR="$HOME/Documents/codeqt/$REPO_NAME/$BRANCH_NAME/$TIMESTAMP/results"

echo "Results will be copied to: $RESULTS_DEST_DIR"

# Function to monitor Docker containers and copy results
monitor_and_copy_results() {
    local repo_name="$1"
    local results_dest_dir="$2"
    
    echo "Starting background monitoring of Docker containers..."
    
    # Wait for all codeqt-* containers to exit
    while true; do
        # Check if any codeqt-* containers are still running
        running_containers=$(docker ps --filter "name=codeqt-" --format "{{.Names}}" 2>/dev/null || true)
        
        if [ -z "$running_containers" ]; then
            echo "All codeqt-* containers have exited. Copying results..."
            break
        else
            echo "Waiting for containers to exit: $running_containers"
            sleep 10
        fi
    done
    
    # Create destination directories
    mkdir -p "$results_dest_dir/codeql"
    mkdir -p "$results_dest_dir/sonar"
    
    # Convert SARIF to JSON if CodeQL results exist and copy results.json
    if [ -f "./target/results/codeql/results.sarif" ]; then
        echo "Converting CodeQL SARIF to JSON format..."
        
        # Ensure sarif-converter.sh is executable
        chmod +x "$(dirname "$0")/sarif-converter.sh"
        
        # Convert SARIF to JSON in target directory first
        "$(dirname "$0")/sarif-converter.sh" \
            "./target/results/codeql/results.sarif" \
            "./target/results/codeql/results.json"
        
        # Copy only the results.json file
        if [ -f "./target/results/codeql/results.json" ]; then
            cp "./target/results/codeql/results.json" "$results_dest_dir/codeql/"
            echo "✅ CodeQL results.json copied to: $results_dest_dir/codeql/"
        fi
    else
        echo "⚠️  No CodeQL SARIF file found to convert"
    fi
    
    # Copy SonarQube results.json if it exists
    if [ -f "./target/results/sonar/results.json" ]; then
        cp "./target/results/sonar/results.json" "$results_dest_dir/sonar/"
        echo "✅ SonarQube results.json copied to: $results_dest_dir/sonar/"
    else
        echo "⚠️  No SonarQube results.json file found"
    fi
    
    echo "Analysis complete! Results available at: $results_dest_dir"
    open -na "Google Chrome" --args --new-window "http://localhost:8081"
}

# Start background monitoring
monitor_and_copy_results "$REPO_NAME" "$RESULTS_DEST_DIR" &
MONITOR_PID=$!

echo "Background monitoring started with PID: $MONITOR_PID"
echo "You can check the progress by monitoring the containers with: docker ps --filter 'name=codeqt-'"