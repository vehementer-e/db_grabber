





CREATE PROCEDURE [finAnalytics].[repPL_MSFO]
	@repMonthFrom date,
	@repMonthTo date

AS
BEGIN

    SELECT [repmonth]
      ,[rowNum]
      ,[rowNameToMerge]
      ,[pokazatel]
      ,[amountMonth]
  FROM [dwh2].[finAnalytics].[repPL_MSFO]
  where repmonth between @repMonthFrom and @repMonthTo
  
END
