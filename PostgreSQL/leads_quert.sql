-- this is a PostgresSQL query

-- this is used to extract Raw Leads from phonecalls, Websource, Form fills and also 
-- attribution as paid, organic etc ... 
-- The complexity in this query is due to the complex tracking of Offline leads
-- which are tracked via phone tracking and another complexity is due to the 
-- extensive franchise network of corporates. So need to assign raw leads to the corporate
-- and its franchise, for which it came for. 

Select  cls.clientname as client_name, cls.clientid as client_id, cls.city as client_city, cls.zipcode as client_zipcode,
		cls.state as client_state, cls.PPL_Live_Date as client_PPL_LiveDate,
          
		le.id as lead_id, le.city as lead_city, le.client_id as lead_client_id, le.contact_id as contact_id1,
		le.country as lead_country, le.deleted, le.name as lead_name, le.notes as lead_notes, le.paid as lead_paid,
		le.primaryattribution, le.secondaryattribution, le.state as lead_state, le.lead_street1 as lead_street1,
		le.type as lead_type, le.zipcode as lead_zipcode, le.createddate as lead_createddate, le.street1 as lead_street1,
		le.street2 as lead_street2,

		cls.corpid as cr_id, cls.corpname as cr_name,

    lccmain.trackingnumber, lccmain.destinationnumber, lccmain.callernumber, lccmain.callername, lccmain.callstart, lccmain.callend, lccmain.callstatus,
    lccmain.audiofilename, lccmain.callanswerstatus, lccmain.audiofileurl, lccmain.quality_rating, (lccmain.callend - lccmain.callstart) as call_duration,


    lcw.fromemail, lcw.emailtoaddresses, lcw.bccemailaddresses, lcw.content, lcw.sitedomainname, lcw.submitserver, lcw.submiturl,
    lcw.web_userid, lcw.subtype, lcf.comments,

   ctnc.id as calltrackingnumberconfiguration, ctnc.routingnumber, ctnc.whisperon, ctnc.callrecordingon, ctnc.provisioned, ctnc.calltrackingon,
   ctnc.areacode, ctnc.local, ctnc.name as ct_name,
   ctn.number as ct_number, ctn.phonenumbergroup, ctn.owned,

   cn.firstname, cn.lastname, cn.status, cn.lastvalidlead_id,
   cn.client_id as client_id1, cn.id as contact_id, cn.createtimestamp as contact_createdtimestamp,

   lr.rating as final_rating, lr.detailed_rating as final_detailed_rating, lr.rated_on as rating_date

-- Since this dataset is very large and getting updated every second
-- And its primary data source of company
-- We need to involve data in JOINs only what we need
-- and not whole tables

From (select le1.id, le1.city, le1.client_id, le1.contact_id,
          le1.country, le1.deleted, le1.name, le1.notes, le1.paid,
          le1.primaryattribution, le1.secondaryattribution, le1.state, le1.street1,
          le1.type, le1.zipcode, le1.createddate, le1.street1 as lead_street1,
          le1.street2 from control_lead le1 Where le1.createddate > '12/31/2020 23:59:59') le 
      INNER JOIN 
          
		  (Select cls.Client_Name as clientname, cls.Client_ID as clientid, cls.city, cls.zipcode,
			  	  cls.state, cls.Country, cls.PPP_Live_Date, 
				  Corporate_Relationship_Id as corpid, Corporate_Relationship_Name as corpname

  		   From dbo.Client_Summary cls) ON le.client_id=cls.clientid
      
      LEFT JOIN control_lead_content_web lcw ON le.id=lcw.id
      
      LEFT JOIN (Select  id, trackingnumber, destinationnumber, callernumber, callername, callstart, callend, callstatus,
                                 audiofilename, callanswerstatus, audiofileurl, quality_rating 
                       FROM control_lead_content_call Where lower(callername) NOT LIKE 'yodle') lccmain 
				
				ON le.id = lccmain.id
      
       LEFT JOIN control_calltrackingnumber ctn ON lccmain.trackingnumber=ctn.number
      
       LEFT JOIN control_calltrackingnumberconfiguration ctnc ON ctn.calltrackingnumberconfiguration_id=ctnc.id

       LEFT JOIN control.lead_contact_form lcf ON le.id=lcf.id 
       
       LEFT JOIN control.contact cn ON le.contact_id=cn.id
       
       LEFT JOIN (     Select lr1.lead_id, lr1.rating, lr1.detailed_rating, lr1.rated_on
                       From (Select lead_id, rating, detailed_rating, rated_on, rank () over (partition by lead_id order by rated_on DESC) as rank 
                                   From control_lead_rating) lr1
                          Where lr1.rank=1 ) lr ON le.id = lr.lead_id