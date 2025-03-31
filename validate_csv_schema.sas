/* File: validate_csv_schema.sas */

/* Step 1: Set up S3 or Local Path */
filename s3csv s3 's3://your-bucket/path/to/file.csv'
  access_key='your-access-key'
  secret_key='your-secret-key';

/* Step 2: Import CSV File */
proc import datafile=s3csv
  out=work.imported_csv
  dbms=csv replace;
  getnames=yes;
run;

/* Step 3: Create Expected Schema (replace with your actual expectations) */
data work.expected_schema;
  length name $32 type $4 format $20;
  infile datalines dsd;
  input name :$32. type :$4. format :$20.;
  datalines;
id,num,8.
name,char,$CHAR20.
birthday,num,DATE9.
;
run;

/* Step 4: Extract Actual Metadata from Imported Dataset */
proc contents data=work.imported_csv out=work.actual_schema(keep=name type format) noprint;
run;

/* Normalize type column: 1=num, 2=char */
data work.actual_schema;
  set work.actual_schema;
  length type $4;
  if type=1 then type='num';
  else if type=2 then type='char';
run;

/* Step 5: Compare Actual vs Expected */
proc sql;
  create table work.schema_comparison as
  select a.name,
         a.type as expected_type,
         a.format as expected_format,
         b.type as actual_type,
         b.format as actual_format,
         case
           when a.type ne b.type then 'Type Mismatch'
           when upcase(a.format) ne upcase(b.format) then 'Format Mismatch'
           else 'Match'
         end as status
  from work.expected_schema a
  full join work.actual_schema b
    on upcase(a.name) = upcase(b.name);
quit;

/* Step 6: Display Results */
proc print data=work.schema_comparison;
  title "Schema Validation Report";
run;
