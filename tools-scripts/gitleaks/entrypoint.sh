#!/bin/bash
set -e

gitleaks dir -v /root/target/repo/${REPO_NAME} --report-path /root/target/results/gitleaks/results.json
