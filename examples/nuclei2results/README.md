# Transform Nuclei Scan Results into a Report with an Executive Summary with ThoughtLoom

In this example, we will demonstrate how to use ThoughtLoom to transform Nuclei scan results into a report with individual findings and an executive summary.

![Demo](demo.gif)

## Example Directory Structure

The example directory contains the following files:

```
.
├── example.json (Sample Nuclei scan results)
├── example.sh (Bash script to run the ThoughtLoom example)
├── issues2summary_system.tmpl (System-prompt template for generating issue summaries)
├── issues2summary.toml (Configuration file for generating issue summaries)
├── issues2summary_user.tmpl (User-prompt template for generating issue summaries)
├── nuclei2issues_system.tmpl (System-prompt template for transforming Nuclei results into issues)
├── nuclei2issues.toml (Configuration file for transforming Nuclei results into issues)
├── nuclei2issues_user.tmpl (User-prompt template for transforming Nuclei results into issues)
├── summaries2executive_system.tmpl (System-prompt template for creating an executive summary)
├── summaries2executive.toml (Configuration file for creating an executive summary)
└── summaries2executive_user.tmpl (User-prompt template for creating an executive summary)
```

## How to Run the Example

1. Ensure that ThoughtLoom is installed and the API keys for OpenAI or Azure are properly set up as environment variables.

2. Navigate to the example directory:

```bash
cd examples/nuclei2results
```

3. Run the example.sh script:

```bash
./example.sh
```

This script will execute the following steps:

- **Step 1:**  Transform Nuclei scan results (example.json) into issues using the `nuclei2issues.toml` template. The output will be stored as `_work/report.json`.

- **Step 2:**  Generate issue summaries using the `issues2summary.toml` template with the input from `_work/report.json`. The output will be stored as `_work/summaries.json`.

- **Step 3:**  Create an executive summary using the `summaries2executive.toml` template with the input from `_work/summaries.json`. The output will be stored as `_work/summary.json`.

- **Step 4:**  Print the individual findings and the report summary to the console.

After the script finishes running, you can view the transformed issues, summaries, and executive summary in the `_work` directory.

With ThoughtLoom, you can quickly and easily process Nuclei scan results to generate valuable insights and present them in an easily understandable format.