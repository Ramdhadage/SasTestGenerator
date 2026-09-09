%macro derive_trtemfl(in=, out=);

data &out;
    set &in.;
    if AE_START_DT >= FIRST_DOSE_DT and
        AE_START_DT <= LAST_DOSE_DT then
        TRTEMFL = 'Y';
    else
        TRTEMFL = 'N';
run;

%mend
