sas_table_profile.txt.sas

%macro profile_data(lib=, table=);

    %local dsid rc varcnt i name type len;

    %let dsid = %sysfunc(open(&lib..&table));
    %let varcnt = %sysfunc(attrn(&dsid, nvars));

    data profile_output;
        length 
            column_name $32 
            type $8 
            defined_length 8 
            max_data_length 8 
            missing_count 8 
            total_count 8 
            missing_percent 8 
            distinct_count 8;
    run;

    %do i = 1 %to &varcnt;
        %let name = %sysfunc(varname(&dsid, &i));
        %let type = %sysfunc(vartype(&dsid, &i));
        %let len  = %sysfunc(varlen(&dsid, &i));

        proc sql noprint;
            create table _colprof as
            select 
                "&name" as column_name length=32,
                "&type" as type,
                &len as defined_length,
                %if &type = C %then %do;
                    max(length(&name)) as max_data_length,
                %end;
                %else %do;
                    . as max_data_length,
                %end;
                count(*) as total_count,
                sum(missing(&name)) as missing_count,
                calculated missing_count*100/calculated total_count as missing_percent,
                count(distinct &name) as distinct_count
            from &lib..&table;
        quit;

        proc append base=profile_output data=_colprof force; run;
        proc datasets lib=work nolist; delete _colprof; quit;
    %end;

    %let rc = %sysfunc(close(&dsid));

    title "Data Profile for &lib..&table";
    proc print data=profile_output noobs; run;

%mend profile_data;



proc sql;
    select 
        name,
        type,
        length,
        nmiss(name) as missing,
        count(distinct name) as distinct
    from dictionary.columns
    where libname='WORK' and memname='YOUR_TABLE';
quit;

profiling_sql.txt.sas

%macro profile_data_sql(lib=, table=);

    proc sql;
        create table profile_output as
        select 
            name as column_name length=32,
            case type 
                when 1 then 'N'
                when 2 then 'C'
            end as type length=1,
            length as defined_length,
            calculated_max as max_data_length,
            missing_count,
            distinct_count
        from (
            select 
                name,
                type,
                length,
                /* For character: compute max(length(var)) */
                case 
                    when type = 2 then 
                        (select max(lengthn(vvaluex(name))) 
                         from &lib..&table)
                    else .
                end as calculated_max,
                (select count(*) - count(name) 
                 from &lib..&table) as missing_count,
                (select count(distinct vvaluex(name)) 
                 from &lib..&table) as distinct_count
            from dictionary.columns
            where libname = upcase("&lib") and memname = upcase("&table")
        );
    quit;

    title "Column Profile for &lib..&table";
    proc print data=profile_output noobs; run;

%mend profile_data_sql;
