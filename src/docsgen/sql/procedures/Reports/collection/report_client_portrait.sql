CREATE   PROCEDURE [collection].[report_client_portrait]
    --@StartDate DATE = null
AS
BEGIN
	--IF @StartDate IS NULL
    --    SET @StartDate = CAST(GETDATE() AS date);
    SELECT 
        [ClientFio],
		[ClientGUID],
		[Age],
		[Gender],
		[EmploymentType],
		[Number],
		[ContractStart],
		[ContractStartMonth],
		[dpd],
		case 
			when dpd > 0 and dpd < 31 then '1-30'
			when dpd >= 31  and dpd < 61 then '31-60'
			when dpd >= 61 and dpd < 91 then '61-90'
			else '91+'
		end as bucket
    FROM 
		reports.collection.dm_client_portret
	where
		dpd > 0
	order by ContractStart desc
END;