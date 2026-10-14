# Architecture

`sastestgenerator` is an R package with a repository-based Shiny app for drafting
SAS macro tests from an FRD and macro source. This map describes source inspected
on 2026-10-14; it does not establish clinical validation or successful execution.

## Current flow

1. **Inputs:** the app receives pasted FRD text and one uploaded `.sas` file.
   It writes the FRD to a temporary `.txt` file. Package callers can read
   `.txt`, `.md`, `.markdown`, or `.sas` FRDs directly.
2. **Import:** `read_frd()` returns a `frd_document`; `import_sas_macro()` returns
   a `sas_macro` with source, names, and parameters extracted by regular
   expressions. This is not a complete SAS parser.
3. **Generation:** `build_generation_prompt()` combines the complete FRD and
   source. `generate_sas_tests_openrouter()` calls `ellmer::chat_openrouter()`
   synchronously, requests JSON, and returns both raw and parsed responses.
4. **Normalization:** functions in `app.R` turn the parsed result into a
   six-column matrix, sample data, and two SAS code strings. The result lives in
   a session-local `reactiveVal()`.
5. **Review and download:** the app displays the matrix and offers a ZIP
   containing an XLSX workbook and two SAS files. Review is the user's
   responsibility; downloading does not require an approval decision.

The offline package path stops at prompt preparation unless a caller supplies
`generator`. That callback receives the prompt, and its return value is passed
through unchanged.

## Code map

| Location | Responsibility | Symbols |
| --- | --- | --- |
| `R/io.R` | Read FRD and SAS source; extract basic macro metadata | `read_frd()`, `import_sas_macro()` |
| `R/generate.R` | Validate object classes, construct prompts, call OpenRouter, parse JSON | `generate_sas_tests()`, `generate_sas_tests_openrouter()`, `build_generation_prompt()` |
| `app.R` | Compose UI, validate inputs, call generation, normalize results, download files | `ui`, `server`, `validate_app_inputs()`, `normalize_generated_result()` |
| `example.R`, `examples/` | Offline usage and synthetic FRD/SAS pairs | Visit-flag, toxicity-flag, and treatment-emergent-flag examples |
| `man/`, `vignettes/`, `_pkgdown.yml` | Generated API help, guides, site navigation | Four exported functions; getting-started and implementation articles |
| `DESCRIPTION`, `renv.lock`, `renv/settings.json` | Package dependencies and explicit runtime/development snapshot | Imports, Suggests, `VignetteBuilder` |

`app.R` loads the current source with `pkgload::load_all(".")` before composing
the application. Launch it from the repository root. The app is not exposed as
an installed-package `run_app()` function. `app_dinesh.R` is an ignored earlier
prototype with placeholder results; it is not the documented entry point.

## Enforcement and limits

| Boundary | Current mechanism and limit |
| --- | --- |
| Input files | Package checks file existence; FRD reading checks extensions. UI checks non-empty text, one SAS upload, and settings. SAS importing does not independently enforce a `.sas` extension. |
| Model response | JSON parsing may return `parsed = NULL`. The app checks a named parsed list and selected fields, then normalizes records. It does not independently verify requirement coverage, expected results, or SAS semantics. |
| Secrets | `ellmer` reads `OPENROUTER_API_KEY`; `.Renviron` is ignored by Git. There is no application-wide secret-redaction mechanism. |
| External transfer | The full FRD and SAS source are sent to OpenRouter and the selected provider. Permitted-input guidance is a documented policy; classification and de-identification are not enforced. |
| Generation | The call blocks its R process while waiting. A spinner and progress messages do not provide asynchronous execution, retries, or a cancellation control. |
| Traceability | Requirement labels and model-supplied traceability are displayed. They are not checked for completeness or bound to immutable input identities. |
| State | An error caught during generation clears the result. Input edits and an early input-validation return do not automatically invalidate an existing result. Regenerate after changes. |
| Export | A successful normalized result can be downloaded without an approval gate. Temporary export files are removed after download handling. The pasted-FRD temporary file has no explicit per-request deletion. |
| Reproducibility | The API returns the model, prompt, raw response, and parsed JSON. The ZIP omits these records, the input files, generation settings, and environment identity. Low temperature does not guarantee identical generations. |

## Scope and open decisions

PDF/DOCX parsing, SAS execution, independent statistical validation, enforced
human approval, authenticated identities, durable audit records, and qualified
deployment controls are outside the current implementation.

The historical app plan includes separate CSV/XLSX downloads. The current app
has one combined ZIP. That difference remains an open scope decision rather
than evidence that all planned exports exist.

## Documentation maintenance

Keep this file as the architecture source. The pkgdown architecture article
includes it during rendering, so the code map is maintained once. Update it
when entry points, data transfer, normalization, state, or exports change.
Keep detailed response shapes in the generation-contract article and observed
checks in `docs/verification.md`. Historical plans describe intent; they do not
override source behavior.
