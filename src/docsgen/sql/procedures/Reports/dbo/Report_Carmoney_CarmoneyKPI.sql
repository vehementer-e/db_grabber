-- =============================================
-- Author:		Kurdin S
-- Create date: 2019-12-25
-- Description:	

-- =============================================

CREATE PROCEDURE [dbo].[Report_Carmoney_CarmoneyKPI]
	-- Add the parameters for the stored procedure here

@PageNo int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


declare @maxdatechoice datetime,
		@currdate datetime,
		@firstmonth date,
		@currmonth date 

set @currdate = getdate();

set @firstmonth = case 
					when datepart(dd,getdate())=1 
						then dateadd(month,-12,dateadd(MONTH,datediff(MONTH,0,dateadd(day,-1,Getdate())),0)) 
					else dateadd(month,-12,dateadd(month,datediff(month,0,getdate()),0)) 
				  end;
set @currmonth = case when datepart(dd,getdate())=1 then dateadd(MONTH,datediff(MONTH,0,dateadd(day,-1,Getdate())),0) else dateadd(month,datediff(month,0,getdate()),0) end;

set @maxdatechoice = (select max([rdate]) 
					  from [dwh_new].[dbo].[mt_report_carmoney_kpi]
					  where [period] = @currmonth);
---------
if object_id('tempdb.dbo.#Tstruct_group1') is not null drop table #Tstruct_group1;
create table #Tstruct_group1(rws int null ,ind nvarchar(255) null);

insert into #Tstruct_group1 (rws ,ind)
values 	(1,N'Количество заявок') ,(2,N'Кол-во займов') ,(3,N'Сумма займов') ,(4,N'Сумма займов накопительно') ,(5,N'Средний размер займа')
		,(6,N'Конвертация') ,(7,N'Approval Rate') ,(8,N'Take Rate') ,(9,N'Кол-во займов со страховкой') ,(10,N'Сумма страховки по Договору') ,(11,N'Сумма страховки Полученная в ДОХОД')

-----------
--if object_id('tempdb.dbo.#Tstruct_group2') is not null drop table #Tstruct_group2;
--create table #Tstruct_group2(rws int null ,ind nvarchar(255) null);

--insert into #Tstruct_group2 (rws ,ind)
--values 	
,(30,N'Портфель просрочка') ,(31,N'без просрочки') ,(32,N'просрочка 1-90 дней') ,(33,N'просрочка 90+ дней') ,(34,N'в т.ч. просрочка 360+ дней')

-----------
--if object_id('tempdb.dbo.#Tstruct_group3') is not null drop table #Tstruct_group3;
--create table #Tstruct_group3(rws int null ,ind nvarchar(255) null);

--insert into #Tstruct_group3 (rws ,ind)
--values 	
,(50,N'ВЫРУЧКА ПО ОПЛАТЕ') ,(51,N'НАЧИСЛЕННАЯ ВЫРУЧКА') ,(52,N'РЕЗЕРВ на ОД (на дату отчета)') 
,(53,N'РЕЗЕРВ на % (на дату отчета)') ,(54,N'РЕЗЕРВ (ВСЕГО)  (на дату отчета)') ,(55,N'Доля РЕЗЕРВА от КП')

---------
if object_id('tempdb.dbo.#Tcolumn') is not null drop table #Tcolumn;
create table #Tcolumn (col int null ,st nvarchar(255) null);

insert into #Tcolumn (col ,st)
values 	(1,N'План') ,(2,N'Факт') ,(3,N'Прогноз') ,(4,N'% выполнения')

drop table if exists #rws_col
select r.rws ,c.col , r.ind ,c.st
into #rws_col
from #Tstruct_group1 r
cross join (select * from #Tcolumn where [st] in (N'План' ,N'Факт' ,N'Прогноз')) c 


drop table if exists #r1
select * 
into #r1
from [dwh_new].[dbo].[mt_report_carmoney_kpi]
where [OnOff]=1 and [Факт/План] in (N'План')  
				and [period] between (case 
										when datepart(dd,getdate())=1 
											then dateadd(month,-12,dateadd(MONTH,datediff(MONTH,0,dateadd(day,-1,Getdate())),0)) 
										else dateadd(month,-12,dateadd(month,datediff(month,0,getdate()),0))
									  end) 
							and (case 
									when datepart(dd,getdate())=1 
										then dateadd(MONTH,datediff(MONTH,0,dateadd(day,-2,Getdate())),0) 
										else dateadd(month,datediff(month,-1,getdate()),0) 
								 end)
				--and [accdate] in (select distinct max([accdate]) over(partition by [period]) from [dwh_new].[dbo].[mt_report_carmoney_kpi]) 
		 
union all
select * from [dwh_new].[dbo].[mt_report_carmoney_kpi]
where [OnOff]=1 and [Факт/План] in (N'План')  
				and [period] = cast(dateadd(month,datediff(month,0,getdate()),0) as date) 


drop table if exists #r2
select * 
into #r2
from [dwh_new].[dbo].[mt_report_carmoney_kpi]
where [OnOff]=1 and [Факт/План] in (N'Факт' ,N'Прогноз')  
				and [period] between (case 
										when datepart(dd,getdate())=1 
											then dateadd(month,-12,dateadd(MONTH,datediff(MONTH,0,dateadd(day,-1,Getdate())),0)) 
										else dateadd(month,-12,dateadd(month,datediff(month,0,getdate()),0))
									  end) 
							and (case 
									when datepart(dd,getdate())=1 
										then dateadd(MONTH,datediff(MONTH,0,dateadd(day,-1,Getdate())),0) 
										else dateadd(month,datediff(month,0,getdate()),0) 
								 end)
				and [accdate] in (select distinct max([accdate]) over(partition by [period] ) from [dwh_new].[dbo].[mt_report_carmoney_kpi]) 


drop table if exists #t_col2
select
		r.[period]
		,row_number() over(order by [period] desc) col2
into #t_col2 
from (select distinct cast([period] as datetime) as [period] ,[Факт/План] from #r2) r  select * from #r2


drop table if exists #t0_plan
select s.* 
		,isnull(r.[period], dateadd(month,datediff(month,0,getdate()),0)) [period]
		,isnull(r.rdate,@maxdatechoice) rdate 
		,isnull(r.accdate, cast(dateadd(day,datediff(day,0,dateadd(day,-1,getdate())),0) as date)) accdate 
		,isnull(r.Indicator ,s.ind) Indicator
		,isnull(r.[Факт/План] ,s.st) [Факт/План]
		,isnull(r.[Value],0) [Value]
		,isnull(r.[OnOff] ,1) [OnOff]
		,isnull(r.[isChanged] ,1) [isChanged]
		,0 as [col2] 
into #t0_plan
from #rws_col s
left join #r1 r on s.ind=r.Indicator and s.st=r.[Факт/План]
where s.st in (N'План')
-- select * from #t0_plan order by 5 desc ,1 asc --group by   order by [period] desc


drop table if exists #t0
select s.* 
		,case 
			when isnull(r.[Факт/План] ,s.st) = 'Факт' then dateadd(second ,1 ,isnull(r.[period], dateadd(month,datediff(month,0,getdate()),0))) 
			when isnull(r.[Факт/План] ,s.st) = 'Прогноз' then dateadd(second ,2 ,isnull(r.[period], dateadd(month,datediff(month,0,getdate()),0)))
		end as [period]
		,isnull(r.rdate,@maxdatechoice) rdate 
		,isnull(r.accdate, cast(dateadd(day,datediff(day,0,dateadd(day,-1,getdate())),0) as date)) accdate 
		,isnull(r.Indicator ,s.ind) Indicator
		,isnull(r.[Факт/План] ,s.st) [Факт/План]
		,isnull(r.[Value],0) [Value]
		,isnull(r.[OnOff] ,1) [OnOff]
		,isnull(r.[isChanged] ,1) [isChanged]
		,c2.col2 
into #t0
from #rws_col s
left join #r r on s.ind=r.Indicator and s.st=r.[Факт/План]
join #t_col2 c2 on c2.[period]=r.[period]
where s.st in (N'Факт' ,N'Прогноз')

-- select * from #t0 where [Факт/План]='Факт' order by 7 desc ,1 asc


drop table if exists #t0_deviation
select p.[period]
		,p.rdate 
		,p.accdate 
		,p.Indicator
		,N'% выполнения' as [Факт/План]
		,p.[Value] as [v1]
		,isnull(r.[Value],0) as [v2]
		,case when isnull(p.[Value],0)<>0 then isnull(r.[Value],0)/p.[Value] else 0 end as [Value]
		,1 as [OnOff]
		,1 as [isChanged] 
into #t0_deviation
from (select * from #t0 where [Факт/План]=N'Прогноз') r 
left join (select * from #t0_plan where rdate in (select max(rdate) over(partition by Indicator,[period]) from #t0_plan)) p on p.Indicator=r.Indicator and p.[period]=r.[period]

--select * from #t0_deviation order by accdate desc

-----------------------------------------------------------
-------------------------- N'Показатели продаж'. Текущий месяц

if @PageNo = 1

--select rws ,col ,[period] ,Indicator ,[Факт/План] ,sum([Value]) [Value]
--from #t0_plan
--where [period]= cast(dateadd(month,datediff(month,0,dateadd(day,-1,getdate())),0) as date) --and st in (N'Факт' ,N'Прогноз')
--group by rws ,col ,[period] ,Indicator ,[Факт/План] 
--order by 1

--select rws ,col ,[period] ,Indicator ,[Факт/План] ,[Value]
--from #t0
--where [period]= cast(dateadd(month,datediff(month,0,dateadd(day,-1,getdate())),0) as date) and st in (N'Прогноз')
--order by 1


select rws ,col ,[period] ,Indicator ,[Факт/План] ,sum([Value]) [Value]
from #t0_plan
where [period]= cast(dateadd(month,datediff(month,0,dateadd(day,-1,getdate())),0) as date) and st in (N'План' ,N'Прогноз')
group by rws ,col ,[period] ,Indicator ,[Факт/План] 

union all
select rws ,col ,[period] ,Indicator ,[Факт/План] ,sum([Value]) [Value]
from #t0
where [period]= cast(dateadd(month,datediff(month,0,dateadd(day,-1,getdate())),0) as date) and st in (N'Факт') -- ,N'Прогноз')
group by rws ,col ,[period] ,Indicator ,[Факт/План] 

union all

select rws ,col ,[period] ,Indicator ,[Факт/План] ,[Value]
from #t0
where [period]= cast(dateadd(month,datediff(month,0,dateadd(day,-1,getdate())),0) as date) and st in (N'Прогноз')-- ,N'Прогноз')
order by 1

-------------------------- N'Показатели продаж'. История 1 год назад

if @PageNo = 2
/*
select rws ,col2 ,[period] ,Indicator ,[Факт/План] ,sum([Value]) [Value]
from #t0_plan
where [period] < cast(dateadd(month,datediff(month,0,dateadd(day,-1,getdate())),0) as date) and st in (N'План' ,N'Прогноз')
group by rws ,col2 ,[period] ,Indicator ,[Факт/План] 

union all
*/
select rws ,col2 ,[period] ,Indicator ,[Факт/План] ,sum([Value]) [Value]
from #t0
where [period] < cast(dateadd(month,datediff(month,0,dateadd(day,-1,getdate())),0) as date) and st in (N'Факт') -- ,N'Прогноз')
group by rws ,col2 ,[period] ,Indicator ,[Факт/План] 

union all

select rws ,col2 ,[period] ,Indicator ,[Факт/План] ,[Value]
from #t0
where [period] < cast(dateadd(month,datediff(month,0,dateadd(day,-1,getdate())),0) as date) and st in (N'Прогноз')-- ,N'Прогноз')
order by 1

/*
-----------------------------------------------------------
-------------------------- N'Показатели портфеля'. Текущий месяц
if @PageNo = 3



-------------------------- N'Показатели портфеля'. История 1 год назад
if @PageNo = 4



-----------------------------------------------------------
-------------------------- N'Показатели портфеля'. Текущий месяц
if @PageNo = 5



-------------------------- N'Показатели портфеля'. История 1 год назад
if @PageNo = 5


*/

END

