# Generate SAS tests with OpenRouter

Calls
[`ellmer::chat_openrouter()`](https://ellmer.tidyverse.org/reference/chat_openrouter.html)
synchronously. Set `OPENROUTER_API_KEY` in `.Renviron` and restart R
before use. The current model default is the literal string
`gpt-4o-mini`; confirm provider support before calling.

## Usage

``` r
generate_sas_tests_openrouter(
  frd,
  macro,
  model = "gpt-4o-mini",
  temperature = 0,
  max_tokens = 4096
)
```

## Arguments

- frd:

  An object returned by
  [`read_frd()`](https://ramdhadage.github.io/SasTestGenerator/reference/read_frd.md).

- macro:

  An object returned by
  [`import_sas_macro()`](https://ramdhadage.github.io/SasTestGenerator/reference/import_sas_macro.md).

- model:

  A non-empty OpenRouter model identifier.

- temperature:

  Sampling temperature passed to `ellmer`.

- max_tokens:

  Maximum number of output tokens.

## Value

A list with `model`, `prompt`, raw response text in `response`, and JSON
decoded with `simplifyVector = FALSE` in `parsed`. Invalid JSON produces
`parsed = NULL`; decoded output is not checked against the requested
schema.

## Details

The request sends the complete FRD text and SAS source to OpenRouter and
its selected provider and may incur charges. Only use permitted content.
Provider errors propagate. The requested JSON contains `test_cases`,
`sample_data`, `sas_code`, `sas_test_code`, and `traceability`.
Generated content requires review; SAS execution and coverage
verification are not performed. This function has no application-level
retries or cancellation.

## Examples

``` r
if (FALSE) { # \dontrun{
frd <- read_frd("examples/simple_frd.txt")
macro <- import_sas_macro("examples/simple_visit_flag.sas")
live_result <- generate_sas_tests_openrouter(frd, macro)
live_result$parsed
} # }
```
