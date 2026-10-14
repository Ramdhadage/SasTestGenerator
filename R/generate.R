#' Generate SAS test cases from an FRD and SAS macro
#'
#' @param frd An object returned by [read_frd()].
#' @param macro An object returned by [import_sas_macro()].
#' @param generator An optional function receiving one prompt string. Its return
#'   value is passed through unchanged, without schema validation.
#' @return Without `generator`, a list with `prompt`, `requirements`, `macro`,
#'   an empty `test_cases` data frame, and an empty `sas_code` character vector.
#'   With `generator`, the value returned by that function.
#' @details The default path constructs a prompt and makes no network call.
#'   The complete FRD text and macro source are included in the prompt. Invalid
#'   input classes and a non-function generator raise errors.
#' @examples
#' frd_path <- tempfile(fileext = ".txt")
#' macro_path <- tempfile(fileext = ".sas")
#' writeLines("FRD-001: Set BASEFL to Y for BASELINE visits.", frd_path)
#' writeLines("%macro derive_flag(input=, output=); %mend;", macro_path)
#' frd <- read_frd(frd_path)
#' macro <- import_sas_macro(macro_path)
#' result <- generate_sas_tests(frd, macro)
#' cat(result$prompt)
#' generate_sas_tests(frd, macro, generator = function(prompt) nchar(prompt))
#' unlink(c(frd_path, macro_path))
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
#' Calls [ellmer::chat_openrouter()] synchronously. Set `OPENROUTER_API_KEY`
#' in `.Renviron` and restart R before use. The current model default is the
#' literal string `gpt-4o-mini`; confirm provider support before calling.
#'
#' @param frd An object returned by [read_frd()].
#' @param macro An object returned by [import_sas_macro()].
#' @param model A non-empty OpenRouter model identifier.
#' @param temperature Sampling temperature passed to `ellmer`.
#' @param max_tokens Maximum number of output tokens.
#' @return A list with `model`, `prompt`, raw response text in `response`, and
#'   JSON decoded with `simplifyVector = FALSE` in `parsed`. Invalid JSON produces
#'   `parsed = NULL`; decoded output is not checked against the requested schema.
#' @details The request sends the complete FRD text and SAS source to OpenRouter
#'   and its selected provider and may incur charges. Only use permitted content.
#'   Provider errors propagate. The requested JSON contains `test_cases`,
#'   `sample_data`, `sas_code`, `sas_test_code`, and `traceability`. Generated
#'   content requires review; SAS execution and coverage verification are not
#'   performed. This function has no application-level retries or cancellation.
#' @examples
#' \dontrun{
#' frd <- read_frd("examples/simple_frd.txt")
#' macro <- import_sas_macro("examples/simple_visit_flag.sas")
#' live_result <- generate_sas_tests_openrouter(frd, macro)
#' live_result$parsed
#' }
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
