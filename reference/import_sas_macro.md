# Import SAS macro source

Import SAS macro source

## Usage

``` r
import_sas_macro(path)
```

## Arguments

- path:

  A single path to an existing SAS source file. The app requires `.sas`;
  this function does not independently check the extension.

## Value

A `sas_macro` list with normalized `path`, UTF-8 `source`,
`macro_names`, and `parameters` character vectors.

## Details

Metadata is extracted with regular expressions, not a complete SAS
parser. Parameters are taken from the first matched macro declaration.
The source is not executed or checked for SAS correctness.

## Examples

``` r
path <- tempfile(fileext = ".sas")
writeLines("%macro derive_flag(input=, output=); %mend derive_flag;", path)
macro <- import_sas_macro(path)
macro$macro_names
#> [1] "derive_flag"
macro$parameters
#> [1] "input"  "output"
unlink(path)
```
