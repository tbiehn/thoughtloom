# Extract Author Persona Example

This example demonstrates how to use ThoughtLoom to analyze a set of writing samples and generate a summary of the author's persona and writing style. The script processes each article to extract author persona insights and then summarizes them into a single description, helping LLMs emulate the author's distinct style, perspective, and philosophical impulses.

## Directory Structure

```
./
├── author.toml                  # Template to extract author persona
├── example.sh                   # Main script to run the example
├── reduce.toml                  # Template to summarize author persona
├── samples                      # Directory containing writing samples
├── system_reduce.tmpl           # System template for reducing summaries
├── system.tmpl                  # System template for author extraction
├── user_reduce.tmpl             # User template for reducing summaries
├── user.tmpl                    # User template for author extraction
└── _work                        # Directory for generated output files
```

## How to Run the Example

1. Place your writing samples as Markdown files (`.md`) in the `samples` directory. I've put a few of my own articles in there.
2. Make sure you have `ThoughtLoom`, `jq`, and the required environment variables set up as described in the main ThoughtLoom README.
3. Run the `example.sh` script from the terminal:

```bash
./example.sh
```

The script will process the writing samples, extract author personas, and create a summarized author persona. The output will be saved in the `_work` directory as `insight.json` and `reduced.json`.