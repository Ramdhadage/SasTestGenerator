# sastestgenerator 0.0.1

* `app.R` now provides a bslib-based Shiny workflow for generating and
  downloading FRD-driven SAS validation matrices.
* `generate_sas_tests_openrouter()` calls OpenRouter through `ellmer` using
  the literal model identifier `gpt-4o-mini` by default.
* `generate_sas_tests()` creates an LLM-ready prompt and structured result.
* `import_sas_macro()` reads SAS source and extracts macro metadata.
* `read_frd()` reads text-based functional requirements documents.
