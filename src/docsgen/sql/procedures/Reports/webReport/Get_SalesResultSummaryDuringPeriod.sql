

CREATE    procedure [webReport].[Get_SalesResultSummaryDuringPeriod]
	WITH EXECUTE AS 'dbo'
as
begin
	 SET NOCOUNT ON;
begin try
--declare @ProductType nvarchar(255)= 'ПТС'
	declare @startDate date , @endDate date = EOMONTH(getdate())
	set @startDate = dateadd(dd, 1, EOMONTH(getdate(), -13))
	
	drop table if exists #period
	;with cte_period as
	(
		select 	dt = @startDate
		union all
		select dt = dateadd(month,1, dt)
		from cte_period
		where EOMONTH(dt)<@endDate
	)
	
	select 
		dt =EOMONTH(dt)
	into #period
	from cte_period
	drop table if exists #Result
	create table #Result
	(
		metricName	nvarchar(255)		
		,periodMonth date
		,fact	 money
	)
	insert into #Result
	(
		metricName,
		periodMonth,
		fact
	)
	select 
		t.metricName,
		p.dt,
		t.fact
	from #period p
	left join (
	 select 
		metricName = 'Дополнительные продукты'
		,dt = eomonth(dt)
		,fact = sum(Прибыль)
	 from webReport.dm_finance_incoming_by_month
	 group by  eomonth(dt)
	) t on t.dt = p.dt
	
	union
	select 
		t.metricName,
		p.dt,
		t.fact
	from #period p
	left join (
		select 
			metricName = case IsInstallment
				when 1 then 'Инстоллмент'
				else 'ПТС'
				end
			,dt = eomonth(ДатаВыдачи)
			,fact = sum(Сумма)
		
		from dbo.dm_sales
		where ishistory = 0
		group by case IsInstallment
				when 1 then 'Инстоллмент'
				else 'ПТС'
				end
			,eomonth(ДатаВыдачи)
	) t on t.dt = p.dt

	select
		periodMonth = FORMAT(t.periodMonth, 'MMM.yyyy', 'ru-ru')
		,metricName			
		,fact				
		,sortOrder = t.periodMonth
	from #result t
	order by sortOrder
	end try
	begin catch
		;throw
	end catch
end
