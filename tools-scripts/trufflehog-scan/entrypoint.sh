#!/bin/bash

# Run trufflehog and format output as JSON array
echo '[' > /root/target/results/trufflehog/results.json
trufflehog filesystem /root/target/repo/${REPO_NAME} --json | sed 's/^/,/' | sed '1s/^,//' >> /root/target/results/trufflehog/results.json
echo ']' >> /root/target/results/trufflehog/results.json
