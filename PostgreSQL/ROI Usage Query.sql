-- this is a Postgres SQL query


select
	clnt.name,
	msg.clientid,
	roi.default_average_revenue_per_sale,
	roi.default_percentage_leads_became_sales,
	msg.sentdate,
	msg_events.report_events, msg_events.event_times
	LEN(msg_events.report_events) - LEN(REPLACE(msg_events.report_events, 'DELIVERED', '')),
	msg_events.Delivered_event_Count, msg_events.Bounce_event_Count, msg_events.Open_event_Count

from
	control.message msg left join control.client_roi_report_settings roi on	msg.clientid = roi.client_id
						left join control.client clnt on msg.clientid = clnt.id
						inner join (	
									select 'id',
											report.Delivered_event_Count,
											report.Bounce_event_Count,
											report.Open_event_Count,
											string_agg(to_char(report.event_time, "MM/DD/YYYY hh:mm:ss"), ',' order by report.event_type) as event_times,
											string_agg(report.event_type, ',' order by report.event_type) as report_events 
									from (	select
												distinct message.id , 
												SUM(CASE WHEN ISNULL(evnt.type,0)='1' THEN 1 ELSE 0 END) as Delivered_event_Count,
												SUM(CASE WHEN ISNULL(evnt.type,0)='2' THEN 1 ELSE 0 END) as Bounce_event_Count,
												SUM(CASE WHEN ISNULL(evnt.type,0)='3' THEN 1 ELSE 0 END) as Open_event_Count,
												case
												when evnt.type = '1' then 'DELIVERED'
												when evnt.type = '2' then 'BOUNCE'
												when evnt.type = '3' then 'OPEN'
												end as event_type, evnt.event_time
											from control.message message 
																inner join reporting.message_events evnt on evnt.message_id = message.id
											where
												evnt.event_time >= date_trunc('month', current_date - interval '1 month')
												and evnt.event_time < date_trunc('month', current_date)
												and message.sentdate >= date_trunc('month', current_date - interval '1 month')
												and message.sentdate < date_trunc('month', current_date)
												and message.type = 127 and evnt.type in (1, 2, 3)) as report 
									group by id) as msg_events
	
						on msg.id = msg_events.id