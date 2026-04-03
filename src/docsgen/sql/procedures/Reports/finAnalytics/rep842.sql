


CREATE PROCEDURE [finAnalytics].[rep842]
	@repYear int
	
AS
BEGIN
    SELECT [repmonth]
      ,[Razdel]
      ,[RowNum]
      ,[sub2Acc]
      ,[aplicator]
      ,[rowName]
      ,[pokazatel]
      ,[sub2AccName]
      ,[isActive]
      ,[restOut]
  FROM [dwh2].[finAnalytics].[rep842]
  where year(repmonth) = @repYear



END
