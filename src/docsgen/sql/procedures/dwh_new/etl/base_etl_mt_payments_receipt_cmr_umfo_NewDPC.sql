
-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2019-08-11
-- Description:	Таблица "ПОСТУПЛЕНИЕ ПЛАТЕЖЕЙ" содержит информацию о суммах учтенных в счет погашения ОД, процентов и пеней
--	exec [etl].[base_etl_mt_payments_receipt_cmr_umfo_NewDPC]			
-- =============================================
CREATE PROCEDURE [etl].[base_etl_mt_payments_receipt_cmr_umfo_NewDPC]
	-- Add the parameters for the stored procedure here
--	@ForDate datetime =cast(getdate() as date)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--	declare	@DateReport datetime2
--	set @DateReport=@ForDate

declare @DateStart datetime,
		@DateStart2 datetime,
		@DateStart2000 datetime,
		@DateStartCurr datetime,
		@DateStartCurr2000 datetime,
		@GetDate2000 datetime,
		@GetDate2000Start datetime,
		@DateStart2000month datetime,
		@DateStartmonth datetime

set @DateStart= dateadd(MONTH,datediff(MONTH,0,dateadd(month,-1,Getdate())),0);
set @DateStartmonth= dateadd(MONTH,datediff(MONTH,0,dateadd(month,-1,Getdate())),0);
set @DateStart2000month= dateadd(MONTH,datediff(MONTH,0,dateadd(month,-1,dateadd(year,2000,Getdate()))),0);
--dateadd(day,-datediff(day,cast('20170101' as datetime),getdate()),getdate())
--dateadd(month,datediff(month,0,GetDate()),-720);
--dateadd(day,datediff(day,0,GetDate()-2),0);
set	@DateStart2 = dateadd(year,2000,@DateStart);
set @DateStart2000 = dateadd(day,datediff(day,0,dateadd(year,2000,dateadd(day,-10,Getdate()))),0);
set @DateStartCurr = dateadd(day,-31,dateadd(day,datediff(day,0,Getdate()),0)); --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,Getdate())),0); --dateadd(day,-15,dateadd(day,datediff(day,0,Getdate()),0)); --
set @DateStartCurr2000=dateadd(day,-31,dateadd(day,datediff(day,0,dateadd(year,2000,Getdate())),0)); --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,dateadd(year,2000,Getdate()))),0); --dateadd(day,-15,dateadd(day,datediff(day,0,dateadd(year,2000,Getdate())),0)); --

set @GetDate2000=dateadd(year,2000,getdate());
set @GetDate2000Start = dateadd(MONTH,datediff(month,0,dateadd(month,-43,@GetDate2000)),0);--dateadd(day,-31,dateadd(day,datediff(day,0,@GetDate2000),0)); --set @GetDate2000Start=dateadd(MONTH,datediff(month,0,dateadd(month,0,@GetDate2000)),0);
--select dateadd(MONTH,datediff(month,0,dateadd(month,-43,@GetDate2000)),0)


delete from [dwh_new].[dbo].[mt_payments_receipt_cmr_umfo]
where [ДатаОперации] >= @DateStartmonth;

--create table [dwh_new].[dbo].[mt_payments_receipt_cmr_umfo]
--(
-- [ПериодУчетаЧислом] int null
--,[ПериодУчета] datetime null 
--,[ДатаОперации] datetime null 

--,[Контрагент] binary(16) null	
--,[Договор] binary(16) null
--,[ДоговорНомер] nvarchar(255) null

--,[ОДНачислено] decimal(15,2) null
--,[ОДОплачено] decimal(15,2) null

--,[ПроцентыНачислено] decimal(15,2) null
--,[ПроцентыОплачено] decimal(15,2) null

--,[ПениНачислено] decimal(15,2) null
--,[ПениОплачено] decimal(15,2) null

--,[ГосПошлинаНачислено] decimal(15,2) null
--,[ГосПошлинаОплачено] decimal(15,2) null

--,[ПереплатаНачислено] decimal(15,2) null
--,[ПереплатаОплачено] decimal(15,2) null

--,[ПроцентыГрейсПериодаНачислено] decimal(15,2) null
--,[ПроцентыГрейсПериодаОплачено] decimal(15,2) null

--,[ПениГрейсПериодаНачислено] decimal(15,2) null
--,[ПениГрейсПериодаОплачено] decimal(15,2) null

--,[ИсточникДанных] nvarchar(50) null
--,[maxDateTime] datetime null
--);

with BusinessLoan_UMFO as
(
select dd.[Ссылка]
      ,dd.[Дата]
	  ,dd.[ФинансовыйПродукт]
	  ,fp.[Наименование] as [КредитныйПродукт]
      ,dd.[СрокЗайма]
      ,dd.[СуммаЗайма]
      ,dd.[ПроцентнаяСтавка]
      ,dd.[НомерДоговора]
	  ,dd.[Контрагент] as [Контрагент_UMFO]

  from [C2-VSR-SQL04].[umfo].[dbo].[Документ_АЭ_ЗаймПредоставленный] dd  with (nolock) --y
    left join [C2-VSR-SQL04].[umfo].[dbo].[Справочник_АЭ_ФинансовыеПродукты] fp  with (nolock) --y
	on dd.[ФинансовыйПродукт]=fp.[Ссылка]
  where dd.[ПометкаУдаления]=0x00 AND dd.[Проведен]=0x01 and fp.[Наименование] like N'Бизнес%займ%'
)
,	Repayment as	--ОД, ПРОЦЕНТЫ, ПЕНИ Начислено
(
select --[Период] ,
	   distinct
	   [ВидДвижения]
	  ,[Контрагент]
      ,[Займ]
      ,[ВидНачисления]
	  ,case 
			when [ВидНачисления]=0x9B7650E549564EF611E720526D97FF6F then N'Основной долг' 
			when [ВидНачисления]=0x9B7650E549564EF611E720526D97FF70 then N'Проценты'
			--else 
	  end as [ВидНачисленияНаим]
      ,dateadd(day,datediff(day,0,[ДатаПлатежа]),0) as [ДатаПлатежа]
      ,case when [ВидДвижения]=0 then [Сумма] else 0 end as [СуммаНачислено]
      ,case when [ВидДвижения]=1 then [Сумма] else 0 end as [СуммаОплачено]
from [C2-VSR-SQL04].[umfo].[dbo].[РегистрНакопления_АЭ_ВзаиморасчетыПоГрафикуЗаймовПредоставленных]  with (nolock)
where [Займ] in (select distinct [Ссылка] from BusinessLoan_UMFO)
	  --and [ВидДвижения]=0 -- приход/начисление
--group by [ВидДвижения] ,[Контрагент] ,[Займ] ,[ВидНачисления] ,[ДатаПлатежа]
union all
select --	  [Период] ,[Регистратор_Ссылка] ,
	  distinct
	  [ВидДвижения]
	  ,[Контрагент]
      ,[Займ]
      ,[ВидНачисления]
	  ,case 
			when [ВидНачисления]=0x9B7650E549564EF611E720526D97FF6F then N'Основной долг' 
			when [ВидНачисления]=0x9B7650E549564EF611E720526D97FF70 then N'Проценты'
			when [ВидНачисления]=0x80FF00155D01C00511E79C29586167AC then N'Пени'
			--else 
	  end as [ВидНачисленияНаим]
      ,dateadd(day,datediff(day,0,[ДатаПлатежа]),0) as [ДатаПлатежа]
      ,case when [ВидДвижения]=0 then [Сумма] else 0 end as [СуммаНачислено]
      ,case when [ВидДвижения]=1 then [Сумма] else 0 end as [СуммаОплачено]
from [C2-VSR-SQL04].[umfo].[dbo].[РегистрНакопления_АЭ_ВзаиморасчетыПоШтрафамЗаймовПредоставленных]  with (nolock)
where [Займ] in (select distinct [Ссылка] from BusinessLoan_UMFO)
	  --and [ВидДвижения]=0 -- расход/оплачено
)
--select * from Repayment
,	t_resRepayment as
(
select dateadd(MONTH,datediff(MONTH,0,grp.[ДатаПлатежа]),0) as [ПериодУчета]
 --,grp.[Период]
 ,grp.[ДатаПлатежа]
 ,bl.[Дата]
 ,bl.[Ссылка]
 ,bl.[НомерДоговора]
 ,bl.[Контрагент_UMFO]
 ,grp.[Контрагент]
 --,bl.[КредитныйПродукт]
-- ,bl.[СрокЗайма]
 --,case when [ВидНачисленияНаим]=N'Основной долг' or [ВидНачисленияНаим] is null then bl.[СуммаЗайма] else 0 end as [СуммаЗайма]
 --,case
	--when bl.[СуммаЗайма]<=150000 then N'до 150'
	--when bl.[СуммаЗайма]>150000 and bl.[СуммаЗайма]<=700000 then N'151-700'
	--when bl.[СуммаЗайма]>700000 and bl.[СуммаЗайма]<=1000000 then N'701-1000'
	--when bl.[СуммаЗайма]>1000000 then N'более 1000'
	--else N'Прочее'
 --end as [Когорта_UMFO]
 ,grp.[СуммаНачислено] as [Начислено]
 ,grp.[СуммаОплачено] as [Оплачено]
 ,grp.[ВидНачисленияНаим] as [ВидНачисленияНаим]
 --,case when [ВидНачисленияНаим]=N'Основной долг' or [ВидНачисленияНаим] is null then isnull([СуммаЗайма],0) - isnull(grp.[Оплачено],0) else 0 end as [ОстатокОД]
from BusinessLoan_UMFO bl
 left join (select [Контрагент] ,[Займ] ,[ВидНачисления] ,[ВидНачисленияНаим] ,[ДатаПлатежа] ,sum([СуммаНачислено]) as [СуммаНачислено] ,sum([СуммаОплачено]) as [СуммаОплачено] 
			from Repayment 
			group by [Контрагент] ,[Займ] ,[ВидНачисления] ,[ВидНачисленияНаим] ,[ДатаПлатежа]) grp
 on bl.[Ссылка]=grp.[Займ]
where not grp.[ДатаПлатежа] is null --cast(grp.[ПериодУчета] as date)=cast(dateadd(MONTH,datediff(MONTH,0,dateadd(day,-1,Getdate())),0) as date)
 )
 --select * from t_resRepayment where [ДатаПлатежа] is null
 ,	EnteringTable as
(
select [ПериодУчета] ,[ДатаПлатежа] ,[Ссылка] ,[Контрагент] ,[НомерДоговора] as [Код] 
		--,r.[КредитныйПродукт] ,r.[СрокЗайма] ,r.[СуммаЗайма] 
		,[Начислено] ,[Оплачено] ,[ВидНачисленияНаим] 
 from t_resRepayment
)
--select * from EnteringTable
,	TempTable_CollectingPayIn as
(
SELECT 
	datediff(day,0,dateadd(year,-2000,[ПериодУчета]))+2 as [ПериодУчетаЧислом]
	,cast(dateadd(year,-2000,[ПериодУчета]) as datetime) as [ПериодУчета]
	--,et.[ПериодУчета] as [Период]
	,dateadd(year,-2000,cast(et.[ДатаПлатежа] as datetime2)) as [ДатаОперации]

	,et.[Контрагент]
	,et.[Ссылка] as [Договор]
	,et.[Код] as [ДоговорНомер]

	,case when [ВидНачисленияНаим]=N'Основной долг' then cast(et.[Начислено] as decimal(15,2)) else 0 end as [ОДНачислено]
	,case when [ВидНачисленияНаим]=N'Основной долг' then cast(et.[Оплачено] as decimal(15,2)) else 0 end as [ОДОплачено]

	,case when [ВидНачисленияНаим]=N'Проценты' then cast(et.[Начислено] as decimal(15,2)) else 0 end as [ПроцентыНачислено]
	,case when [ВидНачисленияНаим]=N'Проценты' then cast(et.[Оплачено] as decimal(15,2)) else 0 end as [ПроцентыОплачено]

	,case when [ВидНачисленияНаим]=N'Пени' then cast(et.[Начислено] as decimal(15,2)) else 0 end as [ПениНачислено]
	,case when [ВидНачисленияНаим]=N'Пени' then cast(et.[Оплачено] as decimal(15,2)) else 0 end as [ПениОплачено]

	,case when [ВидНачисленияНаим]=N'Госпошлина' then cast(et.[Начислено] as decimal(15,2)) else 0 end as [ГосПошлинаНачислено]
	,case when [ВидНачисленияНаим]=N'Госпошлина' then cast(et.[Оплачено] as decimal(15,2)) else 0 end as [ГосПошлинаОплачено]

	,0.00 as [ПереплатаНачислено]
	,0.00 as [ПереплатаОплачено]

	,0.00 as [ПроцентыГрейсПериодаНачислено]
	,0.00 as [ПроцентыГрейсПериодаОплачено]

	,0.00 as [ПениГрейсПериодаНачислено]
	,0.00 as [ПениГрейсПериодаОплачено]

	,N'УМФО' as [ИсточникДанных]

	,max(et.[ДатаПлатежа]) over(partition by et.[Ссылка] ,cast(et.[ДатаПлатежа] as date)) as [maxDateTime]

FROM EnteringTable et
where et.[ДатаПлатежа] between @DateStartCurr2000 and @GetDate2000

union all

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

from [Stg].[_1cCMR].[РегистрНакопления_РасчетыПоЗаймам] r  with (nolock) --[C1-VSR-SQL06].[cmr].[dbo].[РегистрНакопления_РасчетыПоЗаймам] r with (nolock)		--[C1-VSR-SQL05].[CMR_NIGHT01].[dbo].[РегистрНакопления_РасчетыПоЗаймам]
left join [Stg].[_1cCMR].[Справочник_Договоры] d  with (nolock) --[C1-VSR-SQL06].[cmr].[dbo].[Справочник_Договоры] d with (nolock)		--[C1-VSR-SQL05].[CMR_NIGHT01].[dbo].[Справочник_Договоры]
	on r.[Договор]=d.[Ссылка]
where r.[Период] between @DateStartCurr2000 and @GetDate2000
	--and r.[ВидДвижения]=1 
	--and r.[ОДНачисленоУплачено]>=0
	and not r.[ХозяйственнаяОперация] in (0xB81200155D4D085911E944418439AF38 -- сторно по акции
										  ,0x80E400155D64100111E7CE91B4783921 -- сторно
										  ,0x80E400155D64100111E7B30FDDAE843B -- ручная корректировка
										  ) 
)
,	res_t as
(
select [ПериодУчетаЧислом] ,[ПериодУчета] ,[ДатаОперации] ,[Контрагент] ,[Договор] ,[ДоговорНомер] 
	   ,sum([ОДНачислено]) as  [ОДНачислено] ,sum([ОДОплачено]) as [ОДОплачено]
	   ,sum([ПроцентыНачислено]) as [ПроцентыНачислено] ,sum([ПроцентыОплачено]) as [ПроцентыОплачено]
	   ,sum([ПениНачислено]) as [ПениНачислено] ,sum([ПениОплачено]) as [ПениОплачено]
	   ,sum([ГосПошлинаНачислено]) as [ГосПошлинаНачислено] ,sum([ГосПошлинаОплачено]) as [ГосПошлинаОплачено]
	   ,sum([ПереплатаНачислено]) as [ПереплатаНачислено] ,sum([ПереплатаОплачено]) as [ПереплатаОплачено]
	   ,sum([ПроцентыГрейсПериодаНачислено]) as [ПроцентыГрейсПериодаНачислено] ,sum([ПроцентыГрейсПериодаОплачено]) as [ПроцентыГрейсПериодаОплачено]
	   ,sum([ПениГрейсПериодаНачислено]) as [ПениГрейсПериодаНачислено] ,sum([ПениГрейсПериодаОплачено]) as [ПениГрейсПериодаОплачено]
	   ,[ИсточникДанных]
	   ,[maxDateTime]
	   --,aap.[КоличествоПолныхДнейПросрочки] as [КолвоПолнДнПросрВчера]
from TempTable_CollectingPayIn
where [ДатаОперации]>= @DateStartmonth --@DateStartCurr --and [КолвоПолнДнПросрВчера]<>0
group by [ПериодУчетаЧислом] ,[ПериодУчета] ,[ДатаОперации] ,[Контрагент] ,[Договор] ,[ДоговорНомер] ,[ИсточникДанных] ,[maxDateTime]
)

insert into [dwh_new].[dbo].[mt_payments_receipt_cmr_umfo] ([ПериодУчетаЧислом] ,[ПериодУчета] ,[ДатаОперации] 
																,[Контрагент] ,[Договор] ,[ДоговорНомер] 
																,[ОДНачислено] ,[ОДОплачено] 
																,[ПроцентыНачислено] ,[ПроцентыОплачено] 
																,[ПениНачислено] ,[ПениОплачено] 
																,[ГосПошлинаНачислено] ,[ГосПошлинаОплачено] 
																,[ПереплатаНачислено] ,[ПереплатаОплачено] 
																,[ПроцентыГрейсПериодаНачислено] ,[ПроцентыГрейсПериодаОплачено] 
																,[ПениГрейсПериодаНачислено] ,[ПениГрейсПериодаОплачено] 
																,[ИсточникДанных] 
																,[maxDateTime]
																,[КолвоПолнДнПросрВчера]
																)

select r.[ПериодУчетаЧислом] ,r.[ПериодУчета] ,r.[ДатаОперации] ,r.[Контрагент] ,r.[Договор] ,r.[ДоговорНомер] 
	   ,[ОДНачислено] ,[ОДОплачено]
	   ,[ПроцентыНачислено] ,[ПроцентыОплачено]
	   ,[ПениНачислено] ,[ПениОплачено]
	   ,[ГосПошлинаНачислено] ,[ГосПошлинаОплачено]
	   ,[ПереплатаНачислено] ,[ПереплатаОплачено]
	   ,[ПроцентыГрейсПериодаНачислено] ,[ПроцентыГрейсПериодаОплачено]
	   ,[ПениГрейсПериодаНачислено] ,[ПениГрейсПериодаОплачено]
	   ,[ИсточникДанных]
	   ,[maxDateTime]
	   ,isnull(aap.[КоличествоПолныхДнейПросрочки],0) as [КолвоПолнДнПросрВчера]
from res_t r
left join (select DISTINCT dateadd(year,-2000,ap.[Период]) as [Период] ,ap.[Договор] as [Договор] ,ap.[КоличествоПолныхДнейПросрочки_Макс] as [КоличествоПолныхДнейПросрочки]
		   from (select cast(dateadd(day,1,[Период]) as date) as [Период]
						,[Договор]
						,[КоличествоПолныхДнейПросрочкиУМФО]
						,max([КоличествоПолныхДнейПросрочкиУМФО]) over(partition by [Договор] ,cast([Период] as date)) as [КоличествоПолныхДнейПросрочки_Макс]
				 
				 from [Stg].[_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО] with (nolock)
				 
				 where [Период] between @DateStartCurr2000-1 and @GetDate2000) ap
			--where ap.[RANK_AP]=1
			) aap
	on r.[Договор]=aap.[Договор] and cast(r.[ДатаОперации] as date)=aap.[Период] 
where --[ДатаОперации]>= @DateStartCurr 
	(r.[ОДНачислено]+r.[ОДОплачено]+r.[ПроцентыНачислено]+r.[ПроцентыОплачено]+r.[ПениНачислено]+r.[ПениОплачено]+r.[ГосПошлинаНачислено]+r.[ГосПошлинаОплачено])<>0
	--and 
	--aap.[КоличествоПолныхДнейПросрочки]<>0

order by [ДатаОперации] desc


/* ------ '2020-02-11'
select r.[ПериодУчетаЧислом] ,r.[ПериодУчета] ,r.[ДатаОперации] ,r.[Контрагент] ,r.[Договор] ,r.[ДоговорНомер] 
	   ,[ОДНачислено] ,[ОДОплачено]
	   ,[ПроцентыНачислено] ,[ПроцентыОплачено]
	   ,[ПениНачислено] ,[ПениОплачено]
	   ,[ГосПошлинаНачислено] ,[ГосПошлинаОплачено]
	   ,[ПереплатаНачислено] ,[ПереплатаОплачено]
	   ,[ПроцентыГрейсПериодаНачислено] ,[ПроцентыГрейсПериодаОплачено]
	   ,[ПениГрейсПериодаНачислено] ,[ПениГрейсПериодаОплачено]
	   ,[ИсточникДанных]
	   ,[maxDateTime]
	   ,isnull(aap.[КоличествоПолныхДнейПросрочки],0) as [КолвоПолнДнПросрВчера]
from res_t r
left join (select DISTINCT dateadd(year,-2000,ap.[Период]) as [Период] ,ap.[Договор] as [Договор] ,ap.[КоличествоПолныхДнейПросрочки_Макс] as [КоличествоПолныхДнейПросрочки]
		   from (select cast(dateadd(day,1,[Период]) as date) as [Период],[Договор]
						,[КоличествоПолныхДнейПросрочки]
						--,min([КоличествоПолныхДнейПросрочки]) over(partition by [Договор] ,cast([Период] as date)) as [КоличествоПолныхДнейПросрочки_Мин]
						,max([КоличествоПолныхДнейПросрочки]) over(partition by [Договор] ,cast([Период] as date)) as [КоличествоПолныхДнейПросрочки_Макс]
						--,rank() over(partition by [Договор], cast([Период] as date) order by [Период] desc) as [RANK_AP]
				 from [Stg].[_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО] with (nolock) --[C1-VSR-SQL06].[cmr].[dbo].[РегистрСведений_АналитическиеПоказателиМФО] with (nolock) --[C1-VSR-SQL05].[CMR_NIGHT01].[dbo].[РегистрСведений_АналитическиеПоказателиМФО]
				 where [Период] between @DateStartCurr2000-1 and @GetDate2000) ap
			--where ap.[RANK_AP]=1
			) aap
	on r.[Договор]=aap.[Договор] and cast(r.[ДатаОперации] as date)=aap.[Период] 
where --[ДатаОперации]>= @DateStartCurr 
	(r.[ОДНачислено]+r.[ОДОплачено]+r.[ПроцентыНачислено]+r.[ПроцентыОплачено]+r.[ПениНачислено]+r.[ПениОплачено]+r.[ГосПошлинаНачислено]+r.[ГосПошлинаОплачено])<>0
	--and 
	--aap.[КоличествоПолныхДнейПросрочки]<>0

order by [ДатаОперации] desc
*/


END

