-- exec [dbo].[Create_dm_Telegram_Collection_part3] '2020-04-22'
create PROC [dbo].[Create_dm_Telegram_Collection_part3]
	@DateBegin date,
	@DateEnd date,
	@isDebug int = 0
AS
BEGIN
SET NOCOUNT ON;
SET XACT_ABORT ON

SELECT @isDebug = isnull(@isDebug, 0)

-- создаем витрину по договорам на день с целью проверки

/*
declare @ii bigint = 0

while @ii<3
begin 
 declare  @dt date = cast(dateadd(day,-@ii, getdate()) as date)
Select @ii, @dt
set @ii=@ii+1
exec [dbo].[Create_dm_Telegram_Collection_part3] @dt
end
*/

--declare @DateBegin date --= cast(dateadd(day,0, getdate()) as date)
declare @dt_begin date = cast(dateadd(day,0, getdate()) as date),
	@dt_end date = cast(dateadd(day,0, getdate()) as date)

-- если дата пришла не пустая
if (@DateBegin is not null)
begin
	Set @dt_begin = @DateBegin
end

IF (@DateEnd is not null)
begin
	Set @dt_end = @DateEnd
end

--Declare @GetDate2000 date, @GetDate0000 date
--set @GetDate2000 = cast(dateadd(year,2000,@dt) as date);
--set @GetDate0000 = cast(dateadd(year,0,@dt) as date);

declare @dt_begin_2000 date, @dt_end_2000 date
set @dt_begin_2000 = cast(dateadd(year,2000,@dt_begin) as date);
set @dt_end_2000 =	 cast(dateadd(year,2000,@dt_end) as date);

SELECT @dt_end = dateadd(DAY, 1, @dt_end)
SELECT @dt_end_2000 = dateadd(DAY, 1, @dt_end_2000)

if @isDebug = 1 BEGIN
	SELECT @dt_begin, @dt_end
	SELECT @dt_begin_2000, @dt_end_2000
END

-- Временная таблица для исключения блокировки в транзакции

--select @GetDate2000


drop table if exists #t_Collection

if object_id('tempdb.dbo.#baket') is not null drop table #baket

CREATE TABLE #Baket(
	[baket] [nvarchar](50) NULL
) 


 insert into #baket select N'0'
 insert into #baket select N'1-3'
 insert into #baket select N'4-30'
 insert into #baket select N'31-60'
 insert into #baket select N'61-90'
 insert into #baket select N'91-360'
 insert into #baket select N'360+';

with TempTable_CollectingPayIn as
(
SELECT 
	datediff(day,0,dateadd(year,-2000,dateadd(MONTH,datediff(MONTH,0,r.[Период]),0)))+2 as [ПериодУчетаЧислом]	
	,cast(dateadd(year,-2000,dateadd(MONTH,datediff(MONTH,0,r.[Период]),0)) as datetime) as [ПериодУчета]
	,dateadd(year,-2000,dateadd(day,datediff(day,0,cast(r.[Период] as datetime2)),0)) as [ДатаОперации]
	
	,d.[Клиент] as [Контрагент]	
	,d.[Ссылка] as [Договор]
	,d.[Код] as [ДоговорНомер]

	,case when r.[ВидДвижения]=0 then cast(r.[ОДНачисленоУплачено] as decimal(15,2)) else 0 end as [ОДНачислено]
	,case when r.[ВидДвижения]=1 then cast(r.[ОДНачисленоУплачено] as decimal(15,2)) else 0 end as [ОДОплачено]

	,case when r.[ВидДвижения]=0 then cast(r.[ПроцентыНачисленоУплачено] as decimal(15,2)) else 0 end as [ПроцентыНачислено]
	,case when r.[ВидДвижения]=1 then cast(r.[ПроцентыНачисленоУплачено] as decimal(15,2)) else 0 end as [ПроцентыОплачено]

	,case when r.[ВидДвижения]=0 then cast(r.[ПениНачисленоУплачено] as decimal(15,2)) else 0 end as [ПениНачислено]
	,case when r.[ВидДвижения]=1 then cast(r.[ПениНачисленоУплачено] as decimal(15,2)) else 0 end as [ПениОплачено]

	,case when r.[ВидДвижения]=0 then cast(r.[ГосПошлина] as decimal(15,2)) else 0 end as [ГосПошлинаНачислено]
	,case when r.[ВидДвижения]=1 then cast(r.[ГосПошлина] as decimal(15,2)) else 0 end as [ГосПошлинаОплачено]

	,case when r.[ВидДвижения]=0 then cast(r.[Переплата] as decimal(15,2)) else 0 end as [ПереплатаНачислено]
	,case when r.[ВидДвижения]=1 then cast(r.[Переплата] as decimal(15,2)) else 0 end as [ПереплатаОплачено]

	,case when r.[ВидДвижения]=0 then cast(r.[ПроцентыГрейсПериода] as decimal(15,2)) else 0 end as [ПроцентыГрейсПериодаНачислено]
	,case when r.[ВидДвижения]=1 then cast(r.[ПроцентыГрейсПериода] as decimal(15,2)) else 0 end as [ПроцентыГрейсПериодаОплачено]

	,case when r.[ВидДвижения]=0 then cast(r.[ПениГрейсПериода] as decimal(15,2)) else 0 end as [ПениГрейсПериодаНачислено]
	,case when r.[ВидДвижения]=1 then cast(r.[ПениГрейсПериода] as decimal(15,2)) else 0 end as [ПениГрейсПериодаОплачено]


	,N'ЦМР' as [ИсточникДанных]

	,max(r.[Период]) over(partition by d.[Ссылка] ,cast(r.[Период] as date)) as [maxDateTime]

from [Stg].[_1cCMR].[РегистрНакопления_РасчетыПоЗаймам] r  with (nolock) --
	LEFT join [Stg].[_1cCMR].[Справочник_Договоры] d  with (nolock) --
		ON r.[Договор]=d.[Ссылка]
where 1=1
	--AND cast(r.[Период] as date) = @GetDate2000  --r.[Период] between '4020-04-24' and '4020-04-24'
	AND r.[Период] between @dt_begin_2000 AND @dt_end_2000
	--and r.[ВидДвижения]=1 
	--and r.[ОДНачисленоУплачено]>=0
	and not r.[ХозяйственнаяОперация] in (0xB81200155D4D085911E944418439AF38 -- сторно по акции
										  ,0x80E400155D64100111E7CE91B4783921 -- сторно
										  ,0x80E400155D64100111E7B30FDDAE843B -- ручная корректировка
										  ) 
)
--select * from TempTable_CollectingPayIn
select 
	r.ПериодУчетаЧислом,
    r.ПериодУчета,
    r.ДатаОперации,
    r.Контрагент,
    r.Договор,
    r.ДоговорНомер,
    r.ОДНачислено,
    r.ОДОплачено,
    r.ПроцентыНачислено,
    r.ПроцентыОплачено,
    r.ПениНачислено,
    r.ПениОплачено,
    r.ГосПошлинаНачислено,
    r.ГосПошлинаОплачено,
    r.ПереплатаНачислено,
    r.ПереплатаОплачено,
    r.ПроцентыГрейсПериодаНачислено,
    r.ПроцентыГрейсПериодаОплачено,
    r.ПениГрейсПериодаНачислено,
    r.ПениГрейсПериодаОплачено,
    r.ИсточникДанных,
    r.maxDateTime,
	aap.[КоличествоПолныхДнейПросрочки]
into #t_Collection
from TempTable_CollectingPayIn AS r
	--var 1
	LEFT JOIN (
		--var 1
		/*
		SELECT DISTINCT 
			dateadd(year,-2000,ap.[Период]) as [Период],
			ap.[Договор] as [Договор],
			ap.[КоличествоПолныхДнейПросрочки_Макс] as [КоличествоПолныхДнейПросрочки]
		FROM (
			SELECT 
				cast(dateadd(day,1,[Период]) as date) as [Период]
				,[Договор]
				,[КоличествоПолныхДнейПросрочкиУМФО] as [КоличествоПолныхДнейПросрочки]
				,max([КоличествоПолныхДнейПросрочкиУМФО]) over(partition by [Договор] ,cast([Период] as date)) as [КоличествоПолныхДнейПросрочки_Макс]
			FROM [Stg].[_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО] with (nolock)
			--WHERE cast([Период] as date) between dateadd(day, -1,@GetDate2000) and @GetDate2000
			WHERE cast([Период] as date) between dateadd(day, -1, @dt_begin_2000) AND dateadd(day, -1, @dt_end_2000)
		) AS ap -- between '4020-04-23' and '4020-04-24'
		--where ap.[RANK_AP]=1
		*/
		--var 2
		SELECT DISTINCT 
			ap.[Период],
			ap.[Договор] as [Договор],
			ap.[КоличествоПолныхДнейПросрочки_Макс] as [КоличествоПолныхДнейПросрочки]
		FROM (
			SELECT 
				cast(dateadd(day,1,B.[Период]) as date) as [Период]
				,[Договор] = D.Ссылка
				--,[КоличествоПолныхДнейПросрочкиУМФО] as [КоличествоПолныхДнейПросрочки]
				,[КоличествоПолныхДнейПросрочки] = B.dpd
				--,max([КоличествоПолныхДнейПросрочкиУМФО]) over(partition by [Договор] ,cast([Период] as date)) as [КоличествоПолныхДнейПросрочки_Макс]
				,[КоличествоПолныхДнейПросрочки_Макс] = B.dpd_begin_day -- max(B.dpd) OVER(PARTITION by B.external_id, B.Период)
			FROM dwh2.dbo.dm_CMRStatBalance AS B (NOLOCK)
				INNER JOIN Stg._1cCMR.Справочник_Договоры AS D (nolock)
					ON D.Код = B.external_id
			WHERE B.Период between dateadd(day, -1, @dt_begin) AND dateadd(day, -1, @dt_end)
		) AS ap
	) AS aap
	ON r.[Договор]=aap.[Договор] 
	AND cast(r.[ДатаОперации] as date) = aap.[Период] 
where
--r.[ОДОплачено]<>0 or r.[ПроцентыОплачено]<>0 or r.[ПениОплачено]<>0
--	(r.[ОДНачислено]+r.[ОДОплачено]+r.[ПроцентыНачислено]+r.[ПроцентыОплачено]+r.[ПениНачислено]+r.[ПениОплачено]+r.[ГосПошлинаНачислено]+r.[ГосПошлинаОплачено])<>0
	(
		   r.[ОДНачислено]<> 0 
		OR r.[ОДОплачено]<>0 
		OR r.[ПроцентыНачислено]<>0 
		OR r.[ПроцентыОплачено] <>0 
		OR r.[ПениНачислено] <> 0 
		OR r.[ПениОплачено] <>0 
		OR r.[ГосПошлинаНачислено] <> 0 
		OR r.[ГосПошлинаОплачено]<>0 
		OR r.[ПереплатаНачислено]<>0 
		OR r.[ПереплатаОплачено]<>0
	)
	--and [КоличествоПолныхДнейПросрочки] > 1
	--select * from #t_Collection where [ПереплатаНачислено]>0


DELETE 
FROM dbo.dm_Telegram_Collection_Detail_New
--WHERE  cast([ДатаОперации] as date) = @GetDate0000 
WHERE cast([ДатаОперации] as date) BETWEEN @dt_begin AND @dt_end


insert into dbo.dm_Telegram_Collection_Detail_New
select * 						
	,case
	when [КоличествоПолныхДнейПросрочки]=0 or [КоличествоПолныхДнейПросрочки] is null  then N'0'
	else
		case
			when [КоличествоПолныхДнейПросрочки]>0 and [КоличествоПолныхДнейПросрочки]<4 then N'1-3'
			when [КоличествоПолныхДнейПросрочки]>3 and [КоличествоПолныхДнейПросрочки]<31 then N'4-30'
			when [КоличествоПолныхДнейПросрочки]>30 and [КоличествоПолныхДнейПросрочки]<61 then N'31-60'
			when [КоличествоПолныхДнейПросрочки]>60 and [КоличествоПолныхДнейПросрочки]<91 then N'61-90'
			when [КоличествоПолныхДнейПросрочки]>90 and [КоличествоПолныхДнейПросрочки]<361 then N'91-360'
			when [КоличествоПолныхДнейПросрочки]>360 then N'360+'
		end
	end as Бакет3
	--into [dbo].[dm_Telegram_Collection_Detail_New]
	from 
	#t_Collection
	--where  cast([ДатаОперации] as date) = @GetDate0000 
	where cast([ДатаОперации] as date) BETWEEN @dt_begin AND @dt_end

delete 
FROM dbo.dm_Telegram_Collection_Detail_New2
--WHERE cast([ДатаОперации] as date) = @GetDate0000 
WHERE cast([ДатаОперации] as date) BETWEEN @dt_begin AND @dt_end 

insert into dbo.dm_Telegram_Collection_Detail_New2
select  
		  [ДатаОперации]
		  ,ДоговорНомер

     -- ,sum([ОДНачислено]) [ОДНачислено]
      ,sum([ОДОплачено]) [ОДОплачено]

      ,sum([ПроцентыОплачено]) [ПроцентыОплачено]

      ,sum([ПениОплачено])  [ПениОплачено]

      ,sum([ГосПошлинаОплачено]) [ГосПошлинаОплачено]
  
      ,sum([ПереплатаОплачено]) [ПереплатаОплачено]
     
      ,sum([ПроцентыГрейсПериодаОплачено]) [ПроцентыГрейсПериодаОплачено]
   
      ,sum([ПениГрейсПериодаОплачено]) [ПениГрейсПериодаОплачено]
      --,[ИсточникДанных]
      --,[maxDateTime]
      --,[КоличествоПолныхДнейПросрочки]
      ,[Бакет3]
	  --into  [dbo].[dm_Telegram_Collection_Detail_New2]
	  from dbo.dm_Telegram_Collection_Detail_New
	  --where  cast([ДатаОперации] as date) = @GetDate0000  
	  where cast([ДатаОперации] as date) BETWEEN @dt_begin AND @dt_end
	  group by  [ДатаОперации],ДоговорНомер,[Бакет3]

	  delete 
	  FROM dbo.dm_Telegram_Collection_NewAlgorithm
	  --WHERE Период = @GetDate0000 
	  WHERE Период BETWEEN @dt_begin AND @dt_end

	  insert into dbo.dm_Telegram_Collection_NewAlgorithm
	  (
	   [Период]
      ,[Платежи по ОД]
      ,[Проценты]
      ,[Пени]
      ,[Сумма поступлений]
      ,[Бакет просрочки]
	  )
	  select 
		--cast(@GetDate0000 as date) 'Период', 
		[Период] 'Период', 
		sum(isnull([Платежи по ОД],0)) 'Платежи по ОД', 
		sum(isnull([Проценты],0)) [Проценты], 
		sum(isnull([Пени],0)) [Пени], 
		sum(isnull([Сумма поступлений],0)) [Сумма поступлений], 
		bkt.baket "Бакет просрочки"
	  FROM (
			SELECT
				cast([ДатаОперации] as date) [Период]
				,[ОДОплачено] [Платежи по ОД]
				,[ПроцентыОплачено] [Проценты]
				,[ПениОплачено] [Пени]
				,isnull([ОДОплачено],0) + isnull([ПроцентыОплачено],0) + isnull([ПениОплачено],0) [Сумма поступлений]
				,[Бакет3] [Бакет просрочки]
			FROM dbo.dm_Telegram_Collection_Detail_New2
			where (
					[ОДОплачено]<>0 
				OR [ПроцентыОплачено]<>0 
				OR [ПениОплачено] <>0
			)
			--and cast([ДатаОперации] as date) = @GetDate0000
			and cast([ДатаОперации] as date) BETWEEN @dt_begin AND @dt_end
		) AS sq
		right join #Baket  bkt on bkt.baket = sq.[Бакет просрочки]
       group by [Период], bkt.baket

END
