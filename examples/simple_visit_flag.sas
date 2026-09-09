%macro derive_visit_flag(
    input=,
    output=
);

data &output;
    set &input;
    if VISIT = "BASELINE" then BASEFL = "Y";
    else BASEFL = "N";
run;

%mend derive_visit_flag;
