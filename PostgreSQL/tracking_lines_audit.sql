-- This is a PostgresSQL query
-- used to track minutes per tracking phone lines which company is using
-- so they can validate billings and hours per phone number tracking line
-- this query has two parts

select 
cr.id as corp_id
, cr.name as corp_name
, c.id as client_id
, c.name as client_name
, c.status as client_status
, ctnc.name as description
, ctc.primaryattribution
, ctc.secondaryattribution
, c.phone as business_phone
, ctn.number as call_tracking_number
, routingnumber as destination_number
, CASE WHEN ctnc.calltrackingon = True THEN 'Active' ELSE 'Inactive' END as calltracking_status
, ctnc.callrecordingon as recording_status
, ctnc.whisperon as whisper_status
, lcc1.callstart, lcc1.callend, lcc1.id, (lcc1.callend-lcc1.callstart) as callduration

from control.calltrackingnumber ctn
left join (
		select lcc.trackingnumber, lcc.callend, lcc.id, lcc.callstart
		from control.lead_content_call lcc
		where lcc.callstart::date < current_date
				and lower(lcc.callername) != 'yodle'
				and lcc.callstart > CURRENT_DATE - INTERVAL '3 months'
	) lcc1 on lcc1.trackingnumber=ctn.number

join control.calltrackingnumberconfiguration ctnc on ctn.calltrackingnumberconfiguration_id=ctnc.id
join control.ctcattributionconfig ctc on ctc.id=ctnc.attributionconfig_id
join (Select cli.id, cli.name, cli.status, cli.phone FROM control.client cli WHERE oemaccountparent_id is null) c on c.id=ctc.client_id
join control.franchisemasteraccount_client fmac on fmac.franchisechildren_id=c.id
join control.corporate_relationship cr on cr.fma_id=fmac.franchisemasteraccount_id


-- In this second query we just Count Total call minuetes per tracking phone line
 
Select a.corp_id, a.client_id, a.calltracking_status, a.call_tracking_number, a.callstart_year, SUM(a.callduration) as lastthreemonths_callduration
FROM (select cr.id as corp_id
, cr.name as corp_name
, c.id as client_id
, c.name as client_name
, c.status as client_status
, ctn.number as call_tracking_number
, CASE WHEN ctnc.calltrackingon = '1' THEN 'Active' ELSE 'Inactive' END as calltracking_status
, lcc1.callstart, lcc1.callend, lcc1.id, (lcc1.callend-lcc1.callstart) as callduration
, EXTRACT(Month FROM lcc1.callstart) as callstart_month, EXTRACT(Year From lcc1.callstart) as callstart_year

from control.calltrackingnumber ctn
left join (
		select lcc.trackingnumber, lcc.callend, lcc.id, lcc.callstart
		from control.lead_content_call lcc
		where lcc.callstart::date < current_date
				and lower(lcc.callername) != 'yodle'
				and lcc.callstart > CURRENT_DATE - INTERVAL '3 months'
	) lcc1 on lcc1.trackingnumber=ctn.number
join control.calltrackingnumberconfiguration ctnc on ctn.calltrackingnumberconfiguration_id=ctnc.id
join control.ctcattributionconfig ctc on ctc.id=ctnc.attributionconfig_id
join (Select cli.id, cli.name, cli.status, cli.phone FROM control.client cli WHERE oemaccountparent_id is null) c on c.id=ctc.client_id
join control.franchisemasteraccount_client fmac on fmac.franchisechildren_id=c.id
join control.corporate_relationship cr on cr.fma_id=fmac.franchisemasteraccount_id) a
Group By a.corp_id, a.client_id, a.calltracking_status, a.call_tracking_number, a.callstart_year