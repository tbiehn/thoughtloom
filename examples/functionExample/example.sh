#!/bin/bash
set -e

# Step 1: Create a working directory
mkdir -p '_work'

# Step 2: Get a function call out of thoughtloom.
echo "Step 2/2: Generating output with thoughtloom"
echo '{"line":"just some sample input"}' | thoughtloom -c './callfn.toml' > '_work/result.json'

# Step 3: Print the result
echo "Did the model say OK?"
cat '_work/result.json' | jq -r .response
echo "Function the model called;"
cat '_work/result.json' | jq -r .function_name
echo "Parameters for the function call;"
cat '_work/result.json' | jq -r .function_params
echo "Reason the response finished;"
cat '_work/result.json' | jq -r .finish_reason
