#!/bin/bash
set -e

# Create a _work directory if it doesn't exist
mkdir -p '_work'

# Step 1: Extract a persona using LLMs for each article
# Input: Writing samples in ./samples/*.md
# Template: author.toml (Template to extract author persona)
# Output: _work/insight.json (Insights on author persona)
echo "Step 1/2: Extracting author persona for each article"
find ./samples -name "*.md" -type f -print0 | \
  xargs -0 -I{} jq -Rs '{ "article": . }' {} | \
  thoughtloom -c './author.toml' > '_work/insight.json'

# Step 2: Summarize author persona
# Input: _work/insight.json (Insights from previous step)
# Process: Use jq to format the input for thoughtloom
# Template: reduce.toml (Template to summarize author persona)
# Output: _work/reduced.json (Final summary of author persona)
echo "Step 2/2: Summarizing author persona"
cat '_work/insight.json' | \
  jq -s '{items:map(.response)}' | \
  thoughtloom -c './reduce.toml' > '_work/reduced.json'

# Print the results
echo "Printing individual insights..."
cat '_work/insight.json' | jq -s '{items:map(.response)}'

echo "Printing the summary of author persona..."
cat '_work/reduced.json' | jq -r .response