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


echo "REPO_NAME" $REPO_NAME
REPO_DIR="../../target/repo/$REPO_NAME"
RESULTS_DIR="../../target/results/sonar"
mkdir -p $RESULTS_DIR

IMAGE_NAME="codeq-sonar-analyzer:latest"
SERVICE_NAME="sonar-analyzer"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Inside Sonar Analyzer"
echo "Script directory: $SCRIPT_DIR"

SERVICE_NAME="sonarqube-analyzer"

# Check if image exists locally
if [[ "$(docker images -q "$IMAGE_NAME" 2> /dev/null)" == "" ]]; then
    echo "Docker image '$IMAGE_NAME' not found locally. Building it..."
    cd "$SCRIPT_DIR" && REPO_NAME="$REPO_NAME" LANGUAGE="$LANGUAGE" docker-compose build "$SERVICE_NAME"
else
    echo "Docker image '$IMAGE_NAME' already exists. Skipping build."
fi

# Run the container interactively
echo "Starting the container..."
cd "$SCRIPT_DIR" && REPO_NAME="$REPO_NAME" LANGUAGE="$LANGUAGE" docker-compose up -d --force-recreate $SERVICE_NAME




echo "⏳ Waiting for SonarQube to be ready..."
until curl -s http://localhost:9000/api/system/status | grep -q '"status":"UP"'; do
    sleep 5
    echo "Waiting for SonarQube..."
done

# Create project and token
curl -s -u admin:admin -X POST "http://localhost:9000/api/projects/create" \
    -d "project=$REPO_NAME" \
    -d "name=$REPO_NAME" || true

TOKEN_RESPONSE=$(curl -s -u admin:admin -X POST \
    "http://localhost:9000/api/user_tokens/generate" \
    -d "name=token-$(date +%s)")

AUTH_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$AUTH_TOKEN" ]; then
    echo "❌ Failed to generate token"
    echo "Token response: $TOKEN_RESPONSE"
    exit 1
fi

echo "✅ Token generated successfully"

cd $REPO_DIR


SCANNER_PARAMS="-Dsonar.projectKey=$REPO_NAME -Dsonar.sources=. -Dsonar.host.url=http://localhost:9000 -Dsonar.login=$AUTH_TOKEN"

if [ -f "pom.xml" ]; then
    echo "🔧 Maven project detected. Compiling..."
    mvn compile || true
    BIN_DIRS=$(find . -type d -path "*/target/classes" | paste -sd "," -)
    [ -n "$BIN_DIRS" ] && SCANNER_PARAMS="$SCANNER_PARAMS -Dsonar.java.binaries=$BIN_DIRS"
    echo "📊 Running tests and generating coverage report..."
    mvn clean test org.jacoco:jacoco-maven-plugin:0.8.11:prepare-agent org.jacoco:jacoco-maven-plugin:0.8.11:report || true
    [ -f "target/site/jacoco/jacoco.xml" ] && SCANNER_PARAMS="$SCANNER_PARAMS -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml"
elif [ -f "build.gradle" ]; then
    echo "🔧 Gradle project detected. Compiling..."
    ./gradlew compileJava || true
    [ -d "build/classes" ] && SCANNER_PARAMS="$SCANNER_PARAMS -Dsonar.java.binaries=build/classes"
    echo "📊 Running tests and generating coverage report..."
    ./gradlew clean test jacocoTestReport --no-daemon -x check || true
    [ -f "build/reports/jacoco/test/jacocoTestReport.xml" ] && SCANNER_PARAMS="$SCANNER_PARAMS -Dsonar.coverage.jacoco.xmlReportPaths=build/reports/jacoco/test/jacocoTestReport.xml"
elif [ -f "go.mod" ]; then
    echo "🔧 Go project detected..."
    go build ./... || true
    echo "📊 Generating Go test coverage report..."
    go test -coverprofile=coverage.out ./... || true
    SCANNER_PARAMS="$SCANNER_PARAMS -Dsonar.go.coverage.reportPaths=coverage.out"
else
    echo "❌ Error: Unsupported project type. Only Java (Maven/Gradle) and Go projects are supported."
    exit 1
fi



# Run scanner with --network host to access localhost:9000
echo "🔍 Running SonarQube scanner..."
docker run --rm --network host \
    -v "$(pwd):/usr/src" \
    sonarsource/sonar-scanner-cli \
    $SCANNER_PARAMS

# Wait for analysis to finish
echo "⏳ Waiting for analysis to complete..."
cd - > /dev/null

# Poll the analysis status until it completes
while true; do
    ANALYSIS_STATUS=$(curl -s -u "$AUTH_TOKEN:" "http://localhost:9000/api/ce/activity?component=$REPO_NAME" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [ "$ANALYSIS_STATUS" = "SUCCESS" ]; then
        echo "✅ Analysis completed successfully"
        break
    elif [ "$ANALYSIS_STATUS" = "FAILED" ]; then
        echo "❌ Analysis failed"
        exit 1
    else
        echo "⏳ Analysis still in progress..."
        sleep 5
    fi
done

echo "📊 Fetching analysis results..."

cd $RESULTS_DIR

# Get results
METRICS=$(curl -s -u "$AUTH_TOKEN:" "http://localhost:9000/api/measures/component?component=$REPO_NAME&metricKeys=bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density,ncloc,complexity")
ISSUES=$(curl -s -u "$AUTH_TOKEN:" "http://localhost:9000/api/issues/search?componentKeys=$REPO_NAME")

echo $METRICS > metrics.json
echo $ISSUES > issues.json

cat > "summary.txt" << EOF
SonarQube Analysis Summary
==========================
Project: $REPO_NAME
Date: $(date)
Dashboard: http://localhost:9000/dashboard?id=$REPO_NAME

Token: $AUTH_TOKEN

Generated:
- metrics.json
- issues.json

EOF


echo "✅ Analysis completed. Results saved in $RESULTS_DIR"
echo "🌐 View results at: http://localhost:9000/dashboard?id=$REPO_NAME"

