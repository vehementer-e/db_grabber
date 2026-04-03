
CREATE PROCEDURE [finAnalytics].[repPL_summaryMonthlySPOD]
	@repMonthFrom date,
	@repMonthTo date

AS
BEGIN

    select
	[rowNum] = l1.[rowNum]
	,[rowName] = l1.[rowName]
	,[pokazatel] = l1.[pokazatel]
	,[amountYear] = l1.[amountMonth]
	,[amountSPOD] = spod.[sumAmount]-- *-1
	,[amountItog] = l1.[amountMonth] + isnull(spod.[sumAmount],0) --*-1
from(
SELECT 
      [rowNum]
      ,[rowName]
      ,[pokazatel]
      ,[amountMonth] = sum([amountMonth])
FROM [dwh2].[finAnalytics].[repPLf843_summary]
where year(repmonth) = year(@repMonthTo)

group by [rowNum]
      ,[rowName]
      ,[pokazatel]
) l1

left join dwh2.[finAnalytics].[repPLf843SPOD] spod on 
						l1.rowName = spod.[rowName] 
						and spod.repYear = DATEFROMPARTS(year(@repMonthTo),1,1)
						and spod.rowName in ('1','2','3','4','13','15','16','17','10','14','62','18','19','20','21','23','63')
  
END
