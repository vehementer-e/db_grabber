--[webReport].[Get_SalesResultDuringPeriod] 'Инстоллмент'
--[webReport].[Get_SalesResultDuringPeriod] 'ПТС'
CREATE        procedure [webReport].[Get_SalesResultDuringPeriod]
	@ProductType nvarchar(255)= 'ПТС'
	,@weeksAgo smallint = 12
as
begin
	SET NOCOUNT ON;
begin try
	set datefirst 1;
	declare @today date = getdate()
	declare @dtMonday date = DATEADD(d, 1 - DATEPART(w, @today), @today)
	declare @dtFrom date = dateadd(WEEK, -@weeksAgo, @dtMonday)
		,@dtTo date = getdate()
	
;with cte_data as (	
	select 
		[Period] = 
		concat(
			format(DATEADD(d, 1 - DATEPART(w, ДатаВыдачи), ДатаВыдачи), 'dd.MM', 'ru-ru')
			, ' - ', 
			format(dateadd(dd, 6, DATEADD(d, 1 - DATEPART(w, ДатаВыдачи), ДатаВыдачи)), 'dd.MM', 'ru-ru')
		)

		,[weekNum] =  concat(year(ДатаВыдачи), '-',    format(DATEPART(week, ДатаВыдачи), 'D2'))
		,TotalSales = sum(cast(Сумма as money))
		,LoanType = case 
			when [Вид займа] in ('Параллельный') then 'Первичный'
			when [Вид займа] in ('Докредитование') then 'Повторный'
			else [Вид займа] end

	from dbo.dm_Sales
	where ishistory = 0
	and IsInstallment = case @ProductType when 'Инстоллмент' then 1 else 0 end 
	
	and ДатаВыдачи between @dtFrom and @dtTo
	group by  
	concat(
			format(DATEADD(d, 1 - DATEPART(w, ДатаВыдачи), ДатаВыдачи), 'dd.MM', 'ru-ru')
			, ' - ', 
			format(dateadd(dd, 6, DATEADD(d, 1 - DATEPART(w, ДатаВыдачи), ДатаВыдачи)), 'dd.MM', 'ru-ru')
		)

	,concat(year(ДатаВыдачи), '-',    format(DATEPART(week, ДатаВыдачи), 'D2')), 
		case 
			when [Вид займа] in ('Параллельный') then 'Первичный'
			when [Вид займа] in ('Докредитование') then 'Повторный'
			else [Вид займа] end
	
	)
	select 
		LoanType, 
		Period,
		TotalSales,
		weekNum
	
	from cte_data
	order by weekNum, LoanType
end try
begin catch
	;throw
end catch
end

