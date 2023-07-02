#!/bin/bash
set -e

p_namespace=PyTM_Threats

if [[ -z "${p_index}" ]]; then
    read -p "PineconeDB Index not set, enter the index name: " p_index
fi

if [[ -z "${p_region}" ]]; then
    read -p "PineconeDB Region not set, enter the name of the region: " p_region
fi

if [[ -z "${p_project}" ]]; then
    read -p "PineconeDB Project not set, enter the project value: " p_project
fi

# Check and install missing commands
commands=("embedmeup" "thoughtloom" "jq" "xq-python")
commands_install=("go install github.com/tbiehn/embedmeup@latest" "go install github.com/tbiehn/thoughtloom@latest" "apt install jq" "apt install yq")
for i in "${!commands[@]}"; do
    if ! command -v ${commands[$i]} > /dev/null; then
        echo "${commands[$i]} is missing, install it with; ${commands_install[$i]}"
        exit 1
    fi
done

# Step 1: Create a working directory
mkdir -p '_work'

# Step 2: Download working files
wget https://capec.mitre.org/data/xml/capec_latest.xml -O _work/capec_latest.xml
wget https://raw.githubusercontent.com/izar/pytm/master/pytm/threatlib/threats.json -O _work/threats.json

# Step 3: Clear previous embeddings from namespace.
embedmeup -index="$p_index" -region="$p_region" -project "$p_project" -namespace "$p_namespace" -mode deleteAll

# Step 4: Prepare PyTM threats.json and upsert.
jq '.[] | .+ {embedding: (.description + " " + .details)}' < _work/threats.json | embedmeup -index="$p_index" -region="$p_region" -project "$p_project" -namespace "$p_namespace" -mode upsert -param embedding

# Step 5: Prepare CAPEC dataset and kNN retrieve closest threats.json matches.
xq-python -r '.["Attack_Pattern_Catalog"]["Attack_Patterns"]["Attack_Pattern"][] | select(."@Status" != "Deprecated")' _work/capec_latest.xml | jq '.Description |= (if type == "string" then . else tostring end)| . + {embedding:("# Name: " + .["@Name"]+"\n"+.Description)}' | embedmeup -index="$p_index" -region="$p_region" -project "$p_project" -namespace "$p_namespace" -mode retrieve -topK 5  -param embedding | tee _work/CAPEC_Enhanced.json | jq

# Step 6: Use an LLM to identify gaps between CAPEC issues and the retireved threats.json issues.
cat _work/CAPEC_Enhanced.json | thoughtloom -c ./CAPEC_Gaps/simple.toml -p 10 | tee _work/CAPEC_Run.json | jq

# Step 7: Generate a PyTM threat entry for each identified gap - drawing on the kNN closest issues for inspiration.
jq -n 'inputs | select(.finish_reason == "function_call") | .function_params |= fromjson | .identifier |= fromjson' _work/CAPEC_Run.json | thoughtloom -c ./CAPEC_Synth/simple.toml | tee _work/CAPEC_Synth.json | jq

# Step 8: Generate PyTM positive and negative model examples for each new PyTM threat.
cat _work/CAPEC_Synth.json | jq -r .function_params | thoughtloom -c ./Synth_pos_neg/simple.toml | tee _work/posneg.json | jq

# Step 9: Put each threat rule, positive, and negative example into its own directory.
jq 'select(.finish_reason == "function_call") | .function_params = (.function_params | fromjson) + {input: .identifier| fromjson} | .function_params' _work/posneg.json | jq -c -s '.[]' | while read -r line; do
  description=$(printf '%s' "$line" | jq -r '.input.description')
  description=$(echo "$description" | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]')
  description="_work/ex_$description"

  mkdir -p "$description"

  printf '%s' "$line" | jq -r '.positive' > "${description}/positive.py"
  printf '%s' "$line" | jq -r '.negative' > "${description}/negative.py"
  printf '%s' "$line" | jq '.input | .+ {SID:"TEST"} | [.]' > "${description}/threats.json"

  sed -i '/\(\s*[a-zA-Z_][a-zA-Z0-9_]*\)\.process()/ s//\1.threatsFile = ".\/threats.json"\n\1.process()/g' "${description}/positive.py"
  sed -i '/\(\s*[a-zA-Z_][a-zA-Z0-9_]*\)\.process()/ s//\1.threatsFile = ".\/threats.json"\n\1.process()/g' "${description}/negative.py"

done

# Step 10: Rejoice.