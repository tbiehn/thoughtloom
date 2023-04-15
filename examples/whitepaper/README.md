# ThoughtLoom Whitepaper Example

This example demonstrates how to use ThoughtLoom to generate a full whitepaper from just a few bullet points.

This example can cost a few US dollars in API credits.

## Directory Structure

```
.
├── ArticleSegment		# Config and templates for generating a single article segment.
│ ├── segment.toml		# Config for generating an article segment.
│ ├── system.tmpl		# System template for segment.
│ └── user.tmpl			# User template for the segment.
├── example.sh			# Main script to run the example
├── sections2paper.sh	# This script combined generated samples into a single document.
├── splitmd.sh			# Splits the TOC into separate files for parallel processing.
├── styleexample.txt	# A text file containing bullet points for the whitepaper.
├── TableOfContents		# Config and templates for generating a table of contents from bullet points.
│ ├── system.tmpl		# System template for TOC generation
│ ├── tocgen.toml		# Config for TOC generation
│ └── user.tmpl			# User template for TOC generation
└── tbiehn_persona.txt	# A text file describing the desired writer persona for the whitepaper.
```

## How to Run

1. Ensure that ThoughtLoom is installed and properly configured on your system.
2. Open a terminal and navigate to the `examples/whitepaper` directory.
3. Run the `example.sh` script:

```
./example.sh
```

4. The final output will be saved as `_work/paper.md`. Optionally, you can generate a PDF version of the whitepaper by following the instructions printed at the end of the script.

## Steps

The `example.sh` script performs the following steps:

1. Generate a table of contents using the provided bullet points (`styleexample.txt`) and the desired writer persona (`tbiehn_persona.txt`).
2. Split the generated table of contents into individual sections.
3. Generate article segments for each section.
4. Combine the generated sections into a single paper (`_work/paper.md`).