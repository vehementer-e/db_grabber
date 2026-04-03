

-- exec [dbo].[report_sales_diagramm001]

CREATE PROCEDURE [dbo].[report_sales_diagramm001]
	-- Add the parameters for the stored procedure here

AS
BEGIN 

	SET NOCOUNT ON;

		--24.03.2020
	SET DATEFIRST 1;

declare @dtFrom date,
	    @dtTo date,
		@stage nvarchar(255), 
		@Metrika nvarchar(20),
		@Param nvarchar(255),
		@MaxValue int
		--, @PageNo int
		, @ReportMetrika nvarchar(20)
		, @WeekFrom int
		, @WeekTo int
		, @maxWeek int
		, @MaxWeekLastYear int
--declare @Field
--set @ReportMetrika = N'Займы';

set @WeekFrom = datepart(ww,dateadd(week,-5,getdate()));
set @WeekTo=datepart(ww,getdate());

set @dtFrom = case when datepart(dw,getdate())=1 
					then cast(dateadd(week,datediff(week,0,dateadd(week,-5,Getdate())),0) as date) 
					else cast(dateadd(week,datediff(week,0,dateadd(week,-4,Getdate())),0) as date) 
			end;
set @dtTo = case when datepart(dw,getdate())=1 
					then cast(dateadd(week,datediff(week,0,dateadd(week,-1,Getdate())),0) as date) 
					else cast(dateadd(week,datediff(week,0,dateadd(week,0,Getdate())),0) as date) 
			end;



--set @Metrika = case when @ReportMetrika = N'Объемы' then N'Займы' else @ReportMetrika end;	--N'Займы'	--N'Объемы';	--N'Заявки'; --
set @MaxValue = (select (count(distinct [Номер]) + 100) as [maxValue] from [Reports].[dbo].[dm_Factor_Analysis_001]
																 where datepart(ww,[ДатаЗаявкиПолная]) between @WeekFrom and @WeekTo 
																		and datepart(yyyy,[ДатаЗаявкиПолная])=datepart(yyyy,getdate())
																		and not [Группа каналов] in (N'Тест'));

set @maxWeek = (select max([Неделя]) as [MaxWeek] from [dwh_new].[dbo].[dashboard_SalesDiagramm001]);

set @MaxWeekLastYear = (select max(datepart(ww,created)) max_week from dwh_new.dbo.calendar where datepart(yyyy,created) = datepart(yyyy,dateadd(year,-1,getdate())))
--set @dtFrom = dateadd(week, -5 ,dateadd(week,datediff(week,0,Getdate()),0))



--if object_id('[dwh_new].[dbo].[dashboard_SalesDiagramm001]') is not null drop table [dwh_new].[dbo].[dashboard_SalesDiagramm001];

--create table #tjob
--(
--)

--if @Metrika = N'Займы' and  @ReportMetrika = N'Займы'



drop table if exists #startdateofweek
select created 
	  ,[Год] 
	  ,[Неделя] 
	  ,first_value(dt) over(partition by r order by created) as dt --,[r] ,[dt] as [dt0]
into #startdateofweek
from (
	  select 
			created 
			,datepart(yyyy, created) as [Год] 
			,datepart(ww, created) as [Неделя] 		
			,sum(case when datepart(dw, created)=1 then 1 else 0 end) 
				over (order by created rows between unbounded preceding and current row) 
			as [r]
			,case 
				when datepart(dw, created)=1 
					then cast(created as date) 
			end as dt
	  from dwh_new.[dbo].calendar
	  where cast(created as date) between cast(dateadd(week ,-5 ,dateadd(week,datediff(week,0,Getdate()),0)) as date) and cast(dateadd(week ,1 ,getdate()) as date) 
		--and not (case when datepart(dw, created)=1 then cast(created as date) end) is null
	 ) t0
--select * from #startdateofweek

if object_id('tempdb.dbo.#LoanQ') is not null drop table #LoanQ

select N'Займы' as [Метрика] ,a.[Год] ,a.[Неделя] ,a.[КолвоФакт] ,a.[Группа каналов] ,s.dt as [ДатаНачалаНедели]
into #LoanQ
from (select [ГодВыдачи] as [Год] ,[НеделяЗайма] as [Неделя] ,count(distinct [Номер]) as [КолвоФакт] ,[Группа каналов]
	  from [Reports].[dbo].[dm_Factor_Analysis_001] 
	  where not [Заем выдан] is null and [Группа каналов]<>N'Тест' 
			and [Заем выдан] >= @dtFrom and [Заем выдан] < dateadd(day,datediff(day,0,Getdate()),0)
	  group by [ГодВыдачи] ,[НеделяЗайма] ,[Группа каналов]
		) a
left join (select distinct [Год] ,[Неделя] ,dt from #startdateofweek) s on a.[Год]=s.[Год] and a.[Неделя]=s.[Неделя]
		--order by a.[Неделя] desc
;

--if @Metrika = N'Займ' and  @ReportMetrika = N'Объемы'

if object_id('tempdb.dbo.#LoanV') is not null drop table #LoanV

select N'Объем' as [Метрика] ,a.[Год] ,a.[Неделя] ,a.[КолвоФакт] ,a.[Группа каналов] ,s.dt as [ДатаНачалаНедели]
into #LoanV 
from (select [ГодВыдачи] as [Год] ,[НеделяЗайма] as [Неделя] ,sum([Выданная сумма]) as [КолвоФакт] ,[Группа каналов]
	    from [Reports].[dbo].[dm_Factor_Analysis_001] 
		where not [Заем выдан] is null 
				and [Группа каналов]<>N'Тест' 
				and [Заем выдан]  >=  @dtFrom and [Заем выдан] < dateadd(day,datediff(day,0,Getdate()),0)
		group by [ГодВыдачи] ,[НеделяЗайма] ,[Группа каналов]
		) a
		--order by a.[Неделя] desc
left join (select distinct [Год] ,[Неделя] ,dt from #startdateofweek) s on a.[Год]=s.[Год] and a.[Неделя]=s.[Неделя]
;


--if @Metrika = N'Заявки' 

if object_id('tempdb.dbo.#Request') is not null drop table #Request

select N'Заявки' as [Метрика] ,z.[Год] ,z.[Неделя] ,[КолвоФакт] ,z.[Группа каналов] ,s.dt as [ДатаНачалаНедели]
into #Request 
from (select datepart(yyyy,ДатаЗаявкиПолная
) as [Год] ,[НеделяЗаявки] as [Неделя] ,count(distinct [Номер]) as [КолвоФакт] ,[Группа каналов]
	    from [Reports].[dbo].[dm_Factor_Analysis_001] 
		where [Группа каналов]<>N'Тест' 
			  and cast(ДатаЗаявкиПолная as date) >= @dtFrom and cast(ДатаЗаявкиПолная as date) < dateadd(day,datediff(day,0,Getdate()),0)
		group by datepart(yyyy,ДатаЗаявкиПолная) ,[НеделяЗаявки] ,[Группа каналов]
	  ) z
	--order by [Неделя] desc
left join (select distinct [Год] ,[Неделя] ,dt from #startdateofweek) s on z.[Год]=s.[Год] and z.[Неделя]=s.[Неделя]
;

--if @Metrika = N'Лиды' 

if object_id('tempdb.dbo.#Leads') is not null drop table #Leads

select N'Лиды' as [Метрика] ,l.[Год] ,l.[Неделя] ,sum(l.[КолвоФакт]) as [КолвоФакт] ,l.[Группа каналов] ,s.dt as [ДатаНачалаНедели]
into #Leads 
from (
	--DWH-1567. Отказ от использования таблицы lcrm_leads_full_channel
 	 -- SELECT datepart(yyyy,[UF_REGISTERED_AT]) as [Год] ,datepart(ww,[UF_REGISTERED_AT]) as [Неделя] ,count(distinct [ID]) as [КолвоФакт] ,[Группа каналов]
	  --from [Stg].[dbo].[lcrm_tbl_full_w_chanals2] with (nolock)
	  --where [Группа каналов] <> N'Тест' 
			--and [UF_REGISTERED_AT] >= @dtFrom and [UF_REGISTERED_AT] < dateadd(day,datediff(day,0,Getdate()),0) 
			--and [Группа каналов]<>N'Тест'
	  --group by datepart(yyyy,[UF_REGISTERED_AT]) ,datepart(ww,[UF_REGISTERED_AT]) ,[Группа каналов]
	SELECT datepart(yyyy, C.UF_REGISTERED_AT) as [Год], datepart(ww, C.UF_REGISTERED_AT) as [Неделя], count(distinct C.ID) as [КолвоФакт], C.[Группа каналов]
	FROM Stg._LCRM.lcrm_leads_full_calculated AS C (nolock)
	WHERE C.[Группа каналов] <> N'Тест' 
		AND C.UF_REGISTERED_AT >= @dtFrom and C.UF_REGISTERED_AT < dateadd(day,datediff(day,0,Getdate()),0) 
	GROUP BY datepart(yyyy, C.UF_REGISTERED_AT) ,datepart(ww, C.UF_REGISTERED_AT), C.[Группа каналов]
	  ) l
left join (select distinct [Год] ,[Неделя] ,dt from #startdateofweek) s on l.[Год]=s.[Год] and l.[Неделя]=s.[Неделя]
group by l.[Год] ,l.[Неделя] ,l.[Группа каналов] ,s.dt

;
--select * from #Leads


/*
with tj as
(
select * from #Leads
union all
select * from #LoanV
union all
select * from #LoanQ
union all
select * from #Request
)
*/

drop table if exists #t0
select * 
into #t0
from #Leads --where [ДатаНачалаНедели]>=@dtFrom --where [Неделя]>=@WeekFrom --@maxWeek-1
union all
select * from #LoanV --where [ДатаНачалаНедели]>=@dtFrom --where [Неделя]>=@WeekFrom  --@maxWeek-1
union all
select * from #LoanQ --where [ДатаНачалаНедели]>=@dtFrom --where [Неделя]>=@WeekFrom --@maxWeek-1
union all
select * from #Request --where [ДатаНачалаНедели]>=@dtFrom 


drop table if exists #t1
select distinct
		[Метрика] 
		,s.[Год] 
		,s.[Неделя] 
		,[КолвоФакт] 
		,[Группа каналов] 
		,[ДатаНачалаНедели] 
		,case when s2.[Неделя] is null then s.[Неделя] else s2.[Неделя] end as [НеделяУчета]
		,case when s2.[Год] is null then s.[Год] else s2.[Год] end as [ГодУчета] 
into #t1			
from #t0 s
left join (select * from #startdateofweek where [Неделя]=1) s2 on s.[ДатаНачалаНедели]=s2.dt

--select * from #t1

--select * into [dwh_new].[dbo].[dashboard_SalesDiagramm001] from tj
--select * from tj

--truncate table [dwh_new].[dbo].[dashboard_SalesDiagramm001]

begin tran

delete from [dwh_new].[dbo].[dashboard_SalesDiagramm001] where [ДатаНачалаНедели]>=@dtFrom --@MaxWeek-1

insert into [dwh_new].[dbo].[dashboard_SalesDiagramm001] ([Метрика] ,[Год] ,[Неделя] ,[КолвоФакт] ,[Группа каналов] ,[ДатаНачалаНедели] ,[НеделяУчета] ,[ГодУчета])

select * from #t1 where not [НеделяУчета] is null and [ДатаНачалаНедели]>=@dtFrom --where [Неделя]>=@WeekFrom --@maxWeek-1

--union all
--select * from #LoanV where [ДатаНачалаНедели]>=@dtFrom --where [Неделя]>=@WeekFrom  --@maxWeek-1
--union all
--select * from #LoanQ where [ДатаНачалаНедели]>=@dtFrom --where [Неделя]>=@WeekFrom --@maxWeek-1
--union all
--select * from #Request where [ДатаНачалаНедели]>=@dtFrom --where [Неделя]>=@WeekFrom --@maxWeek-1

----select * from [dwh_new].[dbo].[dashboard_SalesDiagramm001] where [Год]=2019

commit tran
 	
END

--alter table [dwh_new].[dbo].[dashboard_SalesDiagramm001] add [ДатаНачалаНедели] date
--alter table [dwh_new].[dbo].[dashboard_SalesDiagramm001] add [НеделяУчета] int ,[ГодУчета] int
