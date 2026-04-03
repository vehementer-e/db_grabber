 CREATE   procedure [webReport].[Get_SalesAdditionalProductsDuringPeriod]
	@weeksAgo smallint = 12
 WITH EXECUTE AS 'dbo'
 as
 begin
 SET NOCOUNT ON;
	set datefirst 1;
	declare @today date = getdate()
	declare @dtMonday date = DATEADD(d, 1 - DATEPART(w, @today), @today)
	declare @dtFrom date = dateadd(WEEK, -@weeksAgo, @dtMonday)
		,@dtTo date = getdate()
		
	begin try
	 select 
		--periodMonth  =EOMONTH(dt)
		[period] = 
		concat(
			format(DATEADD(d, 1 - DATEPART(w, dt), dt), 'dd.MM', 'ru-ru')
			, ' - ', 
			format(dateadd(dd, 6, DATEADD(d, 1 - DATEPART(w, dt), dt)), 'dd.MM', 'ru-ru')
		)
		
		,[weekNum] =  concat(year(dt), '-',   format(DATEPART(week, dt), 'D2'))
		,additionalProducts = Тип
		,TotalSales = sum(Прибыль)
	 from webReport.dm_finance_incoming_by_month t
	 where dt between @dtFrom and @dtTo
	 group by 
		--EOMONTH(dt), 
		concat(
			format(DATEADD(d, 1 - DATEPART(w, dt), dt), 'dd.MM', 'ru-ru')
			, ' - ', 
			format(dateadd(dd, 6, DATEADD(d, 1 - DATEPART(w, dt), dt)), 'dd.MM', 'ru-ru')
		), 
	concat(year(dt), '-',   format(DATEPART(week, dt), 'D2'))
	 , Тип
		
	 order by [weekNum] asc , Тип
	end try
	begin catch
		;throw
	end catch
end