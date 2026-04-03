


CREATE PROCEDURE [finAnalytics].[repPL_summary1]
	@repMonthFrom date,
	@repMonthTo date

AS
BEGIN

    SELECT 
	   [repmonth]
      ,[rowNum]
      ,[rowName]
      ,[pokazatel]
      ,[aplicator]
      ,[BSAcc]
      ,[symbolName]
      ,[sumAmount]
      ,[created]
  FROM [dwh2].[finAnalytics].[repPLf843]
  where repmonth between @repMonthFrom and @repMonthTo
  and rowName not like '%.%'

END
