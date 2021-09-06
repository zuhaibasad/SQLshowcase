-- this is MS-SQL Stored Procedure
-- it is used to backup a table in Data Mart
-- table is continuously updated, deleting rows and adding rows
-- so we need to truncate every time. 

USE [DataMart]
GO
/****** Object:  StoredProcedure [dbo].[Client_Natpal]    Script Date: 9/6/2021 3:02:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Zuhaib,Asad>
-- Create date: 1/4/20201>
-- Description:	Get data from Natpal Client>
-- =============================================

ALTER PROCEDURE [dbo].[Client_Natpal]
	
AS

BEGIN


truncate table [DataMart].[dbo].[client]

insert into [DataMart].[dbo].[client]
SELECT * from OPENQUERY (DB, 'select id, state, country, city, name, status, nationalaccount, nextbillingdate from client;')

END

