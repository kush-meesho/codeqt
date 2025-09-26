#!/bin/bash

# Check if REPO_NAME is set
if [ -z "$REPO_NAME" ]; then
    echo "Error: REPO_NAME environment variable is not set"
    exit 1
fi

# Check if LANGUAGE is set
if [ -z "$LANGUAGE" ]; then
    echo "Error: LANGUAGE environment variable is not set"
    exit 1
fi

# Validate language
if [ "$LANGUAGE" != "java" ] && [ "$LANGUAGE" != "go" ]; then
    echo "Error: Unsupported language '$LANGUAGE'. Must be either 'java' or 'go'"
    exit 1
fi

REPO_DIR="/root/target/repo/$REPO_NAME"
RESULTS_DIR="/root/target/results/sonar"

echo "⏳ Waiting for SonarQube to be ready..."
until curl -s http://sonarqube:9000/api/system/status | grep -q '"status":"UP"'; do
    sleep 5
    echo "Waiting for SonarQube..."
done

TOKEN_RESPONSE=$(curl -s -u admin:admin -X POST \
    "http://sonarqube:9000/api/user_tokens/generate" \
    -d "name=token-$(date +%s)")


AUTH_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

cd $REPO_DIR


SCANNER_PARAMS="-Dsonar.projectKey=$REPO_NAME -Dsonar.sources=. -Dsonar.host.url=http://sonarqube:9000 -Dsonar.token=$AUTH_TOKEN"

if [ -f "pom.xml" ]; then
    # BIN_DIRS=$(find . -type d -path "*/target/classes" | paste -sd "," -)
    BIN_DIRS=$(find . -type d -path "*/target/classes" | while read dir; do echo "$(pwd)/$dir"; done | paste -sd "," -)
    [ -n "$BIN_DIRS" ] && SCANNER_PARAMS="$SCANNER_PARAMS -Dsonar.java.binaries=$BIN_DIRS"
   
elif [ -f "build.gradle" ]; then
    [ -d "build/classes" ] && SCANNER_PARAMS="$SCANNER_PARAMS -Dsonar.java.binaries=build/classes"
   
elif [ -f "go.mod" ]; then
    SCANNER_PARAMS="$SCANNER_PARAMS -Dsonar.go.coverage.reportPaths=coverage.out"
else
    echo "❌ Error: Unsupported project type. Only Java (Maven/Gradle) and Go projects are supported."
    exit 1
fi

sonar-scanner $SCANNER_PARAMS

# Wait for analysis to finish
echo "⏳ Waiting for analysis to complete..."
cd - > /dev/null

# Poll the analysis status until it completes
while true; do
    ANALYSIS_STATUS=$(curl -s -u "$AUTH_TOKEN:" "http://sonarqube:9000/api/ce/activity?component=$REPO_NAME" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
    
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
METRICS=$(curl -s -u "$AUTH_TOKEN:" "http://sonarqube:9000/api/measures/component?component=$REPO_NAME&metricKeys=bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density,ncloc,complexity")
ISSUES=$(curl -s -u "$AUTH_TOKEN:" "http://sonarqube:9000/api/issues/search?componentKeys=$REPO_NAME")

echo $METRICS > metrics.json
echo $ISSUES > results.json

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