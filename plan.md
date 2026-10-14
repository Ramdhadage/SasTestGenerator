# Plan: Connect app.R to sastestgenerator

## Current implementation note

This is the historical app plan. Its requirements are retained for
review; current behavior is described in
[ARCHITECTURE.md](https://ramdhadage.github.io/SasTestGenerator/ARCHITECTURE.md).

Source inspection on 2026-10-14 found the pasted-FRD, SAS-upload,
OpenRouter, matrix-display, and feedback paths in `app.R`. The active
download is one `Validation_Results.zip` containing an XLSX workbook and
two SAS files. Separate CSV and XLSX controls in the plan are not
implemented in the active app. Their intended scope remains open; this
documentation change does not add or remove those requirements. The
ignored `app_dinesh.R` is an earlier placeholder UI.

The documentation implementation and its build/browser results are
recorded in `docs/verification.md`.

## Summary

Transform the current static Shiny prototype into a functional
FRD-driven SAS validation matrix app using the existing package APIs,
live OpenRouter generation, bslib styling, and `checkmate` validation.

The first release will support:

- Pasted FRD text.
- Uploaded `.sas` macro source.
- Live OpenRouter generation.
- Expanded validation-matrix output.
- CSV, XLSX, and SAS ZIP downloads.
- Clear user-facing validation and generation errors.

## Implementation Changes

- Refactor `app.R` into a readable composition root with
  [`bslib::page_sidebar()`](https://rstudio.github.io/bslib/reference/page_sidebar.html)
  or `page_fluid()`, `bs_theme(version = 5)`, accessible colors,
  responsive cards, and optional dark-mode support.
- Add required dependencies to `DESCRIPTION` and update `renv.lock` only
  after approval: `shiny`, `bslib`, `checkmate`, and an XLSX writer such
  as `openxlsx` or `writexl`.
- Use `checkmate` for server-side validation of non-empty FRD text,
  exactly one uploaded `.sas` file, generation settings, and
  generated-result fields.
- On generation, write the FRD to a temporary `.txt` file, call
  [`read_frd()`](https://ramdhadage.github.io/SasTestGenerator/reference/read_frd.md)
  and
  [`import_sas_macro()`](https://ramdhadage.github.io/SasTestGenerator/reference/import_sas_macro.md),
  call
  [`generate_sas_tests_openrouter()`](https://ramdhadage.github.io/SasTestGenerator/reference/generate_sas_tests_openrouter.md),
  validate and normalize the result, and store it in reactive state.
- Preserve the raw model response and show a clear error when JSON
  parsing or schema validation fails.
- Normalize generated output into a matrix containing fields such as
  `Test_ID`, `Requirement_ID`, `Test_Type`, `Test_Scenario`,
  `Expected_Result`, and `Traceability`.
- Provide CSV, XLSX, and SAS ZIP downloads. The XLSX should include the
  matrix and relevant generated sample data.
- Use
  [`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html)
  for package-level errors and Shiny notifications or alerts for
  recoverable UI errors.
- Keep `OPENROUTER_API_KEY` external; never display or persist
  credentials.

## Testing and Acceptance Criteria

- Manually verify live generation, matrix display, CSV/XLSX downloads,
  SAS ZIP contents, API-key failure handling, responsive layout, and
  accessibility contrast.

## Assumptions

- Live OpenRouter is the primary execution mode.
- The expanded validation-matrix schema is the app’s normalized
  contract.
- CSV, XLSX, and SAS ZIP are required in the first implementation.
- SAS execution, PDF/DOCX parsing, and regulated validation evidence
  remain out of scope.
