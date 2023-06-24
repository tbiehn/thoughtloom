#!/bin/bash
set -e

# Step 1: Create a working directory
mkdir -p '_work'

# Step 2: Fetch the last 10 hours of Bitcoin price history and transform it into the desired JSON structure
echo "Step 1/2: Fetching Bitcoin price history"
curl --location --request GET "api.coincap.io/v2/assets/bitcoin/history?interval=h1" | \
  jq '{data: [.data[] | {priceUsd: .priceUsd, date: .date}][-30:]}' > '_work/input.json'

# Step 3: Use thoughtloom with the 'buyorsell.toml' configuration to generate output
echo "Step 2/2: Generating output with thoughtloom"
cat '_work/input.json' | thoughtloom -c './buyorsell.toml' > '_work/result.json'

# Step 4: Print the result
echo "Printing the result:"
cat '_work/result.json' | jq -r .response
