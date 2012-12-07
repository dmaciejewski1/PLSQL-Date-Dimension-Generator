CREATE OR REPLACE PACKAGE BODY SysUtils AS

FUNCTION IsNumber( 
    i_check_value IN VARCHAR2 
    ) 
        RETURN NUMBER
        
AS
    testval NUMBER;
    num_val_error EXCEPTION;
            
    PRAGMA EXCEPTION_INIT( num_val_error, -6502 );
        
 BEGIN
 
  testval := TO_NUMBER( i_check_value );
    
  RETURN 1;
    
  EXCEPTION
  
           WHEN num_val_error THEN RETURN 0;
           
 END IsNumber;
 
  PROCEDURE SysDateSchema

  (
    --declare in params
     i_update_type            IN VARCHAR2, -->build or sync
     i_start_year               IN VARCHAR2, -->must be a four digit integer between 1900 and 2100 that is greater than the value for end_year
     i_end_year                IN VARCHAR2  -->must be a four digit integer between 1900 and 2100 that is less than or eaual to the value start_year
  )

  IS
  
    --declare and/or set procedure config variables    
    c_min_st_yr                INTEGER:=1900; -->sets the lowest value accepted for year from the start_year in param (at time of creation set to: 1900)
    c_max_st_yr               INTEGER:=2100; -->sets the highest value accepted for year from the start_year in param (at time of creation set to: 2100)
    c_min_end_yr             INTEGER:=1900; -->sets the lowest value accepted for year from the end_year in param (at time of creation set to: 1900)
    c_max_end_yr            INTEGER:=2100; -->sets the highest value accepted for year from the end_year in param (at time of creation set to: 2100)
    c_start_month            NUMBER:= 1;      -->sets the start month (at time of creation set to: 1)
    c_start_day                NUMBER:= 1;      -->sets the start day (at time of creation set to: 1)
    c_end_month             NUMBER:= 12;    -->sets the end month (at time of creation set to: 12)
    c_end_day                 NUMBER:= 31;    -->sets the start day (at time of creation set to: 31)
    sys_online                 INTEGER:=1;       -->sets data return (0 = off, 1 = on)  
    
    --declare validated params 
    v_update_type           VARCHAR2(5 BYTE); 
    v_start_year              INTEGER;
    v_end_year               INTEGER;  
    
    --declare procedure variables
    p_type_is_right          NUMBER;    
    p_start_date              DATE;
    p_julian_start_date    NUMBER;  
    p_st_yr_is_no            NUMBER;
    p_st_yt_in_range       NUMBER;                 
    p_end_date               DATE;
    p_julian_end_date     NUMBER;  
    p_ed_yr_is_no           NUMBER;
    p_ed_yr_in_range      NUMBER;   
    p_no_of_dts              NUMBER;
    p_cur_date                DATE;
    p_id                          NUMBER;
    p_ct                          INTEGER:=0;    
                                                                        
--    --procedure execution metadata variables
--    m_procedure_name   VARCHAR2(100):= 'sysutils.SysDateSchema';
--    m_search_id              NUMBER;
--    m_starttime               DATE;
--    m_finishtime              DATE; 
    
--   --error logging variables
--    err_id                       NUMBER;
--    err_occurrence          DATE;
--    err_message             VARCHAR2(4000BYTE);
--    err_stacktrace           VARCHAR2 (4000BYTE);
--    err_number               NUMBER;  

    --declare cursors
    CURSOR is_past_cur IS
                SELECT ID
                FROM dim_sys_date_schema
                WHERE is_past <> 1
                AND sys_date < trunc(sysdate);
                
    CURSOR is_not_past_cur IS
                SELECT ID
                FROM dim_sys_date_schema
                WHERE is_past <> 0
                AND sys_date >= trunc(sysdate);     
                
    CURSOR is_future_cur IS
                SELECT ID
                FROM dim_sys_date_schema
                WHERE is_future <> 1
                AND sys_date > trunc(sysdate);
                
    CURSOR is_not_future_cur IS
                SELECT ID
                FROM dim_sys_date_schema
                WHERE is_future <> 0
                AND sys_date <= trunc(sysdate);  
                
    CURSOR is_today_cur IS
                SELECT ID
                FROM dim_sys_date_schema
                WHERE is_today <> 1
                AND sys_date = trunc(sysdate);
                
    CURSOR is_not_today_cur IS
                SELECT ID
                FROM dim_sys_date_schema
                WHERE is_today <> 0
                AND sys_date <> trunc(sysdate);            
                 
  BEGIN

    --if sys_online = 0 do not return data
    IF sys_online = 0 THEN
    
        NULL;
       
    --elsif sys_online = 1 proceed
    ELSIF sys_online = 1 THEN

       --if i_update_type = 'build' proceed to wipe and repopulate the dim_sys_date_schema table
       IF lower(i_update_type) = 'build' THEN 

              --logic for numericality
          IF sysutils.IsNumber(i_start_year) = 0
               OR
            sysutils.IsNumber(i_end_year) = 0 
               OR
               --logic for year
            i_start_year > i_end_year 
               OR               
            i_start_year < c_min_st_yr
               OR
            i_start_year > c_max_st_yr
               OR
            i_end_year < c_min_end_yr
               OR
            i_end_year > c_max_end_yr                                       
                THEN            
                    NULL;        
          ELSE
                   v_update_type := 'sync';
                   v_start_year:= to_number(i_start_year);
                   v_end_year:= to_number(i_end_year);                                       
                                                                                                          
                 execute immediate 'TRUNCATE TABLE dim_sys_date_schema'; 
                 COMMIT;         
        
                 p_start_date:= to_date(c_start_month||'/'||c_start_day||'/'||v_start_year,'MM/DD/YYYY');
                 p_end_date:= to_date(c_end_month||'/'||c_end_day||'/'||v_end_year, 'MM/DD/YYYY');
               
                 SELECT to_number(to_char(p_start_date, 'J')) INTO p_julian_start_date FROM dual;
                 SELECT to_number(to_char(p_end_date, 'J')) INTO p_julian_end_date FROM dual;
               
                 p_no_of_dts:= p_julian_end_date - p_julian_start_date;                        
                 
                 LOOP
                    
                    p_cur_date:= p_start_date + p_ct;
                    p_ct:= p_ct + 1;
                                                     
                    INSERT INTO dim_sys_date_schema (ID,
                                                                           julian_day,
                                                                           sys_date,
                                                                           year_4digit,
                                                                           year_2digit,
                                                                           quarter_of_year,
                                                                           quarters_left_in_year,
                                                                           month_full_nm,
                                                                           month_abbr_nm,
                                                                           month_of_year,
                                                                           month_of_quarter,
                                                                           months_left_in_year,
                                                                           months_left_in_quarter,
                                                                           week_of_year,
                                                                           week_of_quarter,
                                                                           week_of_month,
                                                                           weeks_left_in_year,
                                                                           weeks_left_in_quarter,
                                                                           weeks_left_in_month,
                                                                           day_of_week_full_nm,
                                                                           day_of_week_abbr_nm,
                                                                           day_of_year,
                                                                           day_of_quarter,
                                                                           day_of_month,
                                                                           day_of_week,
                                                                           day_of_business_week,
                                                                           sunday_of_month,
                                                                           monday_of_month,
                                                                           tuesday_of_month,
                                                                           wednesday_of_month,
                                                                           thursday_of_month,
                                                                           friday_of_month,
                                                                           saturday_of_month,
                                                                           sundays_in_month,
                                                                           mondays_in_month,
                                                                           tuesdays_in_month,
                                                                           wednesdays_in_month,
                                                                           thursdays_in_month,
                                                                           fridays_in_month,
                                                                           saturdays_in_month,
                                                                           days_left_in_year,
                                                                           days_left_in_quarter,
                                                                           days_left_in_month,
                                                                           days_left_in_week,
                                                                           days_left_in_business_week,
                                                                           is_today,
                                                                           is_past,
                                                                           is_future,
                                                                           is_weekday,
                                                                           is_weekend,
                                                                           is_leap_day,
                                                                           is_leap_year,
                                                                           is_first_day_of_year,
                                                                           is_first_day_of_quarter,                                                                           
                                                                           is_first_day_of_month,
                                                                           is_first_day_of_week,
                                                                           is_first_day_of_business_week,
                                                                           is_last_day_of_year,
                                                                           is_last_day_of_quarter,
                                                                           is_last_day_of_month,
                                                                           is_last_day_of_week,
                                                                           is_last_day_of_business_week
                                                                           )
                                                              SELECT p_ct AS ID,
                                                                          to_char(p_cur_date,'J') AS julian_day,
                                                                          to_date(to_char(trunc(p_cur_date),'MM/DD/YYYY'), 'MM/DD/YYYY')  AS sys_date,
                                                                          to_number(to_char(p_cur_date,'YYYY')) AS year_4digit,
                                                                          to_number(to_char(p_cur_date,'YY')) AS year_2digit,
                                                                          to_number(to_char(p_cur_date,'Q')) AS quarter_of_year,                         
                                                                          4 - (to_number(to_char(p_cur_date,'Q'))) AS quarters_left_in_year,
                                                                          to_char(p_cur_date,'Month') AS month_full_nm,
                                                                          to_char(p_cur_date,'MON') AS month_abbr_nm,
                                                                          to_number(to_char(p_cur_date,'MM')) AS month_of_year,
                                                                           CASE
                                                                              WHEN to_number(to_char(p_cur_date,'MM')) IN (1, 4, 7, 10)
                                                                                    THEN 1
                                                                              WHEN to_number(to_char(p_cur_date,'MM')) IN (2, 5, 8, 11)
                                                                                    THEN 2
                                                                              WHEN to_number(to_char(p_cur_date,'MM')) IN (3, 6, 9, 12)
                                                                                    THEN 3
                                                                           END AS month_of_quarter,
                                                                          12 - to_number(to_char(p_cur_date,'MM')) AS months_left_in_year,
                                                                           CASE
                                                                             WHEN to_number(to_char(p_cur_date,'MM')) IN (1, 4, 7, 10)
                                                                                  THEN 2
                                                                             WHEN to_number(to_char(p_cur_date,'MM')) IN (2, 5, 8, 11)
                                                                                  THEN 1
                                                                             WHEN to_number(to_char(p_cur_date,'MM')) IN (3, 6, 9, 12)
                                                                                  THEN 0
                                                                           END AS months_left_in_quarter,
                                                                          to_number(to_char(p_cur_date,'WW')) AS week_of_year,
                                                                           CASE 
                                                                               WHEN to_number(to_char(p_cur_date,'MM')) IN (1, 2, 3)
                                                                                    THEN trunc((p_cur_date - to_date('01/01/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' ))/7) + 1
                                                                               WHEN to_number(to_char(p_cur_date,'MM')) IN (4, 5, 6)  
                                                                                    THEN trunc((p_cur_date - to_date('04/01/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' ))/7) + 1     
                                                                               WHEN to_number(to_char(p_cur_date,'MM')) IN (7, 8, 9)        
                                                                                    THEN trunc((p_cur_date - to_date('07/01/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' ))/7) + 1
                                                                               WHEN to_number(to_char(p_cur_date,'MM')) IN (10, 11, 12)        
                                                                                    THEN trunc((p_cur_date - to_date('10/01/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' ))/7) + 1  
                                                                           END AS week_of_quarter,
                                                                          to_number(to_char(p_cur_date,'W')) AS week_of_month,
                                                                          53 - to_number(to_char(p_cur_date,'WW')) AS weeks_left_in_year,
                                                                          CASE 
                                                                            WHEN to_number(to_char(p_cur_date,'MM')) IN (1, 2, 3)                
                                                                                THEN trunc(  ((to_date('03/31/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' )) - (to_date('01/01/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' )))/7  ) -  trunc((p_cur_date - to_date('01/01/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' ))/7)                                
                                                                            WHEN to_number(to_char(p_cur_date,'MM')) IN (4, 5, 6)  
                                                                                THEN trunc(  ((to_date('06/30/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' )) - (to_date('04/01/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' )))/7  ) -  trunc((p_cur_date - to_date('04/01/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' ))/7)   
                                                                            WHEN to_number(to_char(p_cur_date,'MM')) IN (7, 8, 9)        
                                                                                THEN trunc(  ((to_date('09/30/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' )) - (to_date('07/01/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' )))/7  ) -  trunc((p_cur_date - to_date('07/01/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' ))/7)  
                                                                            WHEN to_number(to_char(p_cur_date,'MM')) IN (10, 11, 12)        
                                                                                THEN trunc(  ((to_date('12/31/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' )) - (to_date('10/01/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' )))/7  ) -  trunc((p_cur_date - to_date('10/01/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' ))/7)  
                                                                          END AS weeks_left_in_quarter,            
                                                                         to_number(to_char(  (round(to_date (to_char( p_cur_date, 'MM')||'/28/'||to_char( p_cur_date, 'YYYY'), 'MM/DD/YYYY'), 'MONTH') - 1),  'W')) - to_number(to_char(p_cur_date,'W')) AS weeks_left_in_month,           
                                                                         to_char(p_cur_date,'Day') AS day_of_week_full_nm,
                                                                         to_char(p_cur_date,'DY') AS day_of_week_abbr_nm,        
                                                                         to_char(p_cur_date,'DDD') AS day_of_year,  
                                                                         
                                                                         CASE
                                                                              WHEN  to_number(to_char(p_cur_date,'MM')) IN (1,2,3)
                                                                                    THEN to_number(p_cur_date - (to_date('1/1/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' ))) + 1
                                                                              WHEN  to_number(to_char(p_cur_date,'MM')) IN (4,5,6)
                                                                                    THEN to_number(p_cur_date - (to_date('4/1/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' ))) + 1
                                                                              WHEN  to_number(to_char(p_cur_date,'MM')) IN (7,8,9)
                                                                                    THEN to_number(p_cur_date - (to_date('7/1/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' ))) + 1
                                                                              WHEN  to_number(to_char(p_cur_date,'MM')) IN (10,11,12)
                                                                                    THEN to_number(p_cur_date - (to_date('10/1/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY' ))) + 1 
                                                                         END AS day_of_quarter,                                                                                                                                                                                                                                                         
                                                                                                                                                                                                                                                                                                                                                                                   
                                                                         to_number(to_char(p_cur_date,'DD')) AS day_of_month,
                                                                         to_number(to_char(p_cur_date,'D')) AS day_of_week,    
                                                                         CASE
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 1
                                                                                    THEN NULL
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 2
                                                                                     THEN 1     
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 3
                                                                                     THEN 2  
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 4
                                                                                     THEN 3
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 5
                                                                                     THEN 4
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 6
                                                                                     THEN 5   
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 7
                                                                                     THEN NULL      
                                                                         END AS day_of_business_week,    
                                                                         
                                                                         CASE
                                                                            WHEN  to_number(to_char(p_cur_date,'D')) = 1
                                                                                THEN to_number(to_char(p_cur_date,'W'))
                                                                             ELSE
                                                                                NULL                                                                                
                                                                         END AS sunday_of_month,   
                                                                         
                                                                         CASE
                                                                            WHEN  to_number(to_char(p_cur_date,'D')) = 2
                                                                                THEN to_number(to_char(p_cur_date,'W'))
                                                                             ELSE
                                                                                NULL                                                                                
                                                                         END AS monday_of_month,       
                                                                         
                                                                         CASE
                                                                            WHEN  to_number(to_char(p_cur_date,'D')) = 3
                                                                                THEN to_number(to_char(p_cur_date,'W'))
                                                                             ELSE
                                                                                NULL                                                                                
                                                                         END AS tuesday_of_month,                     
                                                                         
                                                                         CASE
                                                                            WHEN  to_number(to_char(p_cur_date,'D')) = 4
                                                                                THEN to_number(to_char(p_cur_date,'W'))
                                                                             ELSE
                                                                                NULL                                                                                
                                                                         END AS wednesday_of_month, 
                                                                         
                                                                         CASE
                                                                            WHEN  to_number(to_char(p_cur_date,'D')) = 5
                                                                                THEN to_number(to_char(p_cur_date,'W'))
                                                                             ELSE
                                                                                NULL                                                                                
                                                                         END AS thursday_of_month,          
                                                                         
                                                                         CASE
                                                                            WHEN  to_number(to_char(p_cur_date,'D')) = 6
                                                                                THEN to_number(to_char(p_cur_date,'W'))
                                                                             ELSE
                                                                                NULL                                                                                
                                                                         END AS friday_of_month,        
                                                                         
                                                                         CASE
                                                                            WHEN  to_number(to_char(p_cur_date,'D')) = 7
                                                                                THEN to_number(to_char(p_cur_date,'W'))
                                                                             ELSE
                                                                                NULL                                                                                
                                                                         END AS saturday_of_month,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
                                                                         
                                                                         fn_day_of_week_counter_per_mon(to_number(to_char(trunc(p_cur_date,'MONTH'),'D')),
                                                                                                                             to_number(to_char(last_day(p_cur_date),'DD')),
                                                                                                                             1
                                                                                                                             ) 
                                                                         AS sundays_in_month,  
                                                                         
                                                                         fn_day_of_week_counter_per_mon(to_number(to_char(trunc(p_cur_date,'MONTH'),'D')),
                                                                                                                             to_number(to_char(last_day(p_cur_date),'DD')),
                                                                                                                             2
                                                                                                                             ) 
                                                                         AS mondays_in_month,     
                                                                         
                                                                         fn_day_of_week_counter_per_mon(to_number(to_char(trunc(p_cur_date,'MONTH'),'D')),
                                                                                                                             to_number(to_char(last_day(p_cur_date),'DD')),
                                                                                                                             3
                                                                                                                             ) 
                                                                         AS tuesdays_in_month,   
                                                                         
                                                                         fn_day_of_week_counter_per_mon(to_number(to_char(trunc(p_cur_date,'MONTH'),'D')),
                                                                                                                             to_number(to_char(last_day(p_cur_date),'DD')),
                                                                                                                             4
                                                                                                                             ) 
                                                                         AS wednesdays_in_month,   
                                                                         
                                                                         fn_day_of_week_counter_per_mon(to_number(to_char(trunc(p_cur_date,'MONTH'),'D')),
                                                                                                                             to_number(to_char(last_day(p_cur_date),'DD')),
                                                                                                                             5
                                                                                                                             ) 
                                                                         AS thursdays_in_month,     
                                                                         
                                                                         fn_day_of_week_counter_per_mon(to_number(to_char(trunc(p_cur_date,'MONTH'),'D')),
                                                                                                                             to_number(to_char(last_day(p_cur_date),'DD')),
                                                                                                                             6
                                                                                                                             ) 
                                                                         AS fridays_in_month,     
                                                                         
                                                                         fn_day_of_week_counter_per_mon(to_number(to_char(trunc(p_cur_date,'MONTH'),'D')),
                                                                                                                             to_number(to_char(last_day(p_cur_date),'DD')),
                                                                                                                             7
                                                                                                                             ) 
                                                                         AS saturdays_in_month,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

                                                                         to_number(to_char(last_day(to_date('12/31/'||to_number(to_char(p_cur_date,'YYYY')),'MM/DD/YYYY')),'DDD')) - to_number(to_char(p_cur_date,'DDD')) AS days_left_in_year,
                                                                         
                                                                         CASE
                                                                               WHEN to_number(to_char(p_cur_date,'MM')) IN  (1,2,3)
                                                                                      THEN to_number(to_date('3/31/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY') - p_cur_date)
                                                                               WHEN to_number(to_char(p_cur_date,'MM')) IN  (4,5,6)
                                                                                      THEN to_number(to_date('6/30/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY') - p_cur_date)
                                                                               WHEN to_number(to_char(p_cur_date,'MM')) IN  (7,8,9)
                                                                                      THEN to_number(to_date('9/30/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY') - p_cur_date) 
                                                                               WHEN to_number(to_char(p_cur_date,'MM')) IN  (10,11,12)
                                                                                      THEN to_number(to_date('12/31/'||to_char(p_cur_date,'YYYY'),'MM/DD/YYYY') - p_cur_date)                                                                                       
                                                                         END  AS days_left_in_quarter,                                                                                                                                                                         
                                                                         
                                                                         to_number(to_char(last_day(p_cur_date),'DD')) - to_number(to_char(p_cur_date,'DD'))   AS days_left_in_month,
                                                                         
                                                                         7 - to_number(to_char(p_cur_date,'D')) AS days_left_in_week,
                                                                         
                                                                         CASE
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 1
                                                                                    THEN NULL
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 2
                                                                                     THEN 4     
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 3
                                                                                     THEN 3  
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 4
                                                                                     THEN 2
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 5
                                                                                     THEN 1
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 6
                                                                                     THEN 0   
                                                                              WHEN to_number(to_char(p_cur_date,'D')) = 7
                                                                                     THEN NULL      
                                                                         END AS days_left_in_business_week,                                                                             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
                                                                          CASE
                                                                              WHEN trunc(p_cur_date) = trunc(sysdate)
                                                                                     THEN 1
                                                                              ELSE 0 
                                                                          END AS is_today,         
                                                                          
                                                                          CASE
                                                                             WHEN trunc(p_cur_date) < trunc(sysdate)
                                                                                  THEN 1
                                                                             ELSE 0  
                                                                          END AS is_past,                   
                                                                          CASE
                                                                             WHEN trunc(p_cur_date) > trunc(sysdate)
                                                                                  THEN 1
                                                                              ELSE 0  
                                                                          END AS is_future,                                       
                                                                          CASE
                                                                              WHEN to_number(to_char(p_cur_date,'D')) IN (2,3,4,5,6)
                                                                                    THEN 1
                                                                              ELSE 0  
                                                                          END AS is_weekday,                               
                                                                          CASE
                                                                               WHEN to_number(to_char(p_cur_date,'D')) IN (1,7)
                                                                                     THEN 1
                                                                               ELSE 0
                                                                          END AS is_weekend,      
                                                                          CASE 
                                                                               WHEN to_number(to_char(p_cur_date,'DD')) = 29 AND  to_number(to_char(p_cur_date,'MM')) = 2
                                                                                     THEN   1
                                                                               ELSE 0  
                                                                          END AS is_leap_day,  
                                                                          
                                                                          
                                                                          CASE
                                                                              WHEN to_number(to_char(last_day(to_date('2/1/'||to_number(to_char(p_cur_date,'YYYY')),'MM/DD/YYYY')),'DD')) = 29 
                                                                                    THEN 1
                                                                               ELSE 0
                                                                          END AS is_leap_year,
                                                                          
                                                                          
                                                                                                                                                
                                                                          CASE
                                                                               WHEN to_number(to_char(p_cur_date,'DD')) = 1 AND  to_number(to_char(p_cur_date,'MM')) = 1
                                                                                     THEN   1
                                                                               ELSE 0
                                                                          END AS is_first_day_of_year,                                                                              
                                                                          CASE  
                                                                                WHEN to_number(to_char(p_cur_date,'DD')) = 1 AND  to_number(to_char(p_cur_date,'MM')) = 1
                                                                                      THEN 1
                                                                                WHEN to_number(to_char(p_cur_date,'DD')) = 1 AND  to_number(to_char(p_cur_date,'MM')) = 4
                                                                                      THEN 1
                                                                                WHEN to_number(to_char(p_cur_date,'DD')) = 1 AND  to_number(to_char(p_cur_date,'MM')) = 7
                                                                                      THEN 1
                                                                                WHEN to_number(to_char(p_cur_date,'DD')) = 1 AND  to_number(to_char(p_cur_date,'MM')) = 10
                                                                                      THEN 1
                                                                                ELSE 
                                                                                              0
                                                                          END  AS is_first_day_of_quarter,                                                                                                                                                   
                                                                          CASE
                                                                                 WHEN to_number(to_char(p_cur_date,'DD')) = 1
                                                                                        THEN 1
                                                                                 ELSE
                                                                                                 0
                                                                          END AS is_first_day_of_month,                                                                          
                                                                          
                                                                          CASE
                                                                                 WHEN to_number(to_char(p_cur_date,'D')) = 1
                                                                                        THEN 1
                                                                                 ELSE
                                                                                                 0
                                                                          END AS is_first_day_of_week,
                                                                          
                                                                          CASE
                                                                                 WHEN to_number(to_char(p_cur_date,'D')) = 2
                                                                                        THEN 1
                                                                                 ELSE
                                                                                                 0
                                                                          END AS is_first_day_of_business_week,                                                                          
                                                                                                                                                                                                                                                                                                                              
                                                                          CASE
                                                                               WHEN round(to_date ('12/28/'||to_char( p_cur_date, 'YYYY'), 'MM/DD/YYYY'), 'MONTH') - 1  =  trunc(p_cur_date)
                                                                                    THEN 1
                                                                               ELSE 0
                                                                          END AS is_last_day_of_year,                       
                                                                          CASE  
                                                                                WHEN to_number(to_char(p_cur_date,'DD')) = 31 AND  to_number(to_char(p_cur_date,'MM')) = 3
                                                                                      THEN 1
                                                                                WHEN to_number(to_char(p_cur_date,'DD')) = 30 AND  to_number(to_char(p_cur_date,'MM')) = 6
                                                                                      THEN 1
                                                                                WHEN to_number(to_char(p_cur_date,'DD')) = 30 AND  to_number(to_char(p_cur_date,'MM')) = 9
                                                                                      THEN 1
                                                                                WHEN to_number(to_char(p_cur_date,'DD')) = 31 AND  to_number(to_char(p_cur_date,'MM')) = 12
                                                                                      THEN 1
                                                                                ELSE 
                                                                                              0
                                                                          END  AS is_last_day_of_quarter,                                                                              
                                                                          CASE
                                                                               WHEN round(to_date (to_char( p_cur_date, 'MM')||'/28/'||to_char( p_cur_date, 'YYYY'), 'MM/DD/YYYY'), 'MONTH') - 1  =  trunc(p_cur_date)
                                                                                     THEN 1
                                                                               ELSE 0
                                                                          END AS is_last_day_of_month,             
                                                                          CASE
                                                                               WHEN to_number(to_char(p_cur_date,'D')) = 7
                                                                                     THEN 1
                                                                               ELSE 0 
                                                                          END AS is_last_day_of_week,           
                                                                          CASE
                                                                                WHEN to_number(to_char(p_cur_date,'D')) = 6
                                                                                      THEN 1
                                                                                ELSE 0
                                                                          END AS is_last_day_of_business_week                                                                                                                      
                                                                FROM dual;

                    
                    EXIT WHEN p_ct = p_no_of_dts + 1;
                    
                 END LOOP;
                                 COMMIT;            
          END IF;      
                
       --if i_update_type = 'sync' proceed to update dynamic columns in the dim_sys_date_schema table          
       ELSIF lower(i_update_type) = 'sync' THEN                  
              v_update_type := 'sync';
                       
                 OPEN is_past_cur;
                 LOOP
                    FETCH is_past_cur INTO p_id;
                    EXIT WHEN  is_past_cur%NOTFOUND;
                    
                        UPDATE dim_sys_date_schema
                              SET is_past = 1
                         WHERE ID = p_id;
                    END LOOP;
                 
                 COMMIT;
                 
                 OPEN is_not_past_cur;
                 LOOP
                    FETCH is_not_past_cur INTO p_id;
                    EXIT WHEN  is_not_past_cur%NOTFOUND;
                    
                        UPDATE dim_sys_date_schema
                              SET is_past = 0
                         WHERE ID = p_id;
                    END LOOP;
                 
                 COMMIT;      
                 
                 OPEN is_future_cur;
                 LOOP
                    FETCH is_future_cur INTO p_id;
                    EXIT WHEN  is_future_cur%NOTFOUND;
                    
                        UPDATE dim_sys_date_schema
                              SET is_future = 1
                         WHERE ID = p_id;
                    END LOOP;
                 
                 COMMIT;
                 
                 OPEN is_not_future_cur;
                 LOOP
                    FETCH is_not_future_cur INTO p_id;
                    EXIT WHEN  is_not_future_cur%NOTFOUND;
                    
                        UPDATE dim_sys_date_schema
                              SET is_future = 0
                         WHERE ID = p_id;
                    END LOOP;
                 
                 COMMIT;                                
                 
                 OPEN is_today_cur;
                 LOOP
                    FETCH is_today_cur INTO p_id;
                    EXIT WHEN  is_today_cur%NOTFOUND;
                    
                        UPDATE dim_sys_date_schema
                              SET is_today = 1
                         WHERE ID = p_id;
                    END LOOP;
                 
                 COMMIT;
                 
                 OPEN is_not_today_cur;
                 LOOP
                    FETCH is_not_today_cur INTO p_id;
                    EXIT WHEN  is_not_today_cur%NOTFOUND;
                    
                        UPDATE dim_sys_date_schema
                              SET is_today = 0
                         WHERE ID = p_id;
                    END LOOP;
                 
                 COMMIT;                    
                                                                                                                                                                
        END IF;
    END IF;                                          
  END SysDateSchema;

 END sysutils;
