
CREATE PROCEDURE [etl].[base_etl_mt_loans_transition_mfo]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @DateStart datetime,
		@DateStart2 datetime,
		@DateStart2000 datetime,
		@DateStartCurr datetime,
		@DateStartCurr2000 datetime
set @DateStart=	dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,dateadd(year,2000,Getdate()))),0)	--dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,Getdate())),0)
--dateadd(day,-datediff(day,cast('20170101' as datetime),getdate()),getdate())
--dateadd(month,datediff(month,0,GetDate()),-720);
--dateadd(day,datediff(day,0,GetDate()-2),0);
set	@DateStart2=dateadd(year,2000,@DateStart);
set @DateStart2000= dateadd(day,datediff(day,0,dateadd(year,2000,dateadd(day,-10,Getdate()))),0);
set @DateStartCurr=dateadd(day,-10,dateadd(day,datediff(day,0,Getdate()),0));	-- Переменная для начала (дня) оперативного обновления данных по периоду статуса за последние 14 дней для поля с текущей датой
set @DateStartCurr2000=dateadd(day,-10,dateadd(day,datediff(day,0,dateadd(year,2000,Getdate())),0));	-- Переменная для начала (дня) оперативного обновления данных по периоду статуса за последние 14 дней для поля с текущей датой + 2000

delete from [dwh_new].[dbo].[mt_loans_transition_mfo] 
where [Период_Исх] >= @DateStartCurr; --@DateStartCurr;	--dateadd(day,datediff(day,0,Getdate()),0); -- @DateStart; --dateadd(day,datediff(day,0,Getdate()),0); --

--if OBJECT_ID('[dwh_new_Kurdin_S_V].[dbo].[mt_ReqTrans_1cMFO]') is not null
--truncate table [dwh_new_Kurdin_S_V].[dbo].[mt_ReqTrans_1cMFO];

--if OBJECT_ID('[dwh_new].[dbo].[mt_loans_transition_mfo]') is not null
--drop table [dwh_new].[dbo].[mt_loans_transition_mfo];

--create table [dwh_new].[dbo].[mt_loans_transition_mfo]
--(
--[ДоговорСсылка_Исх] binary(16) null
--,[Период_Исх] datetime null

--,[ДоговорНомер_Исх] varchar(20) null
--,[ДоговорДата_Исх] datetime null
--,[СтатусСсылка_Исх] binary(16) null
--,[СтатусНаим_Исх] nvarchar(50) null
--,[ИсполнительСсылка_Исх] binary(16) null
--,[ИсполнительНаим_Исх] nvarchar(100) null
--,[ДатаВозвратаПТС_Исх] datetime2 null

--,[Период_След] datetime null
--,[Период_След_2] datetime null

--,[СтатусСсылка_След] binary(16) null
--,[СтатусНаим_След] nvarchar(50) null
--,[ИсполнительСсылка_След] binary(16) null
--,[ИсполнительНаим_След] nvarchar(100) null
--,[ДатаВозвратаПТС_След] datetime2 null

--);

with ts as
(
select 
      dl.[Договор]  as [Ссылка]
	  ,dl.[Период] as [Период]
	  ,d.[Номер] as [ДоговорНомер]
	  ,d.[Дата] as [ДоговорДата]
	  ,dl.[Статус] as [СтатусСсылка]
	  ,ds.[Наименование] as [СтатусНаименование]
      ,dl.[Исполнитель] as [ИсполнительСсылка]
	  ,u0.[Наименование] as [ИсполнительНаименование]
      ,dl.[ДатаВозвратаПТС] as [ДатаВозвратаПТС]


  FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокДоговоров] dl with (nolock)
	LEFT JOIN [prodsql02].[mfo].[dbo].[Документ_ГП_Договор] d with (nolock) 
	ON dl.[Договор]=d.[Ссылка]
	LEFT JOIN [prodsql02].[mfo].[dbo].[Справочник_Пользователи] u0  with (nolock) --user
	ON dl.[Исполнитель]=u0.[Ссылка]
	LEFT JOIN [prodsql02].[mfo].[dbo].[Справочник_ГП_СтатусыДоговоров] ds with (nolock)
	ON dl.[Статус]=ds.[Ссылка]

  WHERE dl.[Период] >= @DateStartCurr2000 
		--d.[Дата]>= @DateStart 
)
--select * from ts
-- предварительная таблица TablePreliminary
,	tp as
(
select 
	ts.[Ссылка] as [ДоговорСсылка_Исх]
	,ts.[Период] as [Период_Исх]
	--,ts1.[НомерСтроки] as [НомерСтроки_Исх]
	,ts.[ДоговорНомер] as [ДоговорНомер_Исх]
	,ts.[ДоговорДата] as [ДоговорДата_Исх]
	,isnull(ts.[СтатусСсылка],0) as [СтатусСсылка_Исх]
	,ts.[СтатусНаименование] as [СтатусНаим_Исх]
	,isnull(ts.[ИсполнительСсылка],0) as [ИсполнительСсылка_Исх]
	,ts.[ИсполнительНаименование] as [ИсполнительНаим_Исх]
	,ts.[ДатаВозвратаПТС] as [ДатаВозвратаПТС_Исх]

	,ts2.[Период] as [Период_След]
	,min(ts2.[Период]) over(partition by ts.[Ссылка], ts.[Период] order by ts.[Период]) as [Период_След_2]

	,isnull(ts2.[СтатусСсылка],0) as [СтатусСсылка_След]
	,ts2.[СтатусНаименование] as [СтатусНаим_След]
	,isnull(ts2.[ИсполнительСсылка],0) as [ИсполнительСсылка_След]
	,ts2.[ИсполнительНаименование] as [ИсполнительНаим_След]
	,ts2.[ДатаВозвратаПТС] as [ДатаВозвратаПТС_След]

from ts
	left join ts ts2
	on ts.[Ссылка]=ts2.[Ссылка] and ts.[Период]<ts2.[Период]
 ) 

insert into [dwh_new].[dbo].[mt_loans_transition_mfo] ([ДоговорСсылка_Исх],[Период_Исх] --,[НомерСтроки_Исх]
													   ,[ДоговорНомер_Исх],[ДоговорДата_Исх],[СтатусСсылка_Исх],[СтатусНаим_Исх]
													   ,[ИсполнительСсылка_Исх],[ИсполнительНаим_Исх],[ДатаВозвратаПТС_Исх]
													   ,[Период_След],[Период_След_2] 
													   ,[СтатусСсылка_След],[СтатусНаим_След]
													   ,[ИсполнительСсылка_След],[ИсполнительНаим_След],[ДатаВозвратаПТС_След])
select distinct [ДоговорСсылка_Исх] ,
	dateadd(year,-2000,[Период_Исх]) as [Период_Исх] ,[ДоговорНомер_Исх] 
	,dateadd(year,-2000,[ДоговорДата_Исх]) as [ДоговорДата_Исх] 
	,[СтатусСсылка_Исх] ,[СтатусНаим_Исх] ,[ИсполнительСсылка_Исх] ,[ИсполнительНаим_Исх]
	,dateadd(year,-2000,cast([ДатаВозвратаПТС_Исх] as datetime2)) as [ДатаВозвратаПТС_Исх]
	,dateadd(year,-2000,[Период_След]) as [Период_След]
	,dateadd(year,-2000,[Период_След_2]) as [Период_След_2] 
	,[СтатусСсылка_След] ,[СтатусНаим_След] ,[ИсполнительСсылка_След] ,[ИсполнительНаим_След]
	,dateadd(year,-2000,cast([ДатаВозвратаПТС_След]as datetime2)) as [ДатаВозвратаПТС_След]
from tp
where [Период_След]=[Период_След_2] 
		and [Период_Исх]<>[Период_След]
		and [СтатусНаим_Исх]<>[СтатусНаим_След]
		and [Период_Исх]>=@DateStartCurr2000
--		and [Период_След] is not null
order by [ДоговорНомер_Исх] desc, [Период_Исх] asc

END

--exec [etl].[base_etl_mt_loans_transition_mfo]

