-- exec [dbo].[report_ITILRequests_SLA] 


CREATE  PROCEDURE  [dbo].[report_ITILRequests_SLA] 

@PageNo int

AS
BEGIN
	SET NOCOUNT ON;

	--24.03.2020
	SET DATEFIRST 1;


    -- Insert statements for procedure here

 --   select * from   [Stg].[files].[CC_DailyPlans] 

--if object_id('tempdb.dbo.#tt') is not null drop table #tt

declare @dt date

set @dt = cast(dateadd(day,datediff(day,0,dateadd(day,0,getdate())),0) as date);
 
 
drop table if exists #structure_col
create table #structure_col([num_col] int null ,[Col_name] nvarchar(100) null)
insert into #structure_col
values 
(1 ,'Закрыты в текущем периоде с соблюдением SLA')
,(2 ,'Закрыты в текущем периоде с нарушением SLA')
,(3 ,'Поступившие за текущий период')
,(4 ,'Не закрытые на начало периода')
,(5 ,'Закрытые в текущем периоде, у которых SLA в прошлых периодах')


drop table if exists #empl_exception
select 
	   [Ссылка] 
	   ,[Наименование] empl
into #empl_exception
from [Stg].[_1cItil].[Справочник_Пользователи]
where [Недействителен]=0x01

drop table if exists #group_user_empl
select distinct
		[ГруппаПользователей] UserGroup
		,isnull(employee,'') employee
		,[ТипОбращения]
into #group_user_empl
from [dbo].[dm_ITILRequest]

--select * from [dbo].[dm_ITILRequest]

drop table if exists #calendar
select 
		created dt
		,datepart(week ,created) wdt
		,datepart(mm ,created) mdt
		,datepart(quarter ,created) qdt
		,case when datepart(mm ,created) <= 6 then 1 else 2 end hydt
		,datepart(year ,created) ydt
into #calendar
from dwh_new.dbo.calendar
where created >= dateadd(year,datediff(year,0,Getdate()),0) and created <= Getdate()

drop table if exists #calendar_empl
select
		c.*
		,e.*
into #calendar_empl
from #calendar c
cross join #group_user_empl e


----------------------------------------------
----- Показатели для расчета -----------------
----------------------------------------------

--------- В числителе

-------------------------- По неделям
------- Закрыты в текущем периоде с соблюдением SLA

drop table if exists #execution_SLA
select 
		r.[Ссылка]
      ,[ПометкаУдаления]
	  ,dt_open
      ,[Номер]
	  ,dt_sla0
	  ,dt_sla
	  ,datepart(ww,dt_sla) w_dt_sla
	  ,dt_close0
	  ,dt_close
	  ,datepart(ww,dt_close) w_dt_close
	  ,case 
	   when dt_sla is null then 0
	   when dt_close is null then 1
	   when dt_sla < dt_close then -1
	   when dt_sla >= dt_close then 1
	   end as SLA
	  ,isnull(employee,'') employee
	  ,[ТипОбращения]
	  ,[ГруппаПользователей]
into #execution_SLA	
from [dbo].[dm_ITILRequest] r
left join #empl_exception e on e.[empl]=r.[employee]
where not e.[empl] is null
order by 3 desc
-- select * from #execution_SLA


------- Закрыты в текущем периоде с соблюдением SLA
drop  table if exists #observance_SLA
select
		'Закрыты в текущем периоде с соблюдением SLA' [Indicator]

		,c.wdt
		,c.mdt
		,c.qdt
		,c.hydt
		,c.ydt

		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]

		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
into #observance_SLA
from #calendar c
left join #execution_SLA s on cast(c.dt as date) =cast(s.dt_close as date) and SLA = 1
where not s.[Номер] is null
group by 
grouping sets
(
(c.wdt ,c.ydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей])
, (c.mdt ,c.ydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей])
, (c.qdt ,c.ydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей])
, (c.hydt ,c.ydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей])
, (c.ydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей])
)

--  select * from #observance_SLA

-- Закрыты в текущем периоде с нарушением SLA
drop  table if exists #violation_SLA
select
		'Закрыты в текущем периоде с нарушением SLA' [Indicator]

		,c.wdt
		,c.mdt
		,c.qdt
		,c.hydt
		,c.ydt

		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]

		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
into #violation_SLA
from #calendar c
left join #execution_SLA s on cast(c.dt as date) =cast(s.dt_close as date) and SLA = -1
where not s.[Номер] is null
group by 
grouping sets
(
(c.wdt ,c.ydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей])
, (c.mdt ,c.ydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей])
, (c.qdt ,c.ydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей])
, (c.hydt ,c.ydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей])
, (c.ydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей])
)

--  select * from #violation_SLA



--------- В знаменателе

------- поступившие в текущий период

drop  table if exists #received_current_period
select
		--c.*
		'Поступившие за текущий период' [Indicator]
		,'Неделя' [Периодичность]

		,c.ydt	[acc_year]	
		,c.wdt

		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
into #received_current_period
from #calendar c
left join #execution_SLA s on c.wdt = datepart(w,s.dt_open) and c.ydt = datepart(yyyy ,s.dt_open)
group by c.ydt ,c.wdt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]

union all
select
		'Поступившие за текущий период' [Indicator]
		,'Месяц' [Периодичность]

		,c.ydt	[acc_year]			
		,c.mdt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
from #calendar c
left join #execution_SLA s on c.mdt = datepart(mm,s.dt_open) and c.ydt = datepart(yyyy ,s.dt_open)
where not s.[Номер] is null
group by c.ydt ,c.mdt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]

union all
select
		'Поступившие за текущий период' [Indicator]
		,'Квартал' [Периодичность]

		,c.ydt	[acc_year]			
		,c.qdt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
from #calendar c
left join #execution_SLA s on c.qdt = datepart(quarter,s.dt_open) and c.ydt = datepart(yyyy ,s.dt_open)
where not s.[Номер] is null
group by c.ydt ,c.qdt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]

union all
select
		'Поступившие за текущий период' [Indicator]
		,'Полгода' [Периодичность]

		,c.ydt	[acc_year]			
		,c.hydt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
from #calendar c
left join #execution_SLA s on c.hydt = (case when datepart(mm ,s.dt_open) <= 6 then 1 else 2 end) and c.ydt = datepart(yyyy ,s.dt_open)
where not s.[Номер] is null
group by c.ydt ,c.hydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]

union all
select
		'Поступившие за текущий период' [Indicator]
		,'Год' [Периодичность]

		,c.ydt	[acc_year]			
		,c.ydt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
from #calendar c
left join #execution_SLA s on c.ydt = datepart(yyyy,s.dt_open)
where not s.[Номер] is null
group by c.ydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]




------- Не закрытые на начало периода
drop  table if exists #not_closed_before
select
		'Не закрытые на начало периода' [Indicator]
		,'Неделя' [Периодичность]

		,c.ydt	[acc_year]
		,c.wdt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty

into #not_closed_before
from #calendar c
left join #execution_SLA s on c.wdt < datepart(w,s.dt_open) and  c.wdt <= datepart(w,s.dt_close)
group by c.ydt ,c.wdt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]

union all
select
		'Не закрытые на начало периода' [Indicator]
		,'Месяц' [Периодичность]

		,c.ydt	[acc_year]
		,c.mdt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
from #calendar c
left join #execution_SLA s on c.mdt < datepart(mm,s.dt_open) and  c.mdt <= datepart(mm,s.dt_close)
where not s.[Номер] is null
group by c.ydt ,c.mdt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]

union all
select
		'Не закрытые на начало периода' [Indicator]
		,'Квартал' [Периодичность]

		,c.ydt	[acc_year]
		,c.qdt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
from #calendar c
left join #execution_SLA s on c.qdt < datepart(quarter,s.dt_open) and  c.qdt <= datepart(quarter,s.dt_close)
where not s.[Номер] is null
group by c.ydt ,c.qdt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]

union all
select
		'Закрытые в текущем периоде, у которых SLA в прошлых периодах' [Indicator]
		,'Полгода' [Периодичность]

		,c.ydt	[acc_year]
		,c.hydt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
from #calendar c
left join #execution_SLA s on c.hydt = (case when datepart(mm ,s.dt_close) <= 6 then 1 else 2 end) and c.hydt > (case when datepart(mm ,s.dt_sla) <= 6 then 1 else 2 end)
where not s.[Номер] is null
group by c.ydt ,c.hydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]

union all
select
		'Не закрытые на начало периода' [Indicator]
		,'Год' [Периодичность]

		,c.ydt	[acc_year]
		,c.ydt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
from #calendar c
left join #execution_SLA s on c.ydt < datepart(yyyy,s.dt_open) and  c.ydt <= datepart(yyyy,s.dt_close)
where not s.[Номер] is null
group by c.ydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]


------- Закрытые в текущем периоде, у которых SLA в прошлых периодах
drop  table if exists #closed_but_minusSLA
select
		'Закрытые в текущем периоде, у которых SLA в прошлых периодах' [Indicator]
		,'Неделя' [Периодичность]

		,c.ydt	[acc_year]
		,c.wdt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
into #closed_but_minusSLA
from #calendar c
left join #execution_SLA s on c.wdt = datepart(w,s.dt_close) and c.wdt > datepart(w,s.dt_sla)
group by c.ydt ,c.wdt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]

union all
select
		'Закрытые в текущем периоде, у которых SLA в прошлых периодах' [Indicator]
		,'Месяц' [Периодичность]

		,c.ydt	[acc_year]
		,c.mdt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty

from #calendar c
left join #execution_SLA s on c.mdt = datepart(mm,s.dt_close) and c.mdt > datepart(mm,s.dt_sla)
where not s.[Номер] is null
group by c.ydt ,c.mdt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]

union all
select
		'Закрытые в текущем периоде, у которых SLA в прошлых периодах' [Indicator]
		,'Квартал' [Периодичность]

		,c.ydt	[acc_year]
		,c.qdt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
from #calendar c
left join #execution_SLA s on c.qdt = datepart(quarter,s.dt_close) and c.qdt > datepart(quarter,s.dt_sla)
where not s.[Номер] is null
group by c.ydt ,c.qdt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]

union all
select
		'Закрытые в текущем периоде, у которых SLA в прошлых периодах' [Indicator]
		,'Полгода' [Периодичность]

		,c.ydt	[acc_year]
		,c.hydt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
from #calendar c
left join #execution_SLA s on c.hydt = (case when datepart(mm ,s.dt_close) <= 6 then 1 else 2 end) and c.hydt > (case when datepart(mm ,s.dt_sla) <= 6 then 1 else 2 end)
where not s.[Номер] is null
group by c.ydt ,c.hydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]

union all
select
		'Закрытые в текущем периоде, у которых SLA в прошлых периодах' [Indicator]
		,'Год' [Периодичность]

		,c.ydt	[acc_year]
		,c.ydt
		,s.employee
		,s.[ТипОбращения]
		,s.[ГруппаПользователей] [UserGroup]
		,count(s.[Номер]) Qty
		,count(distinct s.[Номер]) uniqQty
from #calendar c
left join #execution_SLA s on c.ydt = datepart(yyyy,s.dt_close) and c.ydt > datepart(yyyy,s.dt_sla)
where not s.[Номер] is null
group by c.ydt ,s.employee ,s.[ТипОбращения] ,s.[ГруппаПользователей]

/*
select * from #observance_SLA
select * from #violation_SLA

select * from #received_current_period
union all
select * from #not_closed_before
union all
select * from #closed_but_minusSLA
*/





if @PageNo = 1
------- По неделям

with t0 as
(
--drop  table if exists #t0
select
[Период]			= c.wdt
, [Год]				= c.ydt
, [Подразделение]	= c.UserGroup
, [Сотрудник]		= c.employee
, [Тип обращения]	= c.[ТипОбращения]

, [Закрыты в текущем периоде с соблюдением SLA]
		= isnull((select sum(uniqQty) -- select *
				  from #observance_SLA 
				  where mdt is null and qdt is null and hydt is null and ydt=c.ydt and wdt=c.wdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Закрыты в текущем периоде с нарушением SLA]	
		= isnull((select uniqQty --select *
				  from #violation_SLA 
				  where mdt is null and qdt is null and hydt is null and ydt=c.ydt and wdt=c.wdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Поступившие за текущий период]	
		= isnull((select sum(uniqQty) 
				  from #received_current_period 
				  where acc_year=c.ydt and wdt=c.wdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Не закрытые на начало периода]	
		= isnull((select sum(uniqQty) 
				  from #not_closed_before 
				  where acc_year=c.ydt and wdt=c.wdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Закрытые в текущем периоде, у которых SLA в прошлых периодах]
		= isnull((select sum(uniqQty) --select *
				  from #closed_but_minusSLA 
				  where acc_year=c.ydt and wdt=c.wdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
--into #t0
--select *
from (select distinct wdt ,ydt ,UserGroup ,employee ,[ТипОбращения] from #calendar_empl) c
)

select 
		t.*
		,[SLA]	= (case 
					when ([Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах]) <> 0
						then 
						(cast(([Закрыты в текущем периоде с соблюдением SLA]+[Закрыты в текущем периоде с нарушением SLA]) as float)
							/
						cast(([Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах]) as float))
					else 0.00
				 end)
from t0 t
where ([Закрыты в текущем периоде с соблюдением SLA]+[Закрыты в текущем периоде с нарушением SLA]+[Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах])<>0


/*

(1 ,'Закрыты в текущем периоде с соблюдением SLA')
,(2 ,'Закрыты в текущем периоде с нарушением SLA')
,(3 ,'Поступившие за текущий период')
,(4 ,'Не закрытые на начало периода')
,(5 ,'Закрытые в текущем периоде, у которых SLA в прошлых периодах')
*/



if @PageNo = 2
------- По месяцам

with t0 as
(
--drop  table if exists #t0
select
[Период]			= c.mdt
, [Год]				= c.ydt
, [Подразделение]	= c.UserGroup
, [Сотрудник]		= c.employee
, [Тип обращения]	= c.[ТипОбращения]

, [Закрыты в текущем периоде с соблюдением SLA]
		= isnull((select sum(uniqQty) -- select *
				  from #observance_SLA 
				  where wdt is null and qdt is null and hydt is null and ydt=c.ydt and mdt=c.mdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Закрыты в текущем периоде с нарушением SLA]	
		= isnull((select uniqQty --select *
				  from #violation_SLA 
				  where wdt is null and qdt is null and hydt is null and ydt=c.ydt and mdt=c.mdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Поступившие за текущий период]	
		= isnull((select sum(uniqQty) 
				  from #received_current_period 
				  where acc_year=c.ydt and mdt=c.mdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Не закрытые на начало периода]	
		= isnull((select sum(uniqQty) 
				  from #not_closed_before 
				  where acc_year=c.ydt and mdt=c.mdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Закрытые в текущем периоде, у которых SLA в прошлых периодах]
		= isnull((select sum(uniqQty) --select *
				  from #closed_but_minusSLA 
				  where acc_year=c.ydt and mdt=c.mdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
--into #t0
--select *
from (select distinct mdt ,ydt ,UserGroup ,employee ,[ТипОбращения] from #calendar_empl) c
)

select 
		t.*
		,[SLA]	= (case 
					when ([Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах]) <> 0
						then
						(cast(([Закрыты в текущем периоде с соблюдением SLA]+[Закрыты в текущем периоде с нарушением SLA]) as float)
							/
						cast(([Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах]) as float))
					else 0
				 end)
from t0 t
where ([Закрыты в текущем периоде с соблюдением SLA]+[Закрыты в текущем периоде с нарушением SLA]+[Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах])<>0



if @PageNo = 3
------- По кварталам

with t0 as
(
--drop  table if exists #t0
select
[Период]			= c.qdt
, [Год]				= c.ydt
, [Подразделение]	= c.UserGroup
, [Сотрудник]		= c.employee
, [Тип обращения]	= c.[ТипОбращения]

, [Закрыты в текущем периоде с соблюдением SLA]
		= isnull((select sum(uniqQty) -- select *
				  from #observance_SLA 
				  where wdt is null and mdt is null and hydt is null and ydt=c.ydt and qdt=c.qdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)

, [Закрыты в текущем периоде с нарушением SLA]	
		= isnull((select uniqQty --select *
				  from #violation_SLA 
				  where wdt is null and mdt is null and hydt is null and ydt=c.ydt and qdt=c.qdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)

, [Поступившие за текущий период]	
		= isnull((select sum(uniqQty) 
				  from #received_current_period 
				  where acc_year=c.ydt and qdt=c.qdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)

, [Не закрытые на начало периода]	
		= isnull((select sum(uniqQty) 
				  from #not_closed_before 
				  where acc_year=c.ydt and qdt=c.qdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)

, [Закрытые в текущем периоде, у которых SLA в прошлых периодах]
		= isnull((select sum(uniqQty) --select *
				  from #closed_but_minusSLA 
				  where acc_year=c.ydt and qdt=c.qdt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)

--into #t0
--select *
from (select distinct qdt ,ydt ,UserGroup ,employee ,[ТипОбращения] from #calendar_empl) c
)

select 
		t.*
		,[SLA]	= (case 
					when ([Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах]) <> 0
						then
						(cast(([Закрыты в текущем периоде с соблюдением SLA]+[Закрыты в текущем периоде с нарушением SLA]) as float)
							/
						cast(([Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах]) as float))
					else 0
				 end)
from t0 t
where ([Закрыты в текущем периоде с соблюдением SLA]+[Закрыты в текущем периоде с нарушением SLA]+[Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах])<>0



if @PageNo = 4
------- По полугодиям

with t0 as
(
--drop  table if exists #t0
select
[Период]			= c.hydt
, [Год]				= c.ydt
, [Подразделение]	= c.UserGroup
, [Сотрудник]		= c.employee
, [Тип обращения]	= c.[ТипОбращения]

, [Закрыты в текущем периоде с соблюдением SLA]
		= isnull((select sum(uniqQty) -- select *
				  from #observance_SLA 
				  where wdt is null and mdt is null and qdt is null and ydt=c.ydt and hydt=c.hydt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Закрыты в текущем периоде с нарушением SLA]	
		= isnull((select uniqQty --select *
				  from #violation_SLA 
				  where wdt is null and mdt is null and qdt is null and ydt=c.ydt and hydt=c.hydt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Поступившие за текущий период]	
		= isnull((select sum(uniqQty) 
				  from #received_current_period 
				  where acc_year=c.ydt and hydt=c.hydt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Не закрытые на начало периода]	
		= isnull((select sum(uniqQty) 
				  from #not_closed_before 
				  where acc_year=c.ydt and hydt=c.hydt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Закрытые в текущем периоде, у которых SLA в прошлых периодах]
		= isnull((select sum(uniqQty) --select *
				  from #closed_but_minusSLA 
				  where acc_year=c.ydt and hydt=c.hydt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
--into #t0
--select *
from (select distinct hydt ,ydt ,UserGroup ,employee ,[ТипОбращения] from #calendar_empl) c
)

select 
		t.*
		,[SLA]	= (case 
					when ([Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах]) <> 0
						then
						(cast(([Закрыты в текущем периоде с соблюдением SLA]+[Закрыты в текущем периоде с нарушением SLA]) as float)
							/
						cast(([Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах]) as float))
					else 0
				 end)
from t0 t
where ([Закрыты в текущем периоде с соблюдением SLA]+[Закрыты в текущем периоде с нарушением SLA]+[Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах])<>0



if @PageNo = 5
------- По годам

with t0 as
(
--drop  table if exists #t0
select
[Период]			= c.hydt
, [Год]				= c.ydt
, [Подразделение]	= c.UserGroup
, [Сотрудник]		= c.employee
, [Тип обращения]	= c.[ТипОбращения]

, [Закрыты в текущем периоде с соблюдением SLA]
		= isnull((select sum(uniqQty) -- select *
				  from #observance_SLA 
				  where wdt is null and mdt is null and qdt is null and hydt is null and ydt=c.ydt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Закрыты в текущем периоде с нарушением SLA]	
		= isnull((select uniqQty --select *
				  from #violation_SLA 
				  where wdt is null and mdt is null and qdt is null and hydt is null and ydt=c.ydt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Поступившие за текущий период]	
		= isnull((select sum(uniqQty) 
				  from #received_current_period 
				  where acc_year=c.ydt and hydt=c.hydt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Не закрытые на начало периода]	
		= isnull((select sum(uniqQty) 
				  from #not_closed_before 
				  where acc_year=c.ydt and hydt=c.hydt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
, [Закрытые в текущем периоде, у которых SLA в прошлых периодах]
		= isnull((select sum(uniqQty) --select *
				  from #closed_but_minusSLA 
				  where acc_year=c.ydt and hydt=c.hydt and UserGroup=c.UserGroup and employee=c.employee and [ТипОбращения]=c.[ТипОбращения])
				  ,0)
--into #t0
--select *
from (select distinct hydt ,ydt ,UserGroup ,employee ,[ТипОбращения] from #calendar_empl) c
)

select 
		t.*
		,[SLA]	= (case 
					when ([Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах]) <> 0
						then
						(cast(([Закрыты в текущем периоде с соблюдением SLA]+[Закрыты в текущем периоде с нарушением SLA]) as float)
							/
						cast(([Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах]) as float))
					else 0
				 end)
from t0 t
where ([Закрыты в текущем периоде с соблюдением SLA]+[Закрыты в текущем периоде с нарушением SLA]+[Поступившие за текущий период] + [Не закрытые на начало периода] + [Закрытые в текущем периоде, у которых SLA в прошлых периодах])<>0




END
