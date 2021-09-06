-- this is a Postgres SQL query

Select  cl.id as client_id
       ,cl.name as client_name
       ,cl.status as client_status
       ,CASE
           WHEN cl.nationalaccount = TRUE THEN 'National'
           ELSE 'Other'
       	END nationalaccount
	   ,chl11.status as changelog_status
     ,chl11.date as statuschangedate
     ,dm.domainname
     ,chl11.oldstatus


From ( Select 
            c.id, c.name, 
            c.status, c.nationalaccount 
       FROM control.client c 
       WHERE c.status = 'OFF') cl 
	  
      JOIN 
    
    ( Select chl1.client_id, MAX(chl1.date) as date, chl1.status, MAX(chl1.oldstatus) as oldstatus
       FROM (       Select temp.client_id, temp.status, temp.oldstatus, temp.date
      		          FROM ( select chl.client_id, chl.status, chl.date, LAG(chl.status,1) over (partition by chl.client_id order by chl.date asc) as oldstatus
      	                   from changelog.client_status chl
      				             where chl.date > (Current_Date - INTERVAL '1 months')) temp

      		          WHERE temp.status LIKE 'OFF' and (NOT temp.oldstatus LIKE 'OFF')) chl1
                    Group BY chl1.client_id, chl1.status) chl11

      ON cl.id=chl11.client_id
	    
      JOIN control.domainname dm 
      ON cl.id=dm.client_id
