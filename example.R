pkgload::load_all(".")

frd <- read_frd("examples/simple_frd.txt")
macro <- import_sas_macro("examples/simple_visit_flag.sas")
result <- generate_sas_tests(frd, macro)

stopifnot(
    inherits(frd, "frd_document"),
    inherits(macro, "sas_macro"),
    identical(macro$macro_names, "derive_visit_flag"),
    grepl(frd$text, result$prompt, fixed = TRUE),
    grepl(macro$source, result$prompt, fixed = TRUE),
    nrow(result$test_cases) == 0L,
    length(result$sas_code) == 0L
)

cat(result$prompt, "\n")

# Live generation is documented separately so sourcing this file stays offline.
