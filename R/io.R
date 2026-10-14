#' Import SAS macro source
#'
#' @param path A single path to an existing SAS source file. The app requires
#'   `.sas`; this function does not independently check the extension.
#' @return A `sas_macro` list with normalized `path`, UTF-8 `source`,
#'   `macro_names`, and `parameters` character vectors.
#' @details Metadata is extracted with regular expressions, not a complete SAS
#'   parser. Parameters are taken from the first matched macro declaration.
#'   The source is not executed or checked for SAS correctness.
#' @examples
#' path <- tempfile(fileext = ".sas")
#' writeLines("%macro derive_flag(input=, output=); %mend derive_flag;", path)
#' macro <- import_sas_macro(path)
#' macro$macro_names
#' macro$parameters
#' unlink(path)
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
#' @param path A single path to an existing text-based FRD file with extension
#'   `.txt`, `.md`, `.markdown`, or `.sas`.
#' @return A `frd_document` list with normalized `path` and UTF-8 `text`.
#' @details Reads the file as text without extracting or validating requirements.
#'   Missing files and unsupported extensions raise errors. PDF and DOCX parsing
#'   are outside the current scope.
#' @examples
#' path <- tempfile(fileext = ".txt")
#' writeLines("FRD-001: Set BASEFL to Y for BASELINE visits.", path)
#' frd <- read_frd(path)
#' frd$text
#' unlink(path)
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
