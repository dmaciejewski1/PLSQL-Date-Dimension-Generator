PLSQL-Date-Dimension-Generator
===============================

A PL/SQL package that populates a date dimension table with 62 different date permutations

SUMMARY: 
This is a PL/SQL Package that populates and synchronizes a date dimension table based on a range (in years) entered into a procedure.

PURPOSE: 
As opposed to having to hand populate a date dimension table, this package will automatically populate an entire table consisting of many date metric calculations and thousands of rows in no time at all.

SETUP:
1) Install the date dimension table: "dim_sys_date_schema"
2) Install the "SysUtils" Package (Spec and Body:"SysUtils-Spec.sql" and "SysUtils-Body.sql") in a database (so far I've tested this in 10g and 11g environments)

INSTRUCTIONS:
A) To populate the "dim_sys_date_schema" table, here is a code example (in PL/SQL) using data ranging between 2010 to 2015 (Note: any data within the table will be lost upon executing the build command as the table will be wiped and repopulated)

          BEGIN
          SysUtils.SysDateSchema('build', 2010, 2015);
          END;

B) To synchronize the "dim_sys_date_schema" table, here is a code example (in PL/SQL) to synchronize any dynamic column (such as "is_today") within the table:

          BEGIN
          SysUtils.SysDateSchema('sync', NULL, NULL);
          END;