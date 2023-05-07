#!/bin/bash

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--input)
      input_file=$2
      shift 2
      ;;
    -o|--output)
      output_dir=$2
      shift 2
      ;;
    -s|--split)
      split_level=$2
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# Check if required arguments are set
if [[ -z "$input_file" ]]; then
  echo "Input file not set"
  exit 1
fi

if [[ -z "$output_dir" ]]; then
  echo "Output directory not set"
  exit 1
fi

if [[ -z "$split_level" ]]; then
  echo "Split level not set"
  exit 1
fi

# Create output directory if it does not exist
mkdir -p "$output_dir"

# Loop through each line in the input file
while IFS= read -r line; do
  if [[ "$line" =~ ^#{1,$split_level}\  ]]; then
    # Extract the header level from the line
    header_level=$(echo "$line" | grep -o '#' | wc -l)

    # Generate the output file name
    output_file="$output_dir/$(echo "$line" | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]').md"

    # If the header level is less than or equal to the split level, create a new output file
    if [ "$header_level" -le "$split_level" ]; then
      echo "$line" > "$output_file"
    fi
  else
    # Append the line to the current output file
    echo "$line" >> "$output_file"
  fi
done < "$input_file"
