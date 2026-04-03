





CREATE PROCEDURE [finAnalytics].[repPL_MSFOMonthlySPOD]
	@repMonthFrom date,
	@repMonthTo date

AS
BEGIN

    select
	[rowNum] = l1.[rowNum]
	,[pokazatel] = l1.[pokazatel]
	,[amountYear] = l1.[amountMonth]
	,[amountSPOD] = isnull(spod.[sumAmount]/* *-1*/,0)
	,[amountItog] = l1.[amountMonth] + isnull(spod.[sumAmount] /**-1*/,0)
from(
SELECT 
      [rowNum]
      ,[pokazatel]
	  ,rowName = [rowNameToMerge]
      ,[amountMonth] = sum([amountMonth])
FROM [dwh2].[finAnalytics].[repPL_MSFO]
where year(repmonth) = year(@repMonthTo)

group by [rowNum]
	  ,[rowNameToMerge]
      ,[pokazatel]
) l1


left join dwh2.[finAnalytics].[repPLf843SPOD] spod on 
						l1.rowName = spod.[rowName] 
						and spod.repYear = DATEFROMPARTS(year(@repMonthTo),1,1)
						and spod.rowName in ('1','2','4','13','15','20','21','23')
  
END
