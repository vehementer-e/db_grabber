


CREATE PROCEDURE [finAnalytics].[repPL_declaraciaMonthly]
	@repMonthFrom date,
	@repMonthTo date

AS
BEGIN

    SELECT 
	[repmonth]
	, [rowNum]
	, [rowName]
	, [pokazatel]
	, [sprCode]
	, [stavka]
	, [isItog]
	, [sumAmount]
  FROM [dwh2].[finAnalytics].repPLDeclaraciaMonthly
  where repmonth between @repMonthFrom and @repMonthTo

END
