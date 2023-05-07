#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Read JSON input from stdin
json_input=$(cat)

# Process JSON with jq
echo "$json_input" | jq -r '.results[] | "\(.path):\(.start.line)-\(.end.line):\(.check_id)"' | while read -r line_info; do
  file_path=$(echo "$line_info" | cut -d: -f1)
  start_line=$(echo "$line_info" | cut -d: -f2 | cut -d- -f1)
  end_line=$(echo "$line_info" | cut -d: -f2 | cut -d- -f2)
  check_id=$(echo "$line_info" | cut -d: -f3)

  # Calculate the difference between the start and end lines
  diff=$((end_line - start_line))

  # If the difference is less than 20, calculate lines to display around the affected lines
  if [ "$diff" -lt 20 ]; then
    padding=$(( (20 - diff) / 2 ))
    first_line=$((start_line - padding))
    last_line=$((end_line + padding))
  else
    first_line=$start_line
    last_line=$end_line
  fi

  # Ensure the first_line is not less than 1
  if [ "$first_line" -lt 1 ]; then
    first_line=1
  fi

  # Get the contents of the file including FIX START and FIX END comments
  contents=$(awk -v start_line=$start_line -v first_line=$first_line -v end_line=$end_line -v last_line=$last_line -v check_id=$check_id '
    NR>=first_line && NR<start_line { print }
    NR==start_line { printf "# FIX START [%s]\n", check_id; print }
    NR>start_line && NR<=end_line { print }
    NR==end_line+1 { printf "# FIX END [%s]\n", check_id; print }
    NR>end_line+1 && NR<=last_line { print }
  ' "$file_path")

  policy=$(awk -v check_id=$check_id '/^# rule:\s*/ { in_block = match($0, check_id) } in_block { print }' "$script_dir/policies.txt")

  # Create JSON object
  jq -n \
    --arg xcheck "$check_id" \
    --arg xfile "$file_path" \
    --argjson xstart "$first_line" \
    --argjson xend "$last_line" \
    --arg xcontents "$contents" \
    --arg xpolicy "$policy" \
    '{check: $xcheck, file: $xfile, start: $xstart, end: $xend, contents: $xcontents, policy: $xpolicy}'
done
