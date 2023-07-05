# Generate New PyTM Rules Against Gaps in CAPEC Coverage v2: Revenge of the LLMs.

An enhanced version of [CAPEC2PyTM](https://github.com/tbiehn/thoughtloom/tree/main/examples/CAPEC2PyTM) - this example improves gap recognition by lowering the complexity of gap recognition calls (40x the gaps), and splits the rule creation step into two, first reasoning about the applicable PyTM properties, and then writing the rule itself (by some other impressive amount).

Take a months-long adventure down to 40 minutes and ~$100 USD. Pipe it into a backlog. Human in the loop it. This example covers LLM identified gaps between PyTM's rule catalog and MITREs CAPEC using embeddings powered kNN retrieval ([Pinecone](https://www.pinecone.io/) via [embedmeup](https://github.com/tbiehn/embedmeup)). It'll write a PyTM rule, and then produce a positive and negative example for it.

## Directory Structure

```
./
├── CAPEC_Gaps             # Identifies gaps between the PyTM corpus and CAPEC.
├── CAPEC_Synth_step1      # Identifies PyTM properties for a given threat.
├── CAPEC_Synth_step2      # Creates PyTM rules given identified gaps & relevant properties.
├── README.md              # This README file.
├── Synth_pos_neg          # Creates a positive and negative example of each PyTM rule.
└── _work
    └── ex_*               # Candidate threat, PyTM positive and negative example models.
```

## How to Run the Example

You'll need a pinecone (free / starter) account, with an index and project name.
Make an index with `1536` dimensions. You'll see a URL in the dashboard; `[Index]-[Project].svc.[Region].pinecone.io`.

1. Set some environment variables - preferrably in a file that you `source`.

```bash
export OPENAI_API_KEY=
export PINECONE_API_KEY=
export p_index=
export p_region=
export p_project=
```

2. Execute the `example.sh` script:

```bash
./example.sh
```

This script will perform the following steps:

- Fetch the latest CAPEC, PyTM threats.json ruleset.
- Produce embeddings over PyTM threats - storing them for search in pinecone and retrieval from your home-directory.
- Use OpenAI functions to identify gaps in coverage by walking CAPEC findings through kNN retrieved PyTM threat with CAPEC_Gaps.
- Use those emitted function calls to generate identify relevant PyTM properties for threat recognition in CAPEC_Synth_step1. I've limited this to the first 10 in the example script - there's over 400 gaps, and that'll cost you around $60 in credits.
- Use the annotated gap to create a PyTM threat in CAPEC_Synth_step2 - as well formed rules emitted via function calls.
- Take the PyTM threat objects and generate positive and negative examples in Synth_pos_neg.
- Throw them into unique directories as 'threats.json', 'positive.py', 'negative.py'.

Triage and commit at will.

## Note

Please ensure that you have the latest version of ThoughtLoom / EmbedMeUp and the required dependencies installed before running this example.