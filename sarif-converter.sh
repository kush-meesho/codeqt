#!/bin/bash

# SARIF to JSON Converter for CodeQL Results
# Converts SARIF format to a simplified JSON format similar to SonarQube

convert_sarif_to_json() {
    local input_file="$1"
    local output_file="$2"
    
    if [ ! -f "$input_file" ]; then
        echo "Error: SARIF file not found: $input_file"
        return 1
    fi
    
    echo "Converting SARIF to JSON: $input_file -> $output_file"
    
    # Use jq to transform SARIF to simplified JSON format
    jq '
    {
        total: ([.runs[]?.results[]?] | length),
        tool: (.runs[0]?.tool?.driver?.name // "CodeQL"),
        version: (.runs[0]?.tool?.driver?.semanticVersion // "unknown"),
        timestamp: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
        issues: [
            .runs[]?.results[]? | {
                key: (.ruleId + "-" + (.locations[0]?.physicalLocation?.artifactLocation?.uri // "unknown") + "-" + (.locations[0]?.physicalLocation?.region?.startLine // 0 | tostring)),
                ruleId: .ruleId,
                severity: (
                    if .level == "error" then "CRITICAL"
                    elif .level == "warning" then "MAJOR" 
                    elif .level == "note" then "MINOR"
                    else "INFO"
                    end
                ),
                component: (.locations[0]?.physicalLocation?.artifactLocation?.uri // "unknown"),
                line: (.locations[0]?.physicalLocation?.region?.startLine // 0),
                column: (.locations[0]?.physicalLocation?.region?.startColumn // 0),
                endLine: (.locations[0]?.physicalLocation?.region?.endLine // 0),
                endColumn: (.locations[0]?.physicalLocation?.region?.endColumn // 0),
                message: (.message?.text // "No description available"),
                category: "SECURITY",
                type: (
                    if (.properties?["security-severity"] // 0) > 7.0 then "VULNERABILITY"
                    elif (.properties?["security-severity"] // 0) > 4.0 then "SECURITY_HOTSPOT"
                    else "CODE_SMELL"
                    end
                ),
                securitySeverity: (.properties?["security-severity"] // 0),
                tags: (.properties?.tags // []),
                cwe: (.properties?.cwe // []),
                effort: (
                    if .level == "error" then "30min"
                    elif .level == "warning" then "15min"
                    else "5min"
                    end
                )
            }
        ],
        summary: {
            vulnerabilities: ([.runs[]?.results[]? | select(.level == "error")] | length),
            securityHotspots: ([.runs[]?.results[]? | select(.level == "warning")] | length),
            codeSmells: ([.runs[]?.results[]? | select(.level == "note" or .level == "info")] | length),
            totalIssues: ([.runs[]?.results[]?] | length)
        }
    }' "$input_file" > "$output_file"
    
    if [ $? -eq 0 ]; then
        echo "✅ SARIF conversion successful: $(jq -r '.total' "$output_file") issues found"
        return 0
    else
        echo "❌ SARIF conversion failed"
        return 1
    fi
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install jq first."
    echo "On macOS: brew install jq"
    echo "On Ubuntu: sudo apt-get install jq"
    exit 1
fi

# Main execution
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_sarif_file> <output_json_file>"
    echo "Example: $0 results.sarif codeql-results.json"
    exit 1
fi

convert_sarif_to_json "$1" "$2"
