%macro derive_flag(
    input=,
    output=
);

data &output;
    set &input;

    length TOXFL $1;

    if missing(PARAM) or missing(VALUE) or missing(ULN) then
        TOXFL = "N";
    else if PARAM = "ALT" and VALUE > 3 * ULN then
        TOXFL = "Y";
    else
        TOXFL = "N";
run;

%mend derive_flag;
