#!/bin/bash

detect_language() {
    local clone_dir="$1"    
    local language=""
    
    if [ -f "$clone_dir/pom.xml" ] || [ -f "$clone_dir/build.gradle" ]; then
        language="java"
        echo "Detected Java project" >&2
    elif [ -f "$clone_dir/go.mod" ]; then
        language="go"
        echo "Detected Go project" >&2
    else
        echo "Error: Could not detect language. Repository must be either Java or Go." >&2
        exit 1
    fi

    echo "$language"
} 