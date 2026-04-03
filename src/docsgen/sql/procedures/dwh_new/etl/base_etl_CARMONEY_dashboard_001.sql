

-- exec [etl].[base_etl_mt_requests_transition_mfo]

CREATE PROCEDURE [etl].[base_etl_CARMONEY_dashboard_001]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--if object_id('tempdb.dbo.#tmp') is not null drop table #tmp;

--declare @DateStart datetime,
--		@DateStart2 datetime,
--		@DateStart2000 datetime,
--		@DateStartCurr datetime,
--		@DateStartCurr2000 datetime
--set @DateStart=dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,Getdate())),0)
----dateadd(day,-datediff(day,cast('20170101' as datetime),getdate()),getdate())
----dateadd(month,datediff(month,0,GetDate()),-720);
----dateadd(day,datediff(day,0,GetDate()-2),0);
--set	@DateStart2=dateadd(year,2000,@DateStart);
--set @DateStart2000= dateadd(day,datediff(day,0,dateadd(year,2000,dateadd(day,-10,Getdate()))),0);
--set @DateStartCurr=dateadd(day,-2,dateadd(day,datediff(day,0,Getdate()),0));	-- Переменная для начала (дня) оперативного обновления данных по периоду статуса за последние 14 дней для поля с текущей датой
--set @DateStartCurr2000=dateadd(day,-2,dateadd(day,datediff(day,0,dateadd(year,2000,Getdate())),0));	-- Переменная для начала (дня) оперативного обновления данных по периоду статуса за последние 14 дней для поля с текущей датой + 2000

--if not isnull((select [Значение] from [dwh_new].[dbo].[CARMONEY_dashboard_001v01] where cast([ДатаУчета] as date)=cast(dateadd(day,1,getdate()) as date)),0)=0


-----------------------------------------------------------
----------- Загрузка информации из отчета KPI

select distinct * into #report_kpi from reports.dbo.report_kpi
select  *  from reports.dbo.report_kpi

if OBJECT_ID('tempdb.dbo.#report_kpi2') is not null drop table #report_kpi2
select [ПериодУчета] ,[ДатаЧислом] ,[НаименованиеЛиста] ,sum([Сумма]) as [Сумма] ,sum([Колво]) as [Колво] 
into #report_kpi2 
from #report_kpi 
where [НаименованиеЛиста] in (N'KPI кредитный портфель' , N'KPI кредитный портфель_УМФО' ,N'Платежи по ОД' ,N'Платежи по процентам' ,N'Платежи по пеням')
group by [ПериодУчета] ,[ДатаЧислом] ,[НаименованиеЛиста]

union all
select [ПериодУчета] ,[ДатаЧислом] ,[НаименованиеЛиста] ,sum([Сумма]) as [Сумма] ,sum([Колво]) as [Колво] 
from #report_kpi 
where [НаименованиеЛиста] in (N'ИТОГ_2_ЗАЯВКИ_по_каналам' , N'ИТОГ_2_ЗАЙМЫ_по_каналам')
group by [ПериодУчета] ,[ДатаЧислом] ,[НаименованиеЛиста]


insert into [dwh_new].[dbo].[CARMONEY_dashboard_001v01] ([cdate] ,[Период] ,[Периодичность] ,[Показатель] ,[ПланФакт] ,[Значение] ,[ДатаУчета])
--select * from [dwh_new].[dbo].[CARMONEY_dashboard_001v01] where [Показатель]=N'KPI кредитный портфель' and [Период]='2019-11-01'

select getdate() as [cdate] ,cast(cast([ПериодУчета]-2 as datetime) as date) as [Период] 
		,N'Месяц' as [Периодичность] ,N'KPI кредитный портфель' [Показатель] ,N'Факт' as [ПланФакт] 
		,sum([Сумма]) as [Значение] ,cast(cast([ДатаЧислом]-2 as datetime) as date) as [ДатаУчета]
from #report_kpi2
where [НаименованиеЛиста] in (N'KPI кредитный портфель' , N'KPI кредитный портфель_УМФО')
group by cast(cast([ПериодУчета]-2 as datetime) as date) ,cast(cast([ДатаЧислом]-2 as datetime) as date)

union all
select getdate() as [cdate] ,cast(cast([ПериодУчета]-2 as datetime) as date) as [Период] 
		,N'Месяц' as [Периодичность] ,N'Поступление процентов и пени' [Показатель] ,N'Факт' as [ПланФакт] 
		,sum([Сумма]) as [Значение] ,cast(cast([ДатаЧислом]-2 as datetime) as date) as [ДатаУчета]
from #report_kpi2
where [НаименованиеЛиста] in (N'Платежи по процентам' ,N'Платежи по пеням')
group by cast(cast([ПериодУчета]-2 as datetime) as date) ,cast(cast([ДатаЧислом]-2 as datetime) as date)

union all
select getdate() as [cdate] ,cast(cast([ПериодУчета]-2 as datetime) as date) as [Период] 
		,N'Месяц' as [Периодичность] ,N'Погашение ОД' [Показатель] ,N'Факт' as [ПланФакт] 
		,sum([Сумма]) as [Значение] ,cast(cast([ДатаЧислом]-2 as datetime) as date) as [ДатаУчета]
from #report_kpi2
where [НаименованиеЛиста] in (N'Платежи по ОД')
group by cast(cast([ПериодУчета]-2 as datetime) as date) ,cast(cast([ДатаЧислом]-2 as datetime) as date)

union all
select getdate() as [cdate] ,cast(cast([ПериодУчета]-2 as datetime) as date) as [Период] 
		,N'Месяц' as [Периодичность] ,N'Заявки шт' [Показатель] ,N'Факт' as [ПланФакт] 
		,sum([Колво]) as [Значение] ,cast(cast([ДатаЧислом]-2 as datetime) as date) as [ДатаУчета]
from #report_kpi2
where [НаименованиеЛиста] in (N'ИТОГ_2_ЗАЯВКИ_по_каналам')
group by cast(cast([ПериодУчета]-2 as datetime) as date) ,cast(cast([ДатаЧислом]-2 as datetime) as date)

union all
select getdate() as [cdate] ,cast(cast([ПериодУчета]-2 as datetime) as date) as [Период] 
		,N'Месяц' as [Периодичность] ,N'Займы шт' [Показатель] ,N'Факт' as [ПланФакт] 
		,sum([Колво]) as [Значение] ,cast(cast([ДатаЧислом]-2 as datetime) as date) as [ДатаУчета]
from #report_kpi2
where [НаименованиеЛиста] in (N'ИТОГ_2_ЗАЙМЫ_по_каналам')
group by cast(cast([ПериодУчета]-2 as datetime) as date) ,cast(cast([ДатаЧислом]-2 as datetime) as date)

union all
select getdate() as [cdate] ,cast(cast([ПериодУчета]-2 as datetime) as date) as [Период] 
		,N'Месяц' as [Периодичность] ,N'Займы руб' [Показатель] ,N'Факт' as [ПланФакт] 
		,sum([Сумма]) as [Значение] ,cast(cast([ДатаЧислом]-2 as datetime) as date) as [ДатаУчета]
from #report_kpi2
where [НаименованиеЛиста] in (N'ИТОГ_2_ЗАЙМЫ_по_каналам')
group by cast(cast([ПериодУчета]-2 as datetime) as date) ,cast(cast([ДатаЧислом]-2 as datetime) as date)



--SELECT [t1_Колво] as [КолвоЗаймов_Тек]
--	  ,[t1_СуммаЗаявки] as [СуммаЗаймов_Тек] 

--      --,[t1_СрЧекТек] as [СрЧекТек] ,[t1_СрЧекДеньВДень] as []
--	  ,[t3_Колво1_0] as [КолвоЗаявкиОдобрено_Тек] --,[t3_СуммаЗаявки1_0] as [] ,[t3_Колво2_0] as [] ,[t3_СуммаЗаявки2_0] as []
--	  --,[t4_Таблица] as [] ,[t4_Колво_Лид_1] as [] ,[t4_Колво_Лид_2] as [] ,[t4_Колво_Лид_3] as [] ,[t4_Колво_ВРаботу] as [] ,[t4_Колво_Дозвон] as []
--	  ,[t4_Колво_Заявка] as [КолвоЗаявок-Тек]	-- ,[t4_Колво_Заявка_1] as [] ,[t4_Колво_Заявка_2] as [] ,[t4_Колво_Заявка_3] as [] ,[t4_Колво_Заявка_4] as [] ,[t4_Колво_Заявка_5] as []
 
--  FROM [Reports].[dbo].[dm_dashboard_ConmmonTable]

-----------------------------------------------------------
----------- Загрузка оперативной информации по выдачам из ДАШБОРДА 001 (КонтактЦентр)

if OBJECT_ID('tempdb.dbo.#dm_dashboard_CallCentr_actual') is not null drop table #dm_dashboard_CallCentr_actual

select distinct * into #dm_dashboard_CallCentr_actual from reports.dbo.dm_dashboard_CallCentr_actual
--select * from #dm_dashboard_CallCentr_actual

insert into [dwh_new].[dbo].[CARMONEY_dashboard_001v01] ([cdate] ,[Период] ,[Периодичность] ,[Показатель] ,[ПланФакт] ,[Значение] ,[ДатаУчета])
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[ПериодУчетаДн]),0) as date) as [Период] 
		,N'День' as [Периодичность] ,N'Займы план руб Месяц' [Показатель] ,N'План' as [ПланФакт] 
		,([ОстДоЦели]+[СуммаФактМес]) as [Значение] ,[ПериодУчетаДн] as [ДатаУчета]
from #dm_dashboard_CallCentr_actual

union all
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[ПериодУчетаДн]),0) as date) as [Период] 
		,N'День' as [Периодичность] ,N'Займы факт руб Месяц' [Показатель] ,N'Факт' as [ПланФакт] 
		,[СуммаФактМес] as [Значение] ,[ПериодУчетаДн] as [ДатаУчета]
from #dm_dashboard_CallCentr_actual

union all
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[ПериодУчетаДн]),0) as date) as [Период] 
		,N'День' as [Периодичность] ,N'Займы факт колво Месяц' [Показатель] ,N'Факт' as [ПланФакт] 
		,[Ф_КолвоЗаймовМес] as [Значение] ,[ПериодУчетаДн] as [ДатаУчета]
from #dm_dashboard_CallCentr_actual
union all
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[ПериодУчетаДн]),0) as date) as [Период] 
		,N'День' as [Периодичность] ,N'Ср.взвешенная ставка проц' [Показатель] ,N'Факт' as [ПланФакт] 
		,[СрВзвешСтавкаМес] as [Значение] ,[ПериодУчетаДн] as [ДатаУчета]
from #dm_dashboard_CallCentr_actual


----------------- Плюс текущего дня кол-во заявок и займов из ДАШБОРДА 002 (КонтактЦентр)

union all
select getdate() as [cdate] ,cast([ДатаОбновления] as date) as [Период] 
		,N'День' as [Периодичность] ,N'Заявки шт Одобрено День' [Показатель] ,N'Факт' as [ПланФакт] 
		,[t3_Колво1_0] as [Значение] ,cast([ДатаОбновления] as date) as [ДатаУчета]
from [Reports].[dbo].[dm_dashboard_ConmmonTable]

union all
select getdate() as [cdate] ,cast([ДатаОбновления] as date) as [Период] 
		,N'День' as [Периодичность] ,N'Заявки колво День' [Показатель] ,N'Факт' as [ПланФакт] 
		,[t4_Колво_Заявка] as [Значение] ,cast([ДатаОбновления] as date) as [ДатаУчета]
from [Reports].[dbo].[dm_dashboard_ConmmonTable]


union all
select getdate() as [cdate] ,cast([ДатаОбновления] as date) as [Период] 
		,N'День' as [Периодичность] ,N'Займы шт День' [Показатель] ,N'Факт' as [ПланФакт] 
		,[t1_Колво] as [Значение] ,cast([ДатаОбновления] as date) as [ДатаУчета]
from [Reports].[dbo].[dm_dashboard_ConmmonTable]

union all
select getdate() as [cdate] ,cast([ДатаОбновления] as date) as [Период] 
		,N'День' as [Периодичность] ,N'Займы руб День' [Показатель] ,N'Факт' as [ПланФакт] 
		,[t1_СуммаЗаявки] as [Значение] ,cast([ДатаОбновления] as date) as [ДатаУчета]
from [Reports].[dbo].[dm_dashboard_ConmmonTable]


-----------------------------------------------------------
----------- Загрузка информации от финансистов

if OBJECT_ID('tempdb.dbo.#dwh_new_dbo_dashboard_kpi') is not null drop table #dwh_new_dbo_dashboard_kpi

select [ru_name] ,[type] ,[value] ,[date] ,[period]
	   ,rank() over(partition by [ru_name] ,[type] order by [period] desc, [date] desc) as [rank_t] 
into #dwh_new_dbo_dashboard_kpi 

from [dwh_new].[dbo].[dashboard_kpi]


insert into [dwh_new].[dbo].[CARMONEY_dashboard_001v01] ([cdate] ,[Период] ,[Периодичность] ,[Показатель] ,[ПланФакт] ,[Значение] ,[ДатаУчета])


select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[date]),0) as date) as [Период] 
	   ,N'Год' as [Периодичность] ,[ru_name] as [Показатель]
	   ,case when [type]=N'fact' then N'Факт' when [type]=N'plan' then N'План' else [type] end [ПланФакт] 
	   ,[value] as [Значение] ,cast(getdate() as date) as [ДатаУчета] 
--select *
from #dwh_new_dbo_dashboard_kpi where [rank_t]=1 and not [ru_name] in (N'FTE')

union all
---- Добавляем показаатель FTE из другой таблицы
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,f.[Дата]),0) as date) as [Период] 
	   ,N'Год' as [Периодичность] ,[Показатель]
	   ,[ПланФакт] 
	   ,[Значение] ,cast(getdate() as date) as [ДатаУчета] 

from (select [Дата] ,[Indicator] as [Показатель] ,[Факт/План] as [ПланФакт] ,[Value] as [Значение] ,[created] ,rank() over(partition by [Indicator] ,[Факт/План] order by [Дата] desc) as [rank_t]
		from [Stg].[files].[FTE_plan_fact] with (nolock)) f
where f.[rank_t]=1



--end

/*
-- 2019-12-04
if OBJECT_ID('tempdb.dbo.#report_kpi') is not null drop table #report_kpi

select distinct *
into #report_kpi 
from reports.dbo.report_kpi
--where [НаименованиеЛиста] in (N'KPI кредитный портфель' , N'KPI кредитный портфель_УМФО' ,N'Платежи по ОД' ,N'Платежи по процентам' ,N'Платежи по пеням')
--group by [ПериодУчета] ,[НаименованиеЛиста]
--select * from #report_kpi

if OBJECT_ID('tempdb.dbo.#report_kpi2') is not null drop table #report_kpi2
select [ПериодУчета] ,[ДатаЧислом] ,[НаименованиеЛиста] ,sum([Сумма]) as [Сумма] ,sum([Колво]) as [Колво] 
into #report_kpi2 
from #report_kpi 
where [НаименованиеЛиста] in (N'KPI кредитный портфель' , N'KPI кредитный портфель_УМФО' ,N'Платежи по ОД' ,N'Платежи по процентам' ,N'Платежи по пеням')
group by [ПериодУчета] ,[ДатаЧислом] ,[НаименованиеЛиста]

--select [ПериодУчета] ,[ДатаЧислом] ,[НаименованиеПараметра] ,sum([Сумма]) as [Сумма] from #report_kpi 
--where [НаименованиеЛиста] in (N'KPI кредитный портфель') -- , N'KPI кредитный портфель_УМФО') 
--group by [ПериодУчета] ,[ДатаЧислом] ,[НаименованиеПараметра] order by 1 desc
--select * from #report_kpi2 

--if not isnull(select * from #report_kpi2 where cast([ПериодУчета]-2 as date)=cast(dateadd(day,-1,getdate()) as date),0)=0

insert into [dwh_new].[dbo].[CARMONEY_dashboard_001v01] ([cdate] ,[Период] ,[Периодичность] ,[Показатель] ,[ПланФакт] ,[Значение] ,[ДатаУчета])
select getdate() as [cdate] ,cast(cast([ПериодУчета]-2 as datetime) as date) as [Период] 
		,N'Месяц' as [Периодичность] ,N'KPI кредитный портфель' [Показатель] ,N'Факт' as [ПланФакт] 
		,sum([Сумма]) as [Значение] ,cast(cast([ДатаЧислом]-2 as datetime) as date) as [ДатаУчета]
from #report_kpi2
where [НаименованиеЛиста] in (N'KPI кредитный портфель' , N'KPI кредитный портфель_УМФО')
group by cast(cast([ПериодУчета]-2 as datetime) as date) ,cast(cast([ДатаЧислом]-2 as datetime) as date)


insert into [dwh_new].[dbo].[CARMONEY_dashboard_001v01] ([cdate] ,[Период] ,[Периодичность] ,[Показатель] ,[ПланФакт] ,[Значение] ,[ДатаУчета])
select getdate() as [cdate] ,cast(cast([ПериодУчета]-2 as datetime) as date) as [Период] 
		,N'Месяц' as [Периодичность] ,N'Поступление процентов и пени' [Показатель] ,N'Факт' as [ПланФакт] 
		,sum([Сумма]) as [Значение] ,cast(cast([ДатаЧислом]-2 as datetime) as date) as [ДатаУчета]
from #report_kpi2
where [НаименованиеЛиста] in (N'Платежи по процентам' ,N'Платежи по пеням')
group by cast(cast([ПериодУчета]-2 as datetime) as date) ,cast(cast([ДатаЧислом]-2 as datetime) as date)


insert into [dwh_new].[dbo].[CARMONEY_dashboard_001v01] ([cdate] ,[Период] ,[Периодичность] ,[Показатель] ,[ПланФакт] ,[Значение] ,[ДатаУчета])
select getdate() as [cdate] ,cast(cast([ПериодУчета]-2 as datetime) as date) as [Период] 
		,N'Месяц' as [Периодичность] ,N'Погашение ОД' [Показатель] ,N'Факт' as [ПланФакт] 
		,sum([Сумма]) as [Значение] ,cast(cast([ДатаЧислом]-2 as datetime) as date) as [ДатаУчета]
from #report_kpi2
where [НаименованиеЛиста] in (N'Платежи по ОД')
group by cast(cast([ПериодУчета]-2 as datetime) as date) ,cast(cast([ДатаЧислом]-2 as datetime) as date)


--alter table [dwh_new].[dbo].[CARMONEY_dashboard_001v01] add [ДатаУчета] datetime null

-----------------------------------------------------------
----------- Загрузка оперативной информации по выдачам

if OBJECT_ID('tempdb.dbo.#dm_dashboard_CallCentr_actual') is not null drop table #dm_dashboard_CallCentr_actual

select distinct * into #dm_dashboard_CallCentr_actual from reports.dbo.dm_dashboard_CallCentr_actual
select * from #dm_dashboard_CallCentr_actual

insert into [dwh_new].[dbo].[CARMONEY_dashboard_001v01] ([cdate] ,[Период] ,[Периодичность] ,[Показатель] ,[ПланФакт] ,[Значение] ,[ДатаУчета])
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[ПериодУчетаДн]),0) as date) as [Период] 
		,N'День' as [Периодичность] ,N'Займы план руб Месяц' [Показатель] ,N'План' as [ПланФакт] 
		,([ОстДоЦели]+[СуммаФактМес]) as [Значение] ,[ПериодУчетаДн] as [ДатаУчета]
from #dm_dashboard_CallCentr_actual

union all
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[ПериодУчетаДн]),0) as date) as [Период] 
		,N'День' as [Периодичность] ,N'Займы факт руб Месяц' [Показатель] ,N'Факт' as [ПланФакт] 
		,[СуммаФактМес] as [Значение] ,[ПериодУчетаДн] as [ДатаУчета]
from #dm_dashboard_CallCentr_actual

union all
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[ПериодУчетаДн]),0) as date) as [Период] 
		,N'День' as [Периодичность] ,N'Займы факт колво Месяц' [Показатель] ,N'Факт' as [ПланФакт] 
		,[Ф_КолвоЗаймовМес] as [Значение] ,[ПериодУчетаДн] as [ДатаУчета]
from #dm_dashboard_CallCentr_actual
union all
select getdate() as [cdate] ,cast(dateadd(MONTH,datediff(MONTH,0,[ПериодУчетаДн]),0) as date) as [Период] 
		,N'День' as [Периодичность] ,N'Ср.взвешенная ставка проц' [Показатель] ,N'Факт' as [ПланФакт] 
		,[СрВзвешСтавкаМес] as [Значение] ,[ПериодУчетаДн] as [ДатаУчета]
from #dm_dashboard_CallCentr_actual

*/

/*
begin tran

delete from [dwh_new].[dbo].[mt_requests_transition_mfo] 
where [Период_Исх] >= @DateStartCurr; --@DateStartCurr;	--dateadd(day,datediff(day,0,Getdate()),0); -- @DateStart; --dateadd(day,datediff(day,0,Getdate()),0); --

insert into [dwh_new].[dbo].[mt_requests_transition_mfo] (
							[ЗаявкаСсылка_Исх],[Период_Исх] --,[НомерСтроки_Исх]
							,[ЗаявкаНомер_Исх],[ЗаявкаДата_Исх],[СтатусСсылка_Исх],[СтатусНаим_Исх]
							,[ИсполнительСсылка_Исх],[ИсполнительНаим_Исх],[ПричинаСсылка_Исх],[ПричинаНаим_Исх]
							,[ЗаявкаСсылка_След],[Период_След],[Период_След_2] --,[НомерСтроки_След],[ЗаявкаНомер_След],[ЗаявкаДата_След]
							,[СтатусСсылка_След],[СтатусНаим_След]
							,[ИсполнительСсылка_След],[ИсполнительНаим_След],[ПричинаСсылка_След],[ПричинаНаим_След]

							,[СостояниеЗаявки] ,[СтатусДляСостояния]
							)
select * from #tmp

commit tran
*/
END

