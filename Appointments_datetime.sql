SELECT APPOINTMENT_ID, SERVICE_TYPE, DATE, 
       CASE
       WHEN TIME_IN_UTC = '\\N'
       THEN NULL
       ELSE PARSE_DATETIME("%Y-%m-%d %H:%M:%E*S", TIME_IN_UTC )
       END as TIME_IN_UTC, 
       
       CASE
       WHEN TIME_OUT_UTC = '\\N'
       THEN NULL
       ELSE PARSE_DATETIME("%Y-%m-%d %H:%M:%E*S", TIME_OUT_UTC )
       END as TIME_OUT_UTC,
       
       CASE
       WHEN TIME_IN_LOCAL = '\\N'
       THEN NULL
       ELSE PARSE_DATETIME("%Y-%m-%d %H:%M:%E*S", LEFT(TIME_IN_LOCAL, 24) )
       END as TIME_IN_LOCAL,
       
       CASE
       WHEN TIME_OUT_LOCAL = '\\N'
       THEN NULL
       ELSE PARSE_DATETIME("%Y-%m-%d %H:%M:%E*S", LEFT(TIME_OUT_LOCAL,24) )
       END as TIME_OUT_LOCAL,
       
       EMPLOYEE_ID, EMPLOYEE_NAME, EMPLOYEE_EMAIL, LAT, LNG, 
       AMOUNT_BILLED, AMOUNT_COLLECTED FROM `noted-casing-129313.Aptive.Appointments`

Select ROUND(EXTRACT(MINUTE FROM PARSE_DATETIME('%H:%M:%S', LEFT(TripDetailIdlingDuration,8)) ) + EXTRACT(SECOND FROM PARSE_DATETIME('%H:%M:%S', LEFT(TripDetailIdlingDuration,8)) )/60,2), 
ROUND(EXTRACT(MINUTE FROM PARSE_DATETIME('%H:%M:%S', LEFT(TripDetailStopDuration,8) ) ) + EXTRACT(SECOND FROM PARSE_DATETIME('%H:%M:%S', LEFT(TripDetailStopDuration,8)) )/60,2),
ROUND(EXTRACT(MINUTE FROM PARSE_DATETIME('%H:%M:%S', LEFT(TripDetailDrivingDuraion,8) ) ) + EXTRACT(SECOND FROM PARSE_DATETIME('%H:%M:%S', LEFT(TripDetailDrivingDuraion,8)) )/60,2)
From `noted-casing-129313.Aptive.Telematics_geotab`;
