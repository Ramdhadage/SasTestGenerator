# Repository Guidelines

## Project Structure & Module Organization

This repository is an R package proof of concept for generating SAS
macro test cases from functional requirements. Public package functions
live in `R/`: `io.R` reads FRD and SAS files, while `generate.R` builds
prompts and provides the optional OpenRouter/`ellmer` integration.
`app.R` owns the Shiny interface, result normalization, and combined ZIP
download. `example.R` is an offline usage example with assertions.
Package metadata and exports are in `DESCRIPTION` and `NAMESPACE`;
generated API documentation belongs in `man/`. Dependency versions are
managed with `renv.lock`. PDF/DOCX parsing and SAS execution are outside
the current scope. Read `ARCHITECTURE.md` for current wiring and limits.
User guides live in `vignettes/`; `docs/verification.md` records
observed checks and unverified paths. `Prompt with details.md` and
`plan.md` retain historical design intent and open requirements; they do
not establish implemented behavior.

## Build, Test, and Development Commands

Run these from the repository root in R or RStudio:

``` r

renv::restore()             # Restore locked dependencies
devtools::load_all(".")    # Load the package for interactive development
source("example.R")        # Exercise the local prompt-generation workflow
devtools::document()        # Generate NAMESPACE and man/ from roxygen comments
pkgdown::check_pkgdown()    # Check article and function reference registration
pkgdown::build_site(preview = FALSE) # Build to pkgdown-site/
shiny::runApp(".")         # Launch the app; live generation needs an API key
devtools::check()           # Run package checks and documentation checks
```

There is currently no test suite or local build script. When adding
tests, place them under `tests/testthat/` and run
[`devtools::test()`](https://devtools.r-lib.org/reference/test.html)
before
[`devtools::check()`](https://devtools.r-lib.org/reference/check.html).
Use `OPENROUTER_API_KEY` through `.Renviron` for live model calls; never
commit credentials or generated sensitive data. Documentation tools are
declared in `Suggests` and included in the explicit renv snapshot. Keep
live model calls out of automatically executed examples and vignettes.
Record package-check, example, and Chrome DevTools results separately;
source inspection is not runtime or SAS validation.

## Coding Style & Naming Conventions

Use standard R formatting with four-space indentation, snake_case
function and variable names, and explicit package-qualified calls for
imported functions (for example,
[`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html)).
Keep public functions small and document them with roxygen2 comments;
update `NAMESPACE` and `man/` through roxygen2, not by hand. Preserve
the existing S3-like object classes (`frd_document` and `sas_macro`)
when extending the API.

## Testing Guidelines

No framework or coverage threshold is configured yet. New behavior
should add `testthat` tests covering successful parsing, malformed or
unsupported inputs, prompt construction, and validation errors. Keep
tests deterministic by injecting a generator function; do not require
network access or an API key in the default test run.

## Commit & Pull Request Guidelines

Use concise imperative messages consistent with the existing Git
history, such as `Add FRD validation`. Preserve unrelated uncommitted
changes. Pull requests should explain the user-visible or API change,
list validation commands and results, identify dependency or lockfile
changes, and note any out-of-scope limitations. Include a small
reproducible example for changes to prompt or generated-output behavior.
