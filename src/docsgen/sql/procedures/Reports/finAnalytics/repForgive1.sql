



CREATE PROCEDURE [finAnalytics].[repForgive1]
	@repmonth date
	with recompile

AS
BEGIN

SELECT [repmonth]
      ,[subconto]
      ,[dt]
      ,[kt]
      ,[nomenkGR]
      ,[sumAmount]
      ,[rowNum]
      ,[colNum]
  FROM [dwh2].[finAnalytics].[repForgive1]
  where [repmonth] = @repmonth


  
END
