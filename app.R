library(pkgload)
library(shiny)
pkgload::load_all(".")


app_theme <- bslib::bs_theme(
  version = 5,
  preset = "shiny",
  primary = "#1f5a85",
  info = "#0b7285",
  "border-radius" = "0.5rem"
)

matrix_columns <- c(
  "Test_ID", "Requirement_ID", "Test_Type", "Test_Scenario",
  "Expected_Result", "Traceability"
)

ui <- bslib::page_sidebar(
  title = "Validation Matrix Creator",
  theme = app_theme,
  class = "bslib-page-dashboard",
  shinyFeedback::useShinyFeedback(),
  waiter::use_waiter(),
  sidebar = bslib::sidebar(
    bslib::accordion(
      bslib::accordion_panel(
        "Generation settings",
        textInput("model", "OpenRouter model", value = "gpt-4o-mini"),
        numericInput(
          "temperature", "Temperature", value = 0,
          min = 0, max = 2, step = 0.1
        ),
        numericInput(
          "max_tokens", "Maximum output tokens", value = 4096,
          min = 256, max = 32768, step = 256
        )
      ),
      bslib::accordion_panel(
        "About",
        p(
          "This proof of concept prepares FRD-driven SAS macro validation
          tests. Review generated content before using it in a validated
          workflow."
        )
      ),
      open = FALSE
    ),
    bslib::input_dark_mode(id = "dark_mode")
  ),
  bslib::layout_columns(
    bslib::card(
      bslib::card_header("1. Functional requirements"),
      textAreaInput(
        "frd", "Paste the FRD",
        placeholder = "Paste your functional requirements here...",
        width = "100%", height = "260px"
      )
    ),
    bslib::card(
      bslib::card_header("2. SAS macro"),
      fileInput(
        "sas_file", "Upload a SAS macro", accept = ".sas", multiple = FALSE
      ),
      checkboxInput(
        "include_sas", "Include generated SAS program in downloads", TRUE
      ),
      bslib::input_task_button(
        "generate", "Generate test cases", label_busy = "Generating..."
      ),
      textOutput("configuration_note")
    ),
    col_widths = c(8, 4)
  ),
  bslib::card(
    bslib::card_header("Generated validation matrix"),
    uiOutput("result_status"),
    tableOutput("test_matrix"),
    bslib::layout_columns(
      downloadButton("download_xlsx", "Download XLSX"),
      downloadButton("download_sas", "Download SAS ZIP"),
      col_widths = c(4, 4, 4)
    )
  )
)

server <- function(input, output, session) {
  generated <- shiny::reactiveVal(NULL)

  output$configuration_note <- renderText({
    shiny::validate(shiny::need(
      nzchar(Sys.getenv("OPENROUTER_API_KEY")),
      "OPENROUTER_API_KEY is not configured. Add it to .Renviron before generating."
    ))
    "OPENROUTER_API_KEY is configured for live generation."
  })

  observeEvent(input$generate, {
    waiter::waiter_show(
      id = "generate",
      html = waiter::spin_circle(),
      color = "#1f5a85",
      hide_on_render = FALSE
    )
    on.exit(waiter::waiter_hide("generate"), add = TRUE)

    tryCatch(
      {
        if (!validate_app_inputs(input)) {
          shiny::showNotification(
            "Review the highlighted inputs before generating.",
            type = "error",
            duration = 5
          )
          return()
        }
        if (!nzchar(Sys.getenv("OPENROUTER_API_KEY"))) {
          stop(
            "OPENROUTER_API_KEY is not configured. Add it to .Renviron and restart the app."
          )
        }

        shiny::showNotification(
          "Generation started.", type = "message", duration = 2
        )
        shiny::withProgress(
          message = "Generating test cases",
          detail = "Preparing the FRD and SAS macro",
          value = 0,
          {
            shiny::incProgress(0.15)
            frd_path <- tempfile(fileext = ".txt")
            writeLines(input$frd, frd_path, useBytes = TRUE)
            frd <- sastestgenerator::read_frd(frd_path)
            macro <- sastestgenerator::import_sas_macro(input$sas_file$datapath)
            shiny::incProgress(
              0.25,
              detail = "Requesting structured test cases from OpenRouter"
            )
            response <- generate_sas_tests_openrouter(
              frd = frd,
              macro = macro,
              model = input$model,
              temperature = input$temperature,
              max_tokens = input$max_tokens
            )
            shiny::incProgress(0.45, detail = "Validating generated output")
            generated(normalize_generated_result(response))
            shiny::incProgress(0.15, detail = "Preparing downloads")
          }
        )
        shiny::showNotification(
          "Test cases generated successfully.", type = "message"
        )
      },
      error = function(error) {
        generated(NULL)
        shiny::showNotification(
          conditionMessage(error), type = "error", duration = NULL
        )
      }
    )
  })

  output$result_status <- renderUI({
    result <- generated()
    shiny::validate(shiny::need(
      !is.null(result),
      "No generated output yet. Enter the inputs and select Generate test cases."
    ))
    shiny::validate(shiny::need(
      nrow(result$matrix) > 0,
      "The generated response did not contain any validation test cases."
    ))
    sprintf("%d test case(s) ready for review.", nrow(result$matrix))
  })

  output$test_matrix <- renderTable({
    result <- generated()
    shiny::validate(shiny::need(
      !is.null(result),
      "Generate test cases to display the validation matrix."
    ))
    shiny::validate(shiny::need(
      nrow(result$matrix) > 0,
      "No validation matrix rows were returned by the model."
    ))
    result$matrix
  }, striped = TRUE, bordered = TRUE, hover = TRUE, na = "")

  output$download_xlsx <- downloadHandler(
    filename = function() "Validation_Test_Matrix.xlsx",
    content = function(file) {
      result <- require_generated_result(generated())
      writexl::write_xlsx(
        list(
          Validation_Matrix = result$matrix,
          Sample_Data = result$sample_data
        ),
        path = file
      )
    }
  )

  output$download_sas <- downloadHandler(
    filename = function() "SAS_Test_Programs.zip",
    content = function(file) {
      result <- require_generated_result(generated())
      if (!isTRUE(input$include_sas)) {
        shiny::showNotification(
            "Enable the SAS program download before downloading the ZIP.",
            type = "error",
            duration = 5
          )
      }
    sas_dir <- tempfile("sas_exports_")
    dir.create(sas_dir)
    on.exit(unlink(sas_dir, recursive = TRUE, force = TRUE), add = TRUE)

    sas_code_path <- file.path(sas_dir, "sas_code.sas")
    sas_test_code_path <- file.path(sas_dir, "sas_test_code.sas")

    writeLines(result$sas_code, sas_code_path, useBytes = TRUE)
    writeLines(result$sas_test_code, sas_test_code_path, useBytes = TRUE)

    utils::zip(
      zipfile = file,
      files = c(sas_code_path, sas_test_code_path),
      flags = "-j"
    )
    }
  )
}

validate_app_inputs <- function(input) {
  valid_frd <- checkmate::test_string(
    input$frd, min.chars = 1, pattern = "\\S"
  )
  valid_file <- checkmate::test_data_frame(input$sas_file, min.rows = 1)
  valid_extension <- valid_file && identical(
    tolower(tools::file_ext(input$sas_file$name)), "sas"
  )
  valid_model <- checkmate::test_string(
    input$model, min.chars = 1, pattern = "\\S"
  )
  valid_temperature <- checkmate::test_number(
    input$temperature, lower = 0, upper = 2
  )
  valid_tokens <- checkmate::test_number(
    input$max_tokens, lower = 256, upper = 32768, finite = TRUE
  )

  shinyFeedback::feedbackDanger(
    "frd", !valid_frd, "Paste a non-empty functional requirements document."
  )
  shinyFeedback::feedbackDanger(
    "sas_file", !valid_file, "Upload one SAS macro file."
  )
  shinyFeedback::feedbackDanger(
    "sas_file", valid_file && !valid_extension,
    "The uploaded file must have a .sas extension."
  )
  shinyFeedback::feedbackDanger(
    "model", !valid_model, "Enter a non-empty OpenRouter model name."
  )
  shinyFeedback::feedbackDanger(
    "temperature", !valid_temperature, "Use a temperature between 0 and 2."
  )
  shinyFeedback::feedbackDanger(
    "max_tokens", !valid_tokens, "Use a token limit between 256 and 32768."
  )

  all(c(valid_frd, valid_extension, valid_model, valid_temperature, valid_tokens))
}

normalize_generated_result <- function(response) {
  checkmate::assert_list(response, names = "named")
  checkmate::assert_list(response$parsed, null.ok = FALSE, names = "named")
  parsed <- response$parsed
  checkmate::assert_names(
    names(parsed), must.include = c("test_cases", "sas_code")
  )

  list(
    matrix = normalize_test_cases(parsed$test_cases, parsed$traceability),
    sample_data = normalize_sample_data(parsed$sample_data),
    sas_code = normalize_sas_code(parsed$sas_code),
    sas_test_code = normalize_sas_code(parsed$sas_test_code),
    raw_response = response$response
  )
}

normalize_test_cases <- function(test_cases, traceability = NULL) {
  if (is.data.frame(test_cases)) {
    records <- split(test_cases, seq_len(nrow(test_cases)))
  } else {
    checkmate::assert_list(test_cases, min.len = 1)
    records <- test_cases
  }

  rows <- lapply(seq_along(records), function(index) {
    record <- records[[index]]
    if (is.atomic(record) && !is.null(names(record))) {
      record <- as.list(record)
    }
    checkmate::assert_list(record, names = "named")
    data.frame(
      Test_ID = as_text(
        record, c("Test_ID", "test_id"), paste0("TC", sprintf("%03d", index))
      ),
      Requirement_ID = as_text(
        record, c("Requirement_ID", "requirement_id", "Requirement ID"), ""
      ),
      Test_Type = as_text(
        record, c("Test_Type", "test_type", "Test Type"), ""
      ),
      Test_Scenario = as_text(
        record,
        c("Test_Scenario", "test_scenario", "Test Scenario", "scenario"),
        ""
      ),
      Expected_Result = as_text(
        record,
        c("Expected_Result", "expected_result", "Expected Result"),
        ""
      ),
      Traceability = as_text(
        record, c("Traceability", "traceability"),
        traceability_value(traceability, index)
      ),
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, rows)[, matrix_columns, drop = FALSE]
}

normalize_sample_data <- function(sample_data) {
  if (is.data.frame(sample_data)) {
    return(sample_data)
  }
  if (is.null(sample_data)) {
    return(data.frame())
  }
  if (is.list(sample_data) && length(sample_data) > 0) {
    is_record_list <- is.null(names(sample_data)) && all(vapply(
      sample_data, is.list, logical(1)
    ))
    if (is_record_list) {
      column_names <- unique(unlist(
        lapply(sample_data, names), use.names = FALSE
      ))
      if (length(column_names) == 0L) {
        return(data.frame())
      }
      rows <- lapply(sample_data, function(record) {
        values <- lapply(column_names, function(column_name) {
          value <- record[[column_name]]
          if (is.null(value) || length(value) == 0L) {
            return(NA_character_)
          }
          if (is.list(value)) {
            value <- unlist(value, use.names = FALSE)
          }
          paste(as.character(value), collapse = "; ")
        })
        names(values) <- column_names
        as.data.frame(values, stringsAsFactors = FALSE)
      })
      return(do.call(rbind, rows))
    }
    column_lengths <- vapply(sample_data, length, integer(1))
    row_count <- max(column_lengths, 1L)
    sample_data <- lapply(sample_data, function(column) {
      if (length(column) == 0L) {
        return(rep(NA_character_, row_count))
      }
      rep(column, length.out = row_count)
    })
    return(as.data.frame(sample_data, stringsAsFactors = FALSE))
  }
  data.frame(Sample_Data = as.character(sample_data), stringsAsFactors = FALSE)
}

normalize_sas_code <- function(sas_code) {
  if (is.character(sas_code) && length(sas_code) >= 1) {
    return(paste(sas_code, collapse = "\n"))
  }
  checkmate::assert_string(sas_code)
}

as_text <- function(record, candidates, default) {
  normalize_name <- function(value) {
    tolower(gsub("[^a-z0-9]", "", value))
  }
  record_names <- names(record)
  matching <- candidates[match(
    normalize_name(candidates),
    normalize_name(record_names),
    nomatch = 0L
  ) > 0L]
  if (length(matching) == 0) {
    return(default)
  }
  value <- record[[record_names[
    match(normalize_name(matching[1L]), normalize_name(record_names))
  ]]]
  if (is.null(value) || length(value) == 0 || is.na(value[1L])) {
    return(default)
  }
  paste(as.character(value), collapse = "; ")
}

traceability_value <- function(traceability, index) {
  if (is.null(traceability) || length(traceability) < index) {
    return("")
  }
  value <- traceability[[index]]
  if (is.list(value)) {
    value <- unlist(value, use.names = FALSE)
  }
  paste(as.character(value), collapse = "; ")
}

require_generated_result <- function(result) {
  if (is.null(result)) {
    stop("Generate test cases before downloading results.")
  }
  result
}

shiny::shinyApp(ui, server)
