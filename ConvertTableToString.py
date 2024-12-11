/* Step 1: Extract the list of numeric columns from the metadata */
proc sql noprint;
    select name
    into :num_cols separated by ' '
    from dictionary.columns
    where libname = 'WORK' /* Adjust library name as needed */
      and memname = 'X'    /* Replace with your table name */
      and type = 'num';
quit;

/* Step 2: Dynamically generate the SELECT statement */
%let select_stmt = ;
%let count = %sysfunc(countw(&num_cols));

%do i = 1 %to &count;
    %let col = %scan(&num_cols, &i);
    %let select_stmt = &select_stmt, put(&col, best.) as &col._char;
%end;

/* Step 3: Add character columns to the SELECT statement */
proc sql noprint;
    select name
    into :char_cols separated by ', '
    from dictionary.columns
    where libname = 'WORK' /* Adjust library name */
      and memname = 'X'    /* Replace with your table name */
      and type = 'char';
quit;

%let select_stmt = &char_cols &select_stmt;

/* Step 4: Create the new table */
proc sql;
    create table X_casted as
    select &select_stmt
    from X;
quit;
