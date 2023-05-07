#!/bin/bash
set -e

# Create work directory and set input directory
mkdir -p _work
input_dir="_work/patches"
mkdir -p "$input_dir"

# Clear the input directory
rm -rf "$input_dir/*"

# Run Semgrep scan and output issues to issues.json
semgrep scan ./sample-scripts \
  --json -q \
  --no-rewrite-rule-ids \
  --disable-version-check \
  --metrics off \
  --config ./semgrep-sample | ./vuln2context.sh | tee _work/issues.json

# Generate fixes using ThoughtLoom and output to fixes.json
cat ./_work/issues.json | thoughtloom -c ./semgrep2fix.toml > _work/fixes.json

# Print responses from fixes.json
cat ./_work/fixes.json | jq -r .response

counter=1

# Iterate through responses and create patch files
cat ./_work/fixes.json | jq -c 'select(has("response"))' | while IFS= read -r line; do
  response=$(echo "$line" | jq -r '.response')
  if [[ -n "$response" ]]; then
    content=$(echo "$response" | sed -n '/```diff/,/```/ p' | sed '1d;$d')
    echo "$content" > "$input_dir/patch_$counter.diff"
    counter=$((counter + 1))
  fi
done

set +e

fuzz_factor=5

# Apply patches with a fuzz factor
for patch in "$input_dir"/*.diff; do
  patch_name=$(basename "$patch")
  echo "Applying $patch_name with a fuzz factor of $fuzz_factor..."

  # Try applying the patch with the specified fuzz factor and capture the success status
  patch -p0 -l --dry-run --fuzz=$fuzz_factor < "$patch" 
  success=$?

  # Report the patch application success or failure
  if [ $success -eq 0 ]; then
    echo "Applied $patch_name successfully."
  else
    echo "Failed to apply $patch_name."
  fi
done
