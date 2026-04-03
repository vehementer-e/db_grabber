--[webReport].[Get_SalesResultByToday] 'Инстоллмент'
CREATE       procedure [webReport].[Get_SalesResultByToday]
	@ProductType nvarchar(255)= 'ПТС'
as

--Используется в отчете
begin
SET NOCOUNT ON;
begin try

declare  @curMonthPeriodName nvarchar(255) = 'Месяц'
	,@curDayPeriodName nvarchar(255) = 'Сегодня'
drop table if exists #tResult
create table #tResult
(
	Fact money
	,[Plan] money
	,[%CompletionPlan] smallmoney
	,[RR] money
	,[%RR]  smallmoney
)

;with cte_data as 
(
	select 
	[Сумма выдач] = cast(sd.[Сумма выдач] as money) --факт
	,[План Сумма Выдач]= cast(sd.[ПланСуммаВыдач] as money)--План
	,[% выполнения плана по займам]			
		= iif(isnull(sd.ПланСуммаВыдач,0.0)<>0, sd.[Сумма выдач]/isnull(sd.ПланСуммаВыдач,0), 0.0) 
	,[RR за текущий месяц] = cast(
				isnull(sd_curMonth.[% выполнения плана по займам_вчера],0) * isnull(sd_curMonth.ПланСуммаВыдачЗаМесяц,0)
			as money)
	, [% RR за текущий месяц] = isnull(sd_curMonth.[% выполнения плана по займам_вчера],0)

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
and sd.ProductType = @ProductType
)
insert into #tResult(Fact, [Plan], [%CompletionPlan], RR, [%RR])
select 
	
	Fact= [Сумма выдач]
	,[Plan] = [План Сумма Выдач]
	,[%CompletionPlan]= [% выполнения плана по займам] 
	,[RR] = [RR за текущий месяц]
	,[%RR] =[% RR за текущий месяц]
from cte_data

if not exists(select top(1) 1 from #tResult)
begin
	insert into #tResult(Fact, [Plan], [%CompletionPlan], [RR], [%RR])
	values(0, 0, 0, 0, 0 )
end

select 
	Fact, [Plan], [%CompletionPlan], RR, [%RR]
from #tResult
end try
begin catch
	;throw
end catch
end