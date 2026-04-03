

-- exec [etl].[base_etl_mt_requests_transition_mfo] 1

CREATE PROCEDURE [etl].[base_etl_mt_requests_transition_mfo]
	-- Add the parameters for the stored procedure here


@param int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--declare @param int
--set @param = 1

if object_id('tempdb.dbo.#tmp') is not null drop table #tmp;

declare @DateStart datetime,
		@DateStart2 datetime,
		@DateStart2000 datetime,
		@DateStartCurr datetime,
		@DateStartCurr2000 datetime

		

set @DateStart = dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,Getdate())),0);
--dateadd(day,-datediff(day,cast('20170101' as datetime),getdate()),getdate())
--dateadd(month,datediff(month,0,GetDate()),-720);
--dateadd(day,datediff(day,0,GetDate()-2),0);
set	@DateStart2=dateadd(year,2000,@DateStart);
set @DateStart2000= dateadd(day,datediff(day,0,dateadd(year,2000,dateadd(day,-20,Getdate()))),0);


if @param = 1  --2 -- Переменная для запуска в 23 часа для начала (дня) оперативного обновления данных по периоду статуса за последние 4 месяца
	begin 
		set @DateStartCurr = dateadd(month,-3,dateadd(month,datediff(month,0,Getdate()),0)); /*dateadd(month,-3,dateadd(month,datediff(month,0,Getdate()),0));*/
		set @DateStartCurr2000 = dateadd(month,-3,dateadd(month,datediff(month,0,dateadd(year,2000,Getdate())),0))	;
	end;				

if @param = 2  --2 -- Переменная для запуска в для начала (дня) оперативного обновления данных
	begin 
		set @DateStartCurr = dateadd(month,-3,dateadd(month,datediff(month,0,Getdate()),0)); /*dateadd(month,-3,dateadd(month,datediff(month,0,Getdate()),0));*/
		set @DateStartCurr2000 = dateadd(month,-3,dateadd(month,datediff(month,0,dateadd(year,2000,Getdate())),0))	;
	end;

/*
if @param = 3  --1 -- Переменная для запуска в для начала (дня) оперативного обновления данных по периоду статуса за последние 15 дней
	begin 
		set @DateStartCurr = dateadd(day,-31,dateadd(day,datediff(day,0,Getdate()),0));
		set @DateStartCurr2000 = dateadd(day,-31,dateadd(day,datediff(day,0,dateadd(year,2000,Getdate())),0));
	end;					
*/


drop table if exists #request_for
select distinct
		[Заявка]
into #request_for
from [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокЗаявок] with (nolock)
where [Период] >= dateadd(year,2000,cast(dateadd(day,-2,getdate()) as date))  --@DateStartCurr2000



drop table if exists #ts_a

select 
      zl.[Заявка]  as [ЗаявкаСсылка]
	  --,zl.[НомерСтроки] as [НомерСтроки]
	  ,max(dateadd(year,-2000,zl.[Период])) as [Период]
	  ,z.[Номер] as [ЗаявкаНомер]
	  ,dateadd(year,-2000,z.[Дата]) as [ЗаявкаДата]
	  ,zl.[Статус] as [СтатусСсылка]
	  ,zs.[Наименование] as [СтатусНаименование]
      ,zl.[Исполнитель] as [ИсполнительСсылка]
	  ,u0.[Наименование] as [ИсполнительНаименование]
      ,zl.[Причина] as [ПричинаСсылка]
	  ,zrs.[Представление] as [ПричинаНаименование]
	  ,r.[Наименование] as [ПричинаОтказаНаименование]

into #ts_a
  FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокЗаявок] zl with (nolock)
	LEFT JOIN [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] z  with (nolock) -- zayvka
	ON zl.[Заявка]=z.[Ссылка]
	LEFT JOIN [prodsql02].[mfo].[dbo].[Справочник_Пользователи] u0  with (nolock) --user
	ON zl.[Исполнитель]=u0.[Ссылка]
	LEFT JOIN [prodsql02].[mfo].[dbo].[Справочник_ГП_СтатусыЗаявок] zs with (nolock)
	ON zl.[Статус]=zs.[Ссылка]
	LEFT JOIN [prodsql02].[mfo].[dbo].[Перечисление_ГП_ПричиныСтатусаЗаявки] zrs with (nolock)
	ON zl.[Причина]=zrs.[Ссылка]
  left join [PRODSQL02].[mfo].[dbo].[Справочник_ПричиныОтказа] r with (nolock) on zl.[ПричинаОтказа]=r.[Ссылка]

  WHERE  zl.[Заявка] in (select * from #request_for)
		--zl.[Период] >= @DateStartCurr2000 
		--and	z.[Номер]=N'19110710000004'
		--z.[Дата]>=@DateStart2 
 group by zl.[Заявка] ,z.[Номер] ,dateadd(year,-2000,z.[Дата]) ,zl.[Статус] ,zs.[Наименование] ,zl.[Исполнитель] ,u0.[Наименование] ,zl.[Причина] ,zrs.[Представление] ,r.[Наименование]
 --order by max(dateadd(year,-2000,zl.[Период])) desc

UNION all

SELECT 
      zs1.[Заявка] as [ЗаявкаСсылка]
	  --,1 as [НомерСтроки]
	  ,case when zs1.[Приостановлено]=0x01 then dateadd(year,-2000,dateadd(second,2,zs1.[Период])) else dateadd(year,-2000,dateadd(second,-1,zs1.[Период])) end as [Период]
	  ,z1.[Номер] as [ЗаявкаНомер]
	  ,dateadd(year,-2000,z1.[Дата]) as [ЗаявкаДата]
	  ,null as [СтатусСсылка]
	  ,case when zs1.[Приостановлено]=0x01 then N'Отложено рассмотрение' else N'Восстановлено рассмотрение' end as [СтатусНаименование]
      ,[Исполнитель] as [ИсполнительСсылка]
	  ,u1.[Наименование] as [ИсполнительНаименование]
      ,zs1.[ПричинаПриостановкиВерификации] as [ПричинаСсылка] 
	  ,sr.[Наименование] as [ПричинаНаименование]
	  ,null as [ПричинаОтказаНаименование]

  FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ПриостановкаВерификацииЗаявок] zs1  with (nolock) --zayvka stop
	LEFT JOIN [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] z1  with (nolock) -- zayvka
	ON zs1.[Заявка]=z1.[Ссылка]
	LEFT JOIN [prodsql02].[mfo].[dbo].[Справочник_Пользователи] u1  with (nolock) --user
	ON zs1.[Исполнитель]=u1.[Ссылка]
	LEFT JOIN [prodsql02].[mfo].[dbo].[Справочник_ПричиныПриостановкиВерификацииЗаявок] sr  with (nolock) --suspension reason 
	ON zs1.[ПричинаПриостановкиВерификации]=sr.[Ссылка]
  WHERE	zs1.[Заявка] in (select * from #request_for)
		 --zs1.[Период] >= @DateStartCurr2000	
		 --z1.[Дата]>=@DateStart2 

--select * from #ts_a

drop table if exists #ts_b
select 
      [ЗаявкаСсылка]


 	  ,lead([Период]) over (partition by [ЗаявкаСсылка] order by [Период] desc) as [prev_Период]
	  ,[Период]	  
	  ,lag([Период]) over (partition by [ЗаявкаСсылка] order by [Период] desc) as [next_Период]

	  ,[ЗаявкаНомер]
	  ,[ЗаявкаДата]

 	  ,lead([СтатусСсылка]) over (partition by [ЗаявкаСсылка] order by [Период] desc) as [prev_СтатусСсылка]
	  ,[СтатусСсылка]	  
	  ,lag([СтатусСсылка]) over (partition by [ЗаявкаСсылка] order by [Период] desc) as [next_СтатусСсылка]

 	  ,lead([СтатусНаименование]) over (partition by [ЗаявкаСсылка] order by [Период] desc) as [prev_СтатусНаименование]
	  ,[СтатусНаименование]	  
	  ,lag([СтатусНаименование]) over (partition by [ЗаявкаСсылка] order by [Период] desc) as [next_СтатусНаименование]


 	  ,lead([ИсполнительСсылка]) over (partition by [ЗаявкаСсылка] order by [Период] desc) as [prev_ИсполнительСсылка]
	  ,[ИсполнительСсылка]	  
	  ,lag([ИсполнительСсылка]) over (partition by [ЗаявкаСсылка] order by [Период] desc) as [next_ИсполнительСсылка]

 	  ,lead([ИсполнительНаименование]) over (partition by [ЗаявкаСсылка] order by [Период] desc) as [prev_ИсполнительНаименование]
	  ,[ИсполнительНаименование]	  
	  ,lag([ИсполнительНаименование]) over (partition by [ЗаявкаСсылка] order by [Период] desc) as [next_ИсполнительНаименование]

      ,[ПричинаСсылка]
	  ,[ПричинаНаименование]
	  ,[ПричинаОтказаНаименование]

into #ts_b
from #ts_a
--where [СтатусНаименование] in ('Отложено рассмотрение' ,'Восстановлено рассмотрение')

--select * from #ts_b2  where [ЗаявкаНомер]='20020410000238' and [СтатусНаименование] in ('Отложено рассмотрение' ,'Восстановлено рассмотрение') order by 2 desc

drop table if exists #ts_b2 select * into #ts_b2 from #ts_b where [СтатусНаименование] in ('Отложено рассмотрение' ,'Восстановлено рассмотрение') 

drop table if exists #ts_c
-------------------- добавим  специально отсутствующие записи с статусом 'Восстановлено рассмотрение'
select 
		[ЗаявкаСсылка]
		,dateadd(millisecond ,10 ,cast([Период] as datetime)) [Период]
		,[ЗаявкаНомер]
		,[ЗаявкаДата]		
		,[СтатусСсылка]
		,'Восстановлено рассмотрение' as [СтатусНаименование]	
		,[ИсполнительСсылка]
		,'АВТОПОМОЩНИК РЕПОРТ' as [ИсполнительНаименование]	 
		,[ПричинаСсылка]
		,[ПричинаНаименование]
		,[ПричинаОтказаНаименование]
into #ts_c
from #ts_b2 where [СтатусНаименование]='Отложено рассмотрение' and [next_СтатусНаименование]<>'Восстановлено рассмотрение'

union all
-------------------- добавим  специально отсутствующие записи с статусом 'Отложено рассмотрение'
select 
		[ЗаявкаСсылка]
		,dateadd(millisecond ,-10 ,cast([Период] as datetime)) [Период]
		,[ЗаявкаНомер]
		,[ЗаявкаДата]		
		,[СтатусСсылка]
		,'Отложено рассмотрение' as [СтатусНаименование]	  
		,[ИсполнительСсылка]
		,'АВТОПОМОЩНИК РЕПОРТ' as [ИсполнительНаименование]	  
		,[ПричинаСсылка]
		,[ПричинаНаименование]
		,[ПричинаОтказаНаименование]
		
from #ts_b2 where [prev_СтатусНаименование]<>'Отложено рассмотрение' and [СтатусНаименование]='Восстановлено рассмотрение'

--select * from #ts_c where [ЗаявкаНомер]='20020410000238' order by 2 desc

drop table if exists #ts
select * into #ts from #ts_a
union all
select * from #ts_c

-- предварительная таблица TablePreliminary

drop table if exists #tp
select 
	ts1.[ЗаявкаСсылка] as [ЗаявкаСсылка_Исх]
	,ts1.[Период] as [Период_Исх]
	--,ts1.[НомерСтроки] as [НомерСтроки_Исх]
	,ts1.[ЗаявкаНомер] as [ЗаявкаНомер_Исх]
	,ts1.[ЗаявкаДата] as [ЗаявкаДата_Исх]
	,isnull(ts1.[СтатусСсылка],0) as [СтатусСсылка_Исх]
	,ts1.[СтатусНаименование] as [СтатусНаим_Исх]
	,isnull(ts1.[ИсполнительСсылка],0) as [ИсполнительСсылка_Исх]
	,ts1.[ИсполнительНаименование] as [ИсполнительНаим_Исх]
	,isnull(ts1.[ПричинаСсылка],0) as [ПричинаСсылка_Исх]
	,ts1.[ПричинаНаименование] as [ПричинаНаим_Исх] 
	,ts2.[ЗаявкаСсылка] as [ЗаявкаСсылка_След]
	,ts2.[Период] as [Период_След]
	,min(ts2.[Период]) over(partition by ts1.[ЗаявкаСсылка], ts1.[Период] order by ts1.[Период]) as [Период_След_2]
	--,ts2.[НомерСтроки] as [НомерСтроки_След]
	--,ts2.[ЗаявкаНомер] as [ЗаявкаНомер_След]
	--,ts2.[ЗаявкаДата] as [ЗаявкаДата_След]
	,isnull(ts2.[СтатусСсылка],0) as [СтатусСсылка_След]
	,ts2.[СтатусНаименование] as [СтатусНаим_След]
	,isnull(ts2.[ИсполнительСсылка],0) as [ИсполнительСсылка_След]
	,ts2.[ИсполнительНаименование] as [ИсполнительНаим_След]
	,isnull(ts2.[ПричинаСсылка],0) as [ПричинаСсылка_След]
	,ts2.[ПричинаНаименование] as [ПричинаНаим_След] 
	,ts1.[ПричинаОтказаНаименование] as [ПричинаОтказаНаим_Исх]
	,ts2.[ПричинаОтказаНаименование] as [ПричинаОтказаНаим_След]
into  #tp 
  from #ts ts1
	left join #ts ts2
	on ts1.[ЗаявкаСсылка]=ts2.[ЗаявкаСсылка] and ts1.[Период]<ts2.[Период]

--select * from #ts where [ЗаявкаНомер]='20020510000109' order by 2 desc
--select * from #tp where [ЗаявкаНомер_Исх]='20020510000109' order by 2 desc
 
 -------------------------------------------------------------------------------
 ----------------- Определение состояния (в работе, отложено) заявки

drop table if exists #t_state
					select [ЗаявкаНомер_Исх] ,[Период_Исх] ,[СтатусНаим_Исх] ,[Период_След] ,[СтатусНаим_След] 

					   ,case 
							when [СтатусНаим_Исх]=N'Отложено рассмотрение' then N'Отложено'
							when [СтатусНаим_След]=N'Отложено рассмотрение' then N'В работе'
							when [СтатусНаим_Исх]=N'Восстановлено рассмотрение' then N'В работе'
							when [СтатусНаим_След]=N'Восстановлено рассмотрение' then N'Отложено'
							when [СтатусНаим_Исх]=N'Верификация КЦ' or [СтатусНаим_Исх]=N'Черновик'  then N'В работе' 
						end as [ПредвСостояние]
						,case 
							when [СтатусНаим_Исх]=N'Отложено рассмотрение' then 1
							when [СтатусНаим_След]=N'Отложено рассмотрение' then 1
							when [СтатусНаим_Исх]=N'Восстановлено рассмотрение' then 1
							when [СтатусНаим_След]=N'Восстановлено рассмотрение' then 1
							when [СтатусНаим_Исх]=N'Верификация КЦ' or [СтатусНаим_Исх]=N'Черновик'  then 1
							else 0
						end as [СчетчикГруппыСтатуса]
-------------------------------
						,case 
							when [СтатусНаим_Исх]=N'Отложено рассмотрение' --or [СтатусНаим_След]=N'Восстановлено рассмотрение' 
								then N'Отложено'
							--when [СтатусНаим_След]=N'Восстановлено рассмотрение' then N'Отложено'
							when [СтатусНаим_Исх]<>N'Отложено рассмотрение' then N'В работе' 
						end as [ПредвСостояние2]
	  --,case when ts.[СтатусНаименование] is null then 0 else 1 end as [СчетчикГруппыСтатусов]

						,case 
							when [СтатусНаим_Исх]=N'Отложено рассмотрение' then null
							when [СтатусНаим_Исх]=N'Восстановлено рассмотрение' then null
							else [СтатусНаим_Исх] 
						end as [ТекСтатус]

						,case 
							when [СтатусНаим_Исх]=N'Отложено рассмотрение' or [СтатусНаим_Исх]=N'Восстановлено рассмотрение' then 0
							else 1 
						end as [СчетчикГруппыТекСтатуса]
into #t_state
			   from #tp




drop table if exists #t_counter				  
				  select [ЗаявкаНомер_Исх] ,[Период_Исх] ,[СтатусНаим_Исх] ,[Период_След] ,[СтатусНаим_След] --,[ПериодСостояния] ,[Направление] 
						,[ПредвСостояние2] as [Состояние2]
						,[ПредвСостояние] 
						,[СчетчикГруппыСтатуса]
						,sum([СчетчикГруппыСтатуса]) over(partition by [ЗаявкаНомер_Исх] order by [Период_Исх]
														rows between unbounded preceding and current row) as [ГруппаСтатуса] 
						,[ТекСтатус]
						,[СчетчикГруппыТекСтатуса]
						,sum([СчетчикГруппыТекСтатуса]) over(partition by [ЗаявкаНомер_Исх] order by [Период_Исх]
														rows between unbounded preceding and current row) as [ГруппаТекСтатуса] 
into #t_counter				  
				  from #t_state




drop table if exists #t_stateend	
				   select [ЗаявкаНомер_Исх] ,[Период_Исх] ,[СтатусНаим_Исх] ,[Период_След] ,[СтатусНаим_След] --,[ПериодСостояния] ,[Направление] 
						  ,[Состояние2]
						  ,[ПредвСостояние]
						  ,first_value([ПредвСостояние]) over(partition by [ЗаявкаНомер_Исх] ,[ГруппаСтатуса] order by [Период_Исх]) as [Состояние]
						  ,[ГруппаСтатуса] as [ГрСтатуса] ,[СчетчикГруппыСтатуса] as [СчГрСтатуса]

						  ,first_value([ТекСтатус]) over(partition by [ЗаявкаНомер_Исх] ,[ГруппаТекСтатуса] order by [Период_Исх]) as [ВСтатусе]
						  ,[ГруппаТекСтатуса] as [ГрТекСтатуса] ,[СчетчикГруппыТекСтатуса] as [СчГрТекСтатуса]
				  
into #t_stateend				  
				  from #t_counter


--,	tp2 as (
drop table if exists #tp2	
			select [ЗаявкаСсылка_Исх] ,tp.[Период_Исх] ,tp.[ЗаявкаНомер_Исх] ,[ЗаявкаДата_Исх] 
					,[СтатусСсылка_Исх] ,tp.[СтатусНаим_Исх] ,[ИсполнительСсылка_Исх] ,[ИсполнительНаим_Исх] ,[ПричинаСсылка_Исх] ,[ПричинаНаим_Исх]
					,[ЗаявкаСсылка_След] ,tp.[Период_След] ,[Период_След_2] 
					,[СтатусСсылка_След] ,tp.[СтатусНаим_След] ,[ИсполнительСсылка_След] ,[ИсполнительНаим_След] ,[ПричинаСсылка_След] ,[ПричинаНаим_След]
					
					,tst.[Состояние2] as [СостояниеЗаявки] ,tst.[ВСтатусе] as [СтатусДляСостояния] --,tst.[Состояние] 
					,[ПричинаОтказаНаим_Исх] ,[ПричинаОтказаНаим_След]
into #tp2			
			from #tp tp
			left join #t_stateend tst on tp.[ЗаявкаНомер_Исх]=tst.[ЗаявкаНомер_Исх] and tp.[Период_Исх]=tst.[Период_Исх] and tp.[СтатусНаим_Исх]=tst.[СтатусНаим_Исх]
--)
--select * from #tp

select distinct * 
into #tmp 
from #tp2 
where [Период_След]=[Период_След_2] 
		and [Период_Исх]<>[Период_След]
		and [СтатусНаим_Исх]<>[СтатусНаим_След]
		and [Период_Исх]>=@DateStartCurr
--		and [Период_След] is not null
order by [ЗаявкаНомер_Исх] desc, [Период_Исх] asc

--select * from #tmp

--select * from #tmp where [ЗаявкаНомер_Исх]='20020410000238' order by 2 desc

--select * from [dwh_new].[dbo].[mt_requests_transition_mfo] where [ЗаявкаНомер_Исх]='20020410000238' order by 2 desc

begin tran

delete from [dwh_new].[dbo].[mt_requests_transition_mfo] 
where [ЗаявкаСсылка_Исх] in (select * from #request_for)
--where [Период_Исх] >=  @DateStartCurr; --@DateStartCurr;	--dateadd(day,datediff(day,0,Getdate()),0); -- @DateStart; --dateadd(day,datediff(day,0,Getdate()),0); --

insert into [dwh_new].[dbo].[mt_requests_transition_mfo] (
							[ЗаявкаСсылка_Исх],[Период_Исх] --,[НомерСтроки_Исх]
							,[ЗаявкаНомер_Исх],[ЗаявкаДата_Исх],[СтатусСсылка_Исх],[СтатусНаим_Исх]
							,[ИсполнительСсылка_Исх],[ИсполнительНаим_Исх],[ПричинаСсылка_Исх],[ПричинаНаим_Исх]
							,[ЗаявкаСсылка_След],[Период_След],[Период_След_2] --,[НомерСтроки_След],[ЗаявкаНомер_След],[ЗаявкаДата_След]
							,[СтатусСсылка_След],[СтатусНаим_След]
							,[ИсполнительСсылка_След],[ИсполнительНаим_След],[ПричинаСсылка_След],[ПричинаНаим_След]

							,[СостояниеЗаявки] ,[СтатусДляСостояния]
							,[ПричинаОтказаНаим_Исх] ,[ПричинаОтказаНаим_След]
							)
select --* 
	   [ЗаявкаСсылка_Исх]
	   ,[Период_Исх]
	   ,[ЗаявкаНомер_Исх]
	   ,[ЗаявкаДата_Исх]
	   ,[СтатусСсылка_Исх]
	   ,[СтатусНаим_Исх]
	   ,[ИсполнительСсылка_Исх]
	   ,[ИсполнительНаим_Исх]
	   ,[ПричинаСсылка_Исх]
	   ,[ПричинаНаим_Исх]
	   ,[ЗаявкаСсылка_След]
	   ,[Период_След]
	   ,[Период_След_2]
	   ,[СтатусСсылка_След]
	   ,[СтатусНаим_След]
	   ,[ИсполнительСсылка_След]
	   ,[ИсполнительНаим_След]
	   ,[ПричинаСсылка_След]
	   ,[ПричинаНаим_След]
	   
	   ,case when [СтатусНаим_След]='Восстановлено рассмотрение' then 'Отложено'  else [СостояниеЗаявки] end as [СостояниеЗаявки]
	   ,[СтатусДляСостояния]

	   ,[ПричинаОтказаНаим_Исх] 
	   ,[ПричинаОтказаНаим_След]

from #tmp

commit tran

END


--select min([Период_Исх]) from [dwh_new].[dbo].[mt_requests_transition_mfo] where [ПричинаОтказаНаим_След] is not null