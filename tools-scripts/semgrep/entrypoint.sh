#!/bin/bash
set -e


semgrep --config=auto /root/target/repo/$REPO_NAME --json-output=/root/target/results/semgrep/results.json --verbose