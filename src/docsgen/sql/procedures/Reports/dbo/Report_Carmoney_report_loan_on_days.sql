-- =============================================
-- Author:		Kurdin S
-- Create date: 2019-05-07
-- Description:	Отчет о займах и действующих процентных ставках по данным МФО 

-- =============================================

CREATE PROCEDURE [dbo].[Report_Carmoney_report_loan_on_days]
	-- Add the parameters for the stored procedure here

@PageNo int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET DATEFIRST 1;

declare @currweek int, @curryear int, @lastweek int, @lastyear int

set @currweek = case when datepart(dw,getdate())=1 then datepart(ww,dateadd(week,-1,getdate())) else datepart(ww,getdate()) end;
set @curryear = case when datepart(dw,getdate())=1 then datepart(yyyy,dateadd(week,-1,getdate())) else datepart(yyyy,getdate()) end;

set @lastweek = case when datepart(dw,getdate())=1 then datepart(ww,dateadd(week,-2,getdate())) else datepart(ww,dateadd(week,-1,getdate())) end;
set @lastyear = case when datepart(dw,getdate())=1 then datepart(yyyy,dateadd(week,-2,getdate())) else datepart(yyyy,dateadd(week,-1,getdate())) end;

drop table if exists #DayWeek
select cast(created as date) as dt
	   ,case 
			when datepart(dw,created) = 1 then N'Пн'
			when datepart(dw,created) = 2 then N'Вт'
			when datepart(dw,created) = 3 then N'Ср'
			when datepart(dw,created) = 4 then N'Чт'
			when datepart(dw,created) = 5 then N'Пт'
			when datepart(dw,created) = 6 then N'Сб'
			when datepart(dw,created) = 7 then N'Вк'
		end [DayWeek]
		, datepart(ww,created) as [wk]
into #DayWeek
from dwh_new.dbo.calendar where (datepart(ww,created) = @lastweek and datepart(yyyy,created) = @lastyear) 
										or (datepart(ww,created) = @currweek and datepart(yyyy,created) = @curryear)


if object_id('tempdb.dbo.#Tstruct_2') is not null drop table #Tstruct_2;
create table #Tstruct_2(rws int null ,[Term] nvarchar(255) null);
insert into #Tstruct_2 (rws ,[Term])
values 	(1 ,N'12'),	(2 ,N'24'),	(3 ,N'36') ,(4 ,N'48') ,(5 ,N'60'),	(6 ,N'Прочее'),	(7 ,N'ВСЕГО')

drop table if exists #nulltable
select d.* ,s.* into #nulltable from #DayWeek d cross join #Tstruct_2 s 
order by 1 ,3 

drop table if exists #maxdayweek
select max(dt) max_dt ,[wk] into #maxdayweek from #DayWeek group by [wk]

drop table if exists #Tstruct
select case when not cast([Term] as nvarchar(10)) in (12 ,24 ,36 ,48 ,60) then N'Прочее' else cast([Term] as nvarchar(10)) end [Term_key]
	   ,[Term]
		--,[Indicator] --,[Факт/План]
into #Tstruct
from [dwh_new].[dbo].[mt_report_loans_on_days] 
group by [Term] --,[Indicator] --,[Факт/План]
order by 1


drop table if exists #thisweek
select 1 as l ,[cdate] ,datepart(ww,cdate) dt_week ,cast([Term] as nvarchar(10)) [Term] ,[Indicator] ,[Факт/План] ,sum([Value]) as [Value]
into #thisweek
from [dwh_new].[dbo].[mt_report_loans_on_days] 
where datepart(ww,cdate)=@currweek and datepart(yyyy,cdate)=@curryear
group by [cdate] ,cast([Term] as nvarchar(10)) ,[Indicator] ,[Факт/План]

union all
select 1 as l ,[cdate] ,datepart(ww,cdate) dt_week ,N'ВСЕГО' [Term] ,[Indicator] ,[Факт/План] ,sum([Value]) as [Value]
--into #thisweek0
from [dwh_new].[dbo].[mt_report_loans_on_days] 
where datepart(ww,cdate)=@currweek and datepart(yyyy,cdate)=@curryear
group by [cdate] ,datepart(ww,cdate) ,[Indicator] ,[Факт/План]



drop table if exists #lastweek
select 1 as l ,[cdate] ,datepart(ww,cdate) dt_week ,cast([Term] as nvarchar(10)) [Term] ,[Indicator] ,[Факт/План] ,sum([Value]) as [Value]
into #lastweek
from [dwh_new].[dbo].[mt_report_loans_on_days] 
where datepart(ww,cdate)=@lastweek and datepart(yyyy,cdate)=@lastyear
group by [cdate] ,[Term] ,[Indicator] ,[Факт/План]
--order by [cdate]
union all
select 1 as l ,[cdate] ,datepart(ww,cdate) dt_week ,N'ВСЕГО' [Term] ,[Indicator] ,[Факт/План] ,sum([Value]) as [Value]
--into #lastweek
from [dwh_new].[dbo].[mt_report_loans_on_days] 
where datepart(ww,cdate)=@lastweek and datepart(yyyy,cdate)=@lastyear
group by [cdate] ,datepart(ww,cdate) ,[Indicator] ,[Факт/План]

--select * from #lastweek  order by [cdate] 



--	Итог за неделю
drop table if exists #res_thisweek
select 2 as l ,m.max_dt cdate ,dt_week ,[Term] ,[Indicator] ,[Факт/План] ,sum(isnull([Value],0)) as [Value]
into #res_thisweek 
from #thisweek tw /*where [Indicator]=N'Займы шт День'*/ 
left join #maxdayweek m on tw.dt_week=m.wk
where not m.max_dt is null
group by m.max_dt ,dt_week ,[Term] ,[Indicator] ,[Факт/План]



drop table if exists #res_lastweek
select 2 as l ,m.max_dt cdate ,dt_week ,[Term] ,[Indicator] ,[Факт/План] ,sum(isnull([Value],0)) as [Value] --,N'Предыдущая неделя' as [ЭтоНеделя]
into #res_lastweek 
from #lastweek lw /*where [Indicator]=N'Займы шт День'*/ 
left join #maxdayweek m on lw.dt_week=m.wk
where not m.max_dt is null
group by m.max_dt ,dt_week ,[Term] ,[Indicator] ,[Факт/План]


------------------------------------------
------------------------------------------

drop table if exists #enteringtable
select lw.* 
into #enteringtable 
from #lastweek lw --where [Indicator]=N'Займы шт День' --order by [cdate] desc
union all
select rlw.* from #res_lastweek rlw --where [Indicator]=N'Займы шт День'
union all
select tw.* from #thisweek tw --where [Indicator]=N'Займы шт День' --order by [cdate] desc
union all
select rtw.* from #res_thisweek rtw --where [Indicator]=N'Займы шт День'


------------------------------------------


drop table if exists #t_exit
select n.dt ,n.DayWeek ,n.wk ,n.rws ,n.Term 
		,isnull(e.l,1) l ,isnull(e.cdate ,n.dt) cdate ,isnull(e.dt_week ,n.wk) dt_week ,isnull(e.Term ,n.Term) Term2 
		,isnull(e.Indicator ,N'') Indicator ,isnull(e.[Факт/План] ,N'Факт') [Факт/План] ,isnull(e.[Value] ,0) [Value] 
into #t_exit
from #nulltable n
left join #enteringtable e on n.dt=e.cdate and n.Term=e.Term

-- select * from #t_exit

drop table if exists #t1_qty
select dt ,DayWeek ,wk ,rws ,Term 
		,l ,cdate ,dt_week ,Term2 
		,case when Indicator = N'' then N'Займы шт День' else Indicator end as Indicator 
		,[Факт/План] ,[Value]
		,case when l=1 then DayWeek else N'ИТОГО' end as [Колонка] 
		,case when dt_week=@currweek then N'Текущая неделя' else N'Предыдущая неделя' end as [ЭтоНеделя] 
into #t1_qty 
from #t_exit
where /*not [Indicator] is null and*/ [Indicator] in (N'Займы шт День' ,N'')

drop table if exists #t1_sum
select dt ,DayWeek ,wk ,rws ,Term 
		,l ,cdate ,dt_week ,Term2 
		,case when Indicator = N'' then N'Займы руб День' else Indicator end as Indicator 
		,[Факт/План] ,[Value]
		,case when l=1 then DayWeek else N'ИТОГО' end as [Колонка] 
		,case when dt_week=@currweek then N'Текущая неделя' else N'Предыдущая неделя' end as [ЭтоНеделя] 
into #t1_sum 
from #t_exit
where /*not [Indicator] is null and*/ [Indicator] in (N'Займы руб День' ,N'')

drop table if exists #t1_av
select q.dt ,q.DayWeek ,q.wk ,q.rws ,q.Term 
		,q.l ,q.cdate ,q.dt_week ,q.Term2 
		,N'Средней чек' as Indicator 
		,q.[Факт/План] 
		,case when isnull(q.[Value],0)=0 then 0 else ceiling(s.[Value]/q.[Value]) end as [Value]
		,case when q.l=1 then q.DayWeek else N'ИТОГО' end as [Колонка] 
		,case when q.dt_week=@currweek then N'Текущая неделя' else N'Предыдущая неделя' end as [ЭтоНеделя] 
into #t1_av 
from #t1_qty q
join #t1_sum s on q.dt=s.dt and q.Term2 = s.Term2 and q.[Колонка]=s.[Колонка] and q.[Факт/План]=s.[Факт/План]		--,DayWeek ,wk ,rws ,Term ,l ,cdate ,dt_week 

--select * from #t1_av


-----------------------------------------------------------
-------------------------- N'Займы кол-во'

if @PageNo = 1

select t1.* ,rank() over(partition by Indicator order by wk desc ,dt asc ,l asc) as [rankk]  
from #t1_qty t1 order by 1,6,13,4


-----------------------------------------------------------
-------------------------- N'Займы суммы'
if @PageNo = 2

select t1.* ,rank() over(partition by Indicator order by wk desc ,dt asc ,l asc) as [rankk]  
from #t1_sum t1 order by 1,6,13,4


-----------------------------------------------------------
-------------------------- N'Займы средняя сумма'
if @PageNo = 3

select t1.* ,rank() over(partition by Indicator order by wk desc ,dt asc ,l asc) as [rankk]  
from #t1_av t1 order by 1,6,13,4



END

