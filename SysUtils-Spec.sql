CREATE OR REPLACE PACKAGE SysUtils AS
     
FUNCTION IsNumber( 
--PURPOSE: Determines whether an entered value is either a number or not

    i_check_value IN VARCHAR2 -->enter numbers or letters
    
    ) 
        RETURN NUMBER; --> returns "1" if entered value is an number and "0" if not 
        
FUNCTION DayOfWeeKCountForMonth( 
--PURPOSE: Determines the number of times a specific day (of the week) occurs with a in month

    i_start_day IN number,  -->enter the starting day of a month: 1=SUN, 2=MON, ... 7=SAT (e.g. the starting day for the month of December 2012 is a Saturday which = 7) 
    i_days_in_month IN number, --> enter the total number of days of the month above (so the range is between (28 - 31) 
    i_day_to_count IN number --> enter the day of the week to talley: 1=SUN, 2=MON, ... 7=SAT
 ) 
        
        RETURN NUMBER; --> returns the number of times a specific day (of the week) occurs with a in month (i.e. number of Sundays in a month)        
        
PROCEDURE SysDateSchema (
--PURPOSE: Populates and maintains the "dim_sys_date_schema" table

    i_update_type IN VARCHAR2, -->enter either 'build' or 'sync'
    i_start_year IN VARCHAR2,    -->must be a four digit integer between 1900 and 2100 that is greater than the value for end_year
    i_end_year IN VARCHAR2      -->must be a four digit integer between 1900 and 2100 that is less than or eaual to the value start_year  

    );
        
END sysutils;        
