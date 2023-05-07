#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


# Step 1: Create a working directory
mkdir -p '_work'

# Step 2: Set the directory containing the file pairs
dir="./semgrep-sample"

# Step 3: Define a function to process file pairs and output a JSON object
process_file_pair() {
  local yaml_file="$1"
  local example_files=("$@") # Array of matched files, excluding the first argument (yaml_file)
  
  rules=$(cat "$yaml_file")
  examples=$(cat "${example_files[@]:1}") # Concatenate all matched files

  jq -n --arg rules "$rules" --arg examples "$examples" '{rules: $rules, examples: $examples}'
}

# Step 4: Loop through each pair of files in the directory
(
  for yaml_file in "$dir"/*.yaml; do
    # Get the file name without the extension
    base_name=$(basename "$yaml_file" .yaml)

    # Skip .test.yaml or .fix.yaml files.
    if [[ "$base_name" =~ \. ]]; then
      continue
    fi
    
    # Find all files that are not the corresponding YAML file
    matching_files=()
    for file in "$dir"/"$base_name".*; do
      if [ "$file" != "$yaml_file" ]; then
        matching_files+=("$file")
      fi
    done

    # Check if there are any matching files
    if [ ${#matching_files[@]} -gt 0 ]; then
      process_file_pair "$yaml_file" "${matching_files[@]}"
    else
      echo "No matching files found for $base_name.yaml" >&2
    fi

  done
) | thoughtloom -c "$script_dir/semgrep2policy.toml" > "./_work/results.json"

# Step 5: Print the results
cat "./_work/results.json" | jq -r .response