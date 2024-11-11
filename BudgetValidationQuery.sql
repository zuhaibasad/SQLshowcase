with groupedstats as 
    (Select client_id, day, MAX(budget) as budget 
     From control_ad_campaign_lead_stats 
     Where day > '01/01/2021' 
     Group By client_id, day),

 completetable as 
    (Select  cl.Corporate_Relationship_Id as CorpID
            ,cl.Corporate_Relationship_Name as CorpName
            ,MAX(cl.Client_name) as LocationName
            ,cl.client_ID
            ,cl.status as AccountStatus
            ,cl.Bill_Date_Next as nextbillingdate
            ,DATEADD(month, -1, cl.Bill_Date_Next) as previousbillingdate
            ,ad.day as stats_day
            ,MAX(ad.budget) as budget
     From client_summary cl LEFT JOIN 
                                groupedstats ad ON cl.Client_id=ad.client_id 
                                                    and cl.Bill_Date_Next>ad.day 
                                                    and DATEADD(month, -1, cl.Bill_Date_Next)<=ad.day

    Where cl.status LIKE 'LIVE' and ad.day >= DATEADD(day, -10,  cast(GETDATE() as DATE))
    Group By cl.Corporate_RelationShip_Id, cl.Corporate_RelationShip_Name, cl.Client_id, cl.Status, cl.Bill_Date_Next, ad.day)

Select c.*, p.product_status as SEMStatus, b.*, 
		DENSE_RANK() OVER(Partition By c.client_id Order By c.previousbillingdate DESC) as cyclenumber
From completetable c LEFT JOIN 
						(Select client_id, STRING_AGG(product, ', ') as product,
								CASE
								WHEN STRING_AGG(status, ', ') LIKE '%Live%' THEN 'Live' ELSE 'Off' END as product_status
								From analytics_client_product_status
								Where product LIKE '%SEM%'
								Group By client_id) p ON c.Client_ID=p.client_id 
					 LEFT JOIN acquisio_budgetbalance b ON b.clientid=c.client_id AND b.DataExtractedAt=c.stats_day