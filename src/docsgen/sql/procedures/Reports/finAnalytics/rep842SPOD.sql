



CREATE PROCEDURE [finAnalytics].[rep842SPOD]
	@repYear int
	
AS
BEGIN
    
	drop table if exists #rep
	select
	a.Razdel
	,a.RowNum
	,a.restOut
	,[SPOD] = isnull(b.Остаток,0)
	,[amountItog] = a.restOut + isnull(b.Остаток,0)

	into #rep

	from dwh2.[finAnalytics].[rep842] a
	left join [dwh2].[finAnalytics].[repPLf842SPODFact] b on a.rowName=b.[Номер строки] and a.sub2Acc=b.СчетКод
	where a.repmonth = DATEFROMPARTS(@repYear,12,1)
	and (b.[Отчетный год] = a.repmonth or b.[Отчетный год] is null)

	merge into #rep t1
	using(
		select
		[amountItog] = sum([amountItog])
		from #rep
		where razdel = 12 and rowNum != 10
	) t2 on (t1.razdel = 12 and t1.rowNum = 10)
	when matched
	then update
		set t1.[amountItog] = t2.[amountItog];

	merge into #rep t1
	using(
		select
		[amountItog] = sum([amountItog])
		from #rep
		where razdel in (1,4,5,9,10,11,12,13,14) and rowNum = 10
	) t2 on (t1.razdel = 15 and t1.rowNum = 10)
	when matched
	then update
		set t1.[amountItog] = t2.[amountItog];

	merge into #rep t1
	using(
		select
		[amountItog] = sum([amountItog])
		from #rep
		where razdel = 19 and rowNum != 10
	) t2 on (t1.razdel = 19 and t1.rowNum = 10)
	when matched
	then update
		set t1.[amountItog] = t2.[amountItog];

	merge into #rep t1
	using(
		select
		[amountItog] = sum([amountItog])
		from #rep
		where razdel = 20 and rowNum != 10
	) t2 on (t1.razdel = 20 and t1.rowNum = 10)
	when matched
	then update
		set t1.[amountItog] = t2.[amountItog];

	merge into #rep t1
	using(
		select
		[amountItog] = sum([amountItog])
		from #rep
		where razdel in (17,19,20,21,22) and rowNum = 10
	) t2 on (t1.razdel = 23 and t1.rowNum = 10)
	when matched
	then update
		set t1.[amountItog] = t2.[amountItog];

	merge into #rep t1
	using(
		select
		[amountItog] = sum([amountItog])
		from #rep
		where razdel = 29 and rowNum != 10
	) t2 on (t1.razdel = 29 and t1.rowNum = 10)
	when matched
	then update
		set t1.[amountItog] = t2.[amountItog];

	merge into #rep t1
	using(
		select
		[amountItog] = sum([amountItog])
		from #rep
		where razdel in (24,25,29) and rowNum = 10
	) t2 on (t1.razdel = 30 and t1.rowNum = 10)
	when matched
	then update
		set t1.[amountItog] = t2.[amountItog];

	merge into #rep t1
	using(
		select
		[amountItog] = sum([amountItog])
		from #rep
		where razdel in (23,30) and rowNum = 10
	) t2 on (t1.razdel = 31 and t1.rowNum = 10)
	when matched
	then update
		set t1.[amountItog] = t2.[amountItog];

	merge into #rep t1
	using(
		select
		[amountItog] = sum(case when razdel in (23,30) then [amountItog] * -1 else [amountItog] end)
		from #rep
		where razdel in (15,23,30) and rowNum = 10
	) t2 on (t1.razdel = 32 and t1.rowNum = 10)
	when matched
	then update
		set t1.[amountItog] = t2.[amountItog];

	select
	*
	from #rep



END
