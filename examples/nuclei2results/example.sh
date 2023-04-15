#!/bin/bash
set -e

mkdir -p '_work'


# Step 1: Transform Nuclei scan results into issues
# Input: example.json (Nuclei scan results)
# Template: nuclei2issues.toml (Template to transform Nuclei results into issues)
# Output: _work/report2.json (Transformed issues)
echo "Step 1/3: Transform Nuclei scan results into issues"
cat example.json | thoughtloom -c './nuclei2issues.toml' > '_work/report.json'

# Step 2: Generate issue summaries
# Input: _work/report.json (Issues from previous step)
# Template: issues2summary.toml (Template to create issue summaries)
# Output: _work/summaries.json (Generated summaries)
echo "Step 2/3: Generate issue summaries"
cat '_work/report.json' | thoughtloom -c './issues2summary.toml' > '_work/summaries.json'

# Step 3: Create an executive summary
# Input: _work/summaries.json (Issue summaries from previous step)
# Process: Use jq to format the input for thoughtloom
# Template: summaries2executive.toml (Template to create an executive summary)
# Output: _work/summary.json (Final executive summary)
echo "Step 3/3: Create an executive summary"
cat '_work/summaries.json' | \
  jq -s '{items:map(.response)}' | \
  thoughtloom -c './summaries2executive.toml' > '_work/summary.json'

# Step 4: Print all the results
echo "Printing individual findings..."
cat '_work/report.json' | jq -r .response

# echo "Printing finding summaries..."
# cat '_work/summaries.json' | jq -r .response

echo "Printing report summary..."
cat '_work/summary.json' | jq -r .response