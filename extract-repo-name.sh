#!/bin/bash

# Function to extract repository name from URL
extract_repo_name() {
    local url="$1"
    
    # Check if URL is provided
    if [ -z "$url" ]; then
        echo "Error: URL is required" >&2
        return 1
    fi
    
    # Debug output
    echo "Extracting name from URL: $url" >&2
    
    # Extract and return the name
    local name=$(basename -s .git "$url")
    
    # Check if extraction was successful
    if [ -z "$name" ]; then
        echo "Error: Failed to extract repository name" >&2
        return 1
    fi
    
    echo "Extracted name: $name" >&2
    echo "$name"
} 