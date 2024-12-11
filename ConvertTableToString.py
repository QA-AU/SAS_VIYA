/* Step 1: Extract numeric and character columns from the metadata */
proc sql noprint;
    select name
    into :num_cols separated by ' '
    from dictionary.columns
    where libname = 'WORK' /* Adjust library name */
      and memname = 'X'    /* Replace with your table name */
      and type = 'num';

    select name
    into :char_cols separated by ', '
    from dictionary.columns
    where libname = 'WORK' /* Adjust library name */
      and memname = 'X'    /* Replace with your table name */
      and type = 'char';
quit;

/* Step 2: Build the SELECT statement */
%let select_stmt = &char_cols;

%macro build_select();
    %let count = %sysfunc(countw(&num_cols));
    %do i = 1 %to &count;
        %let col = %scan(&num_cols, &i);
        %let select_stmt = &select_stmt, put(&col, best.) as &col._char;
    %end;
%mend build_select;

%build_select();

/* Step 3: Create the new table */
proc sql;
    create table X_casted as
    select &select_stmt
    from X;
quit;
