#!/bin/sh
set -e

echo "Starting Grype scan..."
grype dir:/root/target/repo/${REPO_NAME} -o json > /root/target/results/grype/results.json

echo "Grype scan completed. Results saved in /root/target/results/grype/"
