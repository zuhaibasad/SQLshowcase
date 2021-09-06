-- this is a PostgresSQL query


select cr.id as corp_id, 
cr.name as corp_name, 
c.id as client_id, 
fec.external_id as franchise_id, 
c.name as client_name, 
c.status as client_status,
 f.fmas as fma_id, 
 ctnc.name as description, 
 ctc.primaryattribution, 
 ctc.secondaryattribution, 
 c.phone as business_phone,
ctn.number as call_tracking_number, 
routingnumber as destination_number, 
case when ctnc.calltrackingon='true' then 'Active' when ctnc.calltrackingon='false' then 'Inactive' end as calltracking_status, 
ctnc.callrecordingon as recording_status,
ctnc.whisperon as whisper_status, 
most_recent_call_date 

from control.calltrackingnumber ctn 
      join control.calltrackingnumberconfiguration ctnc on ctn.calltrackingnumberconfiguration_id=ctnc.id
 	  join control.ctcattributionconfig ctc on ctc.id=ctnc.attributionconfig_id
 	  join control.client c on c.id=ctc.client_id
 	  join control.franchisemasteraccount_client fmac on fmac.franchisechildren_id=c.id
 	  join control.corporate_relationship cr on cr.fma_id=fmac.franchisemasteraccount_id
 	  join ( select franchisechildren_id as client_id, array_to_string(array_agg(distinct franchisemasteraccount_id),', ') as fmas
 	  		 from control.franchisemasteraccount_client fmac
 	  		 group by franchisechildren_id ) f on f.client_id=c.idleft 
 	  join mapping.franchise_external_client_id fec on c.id=fec.client_idleft 
 	  join ( 
 	  		select trackingnumber, callstart::date as most_recent_call_date 
 	  		from (  select trackingnumber, lcc.id, callstart, rank() over (partition by trackingnumber order by callstart desc) as rank  
 	  			    from control.lead_content_call lcc  
 	  			    where callstart::date >= current_date-interval '90 days' 
 	  			          and callstart::date < current_date and lower(callername) != 'yodle'  ) x 
 	  		where rank=1 ) lcc on lcc.trackingnumber=ctn.number

where nationalaccount=trueand oemaccountparent_id is null