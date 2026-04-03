





CREATE PROCEDURE [finAnalytics].[repForgive6]
	@repmonth date
	with recompile

AS
BEGIN

SELECT [repmonth]
      ,[nomenkGr]
      ,[pokazatel]
      ,[rowNum]
      ,[sumOD]
      ,[sumPrc]
      ,[sumOther]
      ,[sumItogo]
      ,[sumnonColl]
      ,[sumAll]
      ,[comment]
      ,[emptyFld]
      ,[checkOSV]
      ,[checkResult]
  FROM [dwh2].[finAnalytics].[repForgive5]
  where [repmonth] = @repmonth


  
END
