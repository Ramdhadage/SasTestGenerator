# Generate SAS test cases from an FRD and SAS macro

Generate SAS test cases from an FRD and SAS macro

## Usage

``` r
generate_sas_tests(frd, macro, generator = NULL)
```

## Arguments

- frd:

  An object returned by
  [`read_frd()`](https://ramdhadage.github.io/SasTestGenerator/reference/read_frd.md).

- macro:

  An object returned by
  [`import_sas_macro()`](https://ramdhadage.github.io/SasTestGenerator/reference/import_sas_macro.md).

- generator:

  An optional function receiving one prompt string. Its return value is
  passed through unchanged, without schema validation.

## Value

Without `generator`, a list with `prompt`, `requirements`, `macro`, an
empty `test_cases` data frame, and an empty `sas_code` character vector.
With `generator`, the value returned by that function.

## Details

The default path constructs a prompt and makes no network call. The
complete FRD text and macro source are included in the prompt. Invalid
input classes and a non-function generator raise errors.

## Examples

``` r
frd_path <- tempfile(fileext = ".txt")
macro_path <- tempfile(fileext = ".sas")
writeLines("FRD-001: Set BASEFL to Y for BASELINE visits.", frd_path)
writeLines("%macro derive_flag(input=, output=); %mend;", macro_path)
frd <- read_frd(frd_path)
macro <- import_sas_macro(macro_path)
result <- generate_sas_tests(frd, macro)
cat(result$prompt)
#> You are a Senior SAS Programmer and Clinical Programming Validation Expert.
#> 
#> Generate structured JSON containing test cases, sample data, SAS validation/test code,
#> 
#> and traceability for the supplied functional requirements and SAS macro.
#> 
#> Functional requirements:
#> 
#> FRD-001: Set BASEFL to Y for BASELINE visits.
#> 
#> SAS macro:
#> 
#> %macro derive_flag(input=, output=); %mend;
generate_sas_tests(frd, macro, generator = function(prompt) nchar(prompt))
#> [1] 367
unlink(c(frd_path, macro_path))
```
