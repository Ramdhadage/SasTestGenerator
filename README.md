# sastestgenerator

Minimal proof-of-concept R package for preparing SAS macro validation tests from
functional requirements documents (FRDs).

## Current scope

The initial package can:

1. Read text-based FRDs.
2. Import SAS macro source and extract macro names and parameters.
3. Build a structured prompt for an LLM.
4. Accept an optional generator function for an `ellmer` integration.

```r
frd <- read_frd("requirements.txt")
macro <- import_sas_macro("derive_flag.sas")

result <- generate_sas_tests(frd, macro)
cat(result$prompt)

# Set OPENROUTER_API_KEY in .Renviron before calling the live model.
live_result <- generate_sas_tests_openrouter(frd, macro)
live_result$parsed
```

PDF/DOCX parsing and generated SAS execution are intentionally outside this
first POC boundary. The OpenRouter API key is read by `ellmer` from the
`OPENROUTER_API_KEY` environment variable and is never stored by the package.
