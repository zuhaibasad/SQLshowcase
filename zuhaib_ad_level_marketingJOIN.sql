With merging as (Select * -- since Channel google ad has only campaign_id, adset_id, ad_id column 
						  -- and Channel facbook ad has only campaign_name, adset_name, ad_name filled
						  -- its necessary to merge both for correct grouping and JOINING with Ads Report

						,COALESCE(campaign_id,campaign_name) as campaign_main
						,COALESCE(adset_id, adset_name) as adset_main
						,COALESCE(ad_id, ad_name) as ad_main
						,date_trunc('week', "Closed Date") as week_of

				 FROM report1
				 WHERE "Closed Date" IS NOT NULL),

		startweek as (SELECT 
				    week_of as week_of_hs
				    ,"Channel" as channel_hs

				    ,campaign_main::text as campaign_main
				    ,adset_main::text as adset_main
				    ,ad_main::text as ad_main
				    
				    ,MAX("campaign_id") as campaign_id_hs
				    ,MAX("campaign_name") as campaign_name_hs
				    ,MAX("adset_id")::text as adset_id_hs
				    ,MAX("adset_name") as adset_name_hs
				    ,MAX("ad_id")::text as ad_id_hs
				    ,MAX("ad_name") as ad_name_hs

				    ,SUM(CASE
				    		WHEN "Channel" = 'pema' AND start < '2021-07-08' THEN 79
				    		WHEN "Channel" = 'pema' AND start < '2021-11-01' THEN 100
				    		WHEN "Channel" = 'pema' THEN 200
				    		ELSE 0 END) AS cost_pema
				  	,MAX("start") as most_recent_call
				    ,COUNT(*) AS calls_scheduled
				    ,SUM(CASE WHEN start < NOW() AND "stage" NOT IN ('MQL') THEN 1 ELSE 0 END) AS calls_past
				    ,SUM(CASE WHEN start < NOW() AND "stage" NOT IN ('MQL', 'No Show', 'Cancelled') THEN 1 ELSE 0 END) AS calls_taken
				    ,SUM(CASE WHEN start < NOW() AND "stage" IN ('No Show', 'Cancelled') THEN 1 ELSE 0 END) AS calls_missed
				    
				    ,SUM(CASE WHEN "stage" = 'Won' THEN 1 ELSE 0 END) AS won
				    ,SUM(CASE WHEN "stage" = 'Lost' THEN 1 ELSE 0 END) AS lost
				    ,SUM(CASE WHEN "stage" = 'No Show' THEN 1 ELSE 0 END) AS no_show
				    ,SUM(CASE WHEN "stage" = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled
				    ,SUM(CASE WHEN "stage" = 'Follow-Up Call Scheduled' THEN 1 ELSE 0 END) AS follow_up
				    ,SUM(CASE WHEN "stage" = 'Pending' THEN 1 ELSE 0 END) AS pending
				    ,SUM(CASE WHEN "stage" = 'Refunded' THEN 1 ELSE 0 END) AS refunded
				    ,SUM(CASE WHEN "stage" = 'MQL' THEN 1 ELSE 0 END) AS MQL
				  
				  	,COUNT(DISTINCT CASE WHEN "stage"='Won' THEN id ELSE NULL END) AS deals_won
				  	,COUNT(DISTINCT CASE WHEN "stage"='Won' THEN id ELSE NULL END) AS deals_closed

				    ,SUM(CASE WHEN "stage"='Won' THEN "downpayment" ELSE 0 END) AS downpayment_collected
				    ,SUM(CASE WHEN "stage"='Won' THEN "paid" ELSE 0 END) AS cash_collected
				    ,SUM(CASE WHEN "stage"='Won' THEN "amount" ELSE 0 END) AS Revenue
				  
				    ,array_agg(DISTINCT "stage") AS stages
				    
				    FROM merging
				    GROUP BY week_of,"Channel", campaign_main, adset_main, ad_main), -- is grouping at ad-level fine for hubspot stats/metrics?

	week_ads_spend as ( -- on campaign_id, adset_id, ad_id
						  SELECT 
						  	week_of as week_of_ads
						    ,MAX(date) as most_recent_ad_payment
						  	,"channel" AS channel_ads
						  	, CASE WHEN "channel" LIKE 'youtube' THEN 'google ad' ELSE "channel" END as channel_ads_temp
						  	,"campaign_id"::text as campaign_id_ads
						  	,"campaign_name" as campaign_name_ads
						  	
						  	,"adset_id"::text as adset_id_ads
						  	,"adset_name" as adset_name_ads

						  	,"ad_id"::text as ad_id_ads
						  	,"ad_name" as ad_name_ads
						  	
						  	
						  	,SUM("spend") AS cost
						  
						  FROM report2
						  GROUP BY week_of, "channel", "campaign_name", "campaign_id", "adset_id", "adset_name", "ad_id", "ad_name")

	Select  
			 COALESCE(ad_id_hs, ad_id_ads) as ad_id
			,COALESCE(adset_id_hs, adset_id_ads) as adset_id
			,COALESCE(campaign_id_hs, campaign_id_ads) as campaign_id
			,btrim(lower(campaign)) as campaign
			,btrim(lower(adset)) as adset
			,btrim(lower(ad)) as ad
			,* EXCEPT(campaign, adset, ad)
	From (

		SELECT	 COALESCE(hs.week_of_hs, ad.week_of_ads) as week_of
				,COALESCE(ad.channel_ads, hs.channel_hs) as channel
	    		,COALESCE(hs.campaign_name_hs, ad.campaign_name_ads) as campaign
				,COALESCE(hs.adset_name_hs, ad.adset_name_ads) as adset
				,COALESCE(hs.ad_name_hs, ad.ad_name_ads, hs.ad_id_hs) as ad
				,*

		From startweek hs LEFT JOIN week_ads_spend ad
					 ON hs.week_of_hs=ad.week_of_ads
					 AND hs.channel_hs=ad.channel_ads_temp
					 AND (btrim(lower(hs.campaign_main)) = btrim(lower(ad.campaign_id_ads)) OR btrim(lower(hs.campaign_main)) = btrim(lower(ad.campaign_name_ads)))
					 AND (btrim(lower(hs.adset_main)) = btrim(lower(ad.adset_id_ads)) OR btrim(lower(hs.adset_main)) = btrim(lower(ad.adset_name_ads)) )
					 AND (btrim(lower(hs.ad_main)) = btrim(lower(ad.ad_id_ads)) OR btrim(lower(hs.ad_main)) = btrim(lower(ad.ad_name_ads)) )

		UNION

		SELECT	 COALESCE(hs.week_of_hs, ad.week_of_ads) as week_of 
				,COALESCE(ad.channel_ads, hs.channel_hs) as channel
	    		,COALESCE(hs.campaign_name_hs, ad.campaign_name_ads) as campaign
				,COALESCE(hs.adset_name_hs, ad.adset_name_ads) as adset
				,COALESCE(hs.ad_name_hs, ad.ad_name_ads, hs.ad_id_hs) as ad
				,*

		From startweek hs RIGHT JOIN week_ads_spend ad
					 ON hs.week_of_hs=ad.week_of_ads
					 AND hs.channel_hs = ad.channel_ads_temp
					 AND (btrim(lower(hs.campaign_main)) = btrim(lower(ad.campaign_id_ads)) OR btrim(lower(hs.campaign_main)) = btrim(lower(ad.campaign_name_ads)))
					 AND (btrim(lower(hs.adset_main)) = btrim(lower(ad.adset_id_ads)) OR btrim(lower(hs.adset_main)) = btrim(lower(ad.adset_name_ads)) )
					 AND (btrim(lower(hs.ad_main)) = btrim(lower(ad.ad_id_ads)) OR btrim(lower(hs.ad_main)) = btrim(lower(ad.ad_name_ads)) )
 	) a

Order By a.week_of DESC, a.channel

