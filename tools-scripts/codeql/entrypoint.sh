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

codeql database create codeql-db --language="$LANGUAGE" --source-root="target/repo/$REPO_NAME" --no-run-unnecessary-builds
codeql pack download codeql/$LANGUAGE-queries
codeql database analyze codeql-db \
    codeql/$LANGUAGE-queries:codeql-suites/$LANGUAGE-security-and-quality.qls \
    --format=sarif-latest \
    --output=target/results/codeql/results.sarif \
    --ram=10000 \
    --threads=8

