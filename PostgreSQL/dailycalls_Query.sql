-- this is a PostgreSQL query
-- it is written as required by our client for naming conventions


select 

cast(EXTRACT(YEAR FROM l.createddate) as VARCHAR) ||'q'|| cast(EXTRACT(QTR FROM l.createddate) as VARCHAR) ||'.'|| cast(l.id as VARCHAR) as callid
,regexp_replace(lcc.trackingnumber, '(\d{3})(\d{3})(\d{4})', '(\1) \2-\3') as didfmt
,lcc.callstart as gmttime
,lcc.callstatus

,((DATE_PART('day', lcc.callend::timestamp - lcc.callstart::timestamp) * 24 + 
        DATE_PART('hour', lcc.callend::timestamp - lcc.callstart::timestamp)) * 60 +
        DATE_PART('minute', lcc.callend::timestamp - lcc.callstart::timestamp)) * 60 +
        DATE_PART('second', lcc.callend::timestamp - lcc.callstart::timestamp) as callduration

,regexp_replace(lcc.callernumber, '(\d{3})(\d{3})(\d{4})', '(\1) \2-\3') as anifmt
,CASE WHEN fli.external_id IS NULL THEN cast(c.id as VARCHAR) ELSE fli.external_id END as customercode
,'' as contactemail
,CASE
     WHEN a.description IS NULL
     THEN 'organic' ELSE a.description END as adsource
,'https://s3.amazonaws.com/callaudio/' || lcc.audiofileurl as audiourl
,LEFT(lcc.callername, strpos(lcc.callername, ' ')) as caller_first_name
,RIGHT(lcc.callername, LENGTH(lcc.callername)-strpos(lcc.callername, ' ')) as caller_last_name

,case when l.city = '' then 'Unknown' else l.city end as callercity
,case when l.state = '' then 'Unknown' else l.state end as callerstate
,case when l.zipcode = '' then 'Unknown' else l.zipcode end as callerzip

from control.lead l
        left join control.lead_content_call lcc on lcc.id = l.id
        left join control.session s on l.sessionid = s.id
        left join control.client c on c.id = l.client_id
        left join control.franchisemasteraccount_client fma on fma.franchisechildren_id = c.id
        join control.corporate_relationship corp on corp.fma_id = fma.franchisemasteraccount_id
        left join mapping.franchise_external_client_id fli on c.id = fli.client_id
        left join control.calltrackingnumber n on n.number = lcc.trackingnumber
        left join control.calltrackingnumberconfiguration nc on n.calltrackingnumberconfiguration_id = nc.id
        left join control.ctcattributionconfig a on a.id = nc.attributionconfig_id

where corp.Id IN
        (827, 
        825, 
        823, 
        822)

and l.createddate >= NOW()::date - INTERVAL '1 day' and l.createddate < NOW()::date and l.dtype = 'CallTrackingLead'