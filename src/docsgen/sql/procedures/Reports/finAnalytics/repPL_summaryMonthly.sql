



CREATE PROCEDURE [finAnalytics].[repPL_summaryMonthly]
	@repMonthFrom date,
	@repMonthTo date

AS
BEGIN

    SELECT 
	   [repmonth]
      ,[rowNum]
      ,[rowName]
      ,[pokazatel]
      ,[amountPrev]
      ,[amountTek]
      ,[amountMonth]
      ,[created]
  FROM [dwh2].[finAnalytics].[repPLf843_summary]
  where repmonth between @repMonthFrom and @repMonthTo
  
END
