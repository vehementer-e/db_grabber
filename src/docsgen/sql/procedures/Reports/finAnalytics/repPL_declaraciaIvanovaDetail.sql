




CREATE PROCEDURE [finAnalytics].[repPL_declaraciaIvanovaDetail]
	@repYear date

AS
BEGIN

	declare @repMonthTo date = (select max(repmonth) 
								from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
								where year(repmonth) = year(@repYear))

    SELECT [repmonth]
      ,[part]
      ,[partNum]
      ,[rowNum]
      ,[rowName]
      ,[accNum]
      ,[pokazatel]
      ,[amountBU]
      ,[correctionPlus]
      ,[correctionMinus]
      ,[amountNU]
      ,[comment]
  FROM [dwh2].[finAnalytics].[repPLDeclaraciaIvanova]
  where repmonth = @repMonthTo

END
