#!/bin/bash

# Function to clone repository and setup directories
source ./extract-repo-name.sh

setup_and_clone_repo() {
    local repo_url=$1
    local repo_name=$(extract_repo_name $repo_url)
    
    # Define the clone directory
    local clone_dir="./target/repo/$repo_name"

    local result_dir="./target/results"
    mkdir -p "$result_dir"

    # Ensure parent directory exists
    mkdir -p "$(dirname "$clone_dir")"

    # Clone the repository
    git clone $repo_url $clone_dir
    echo "Cloned repository into $clone_dir" >&2
    echo $clone_dir
} 