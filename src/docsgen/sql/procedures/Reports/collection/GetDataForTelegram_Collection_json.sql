


/*
--exec dbo.[GetDataForTelegram_Collection_json]  @productType = 'Инстоллмент', @period = 'Месяц'
--exec collection.[GetDataForTelegram_Collection_json]  @productType = 'ПТС', @period = 'Сегодня'
--exec collection.[GetDataForTelegram_Collection_json]  @productType = 'ПТС', @period = 'Выходные'
--exec collection.[GetDataForTelegram_Collection_json]  @productType = 'Инстоллмент', @period = 'Месяц'
Процедура создана для использование в телеграмм боте - новый написанный на NodeJs в рамках задачи - BP-1844
*/
CREATE    procedure [collection].[GetDataForTelegram_Collection_json]
	@productType nvarchar(30) = 'ПТС',
	@period nvarchar(30) = 'Сегодня'
as
begin
	set datefirst 1;
	declare @date  date = getdate()
	--select  * from dbo.tvf_GetPeriod(@date)
	declare @dateEnd date = dateadd(day,1,@date)
	--set @productType = 'ПТС'
	
begin try
	declare @dateStart date 
	declare @periodName nvarchar(255)
	
	select top(1) 
		@dateStart = dateBegin  
		,@dateEnd = dateEnd
		,@periodName = periodFormat
	from dbo.tvf_GetPeriod(@date)
	where periodName = @period
	set @dateStart = isnull(@dateStart, @date)
	set @dateEnd = isnull(@dateEnd, dateadd(day,1,@date))
	set @periodName =isnull(@periodName, format(@date , 'dd.MM.yyyy'))
	
	print @dateStart
	print @dateEnd
	print @period

	drop table if exists #result
	create table #result
	(
		name nvarchar(255),
		value nvarchar(255),
		groupName nvarchar(255),
		[groupOrder] int
	)

	if(1=1) -- @productType= 'ПТС'
	begin
		;with cte as (select

			 [groupName]= 'Кэш (по начислениям)'
			,[Без просрочки (0)]	= cast(format(SUM(iif([Бакет просрочки] = '0', [Кэш (по начислениям)], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Soft (1-30)]			= cast(format(SUM(iif([Бакет просрочки] = '1-30', [Кэш (по начислениям)], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Middle (31-60)]		= cast(format(SUM(iif([Бакет просрочки] = '31-60', [Кэш (по начислениям)], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[PreLegal (61-90)]		= cast(format(SUM(iif([Бакет просрочки] = '61-90', [Кэш (по начислениям)], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Hard (91-360)]		= cast(format(SUM(iif([Бакет просрочки] = '91-360', [Кэш (по начислениям)], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Hard (361+)]			= cast(format(SUM(iif([Бакет просрочки] = '360+', [Кэш (по начислениям)], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Итого в просрочке]	= cast(format(SUM(iif([Бакет просрочки] not in(N'0'), [Кэш (по начислениям)], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Всего]				= cast(format(SUM([Кэш (по начислениям)]), 'C0', 'ru-ru')  as nvarchar(255))
		--select *
		from [collection].dm_Telegram_Collection
		where Период between @dateStart	and @dateEnd
		--and [period] = @period
		and [ТипПродукта] = @productType
		UNION
		select 
		[groupName]= 'Приведенный баланс'
			,[Без просрочки (0)]	= cast(format(SUM(iif([Бакет просрочки] = '0', [Приведенный баланс], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Soft (1-30)]			= cast(format(SUM(iif([Бакет просрочки] = '1-30', [Приведенный баланс], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Middle (31-60)]		= cast(format(SUM(iif([Бакет просрочки] = '31-60', [Приведенный баланс], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[PreLegal (61-90)]		= cast(format(SUM(iif([Бакет просрочки] = '61-90', [Приведенный баланс], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Hard (91-360)]		= cast(format(SUM(iif([Бакет просрочки] = '91-360', [Приведенный баланс], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Hard (361+)]			= cast(format(SUM(iif([Бакет просрочки] = '360+', [Приведенный баланс], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Итого в просрочке]	= cast(format(SUM(iif([Бакет просрочки] not in(N'0'), [Приведенный баланс], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Всего]				= cast(format(SUM( [Приведенный баланс]), 'C0', 'ru-ru')  as nvarchar(255))
		--select *
		from [collection].dm_Telegram_Collection
		where Период between @dateStart	and @dateEnd
		and [ТипПродукта] = @productType
		union
		select
			 [groupName]= 'Сумма поступлений'
			,[Без просрочки (0)]	= cast(format(SUM(iif([Бакет просрочки] = '0', [Сумма поступлений], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Soft (1-30)]			= cast(format(SUM(iif([Бакет просрочки] = '1-30', [Сумма поступлений], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Middle (31-60)]		= cast(format(SUM(iif([Бакет просрочки] = '31-60', [Сумма поступлений], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[PreLegal (61-90)]		= cast(format(SUM(iif([Бакет просрочки] = '61-90', [Сумма поступлений], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Hard (91-360)]		= cast(format(SUM(iif([Бакет просрочки] = '91-360', [Сумма поступлений], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Hard (361+)]			= cast(format(SUM(iif([Бакет просрочки] = '360+', [Сумма поступлений], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Итого в просрочке]	= cast(format(SUM(iif([Бакет просрочки] not in(N'0'), [Сумма поступлений], 0)), 'C0', 'ru-ru')  as nvarchar(255))
			,[Всего]				= cast(format(SUM([Сумма поступлений]), 'C0', 'ru-ru')  as nvarchar(255))
		--select *
		from [collection].dm_Telegram_Collection
		where 
			Период between @dateStart	and @dateEnd
			and
			 [ТипПродукта] = @productType

		--and period = @period
		--and ProductType = @productType
		), cte_unpvt as (
		select  
			  upvt.name 
			, upvt.value 
			, [groupName] = case 
				when [groupName]  in ('Кэш (по начислениям)')  then 'Кэш (по начислениям)'
				when [groupName]  in ('Приведенный баланс')  then 'Приведенный баланс'
				when [groupName]  in ('Сумма поступлений')  then 'Сумма поступлений'
				end
			, [groupOrder] = case 
				when [groupName]  in ('Кэш (по начислениям)')  then 1
				when [groupName]  in ('Приведенный баланс')  then 2
				when [groupName]  in ('Сумма поступлений')  then 3
				else 100
				end
		from cte cte
			unpivot 
				(
					value for name
					IN (
						 [Без просрочки (0)]
						,[Soft (1-30)]					
						,[Middle (31-60)]			
						,[PreLegal (61-90)]			
						,[Hard (91-360)]				
						,[Hard (361+)]							
						,[Итого в просрочке]					
						,[Всего]
					)
				) upvt
		)
		insert into #result
		select * 

		from cte_unpvt
end
	
select (
select 
 
 period,
 (
	 select  distinct g.groupName,
		g.[groupOrder],
		(select  
			name 
			,value 
		from #result v
		where v.groupName = g.groupName
		for json auto
		) data
	 from #result g
	 order by g.[groupOrder]
	 for json auto
 ) info
 
from (
values(@periodName ) 
)t(period)

For json auto, WITHOUT_ARRAY_WRAPPER 
 ) json_result
end try
begin catch
	;throw
end catch
 end
