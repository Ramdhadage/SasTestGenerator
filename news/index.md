# Changelog

## sastestgenerator 0.0.1

- `app.R` now provides a bslib-based Shiny workflow for generating and
  downloading FRD-driven SAS validation matrices.
- [`generate_sas_tests_openrouter()`](https://ramdhadage.github.io/SasTestGenerator/reference/generate_sas_tests_openrouter.md)
  calls OpenRouter through `ellmer` using the literal model identifier
  `gpt-4o-mini` by default.
- [`generate_sas_tests()`](https://ramdhadage.github.io/SasTestGenerator/reference/generate_sas_tests.md)
  creates an LLM-ready prompt and structured result.
- [`import_sas_macro()`](https://ramdhadage.github.io/SasTestGenerator/reference/import_sas_macro.md)
  reads SAS source and extracts macro metadata.
- [`read_frd()`](https://ramdhadage.github.io/SasTestGenerator/reference/read_frd.md)
  reads text-based functional requirements documents.
