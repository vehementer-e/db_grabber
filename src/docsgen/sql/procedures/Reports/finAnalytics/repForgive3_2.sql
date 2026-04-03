





CREATE PROCEDURE [finAnalytics].[repForgive3_2]
	@repmonth date
	with recompile

AS
BEGIN

SELECT [repmonth]
      ,[spisReason]
	  ,[bucket]
      ,[nomenkGR]
      ,[sumSpisPRC]
      ,[sumSpisPenia]
      ,[sumFogiveOD]
      ,[sumFogivePRC]
      ,[sumFogivePenia]
      ,[sumItog]
      ,restoreRVP
	  ,finrez
      ,[rowNum]
	  ,[bucketNum]
  FROM [dwh2].[finAnalytics].[repForgive2_2]
  where [repmonth] = @repmonth


  
END
