-- This is a PostgresSQL query
-- it is calculating balance for each of our client's
-- each client is under some Parent Corporate (franchise network)

Select c.id as client_id
	   ,c.name as client_name
	   ,(date_trunc('MONTH', (balance.day)::date) + INTERVAL '1 MONTH - 1 day')::DATE
	   ,balance.endbalancecents
	   ,balance.financialaccount_id
	   ,cfa.client_id as cfa_clientid
	   ,cfa.financialaccounts_id as cfa_financialaccounts_id
	   ,cr.name as corp_name
	   ,cr.fma_id

FROM control.client c
			LEFT JOIN control.client_financialaccount cfa ON c.id = cfa.client_id
     		JOIN snapshot.financialaccount_balance balance ON balance.financialaccount_id = cfa.financialaccounts_id
     		join control.franchisemasteraccount_client fmac on fmac.franchisechildren_id=c.id 
     		join control.corporate_relationship cr on cr.fma_id=fmac.franchisemasteraccount_id

Where cr.name LIKE 'Budget%Blinds' OR cr.name LIKE 'Concrete%Craft' OR cr.name LIKE 'Tailored%Living' and balance.day > '12/31/2018'

order by balance.day ASC
