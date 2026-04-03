




CREATE   PROCEDURE [finAnalytics].[rep840_1_6]
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
	, [restOD] = [restOD] / @sumRang
	, [restPRC] = [restPRC] / @sumRang
	, [restPenya] = [restPenya] / @sumRang
	, [rowNum]
	
    from dwh2.[finAnalytics].rep840_1_6
	where REPMONTH= @repmonth
    
END
