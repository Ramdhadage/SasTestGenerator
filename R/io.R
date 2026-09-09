#' Import SAS macro source
#'
#' @param path Path to a `.sas` file.
#' @return An object of class `sas_macro` containing the source and basic
#'   metadata.
#' @export
import_sas_macro <- function(path) {
  check_input_file(path, "SAS macro")
  source <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )

  structure(
    list(
      path = normalizePath(path, winslash = "/", mustWork = TRUE),
      source = source,
      macro_names = extract_macro_names(source),
      parameters = extract_macro_parameters(source)
    ),
    class = "sas_macro"
  )
}

#' Read a functional requirements document
#'
#' @param path Path to a text-based FRD file (`.txt`, `.md`, or `.sas`).
#' @return An object of class `frd_document` containing the document text.
#' @export
read_frd <- function(path) {
  check_input_file(path, "functional requirements document")
  extension <- tolower(tools::file_ext(path))
  if (!extension %in% c("txt", "md", "markdown", "sas")) {
    cli::cli_abort(c(
      "Unsupported FRD format: {.val {extension}}.",
      "i" = "The initial POC supports {.file .txt}, {.file .md}, and {.file .sas}."
    ))
  }

  structure(
    list(
      path = normalizePath(path, winslash = "/", mustWork = TRUE),
      text = paste(readLines(path, warn = FALSE, encoding = "UTF-8"),
        collapse = "\n"
      )
    ),
    class = "frd_document"
  )
}

check_input_file <- function(path, label) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !file.exists(path)) {
    cli::cli_abort("{label} file {.file {path}} does not exist.")
  }
  invisible(path)
}

extract_macro_names <- function(source) {
  matches <- gregexpr("%macro[[:space:]]+([[:alnum:]_]+)",
    source,
    ignore.case = TRUE,
    perl = TRUE
  )
  values <- regmatches(source, matches)[[1L]]
  sub("%macro[[:space:]]+", "", values, ignore.case = TRUE)
}

extract_macro_parameters <- function(source) {
  starts <- gregexpr("(?is)%macro[[:space:]]+[[:alnum:]_]+[[:space:]]*\\([^)]*\\)",
    source,
    perl = TRUE
  )
  values <- regmatches(source, starts)[[1L]]
  if (length(values) == 0L || identical(values, character())) {
    return(character())
  }
  parameters <- sub(".*\\(", "", values)
  parameters <- sub("\\).*", "", parameters)
  parameters <- trimws(strsplit(parameters, ",", fixed = TRUE)[[1L]])
  sub("=.*", "", parameters)
}
