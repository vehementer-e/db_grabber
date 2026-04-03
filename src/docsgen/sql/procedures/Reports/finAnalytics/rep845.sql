



CREATE PROCEDURE [finAnalytics].[rep845]
	@repYear int
	
AS
BEGIN
    SELECT 
	   [repmonth]
      ,[rowNum]
      ,[rowName]
      ,[pokazatel]
      ,[aplicator]
      ,[DTAcc]
      ,[KTAcc]
      ,[isBold]
      ,[comment]
      ,[amount]
  FROM [dwh2].[finAnalytics].[rep845]
  where year(repmonth) = @repYear

END
