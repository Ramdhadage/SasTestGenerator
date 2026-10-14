# Generation contract and downloads

This guide describes the prompt and normalization code inspected on
2026-10-14. It separates what the model is asked to produce from what
the application checks.

## Package return values

[`generate_sas_tests()`](https://ramdhadage.github.io/SasTestGenerator/reference/generate_sas_tests.md)
without a callback returns an offline list containing `prompt`,
`requirements`, `macro`, an empty `test_cases` data frame, and an empty
`sas_code` character vector. With a callback, it returns the callback’s
value unchanged.

[`generate_sas_tests_openrouter()`](https://ramdhadage.github.io/SasTestGenerator/reference/generate_sas_tests_openrouter.md)
returns:

| Field | Value |
|----|----|
| `model` | Requested model identifier |
| `prompt` | Prompt containing the FRD and macro source |
| `response` | Raw model response text |
| `parsed` | JSON decoded with `simplifyVector = FALSE`, or `NULL` when decoding fails |

Provider and authentication errors propagate from `ellmer`. Invalid JSON
does not itself raise a package error: `parsed` becomes `NULL`. The
package does not enforce the requested output schema after decoding.

## Requested JSON

The system prompt requests these top-level fields: `test_cases`,
`sample_data`, `sas_code`, `sas_test_code`, and `traceability`. Each
test case is requested to contain exactly `Test_ID`, `Requirement_ID`,
`Test_Type`, `Test_Scenario`, `Input`, and `Expected_Result`.

The following is an illustrative shape, not a recorded model response or
an executed SAS test:

``` json
{
  "test_cases": [
    {
      "Test_ID": "TC001",
      "Requirement_ID": "FRD-001",
      "Test_Type": "POSITIVE",
      "Test_Scenario": "A BASELINE visit receives the baseline flag",
      "Input": "VISIT = BASELINE",
      "Expected_Result": "BASEFL = Y"
    }
  ],
  "sample_data": [{"VISIT": "BASELINE"}],
  "sas_code": "/* Draft SAS sample-data program */",
  "sas_test_code": "/* Draft SAS validation program */",
  "traceability": ["FRD-001 -> TC001"]
}
```

The prompt does not fully specify the nested sample-data or traceability
schema, or establish a guaranteed division of responsibility between the
two SAS files. Review both programs rather than inferring their contents
from their filenames.

## What the app accepts and displays

`normalize_generated_result()` requires a named response list and a
named `parsed` list containing `test_cases` and `sas_code`. Both SAS
fields are then normalized: character vectors are joined with newlines,
and other values must pass a string assertion. Consequently, a missing
`sas_test_code` also fails normalization, even though it is not named in
the initial presence assertion.

The matrix has these six columns:

| Column | Current normalization |
|----|----|
| `Test_ID` | Model value, or a generated `TC001`-style identifier |
| `Requirement_ID` | Model value, or an empty string |
| `Test_Type` | Model value, or an empty string |
| `Test_Scenario` | Model value, or an empty string |
| `Expected_Result` | Model value, or an empty string |
| `Traceability` | Per-record value, otherwise the corresponding positional top-level entry, otherwise empty |

Recognized alternative field spellings are handled by the code in
`normalize_test_cases()` and `as_text()`. Missing descriptive fields can
become empty cells. `Input` is requested from the model but is not
displayed or included in the exported matrix. Extra test-case fields are
also omitted from that matrix. Requirement IDs and traceability are not
checked against the FRD or assessed for complete coverage.

`sample_data` can be a data frame, row-record list, column list, or
scalar-like value. Missing sample data becomes an empty data frame.
Row-record values are converted to strings and nested values joined with
`;`; uneven column lists are recycled to a common length. These
conversions do not verify SAS variable types, input constraints, or
consistency with the generated programs.

## Downloads

The active download button creates `Validation_Results.zip` with:

| File | Contents |
|----|----|
| `Validation_Test_Matrix.xlsx` | `Validation_Matrix` and `Sample_Data` worksheets |
| `sas_code.sas` | Normalized model-supplied `sas_code` |
| `sas_test_code.sas` | Normalized model-supplied `sas_test_code` |

The workbook is written by `writexl`; ZIP creation uses
[`utils::zip()`](https://rdrr.io/r/utils/zip.html) and needs a working
ZIP utility on the host. The app does not offer separate CSV or XLSX
buttons. Those controls remain in the historical plan as an unresolved
scope difference.

## Failure and assurance boundaries

- Missing credentials stop live generation. Invalid UI inputs receive
  field feedback. Provider errors and failed normalization are shown as
  notifications.
- A caught generation error clears the result. Input changes and an
  early input-validation return can leave a previous result available;
  regenerate and confirm the correct input context before downloading.
- Empty matrices can produce a display validation message; downloading
  only checks that a normalized result exists. Display status is not an
  approval gate.
- The raw response is retained in the session result but is not
  exported. The ZIP also omits original inputs, prompt/model/settings,
  environment details, timestamps, and approval records. It is not a
  reproducibility or audit bundle.
- JSON success and a populated matrix do not establish SAS syntax,
  execution, expected-result correctness, or requirement coverage. Low
  temperature does not guarantee identical model output.
- The app sends the full FRD and SAS source to OpenRouter and its
  selected provider. It has no data-classification or de-identification
  control, enforced approval, durable evidence store, or SAS execution
  service.

For the input-to-export path and owning functions, read the
[architecture
article](https://ramdhadage.github.io/SasTestGenerator/articles/architecture.md).
