




CREATE PROCEDURE [finAnalytics].[repForgive3]
	@repmonth date
	with recompile

AS
BEGIN

SELECT [repmonth]
      ,[spisReason]
      ,[nomenkGR]
      ,[sumSpisPRC]
      ,[sumSpisPenia]
      ,[sumFogiveOD]
      ,[sumFogivePRC]
      ,[sumFogivePenia]
      ,[sumItog]
      ,[dogCount]
      ,[rowNum]
	  ,[dogCountOD]
  FROM [dwh2].[finAnalytics].[repForgive2]
  where [repmonth] = @repmonth


  
END
