-- this is MS-SQL Stored Procedure

-- this updates table in DataMart in SQL Server using table in PostgreSQL database

USE [DataMart]
GO
/****** Object:  StoredProcedure [dbo].[ad__leads]    Script Date: 9/2/2021 10:30:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Zuhaib,Asad>
-- Create date: 1/4/20201>
-- Description:	Get data from PostgresSQL ad__leads>
-- =============================================

ALTER PROCEDURE [dbo].[control_lead_stats]
	
AS

BEGIN

truncate table [DataMart].[dbo].[ad__leads]
insert into [DataMart].[dbo].[ad__leads]
SELECT * from OPENQUERY (DB, 'select day,clicks,lead_count,impressions,budget,campaign_name,client_id,created_date,spend from control.ad_leads where created_date >= ''2020-01-01'';')
END

