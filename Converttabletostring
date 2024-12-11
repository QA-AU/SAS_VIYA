/* Step 1: Extract the list of numeric columns from the metadata */
proc sql noprint;
    select name
    into :num_cols separated by ' '
    from dictionary.columns
    where libname = 'WORK' /* Adjust library name as needed */
      and memname = 'X'    /* Replace with your table name */
      and type = 'num';
quit;

/* Step 2: Create a new table with numeric columns cast to character */
proc sql;
    create table X_casted as
    select
        %let count = %sysfunc(countw(&num_cols));
        %do i = 1 %to &count;
            %let col = %scan(&num_cols, &i);
            put(&col, best.) as &col._char /* Convert numeric to character */
            %if &i ne &count %then ,; /* Add commas between columns */
        %end;
        *
        /* Include character columns as-is */
        ,
        *
    from X;
quit;
