-- exec [dbo].[Create_dm_Telegram_Collection_part3_Alternative] '2024-04-01'
create PROC [dbo].[Create_dm_Telegram_Collection_part3_Alternative]
	@DateBegin date
AS
BEGIN
	SET NOCOUNT ON;

-- создаем витрину по договорам на день с целью проверки

/*
declare @ii bigint = 0

while @ii<31
begin 
 declare  @dt date = cast(dateadd(day,-@ii, getdate()) as date)
Select @ii, @dt
set @ii=@ii+1
exec [dbo].[Create_dm_Telegram_Collection_part3_Alternative] @dt
end
*/

--declare @DateBegin date --= cast(dateadd(day,0, getdate()) as date)
  declare  @dt date = cast(dateadd(day,0, getdate()) as date)

  -- если дата пришла не пустая
  if (@DateBegin is not null)
	  begin
		 Set @dt = @DateBegin
	  end
 Declare @GetDate2000 date,
	@GetDate0000 date
	set @GetDate2000= cast(dateadd(year,2000,@dt) as date);
		set @GetDate0000= cast(dateadd(year,0,@dt) as date);
	-- Временная таблица для исключения блокировки в транзакции

	select @GetDate2000
drop table if exists #t

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
	
left join [Stg].[_1cCMR].[Справочник_Договоры] d  with (nolock) --
	on r.[Договор]=d.[Ссылка]
where cast(r.[Период] as date) = @GetDate2000  --r.[Период] between '4020-04-24' and '4020-04-24'
	--and r.[ВидДвижения]=1 
	--and r.[ОДНачисленоУплачено]>=0
	and not r.[ХозяйственнаяОперация] in (0xB81200155D4D085911E944418439AF38 -- сторно по акции
										  ,0x80E400155D64100111E7CE91B4783921 -- сторно
										  ,0x80E400155D64100111E7B30FDDAE843B -- ручная корректировка
										  ) 
	--DWH-1919
	AND d.IsInstallment = 0x00
	AND d.IsSmartInstallment = 0x00
)

--select * from TempTable_CollectingPayIn

select r.* , [КоличествоПолныхДнейПросрочки]
into #t
from TempTable_CollectingPayIn r
left join (
		/*
		--var 1
		SELECT DISTINCT 
			dateadd(year,-2000,ap.[Период]) as [Период] ,
			ap.[Договор] as [Договор] ,
			ap.[КоличествоПолныхДнейПросрочки_Макс] as [КоличествоПолныхДнейПросрочки]
		from (
			SELECT cast(dateadd(day,0,[Период]) as date) as [Период]
				,[Договор]
				,[КоличествоПолныхДнейПросрочкиУМФО] as [КоличествоПолныхДнейПросрочки]
				,max([КоличествоПолныхДнейПросрочкиУМФО]) over(partition by [Договор] ,
					cast([Период] as date)) as [КоличествоПолныхДнейПросрочки_Макс]
			from [Stg].[_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО] with (nolock)
			where cast([Период] as date) = @GetDate2000 -- between dateadd(day, -1,@GetDate2000) and @GetDate2000 
		) ap -- between '4020-04-23' and '4020-04-24'
		--where ap.[RANK_AP]=1
		*/

		--var 2
		SELECT DISTINCT 
			ap.[Период],
			ap.[Договор] as [Договор],
			ap.[КоличествоПолныхДнейПросрочки_Макс] as КоличествоПолныхДнейПросрочки
		FROM (
			SELECT 
				cast(dateadd(day,0,B.[Период]) as date) as [Период]
				,[Договор] = D.Ссылка
				--,[КоличествоПолныхДнейПросрочкиУМФО] as [КоличествоПолныхДнейПросрочки]
				,[КоличествоПолныхДнейПросрочки] = B.dpd
				--,[КоличествоПолныхДнейПросрочки] = B.dpd
				--,max([КоличествоПолныхДнейПросрочкиУМФО]) over(partition by [Договор] ,cast([Период] as date)) as [КоличествоПолныхДнейПросрочки_Макс]
				,[КоличествоПолныхДнейПросрочки_Макс] = dpd_begin_day --OVER(PARTITION by B.external_id, B.Период)
			FROM dwh2.dbo.dm_CMRStatBalance AS B (NOLOCK)
				INNER JOIN Stg._1cCMR.Справочник_Договоры AS D (nolock)
					ON D.Код = B.external_id
			WHERE B.Период = @GetDate0000
		) AS ap

	) aap
	on r.[Договор]=aap.[Договор] and cast(r.[ДатаОперации] as date)=aap.[Период] 
	
where
--r.[ОДОплачено]<>0 or r.[ПроцентыОплачено]<>0 or r.[ПениОплачено]<>0
--	(r.[ОДНачислено]+r.[ОДОплачено]+r.[ПроцентыНачислено]+r.[ПроцентыОплачено]+r.[ПениНачислено]+r.[ПениОплачено]+r.[ГосПошлинаНачислено]+r.[ГосПошлинаОплачено])<>0
	(r.[ОДНачислено]<> 0 or r.[ОДОплачено]<>0 or r.[ПроцентыНачислено]<>0 or r.[ПроцентыОплачено] <>0 or  r.[ПениНачислено] <> 0 or r.[ПениОплачено] <>0 or r.[ГосПошлинаНачислено] <> 0 or r.[ГосПошлинаОплачено]<>0 or [ПереплатаНачислено]<>0 or [ПереплатаОплачено]<>0)
	--and [КоличествоПолныхДнейПросрочки] > 1
	--select * from #t where [ПереплатаНачислено]>0
delete from  [dbo].[dm_Telegram_Collection_Detail_New_Alternative] where  cast([ДатаОперации] as date) = @GetDate0000 
insert into [dbo].[dm_Telegram_Collection_Detail_New_Alternative]
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
	--into [dbo].[dm_Telegram_Collection_Detail_New_Alternative]
	from 
	#t
	where  cast([ДатаОперации] as date) = @GetDate0000 



END
