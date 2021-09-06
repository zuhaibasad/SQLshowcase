-- this is a Postgres SQL query 

-- was for  ad-hoc reporting requirement for one of our client

Select	cl.name as client_name, 
		cl.id as client_id, 
		cl.city as client_city,
		cl.zipcode as client_zipcode,
		cl.street1 as client_street1,
		cl.state as client_state,
		cl.orderdate as client_orderdate,
		le.id as lead_id,
		le.city as lead_city,
		le.client_id as lead_client_id,
		le.contact_id as contact_id1,
		le.country as lead_country,
		le.deleted,
		le.name as lead_name,
		le.notes as lead_notes,
		le.paid as lead_paid,
		le.primaryattribution,
		le.secondaryattribution,
		le.state as lead_state,
		le.street1 as lead_street1,
		le.type as lead_type,
		le.zipcode as lead_zipcode,
		le.createddate as lead_createddate,
		lcl.audiofilename, 
		lcl.audiofileurl,
		lcl.callend,
		lcl.callstart,
		lcl.callstatus,
		lcl.callername,
		lcl.callernumber,
		lcl.trackingnumber,
		(lcl.callend - lcl.callstart) as call_duration,
		lcw.content,
		lcw.fromemail,
		cn.firstname,
		cn.lastname, 
		cn.status,
		cn.lastvalidlead_id,
 	    cn.client_id as client_id1,
 	    cn.id as contact_id,
 	    cn.createtimestamp as contact_createdtimestamp,
 	    lcf.comments

From control.client cl 
	 Left JOIN control.lead le ON cl.id = le.client_id
	 LEFT Join control.lead_content_call lcl ON le.id=lcl.id
	 LEFT JOIN control.lead_content_web lcw ON le.id=lcw.id
	 LEFT JOIN control.lead_contact_form lcf ON le.id=lcf.id
	 LEFT JOIN control.contact cn ON le.id=cn.lastlead_id

Where le.createddate >= '09/01/2020' and 
			(cl.name LIKE 'Affordable Dentures%' or cl.name LIKE 'Urgent Dental Care%' or cl.name = 'Advara Dental & Dentures' or 
				cl.name = 'XO Dentistry - Gilbert, AZ' or 
			 	cl.name = 'XO Dentistry - Phoenix, AZ' or cl.name = 'Dixie Dental Center- Spanish Fort, AL'
			 	or cl.name = 'Augusta Dental Center - East Augusta, GA' )
	and oemaccountparent_id is null and lcl.callername != 'yodle'

Order by cl.id ASC
