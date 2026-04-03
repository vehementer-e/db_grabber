-- exec [collection].[Create_dm_Telegram_Collection] '2025-10-01', '2025-10-03', 1
CREATE PROC [collection].[Create_dm_Telegram_Collection]
	@DateBegin date	= null,
	@DateEnd date	= null,
	@isDebug int = 0
AS
BEGIN
SET NOCOUNT ON;
SET XACT_ABORT ON

SELECT @isDebug = isnull(@isDebug, 1)
begin try

--declare @DateBegin date --= cast(dateadd(day,0, getdate()) as date)
declare @dt_begin date =dateadd(dd,1,eomonth(getdate(),-2)),
	@dt_end date = getdate()

-- если дата пришла не пустая
if (@DateBegin is not null)
begin
	Set @dt_begin = @DateBegin
end

IF (@DateEnd is not null)
begin
	Set @dt_end = @DateEnd
end

SELECT @dt_end = dateadd(DAY, 1, @dt_end)

if @isDebug = 1 BEGIN
	SELECT @dt_begin, @dt_end
END


declare @toDay  date = getdate()
drop table if exists #baket

declare @t_Baket table(
	[baket] [nvarchar](50) NULL
	,dpd_min smallint
	,dpd_max smallint
) 
insert into @t_Baket
select [baket], dpd_min, dpd_max
from (values 
	(N'0',0,0)
	,(N'1-30', 1,30)
	,(N'31-60',31,60)
	,(N'61-90', 61,90)
	,(N'91-360', 91,360)
	,(N'360+',361,32767)
) t([baket], dpd_min, dpd_max)



declare @t_reduced_balance_today table
(
	reduced_balance money
	,baket nvarchar(50)
	,[ТипПродукта] nvarchar(255)
)
insert into @t_reduced_balance_today(reduced_balance, baket, [ТипПродукта])
select 
	reduced_balance = cast(value as money)
	,baket = Стадия
    ,[ТипПродукта] = 'Инстоллмент'
from 

		(select 
		 [1-30]			= isnull(cast(t1_1_2_fact_to_day as money),0) 
		,[31-60]		= isnull(cast(t1_2_2_fact_to_day as money),0) 
		,[61-90]		= isnull(cast(t1_3_2_fact_to_day as money),0)
		,[91-360]		= isnull(cast(t1_4_2_fact_to_day as money),0)
		,[361+]			= isnull(cast(t1_5_2_fact_to_day as money),0)
	from Reports.dbo.dm_dashboard_Collection_Installment_v02_new_save_balance
	) t
	UNPIVOT   
		(Value FOR Стадия 
			IN   ([1-30], [31-60], [61-90], [91-360],[361+] )) 
			as unpvt

insert into @t_reduced_balance_today(reduced_balance, baket, [ТипПродукта])
select reduced_balance = cast(value as money)
	,baket = Стадия
    ,[ТипПродукта] = 'ПТС'
from 

		(select 
			 [1-30]		= isnull(cast(t1_1_2_fact_to_day as money),0) 
			,[31-60]	= isnull(cast(t1_2_2_fact_to_day as money),0) 
			,[61-90]	= isnull(cast(t1_3_2_fact_to_day as money),0)
			,[91-360]	= isnull(cast(t1_4_2_fact_to_day as money),0)
			,[361+]		= isnull(cast(t1_5_2_fact_to_day as money),0)
	from Reports.dbo.dm_dashboard_Collection_v02_new_save_balance
	) t
	UNPIVOT   
		(Value FOR Стадия 
			IN   ([1-30], [31-60], [61-90], [91-360],[361+] )) 
			as unpvt
if @isDebug =1
	select * from @t_reduced_balance_today
;with TempTable_CollectingPayIn as
(
SELECT 
	b.d as [ДатаОперации]
	,[ТипПродукта] = case b.[Тип Продукта] 
		when 'ПТС31' then 'ПТС'
		when 'ПТС' then 'ПТС'
		when  'Инстоллмент' then 'Инстоллмент'
		when  'PDL' then 'Инстоллмент'
	end
	,b.external_id as [ДоговорНомер]
	,[Кэш (по начислениям)] = isnull([основной долг уплачено],0) 
		+ isnull([Проценты уплачено],0) 
		+ isnull([ПениУплачено],0) 
		+ isnull([ГосПошлинаУплачено], 0)
	,[Приведенный баланс] = cd.reduced_balance
	, b.dpd_begin_day as [КоличествоПолныхДнейПросрочки]
	,b.[сумма поступлений]
from 
	dwh2.dbo.dm_CMRStatBalance AS b
	left join dwh2.riskCollection.collection_datamart cd on cd.external_id = b.external_id
		and cd.d = b.d

where 1=1
	AND 
		b.d between @dt_begin AND @dt_end
and (	
	[сумма поступлений]<>0
		OR [основной долг уплачено]<>0 
		
	)
)
select 
    r.ДатаОперации
    ,r.[ТипПродукта]
    ,r.ДоговорНомер
    ,r.[Кэш (по начислениям)]
    ,r.[Приведенный баланс]
	,r.[КоличествоПолныхДнейПросрочки]
	,r.[сумма поступлений]
	,[Бакет просрочки] = t.baket
	into #t_Collection
from 
	TempTable_CollectingPayIn AS r
		left join @t_Baket t on r.[КоличествоПолныхДнейПросрочки] between t.dpd_min and t.dpd_max


if @isDebug = 1
	select * from #t_Collection

drop table if exists #Collection_Detail_agg
;with cte as (
select  
	[ДатаОперации]
	,[ТипПродукта]
	,[Бакет просрочки] = [Бакет просрочки]
	,[Кэш (по начислениям)] = sum([Кэш (по начислениям)])
	,[Приведенный баланс] = sum([Приведенный баланс])
	,[сумма поступлений] = sum([сумма поступлений]) 
from 
	#t_Collection
where 1=1
group 
	by
		[ДатаОперации],[ТипПродукта],[Бакет просрочки]
		)
select 
	 t.[ДатаОперации]
	,t.[ТипПродукта]
	,t.[Бакет просрочки]	
	,t.[Кэш (по начислениям)] 
	,[Приведенный баланс] = iif(t.[ДатаОперации] = @today
		, rb.reduced_balance
		, t.[Приведенный баланс]
		)
	,t.[сумма поступлений] 
	
into #Collection_Detail_agg
from cte t
	left join @t_reduced_balance_today rb on rb.baket = t.[Бакет просрочки]
		and rb.[ТипПродукта] = t.[ТипПродукта]
if @isDebug = 1
begin
	select * from #Collection_Detail_agg;
end
begin tran
	
	delete FROM 
		[collection].dm_Telegram_Collection
	WHERE 
		Период BETWEEN @dt_begin AND @dt_end
		

	insert into 
		[collection].dm_Telegram_Collection
		  (
		   [Период]
		  ,[Кэш (по начислениям)] 
		  ,[Сумма поступлений]
		  ,[Бакет просрочки]
		  ,[ТипПродукта]
		  ,[Приведенный баланс]
		 
		  )
	
	select 
		   [Период] = [ДатаОперации]
		  ,[Кэш (по начислениям)]
		  ,[Сумма поступлений]
		  ,[Бакет просрочки]
		  ,[ТипПродукта]
		  ,[Приведенный баланс]
		 
	from #Collection_Detail_agg
	
	commit tran
end try
begin catch
	if @@TRANCOUNT>0 
		rollback tran
	;throw
end catch
END


--select top(1000) * from  dwh2.hub.ДоговорЗайма
-- select top(10) * from dbo.dm_Telegram_Collection_NewAlgorithm order by [Период] desc
-- select * from [collection].dm_Telegram_Collection order by [Период] desc


