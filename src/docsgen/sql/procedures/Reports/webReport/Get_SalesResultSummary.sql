
CREATE   procedure [webReport].[Get_SalesResultSummary]
	WITH EXECUTE AS 'dbo'
as
begin
	 SET NOCOUNT ON;
begin try
--declare @ProductType nvarchar(255)= 'ПТС'
	declare  @curMonthPeriodName nvarchar(255) = 'Месяц'
		,@curDayPeriodName nvarchar(255) = 'Месяц'
		,@today date = getdate()
		drop table if exists #result
	
		create table #result
		(
			metricName			nvarchar(255),
			fact				money,
			[plan]				money,
			[%completionPlan]	smallmoney,
			[RR]				money,
			[%RR]				smallmoney,

		)
		;with cte_data as 
		(
			select 
			[Сумма выдач] = cast(sd.[Сумма выдач] as money) --факт
			,[План Сумма Выдач]= cast(sd.[ПланСуммаВыдач] as money)--План
			,[% выполнения плана по займам]			
				= iif(isnull(sd.ПланСуммаВыдач,0.0)<>0, sd.[Сумма выдач]/isnull(sd.ПланСуммаВыдач,0), 0.0) 
			,[RR за текущий месяц]	=  
					isnull(sd_curMonth.[% выполнения плана по займам_вчера],0) * isnull(sd_curMonth.ПланСуммаВыдачЗаМесяц,0)
			,[%RR за текущий месяц] = isnull(sd_curMonth.[% выполнения плана по займам_вчера],0)
			,sd.ProductType
			from dbo.dm_SalesDashboard sd
				left join (
					select  
						[Сумма выдач по текущий день] = sd_month.[Сумма выдач],
						[План - c начала месяц по текущий день] = isnull(ПланСуммаВыдачПоТекущДен,0) + isnull(cur_day.ПланСуммаВыдач, 0),
						ПланСуммаВыдачЗаМесяц = sd_month.ПланСуммаВыдач,
						--Выдачи с начала по месяца по вчерашний день включительно
						sd_month.ПланСуммаВыдачПоТекущДен,
						sd_month.СуммаВыдачПоТекущДен,
						[% выполнения плана по займам_вчера] = iif(sd_month.ПланСуммаВыдачПоТекущДен<>0, 
							1.0*sd_month.СуммаВыдачПоТекущДен/sd_month.ПланСуммаВыдачПоТекущДен
							,0),
						sd_month.ProductType
					from dbo.dm_SalesDashboard sd_month 
					--Берем данные за сегодня
					left join
					(
						select 
							[Сумма выдач],
							ПланСуммаВыдач,
							ProductType
						from dbo.dm_SalesDashboard sd_cur_day
						where sd_cur_day.channel_B = 'Total'
						and sd_cur_day.period = @curDayPeriodName
					) cur_day on cur_day.ProductType = sd_month.ProductType
					where 
						sd_month.period = @curMonthPeriodName
					and sd_month.channel_B = 'Total'
					) sd_curMonth on sd_curMonth.ProductType  = sd.ProductType
		where period = @curDayPeriodName
		and sd.channel_B = 'Total'
		--and sd.ProductType = @ProductType
		)
		insert into #result(
			metricName			
			,fact				
			,[plan]				
			,[%completionPlan]	
			,[RR]	
			,[%RR]


		)
		select 
			ProductType
			, fact= [Сумма выдач]
			,[plan] = [План Сумма Выдач]
			,[%completionPlan]= [% выполнения плана по займам] 
			,[RR] = [RR за текущий месяц]
			,[%RR] = [%RR за текущий месяц]
		from cte_data

		drop table if exists #cur_month
		drop table if exists #plan
		--план
		select dt= EOMONTH(Дата),	[plan] = cast([План комиссии PNL] as money)
			into #plan
		from stg.files.contactcenterplans_buffer_stg
		where [План комиссии PNL] is not null
		and EOMONTH(Дата) = EOMONTH(@today)
	
		
			
		
		select 
			dt =dt ,
			[KP]				= pvt.КП,
			[Commision]			= pvt.Комиссии,
			[RedemptionIncome]	= pvt.[Доход с погашений]
			,Total = isnull(pvt.КП, 0) + isnull(pvt.Комиссии,0) + isnull(pvt.[Доход с погашений], 0)
		into #cur_month
		from 
		(
		select 
			additionalProducts = Тип
			,TotalSales = sum(cast(Прибыль as money))
			,dt= max(dt)
		from 
			webReport.dm_finance_incoming_by_month
		where eomonth(dt)= eomonth(@today)
		group by Тип
		) t
		pivot (
			sum(TotalSales)
			for additionalProducts in ([Доход с погашений], [Комиссии], [КП])
		) pvt
	insert into #result(
		metricName			
		,fact				
		,[plan]				
		,[%completionPlan]	
		,[RR]	
		,[%RR]
	)
		select 
		'Дополнительные продукты'
			,fact =cur_month.Total
			,p.[plan]
			,[%СompletionPlan]= iif(p.[plan]!=0, cur_month.Total / p.[plan], 0)
			,null
			,null
		from (
			select dt= @today
		) t_dt
		left join #plan p on p.dt = eomonth(t_dt.dt)
		left join #cur_month cur_month on cur_month .dt = t_dt.dt
		
		select 
			metricName			
			,fact				
			,[plan]				
			,[%completionPlan]	
			,[RR]	
			,[%RR]
			,[sortOrder] = case metricName
				when 'ПТС' then 1
				when 'Инстоллмент' then 2
				when 'Дополнительные продукты' then 3
			else 100500 end
		
		from #result
	end try
	begin catch
		;throw
	end catch
end