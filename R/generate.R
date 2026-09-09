#' Generate SAS test cases from an FRD and SAS macro
#'
#' @param frd An object returned by [read_frd()].
#' @param macro An object returned by [import_sas_macro()].
#' @param generator Optional function receiving the generated prompt and
#'   returning a structured result. This is the extension point for `ellmer`.
#' @return A list containing `prompt`, `requirements`, `test_cases`, and
#'   `sas_code`. Without `generator`, the test-case fields are intentionally
#'   empty and the result is suitable for passing to an LLM implementation.
#' @export
generate_sas_tests <- function(frd, macro, generator = NULL) {
  if (!inherits(frd, "frd_document")) {
    cli::cli_abort("{.arg frd} must be created with {.fn read_frd}.")
  }
  if (!inherits(macro, "sas_macro")) {
    cli::cli_abort("{.arg macro} must be created with {.fn import_sas_macro}.")
  }
  if (!is.null(generator) && !is.function(generator)) {
    cli::cli_abort("{.arg generator} must be a function or {.code NULL}.")
  }

  prompt <- build_generation_prompt(frd$text, macro$source)
  if (!is.null(generator)) {
    return(generator(prompt))
  }

  list(
    prompt = prompt,
    requirements = frd$text,
    macro = macro,
    test_cases = data.frame(),
    sas_code = character()
  )
}

#' Generate SAS tests with OpenRouter
#'
#' Uses [ellmer::chat_openrouter()] and the OpenRouter model
#' `openai/gpt-4.1-mini`. Set `OPENROUTER_API_KEY` in `.Renviron` before use.
#'
#' @param frd An object returned by [read_frd()].
#' @param macro An object returned by [import_sas_macro()].
#' @param model OpenRouter model identifier.
#' @param temperature Sampling temperature passed to `ellmer`.
#' @param max_tokens Maximum number of output tokens.
#' @return A list containing the prompt, raw response, and parsed JSON response.
#' @export
generate_sas_tests_openrouter <- function(
    frd,
    macro,
    model = "gpt-4o-mini",
    temperature = 0,
    max_tokens = 4096) {
  validate_generation_inputs(frd, macro)
  if (!is.character(model) || length(model) != 1L || !nzchar(model)) {
    cli::cli_abort("{.arg model} must be a non-empty character value.")
  }

  prompt <- build_generation_prompt(frd$text, macro$source)
  chat <- ellmer::chat_openrouter(
    system_prompt = paste(
      "Return only valid JSON. Do not wrap the JSON in Markdown fences.",
      "The top-level object must contain test_cases, sample_data, sas_code,  sas_test_code",
      "and traceability. Every test_cases item must contain exactly these keys:",
      "Test_ID, Requirement_ID, Test_Type, Test_Scenario, Input, Expected_Result.",
      "Use the exact underscore spelling shown; do not use spaces or hyphens",
      "in these keys. Requirement_ID must use the FRD requirement identifier",
      "(for example FRD-001), and Test_Type must describe the test category."
    ),
    model = model,
    params = ellmer::params(
      temperature = temperature,
      max_tokens = max_tokens
    ),
    echo = "none"
  )
  response <- chat$chat(prompt)

  parsed <- tryCatch(
    jsonlite::fromJSON(response, simplifyVector = FALSE),
    error = function(error) NULL
  )

  list(
    model = model,
    prompt = prompt,
    response = response,
    parsed = parsed
  )
}

validate_generation_inputs <- function(frd, macro) {
  if (!inherits(frd, "frd_document")) {
    cli::cli_abort("{.arg frd} must be created with {.fn read_frd}.")
  }
  if (!inherits(macro, "sas_macro")) {
    cli::cli_abort("{.arg macro} must be created with {.fn import_sas_macro}.")
  }
  invisible(TRUE)
}

build_generation_prompt <- function(frd_text, macro_source) {
  paste(
    
    "You are a Senior SAS Programmer and Clinical Programming Validation Expert.",
    "Generate structured JSON containing test cases, sample data, SAS validation/test code,",
    "and traceability for the supplied functional requirements and SAS macro.",
    "Functional requirements:",
    frd_text,
    "SAS macro:",
    macro_source,
    sep = "\n\n"
  )
}
