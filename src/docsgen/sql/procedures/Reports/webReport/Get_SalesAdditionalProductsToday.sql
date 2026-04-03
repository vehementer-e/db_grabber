 CREATE   procedure [webReport].[Get_SalesAdditionalProductsToday]
 WITH EXECUTE AS 'dbo'
 as
 begin
 
	declare @today date = getdate()
	SET NOCOUNT ON;
	begin try
		
		drop table if exists #today
		drop table if exists #cur_month
		drop table if exists #plan
		select dt= EOMONTH(Дата),	[plan] = cast([План комиссии PNL] as money)
			into #plan
		from stg.files.contactcenterplans_buffer_stg
		where [План комиссии PNL] is not null
		and EOMONTH(Дата) = EOMONTH(@today)
		declare @ptsToday money = (
		select sum([Сумма выдач]) from dbo.dm_SalesDashboard
		where period = 'Сегодня'
		and ProductType = 'ПТС'
		and channel_B = 'Total'
		)
		declare @ptsCurMonth money = (
				select sum([Сумма выдач]) from dbo.dm_SalesDashboard
		where period = 'Месяц'
		and ProductType = 'ПТС'
		and channel_B = 'Total'
		)
	--Результат за сегодня	
		select 
		dt
		,[KP]				= pvt.КП
		,[%KP]				= iif(@ptsToday>0, pvt.КП/@ptsToday, 0)
		,[Commision]		= pvt.Комиссии
		,[RedemptionIncome]  = pvt.[Доход с погашений]
		,total = isnull(pvt.КП, 0) + isnull(pvt.Комиссии,0) + isnull(pvt.[Доход с погашений], 0)
		into #today
		from (
		select 
			dt,
			additionalProducts = Тип
			,TotalSales = cast(Прибыль as money)
		from 
			webReport.dm_finance_incoming_by_month
		where dt= @today	
		) t
		pivot (
			sum(TotalSales)
			for additionalProducts in ([Доход с погашений], [Комиссии], [КП])
		) pvt
	--Результат за текущий месяц	
		select 
			dt				= dt,
			[KP]			= pvt.КП,
			[%KP]			= iif(@ptsCurMonth>0, pvt.КП/@ptsCurMonth, 0),
			[Commision]		= pvt.Комиссии,
			[RedemptionIncome] = pvt.[Доход с погашений]
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
		--Итог
		select 
		 today  = @today
		 ,p.[plan]
		 ,[todayCommision] = td.Commision
		 ,[todayKP] = td.KP
		 ,[today%KP] = td.[%KP]
		 ,[todayRedemptionIncome] = td.RedemptionIncome
		 ,todayTotal = td.total
		 ,[curMonthCommision] = cur_month.Commision
		 ,[curMonthKP] = cur_month.KP
		 ,[curMonth%KP] = cur_month.[%KP]
		 ,[curMonthRedemptionIncome] = cur_month.RedemptionIncome
		 ,curMonthTotal =cur_month.Total
		 ,[%СompletionPlan]= iif(p.[plan]!=0, cur_month.Total / p.[plan], 0)
		from (
			select dt= @today
				
		) t_dt
		left join #plan p on p.dt = eomonth(t_dt.dt)
		left join #today td on td.dt = t_dt.dt
		left join #cur_month cur_month on cur_month .dt = t_dt.dt
		

	end try
	begin catch
		;throw
	end catch
end
