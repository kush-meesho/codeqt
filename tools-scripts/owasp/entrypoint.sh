#!/bin/sh
set -e

echo "Inside Owasp Analyzer"
# Check if required environment variables are set
if [ -z "$REPO_NAME" ]; then
    echo "Error: REPO_NAME environment variable is not set"
    exit 1
fi

REPO_PATH="usr/share/dependency-check/target/repo/${REPO_NAME}"
RESULTS_DIR="usr/share/dependency-check//target/results/owasp"

echo "Running OWASP Dependency Check analysis on: ${REPO_PATH}"
# Run OWASP Dependency Check
/usr/share/dependency-check/bin/dependency-check.sh \
    --scan "${REPO_PATH}" \
    --format "HTML" \
    --format "JSON" \
    --out ${RESULTS_DIR} \
    --project "${REPO_NAME}" \
    --disableCentral \
    --failOnCVSS 0 \
    --nvdApiKey ${NVD_API_KEY}

echo "OWASP Dependency Check analysis completed. Results saved in /root/target/results/owasp/"
