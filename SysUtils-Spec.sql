CREATE OR REPLACE PACKAGE SysUtils AS
     
FUNCTION IsNumber( 

    i_check_value IN VARCHAR2 -->enter numbers or letters
    
    ) 
        RETURN NUMBER;
        
PROCEDURE SysDateSchema (

    i_update_type IN VARCHAR2, -->enter either 'build' or 'sync'
    i_start_year IN VARCHAR2,    -->must be a four digit integer between 1900 and 2100 that is greater than the value for end_year
    i_end_year IN VARCHAR2      -->must be a four digit integer between 1900 and 2100 that is less than or eaual to the value start_year  

    );
        
END sysutils;        
