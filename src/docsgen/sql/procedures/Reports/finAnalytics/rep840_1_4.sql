


CREATE PROCEDURE [finAnalytics].[rep840_1_4]
        @repmonth date,
        @sumRang int

AS
BEGIN
  
	select
	[REPMONTH]
	, [client]
	, [INN]
	, [OGRN]
	, [dogNum]
	, [restAll] = [restAll]/@sumRang
	, [StavkaRepDate]
	, [rowNum]
    from dwh2.[finAnalytics].[rep840_1_4]
	where REPMONTH= @repmonth
    
END
