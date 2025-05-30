#!/bin/bash

codeql database create codeql-db --language=java --source-root=target/repo/ads-campaign-management
codeql pack download codeql/java-all
codeql pack download codeql/java-queries
codeql database analyze codeql-db \
    codeql/java-queries:codeql-suites/java-security-and-quality.qls \
    --format=sarif-latest \
    --output=target/results/java-results.sarif \
    --ram=10000

