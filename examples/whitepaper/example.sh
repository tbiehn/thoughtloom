#!/bin/bash
set -e

echo "This example can cost a few US dollars in API credits."
# Get user confirmation here.

mkdir -p '_work/splits'
rm -rf '_work/splits/*'

persona=$(cat tbiehn_persona.txt)
points=$(cat styleexample.txt)

# Step 1: Generate table of contents
# Input: tbiehn_persona.txt (Persona of the writer)
#        styleexample.txt (List of bullets for the whitepaper)
# Template: tocgen.toml (Template to generate table of contents)
# Output: _work/TOC.json (Table of contents in JSON format)
echo "Step 1/4: Generate table of contents"
jq -n --arg persona "$persona" --arg points "$points" '{persona: $persona, points: $points}' | \
  thoughtloom -c './TableOfContents/tocgen.toml' > './_work/TOC.json'

cat './_work/TOC.json' | jq -r .response > './_work/TOC.md'

# Step 2: Split the table of contents into sections
# Input: _work/TOC.md (Table of contents in Markdown format)
# Script: splitmd.sh (Shell script to split a Markdown file)
# Output: _work/splits/ (Directory containing split sections)
echo "Step 2/4: Split the table of contents into sections"
'./splitmd.sh' -i './_work/TOC.md' -o './_work/splits/' -s 3

# Step 3: Generate article segments
# Input: _work/splits/*.md (Individual sections from table of contents)
# Template: segment.toml (Template to generate article segments)
# Output: _work/sections.json (Generated article sections in JSON format)
echo "Step 3/4: Generate article segments"
for file in ./_work/splits/*.md; do
  section=$(cat "$file")
  jq -n --arg toc "$toc" --arg points "$points" --arg section "$section" '{toc: $toc, points: $points, section: $section}'
done | thoughtloom -c './ArticleSegment/segment.toml' > './_work/sections.json'

# Step 4: Combine sections into a single paper
# Input: _work/sections.json (Article sections in JSON format)
#        _work/TOC.md (Table of contents in Markdown format)
# Script: sections2paper.sh (Shell script to combine sections into a paper)
# Output: _work/paper.md (Final whitepaper in Markdown format)
echo "Step 4/4: Combine sections into a single paper"
'./sections2paper.sh' './_work/sections.json' './_work/TOC.md' './_work/paper.md'

echo "Results"
cat './_work/paper.md'

echo "Optionally create an output.pdf using pandoc"
echo "pandoc _work/paper.md -o _work/output.pdf --pdf-engine=pdflatex -V geometry:margin=1in"
