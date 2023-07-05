# Generate New PyTM Rules Against Gaps in CAPEC Coverage.

Take a months-long adventure down to 40 minutes and ~$10 USD. Pipe it into a backlog. Human in the loop it. This example covers LLM identified gaps between PyTM's rule catalog and MITREs CAPEC using embeddings powered kNN retrieval ([Pinecone](https://www.pinecone.io/) via [embedmeup](https://github.com/tbiehn/embedmeup)). It'll write a PyTM rule, and then produce a positive and negative example for it.

## Directory Structure

```
./
├── CAPEC_Gaps             # Identifies gaps between the PyTM corpus and CAPEC.
├── CAPEC_Synth            # Creates PyTM rules given identified gaps.
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
- Use those emitted function calls to generate a PyTM rule in CAPEC_Synth - as well formed rules emitted via function calls.
- Take the PyTM threat objects and generate positive and negative examples in Synth_pos_neg.
- Throw them into unique directories as 'threats.json', 'positive.py', 'negative.py'.

Triage and commit at will.

## Note

Please ensure that you have the latest version of ThoughtLoom / EmbedMeUp and the required dependencies installed before running this example.