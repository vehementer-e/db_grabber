


CREATE PROCEDURE [finAnalytics].[rep832]
	@qName NVarchar(50)
	
AS
BEGIN

    SELECT [qName]
      ,[repmonth]
      ,[rowNum]
      ,[dogCode]
      ,[PDNInterval]
      ,[srokInterval]
      ,[sumInterval]
      ,[allZaim]
      ,[allZaimpayBack]
      ,[sumAllZaim]
      ,[sumAllZaimpayBack]
      ,[zaimPDN]
      ,[sumZaimPDN]
  FROM [dwh2].[finAnalytics].[rep832]
  where qName = @qName

END
