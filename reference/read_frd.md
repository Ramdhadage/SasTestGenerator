# Read a functional requirements document

Read a functional requirements document

## Usage

``` r
read_frd(path)
```

## Arguments

- path:

  A single path to an existing text-based FRD file with extension
  `.txt`, `.md`, `.markdown`, or `.sas`.

## Value

A `frd_document` list with normalized `path` and UTF-8 `text`.

## Details

Reads the file as text without extracting or validating requirements.
Missing files and unsupported extensions raise errors. PDF and DOCX
parsing are outside the current scope.

## Examples

``` r
path <- tempfile(fileext = ".txt")
writeLines("FRD-001: Set BASEFL to Y for BASELINE visits.", path)
frd <- read_frd(path)
frd$text
#> [1] "FRD-001: Set BASEFL to Y for BASELINE visits."
unlink(path)
```
