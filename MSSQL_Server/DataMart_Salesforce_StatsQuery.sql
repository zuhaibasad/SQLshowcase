-- this is MS-SQL query
-- it is developed over several monhts
-- this query used many datasources which were difficult to integrate
-- this query is important and used to monitor a critical decision strategy by the company

Select corpavg.*,
       AVG(corpavg.CycleCPC) OVER (Partition By corpavg.corp_id, corpavg.cyclenumber) as CorpCPCAvg,   
       AVG(corpavg.CycleCVR) OVER (Partition By corpavg.corp_id, corpavg.cyclenumber) as CorpCVRAvg   

From (Select cycle.*,    
        CASE   
           WHEN cycle.CycleLeads = 0   
           THEN cycle.CycleSpend   
           ELSE (1.0*cycle.CycleSpend)/(cycle.CycleLeads)   
        END as CyclePPL,    
        CASE    
           WHEN cycle.CycleClicks = 0   
           THEN NULL   
           ELSE (1.0*cycle.CycleLeads)/(cycle.CycleClicks)   
        END as CycleCVR,    
        CASE    
           WHEN cycle.CycleImpressions = 0   
           THEN NULL   
           ELSE (1.0*cycle.CycleClicks)/(cycle.CycleImpressions)   
        END as CycleCTR,   
        CASE    
           WHEN cycle.CycleClicks = 0   
           THEN cycle.CycleSpend   
           ELSE (1.0*cycle.CycleSpend)/(cycle.CycleClicks)   
        END as CycleCPC   
   
 From (Select grp.*,SUM(grp.spend) OVER (Partition By grp.corp_id, grp.IDLocationName, grp.cyclenumber Order By grp.cyclenumber ASC) as CycleSpend,   
                SUM(grp.clicks) OVER (Partition By grp.corp_id, grp.IDLocationName, grp.cyclenumber Order By grp.cyclenumber ASC) as CycleClicks,   
                SUM(grp.leads) OVER (Partition By grp.corp_id, grp.IDLocationName, grp.cyclenumber Order By grp.cyclenumber ASC) as CycleLeads,   
                SUM(grp.impressions) OVER (Partition By grp.corp_id, grp.IDLocationName, grp.cyclenumber Order By grp.cyclenumber ASC) as CycleImpressions,   
                MAX(grp.budget) OVER (Partition By grp.corp_id, grp.IDLocationName, grp.cyclenumber Order By grp.cyclenumber ASC) as CycleBudget         
   
      From (Select master.corp_id, MAX(master.corp_name) as corp_name, master.full_client_id, MAX(master.day) as stats_day, MAX(master.begintime_session) as sess_day,master.full_date, MAX(master.weeknumber) as weeknumber, MAX(master.year) as year,    
               MAX(master.IDLocationName) as IDLocationName, MAX(master.cyclenumber) as cyclenumber, MAX(master.status) as account_status, SUM(master.lead_count) as leads,   
               SUM(master.spend) as spend, SUM(master.impressions) as impressions, SUM(master.clicks) as clicks, MAX(master.budget) as budget, MAX(master.balance) as balance, MAX(master.refresheded_at) as refresheda,   
               CONCAT('Cycle ',MAX(master.cyclenumber)) as cycle, SUM(master.site_paid_desktop_sessions) as site_paid_desktop_sessions,    
               SUM(master.site_unpaid_desktop_sessions) as site_unpaid_desktop_sessions, SUM(master.site_paid_mobile_sessions) as site_paid_mobile_sessions,   
               SUM(master.site_unpaid_mobile_sessions) as site_unpaid_mobile_sessions, SUM(master.direct_sessions) as direct_sessions,    
               SUM(master.link_sessions) as link_sessions, SUM(master.bounced_sessions) as bounced_sessions,    
               MAX(master.nextbillingdate) as nextbillingdate, MAX(master.previousbillingdate) as previousbillingdate, MAX(master.ClosedDate) as ClosedDate, MAX(master.CaseNumber) as CaseNumber   
   
   
         From (Select DISTINCT stats_sess_client.*, DATEADD(day, +1, stats_sess_client.previousbillingdate) as first_cycle_day,    
                        CONCAT(stats_sess_client.full_client_id, ' - ', stats_sess_client.location_name) as IDLocationName,   
                        DATEPART(wk, stats_sess_client.full_date) as weeknumber, DATEPART(yyyy, stats_sess_client.full_date) as year,    
                        DENSE_RANK() OVER (Partition By stats_sess_client.full_client_id order by stats_sess_client.previousbillingdate DESC ) as cyclenumber,    
                        baltab.balance, baltab.refresheded_at, SF.ClosedDate, SF.CaseNumber   
             From (   
                  Select stats_sess.*, cl.*   
                  From (Select acls.*, s.*, ISNULL(acls.clientid, s.client_id) as full_client_id, ISNULL(acls.day, s.begintime_session) as full_date   
                       From (Select ac.client_id as clientid, SUM(ac.clicks) as clicks, SUM(ac.impressions) as impressions,                                          
                             SUM(ac.lead_count) as lead_count, SUM(spend) as spend, MAX(ac.budget) as budget, ac.day                                         
                               FROM control_ad_campaign_lead_stats ac    
                           Where ac.day > '01/01/2020'   
                               Group by ac.client_id, ac.day) acls         
                           FULL OUTER JOIN    
                         (Select Distinct s1.*    
                               From control_session s1   
                           Where s1.begintime_session > '01/01/2020') s ON acls.clientid=s.client_id AND acls.day=s.begintime_session) stats_sess   
   
                  FULL OUTER JOIN (Select c2.client_id as cid, c2.location_name, c2.nextbillingdate, DATEADD(month, -1, c2.nextbillingdate) as previousbillingdate,   
                                   c2.status, c2.corp_id, c2.corp_name   
                              FROM    
                                 (Select c.Client_ID as client_id, c.Client_Name as location_name, c.Bill_Date_Next as nextbillingdate, c.Status, c.Corporate_Relationship_Id as corp_id, c.Corporate_Relationship_Name as corp_name   
                                  From Client_Summary c   
                                  UNION ALL                 
                                  Select c.Client_ID as client_id, c.Client_Name as location_name, DATEADD(month, -1, c.Bill_Date_Next) as nextbillingdate, c.Status, c.Corporate_Relationship_Id as corp_id, c.Corporate_Relationship_Name as corp_name   
                                  From Client_Summary c   
                                  UNION ALL   
                                  Select c.Client_ID as client_id, c.Client_Name as location_name, DATEADD(month, -2, c.Bill_Date_Next) as nextbillingdate, c.Status, c.Corporate_Relationship_Id as corp_id, c.Corporate_Relationship_Name as corp_name   
                                  From Client_Summary c   
                                  UNION ALL   
                                  Select c.Client_ID as client_id, c.Client_Name as location_name, DATEADD(month, -3, c.Bill_Date_Next) as nextbillingdate, c.Status, c.Corporate_Relationship_Id as corp_id, c.Corporate_Relationship_Name as corp_name   
                                  From Client_Summary c   
                                  UNION ALL   
                                  Select c.Client_ID as client_id, c.Client_Name as location_name, DATEADD(month, -4, c.Bill_Date_Next) as nextbillingdate, c.Status, c.Corporate_Relationship_Id as corp_id, c.Corporate_Relationship_Name as corp_name   
                                  From Client_Summary c   
                                  UNION ALL   
                                  Select c.Client_ID as client_id, c.Client_Name as location_name, DATEADD(month, -5, c.Bill_Date_Next) as nextbillingdate, c.Status, c.Corporate_Relationship_Id as corp_id, c.Corporate_Relationship_Name as corp_name   
                                  From Client_Summary c                   
                                  UNION ALL   
                                  Select c.Client_ID as client_id, c.Client_Name as location_name, DATEADD(month, -6, c.Bill_Date_Next) as nextbillingdate, c.Status, c.Corporate_Relationship_Id as corp_id, c.Corporate_Relationship_Name as corp_name   
                                  From Client_Summary c   
                                  UNION ALL                   
                                  Select c.Client_ID as client_id, c.Client_Name as location_name, DATEADD(month, -7, c.Bill_Date_Next) as nextbillingdate, c.Status, c.Corporate_Relationship_Id as corp_id, c.Corporate_Relationship_Name as corp_name   
                                  From Client_Summary c   
                                  UNION ALL   
                                  Select c.Client_ID as client_id, c.Client_Name as location_name, DATEADD(month, -8, c.Bill_Date_Next) as nextbillingdate, c.Status, c.Corporate_Relationship_Id as corp_id, c.Corporate_Relationship_Name as corp_name   
                                  From Client_Summary c   
                                  UNION ALL   
                                  Select c.Client_ID as client_id, c.Client_Name as location_name, DATEADD(month, -9, c.Bill_Date_Next) as nextbillingdate, c.Status, c.Corporate_Relationship_Id as corp_id, c.Corporate_Relationship_Name as corp_name   
                                  From Client_Summary c ) c2 ) cl    
               
                     ON cl.cid=stats_sess.full_client_id and cl.previousbillingdate <= stats_sess.full_date and cl.nextbillingdate > stats_sess.full_date) stats_sess_client   
                     LEFT JOIN    
                     (Select round(cast(pac.balance_micros as bigint)/1000000,2) as balance, 
                             pac.refresheded_at, cast(pacrm.domain_key as bigint) as acquisio_client_id, 
                             pacrm.created,
                             pacrm.start_date    
                      From public_acquisio_customer pac    
                              JOIN    
                                     (Select * From public_acquisio_customer_ref_mapping Where domain LIKE 'premiumservicesclient') pacrm    
                              ON pac.acquisio_ref=pacrm.acquisio_customer_ref   
                      Where refresheded_at > '01/01/2020') baltab ON stats_sess_client.full_client_id=baltab.acquisio_client_id and stats_sess_client.full_date=DATEADD(DAY, -1,Convert(date,baltab.refresheded_at))   
                     
                     LEFT JOIN (Select Id, Convert(bigint, Client_ID__c) as SF_ClientID, CaseNumber, ClosedDate   
                                From dbo.salesforcecase Where ClosedDate> '01/01/2020' AND ISNUMERIC(Client_ID__c)=1) SF 

                     on stats_sess_client.full_client_id=SF.SF_ClientID AND stats_sess_client.full_date=convert(date,SF.ClosedDate) ) master   
            
      Group By master.corp_id, master.full_client_id, master.full_date) grp) cycle) corpavg