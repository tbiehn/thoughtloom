#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <json_file> <toc_file> <output_file>"
  exit 1
fi

json_file=$1
toc_file=$2
output_file=$3

# Read the JSON file and extract the responses into an associative array
declare -A responses
total_responses=$(jq -sr 'length' "$json_file")

echo $total_responses

for ((i = 0; i < total_responses; i++)); do
  first_line=$(jq -sr --argjson index "$i" '.[$index].response | split("\n") | .[0]' "$json_file")
  response=$(jq -sr --argjson index "$i" '.[$index].response' "$json_file")
  echo Line: [$first_line]
  if [ -n "$response" ]; then
    responses["$first_line"]="$response"
  fi
done

# Read the TOC.md file and concatenate the responses in the correct order
combined_responses=""
while read -r line; do
  echo Considering: [$line]
    if [ -n "$line" ]; then
    response="${responses["$line"]}"
    if [ -n "$response" ]; then
      echo AddingSection: [$response]
      combined_responses+="${response}\n\n"
    fi
  fi
done < "$toc_file"

# Save the combined responses to a text file
echo -e "$combined_responses" > "$output_file"
