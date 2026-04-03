
-- dwh-563
--exec [dbo].[reportFedor_Employee_Activity_dwh563_v1]  'KD.Daily' 
CREATE PROC dbo.reportFedor_Employee_Activity_dwh563_v1
    @page nvarchar(20)
  , @DtFrom date = null
  , @DtTo date =null
AS
BEGIN
	
	SET NOCOUNT ON;
  if @dtFrom is null 
    set @dtFrom='20200901'

  if @dtTo is null
    set @DtTo=getdate()

	-- сотрудники КД
	drop table if exists #curr_employee_cd
	create table #curr_employee_cd([Employee] nvarchar(255))

	INSERT #curr_employee_cd(Employee)
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
		AND (U.IsDeleted = 0
			OR (U.IsDeleted = 1 AND U.DeleteDate >= @dtFrom)
		)
		AND UR.IsDeleted = 0
		AND R.Name IN ('Чекер')
	union 
	select Employee 
	from (
		select Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
			,DeleteDate = case id
				when '244F6B46-49D8-4E11-B68D-05C5D7A9C8BC' then '2023-03-31'
				when '6FE99E14-F925-4F62-BC3B-D8FFD8D82B98' then '2024-04-23'
			end
		from Stg._fedor.core_user u
		where Id in(
			'244F6B46-49D8-4E11-B68D-05C5D7A9C8BC', --Жарких Марина Павловна
			'6FE99E14-F925-4F62-BC3B-D8FFD8D82B98' --Короткова Евгения Игоревна --обращение #prod 25 апреля 2024 г. a.zaharov 11:22
			)
	) u
	where U.DeleteDate >= @dtFrom


	-- Верификаторы
	drop table if exists #curr_employee_vr
	create table #curr_employee_vr([Employee] nvarchar(255))

	INSERT #curr_employee_vr(Employee)
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
		AND (U.IsDeleted = 0
			OR (U.IsDeleted = 1 AND U.DeleteDate >= @dtFrom)
		)
		AND UR.IsDeleted = 0
		AND R.Name IN ('Верификатор')

  drop table if exists #log

  /*
  select cast(a.createdOn as date) Date,
       LastName   + N' '
       + FirstName + N' '
       + MiddleName FIO
       , dateadd(hour,3,a.CreatedOn) StartDateTime
       , dateadd(hour,3,StopDateTime) StopDateTime
       --, datediff(second,a.CreatedOn,StopDateTime) duration
       , Name Activity
       ,case when kd.employee is not null then 'Контроль данных' 
             when v.employee is not null then 'Верификация' 
             when kd.employee is not null  and v.employee is not null then 'Контроль данных и Верификация' 
             else '-'
        end Stage
    into #log
    from [Stg].[_fedor].[core_UserActivity]  a
    left join  [Stg].[_fedor].[core_UserActivityDictionary] d on a.[IdActivity]=d.[Id] 
    left join [Stg].[_fedor].[core_user] u on a.[IdOwner]=u.[Id]

	--исправление по обращению Юлия Сидорова @Yu.Sidorova 2023-04-09 07:25
    --left join feodor.dbo.KDEmployees kd on kd.employee=(LastName   + N' '+ FirstName + N' '+ MiddleName) collate Cyrillic_General_CI_AS
    left join #curr_employee_cd kd on kd.Employee=(LastName   + N' '+ FirstName + N' '+ MiddleName) collate Cyrillic_General_CI_AS
    --left join feodor.dbo.Vemployees v on v.employee=(LastName   + N' '+ FirstName + N' '+ MiddleName) collate Cyrillic_General_CI_AS
    left join #curr_employee_vr v on v.Employee=(LastName   + N' '+ FirstName + N' '+ MiddleName) collate Cyrillic_General_CI_AS
	
   where a.CreatedOn>'20200901' and  a.IsDeleted<>1
   and a.CreatedOn>@dtFrom and a.CreatedOn<dateadd(day,1,@DtTo)
   */

	--1 'Контроль данных'
  select cast(a.createdOn as date) Date,
       LastName   + N' '
       + FirstName + N' '
       + MiddleName FIO
       , dateadd(hour,3,a.CreatedOn) StartDateTime
       , dateadd(hour,3,StopDateTime) StopDateTime
       --, datediff(second,a.CreatedOn,StopDateTime) duration
       , Name Activity
       --,case when kd.employee is not null then 'Контроль данных' 
       --      when v.employee is not null then 'Верификация' 
       --      when kd.employee is not null  and v.employee is not null then 'Контроль данных и Верификация' 
       --      else '-'
       -- end Stage
		,'Контроль данных' AS Stage
    into #log
    from [Stg].[_fedor].[core_UserActivity]  a
    left join  [Stg].[_fedor].[core_UserActivityDictionary] d on a.[IdActivity]=d.[Id] 
    left join [Stg].[_fedor].[core_user] u on a.[IdOwner]=u.[Id]

		--исправление по обращению Юлия Сидорова @Yu.Sidorova 2023-04-09 07:25
    --left join feodor.dbo.KDEmployees kd on kd.employee=(LastName   + N' '+ FirstName + N' '+ MiddleName) collate Cyrillic_General_CI_AS
    INNER JOIN #curr_employee_cd kd on kd.Employee=(LastName   + N' '+ FirstName + N' '+ MiddleName) collate Cyrillic_General_CI_AS
    --left join feodor.dbo.Vemployees v on v.employee=(LastName   + N' '+ FirstName + N' '+ MiddleName) collate Cyrillic_General_CI_AS
    --left join #curr_employee_vr v on v.Employee=(LastName   + N' '+ FirstName + N' '+ MiddleName) collate Cyrillic_General_CI_AS
	
   where a.CreatedOn>'20200901' and  a.IsDeleted<>1
   and a.CreatedOn>@dtFrom and a.CreatedOn<dateadd(day,1,@DtTo)


	--2 'Верификация'
	INSERT #log
  select cast(a.createdOn as date) Date,
       LastName   + N' '
       + FirstName + N' '
       + MiddleName FIO
       , dateadd(hour,3,a.CreatedOn) StartDateTime
       , dateadd(hour,3,StopDateTime) StopDateTime
       --, datediff(second,a.CreatedOn,StopDateTime) duration
       , Name Activity
       --,case when kd.employee is not null then 'Контроль данных' 
       --      when v.employee is not null then 'Верификация' 
       --      when kd.employee is not null  and v.employee is not null then 'Контроль данных и Верификация' 
       --      else '-'
       -- end Stage
		,'Верификация' AS Stage
    --into #log
    from [Stg].[_fedor].[core_UserActivity]  a
    left join  [Stg].[_fedor].[core_UserActivityDictionary] d on a.[IdActivity]=d.[Id] 
    left join [Stg].[_fedor].[core_user] u on a.[IdOwner]=u.[Id]

		--исправление по обращению Юлия Сидорова @Yu.Sidorova 2023-04-09 07:25
    --left join feodor.dbo.KDEmployees kd on kd.employee=(LastName   + N' '+ FirstName + N' '+ MiddleName) collate Cyrillic_General_CI_AS
    --left join #curr_employee_cd kd on kd.Employee=(LastName   + N' '+ FirstName + N' '+ MiddleName) collate Cyrillic_General_CI_AS
    --left join feodor.dbo.Vemployees v on v.employee=(LastName   + N' '+ FirstName + N' '+ MiddleName) collate Cyrillic_General_CI_AS
    INNER JOIN #curr_employee_vr v on v.Employee=(LastName   + N' '+ FirstName + N' '+ MiddleName) collate Cyrillic_General_CI_AS
	
   where a.CreatedOn>'20200901' and  a.IsDeleted<>1
   and a.CreatedOn>@dtFrom and a.CreatedOn<dateadd(day,1,@DtTo)


	/*
	Корнеева Вероника Игоревна
	сменила фамилию на
	Столица Вероника Игоревна
	*/
	UPDATE T
	SET FIO = replace(FIO, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна')
	FROM #log AS T




-- лог выполнения
drop table if exists #detail
;
with l as (
  select  Stage
       , Date
       , FIO
       , StartDateTime
       , StopDateTime = case when StopDateTime is null then lead (StartDatetime) over ( partition by  date,fio order by StartDateTime) else StopDateTime end
       , Activity
    from #log 
    
),
l1 as (
      select  Stage
       , Date
       , FIO
       , StartDateTime
       , StopDateTime
       , datediff(second,StartDateTime,StopDateTime) duration
       , Activity

    from l
)
  select  Stage
       , Date
       , FIO
       , StartDateTime
       , StopDateTime
       , duration
       , Activity
       , duration/60/60 hours
       , duration/60 -  60* (duration/60/60) minutes
       , duration - 60 * (duration/60) seconds 
    into #detail
    from l1

  if @page='Detail'
  select Stage, Date, FIO, StartDateTime, StopDateTime
   , format(duration/60/60,'00')+N':'+format(duration/60 -  60* (duration/60/60),'00')+N':'+ format(duration-60*(duration/60),'00') duration
   , Activity, hours, minutes, seconds 
   from #detail
  order by stage,date,fio,StartDateTime




   if @page='KD.Daily'
-- аггрегированные
  select Date=case when Activity='В работе'           then dateadd(hour,1,cast(Date as datetime))
                   when Activity='В ожидании заявки'  then dateadd(hour,2,cast(Date as datetime))
                   when Activity='Пауза'              then dateadd(hour,3,cast(Date as datetime))
               end
       , FIO
       , Activity
       --, sum(duration) duration
       , format(sum(duration)/60/60,'00')+N':'+format(sum(duration)/60 -  60* (sum(duration)/60/60),'00')+N':'+ format(sum(duration)-60*(sum(duration)/60),'00') duration
    from #detail 
    WHERE Stage='Контроль данных' and Activity in ('Пауза' ,'В ожидании заявки','В работе' )
   group by Date
       , FIO
       , Activity
   order by Date, FIO
       , Activity



   if @page='V.Daily'
-- аггрегированные
  select Date=case when Activity='В работе'           then dateadd(hour,1,cast(Date as datetime))
                   when Activity='В ожидании заявки'  then dateadd(hour,2,cast(Date as datetime))
                   when Activity='Пауза'              then dateadd(hour,3,cast(Date as datetime))
               end
       , FIO
       , Activity
       --, sum(duration) duration
       , format(sum(duration)/60/60,'00')+N':'+format(sum(duration)/60 -  60* (sum(duration)/60/60),'00')+N':'+ format(sum(duration)-60*(sum(duration)/60),'00') duration
    from #detail 
    WHERE Stage='Верификация' and Activity in ('Пауза' ,'В ожидании заявки','В работе' )
   group by Date
       , FIO
       , Activity
   order by Date, FIO
       , Activity



        if @page='KD.Monthly'
-- аггрегированные
  select Date=case when Activity='В работе'           then dateadd(hour,1,cast(format(Date,'yyyyMM01') as datetime))
                   when Activity='В ожидании заявки'  then dateadd(hour,2,cast(format(Date,'yyyyMM01') as datetime))
                   when Activity='Пауза'              then dateadd(hour,3,cast(format(Date,'yyyyMM01') as datetime))
               end
       , FIO
       , Activity
       --, sum(duration) duration
       , format(sum(duration)/60/60,'00')+N':'+format(sum(duration)/60 -  60* (sum(duration)/60/60),'00')+N':'+ format(sum(duration)-60*(sum(duration)/60),'00') duration
    from #detail 
    WHERE Stage='Контроль данных' and Activity in ('Пауза' ,'В ожидании заявки','В работе' )
   group by format(Date,'yyyyMM01')
       , FIO
       , Activity
   order by format(Date,'yyyyMM01'), FIO
       , Activity


        if @page='V.Monthly'
-- аггрегированные
  select Date=case when Activity='В работе'           then dateadd(hour,1,cast(format(Date,'yyyyMM01') as datetime))
                   when Activity='В ожидании заявки'  then dateadd(hour,2,cast(format(Date,'yyyyMM01') as datetime))
                   when Activity='Пауза'              then dateadd(hour,3,cast(format(Date,'yyyyMM01') as datetime))
               end
       , FIO
       , Activity
       --, sum(duration) duration
       , format(sum(duration)/60/60,'00')+N':'+format(sum(duration)/60 -  60* (sum(duration)/60/60),'00')+N':'+ format(sum(duration)-60*(sum(duration)/60),'00') duration
    from #detail 
    WHERE Stage='Верификация' and Activity in ('Пауза' ,'В ожидании заявки','В работе' )
   group by format(Date,'yyyyMM01')
       , FIO
       , Activity
   order by format(Date,'yyyyMM01'), FIO
       , Activity



/*

drop table if exists #UserActivity
select distinct
      a.[Id]
	  ,([LastName]+' '+[FirstName]+' '+[MiddleName]) empl
	  ,NaumenLogin
	  ,DomainLogin
      ,a.[CreatedOn]
      ,a.[StopDateTime]
	  ,(cast(isnull(a.[StopDateTime],getdate()) as datetime) - cast(a.[CreatedOn] as datetime)) tm
	  ,(cast(cast(isnull(a.[StopDateTime],getdate()) as datetime) as decimal(15,10)) - cast(cast(a.[CreatedOn] as datetime) as decimal(15,10))) tm2
      ,d.[Name]  [Activity]
      ,a.[IsDeleted]
	  ,datediff(second ,cast(isnull(a.[StopDateTime],getdate()) as datetime) ,(cast(a.[StopDateTime] as datetime))) tm3_sec
	  ,rank() over(partition by DomainLogin ,d.[Name] order by a.[CreatedOn]) rk
into #UserActivity
-- select *
--from [Stg].[_fedor].[core_UserActivity] a --order by 2 desc ,3 desc
from #after_core_UserActivity a
left join /*select * from*/ [Stg].[_fedor].[core_UserActivityDictionary] d on a.[IdActivity]=d.[Id] 
left join [Stg].[_fedor].[core_user] u on a.[IdOwner]=u.[Id]
where [IdActivity] <> 4



-- select * from [Stg].[_fedor].[core_UserActivity] order by 3 desc ,2 desc
/* 
select * from #UserActivity 
where empl='КОНЧИКОВА ЕЛЕНА ЕВГЕНЬЕВНА' 
		and cast([CreatedOn] as date) = '20200911' 
		and [Activity] = 'В работе'
order by 5 desc ,2 desc

*/

drop table if exists #UserActivity2
select 
	  --[Id]
	  cast([CreatedOn] as date) dt
	  ,cast(dateadd(month,datediff(month,0,[CreatedOn]),0) as date) mdt
      ,empl
	  ,NaumenLogin
	  ,DomainLogin
--      ,[CreatedOn]
--      ,[StopDateTime]
	  ,sum(isnull(tm2,0)) tm
      ,[Activity]
--      ,[IsDeleted]
into #UserActivity2
from #UserActivity
--where [IsDeleted] <> 1
group by 
grouping sets
(
(cast([CreatedOn] as date) ,empl ,NaumenLogin ,DomainLogin ,[Activity]) --,[IsDeleted]
,(cast(dateadd(month,datediff(month,0,[CreatedOn]),0) as date) ,empl ,NaumenLogin ,DomainLogin ,[Activity])
)
-- select * from #UserActivity2 where empl = 'КОНЧИКОВА ЕЛЕНА ЕВГЕНЬЕВНА' order by 3 asc ,2 desc

drop table if exists #Structure_User
select s.* ,a.empl
into #Structure_User
from (select distinct empl from #UserActivity2) a
cross join #Structure s
--select * from #Structure --#Structure_User

drop table if exists #Structure_User_month
select s.* ,a.empl
into #Structure_User_month
from (select distinct empl from #UserActivity2) a
cross join (select distinct NumAct ,NameAct ,cast(dateadd(month,datediff(month,0,dt),0) as date) mdt from #Structure) s
--select * from #Structure_User_month


drop table if exists #tbl_res
select cast(s.dt as datetime) dt 
	  ,NumAct 
	  ,NameAct
	  ,s.empl
	  ,NaumenLogin
	  ,DomainLogin
	  ,tm ts
	  ,convert(nvarchar ,cast(isnull(tm,0) as datetime) ,8) tm2
      ,[Activity]
	  ,'По дням' [Periodical]
into #tbl_res
--select *
from #Structure_User s
left join (select * from #UserActivity2 where dt is not null) a on s.dt = a.dt and s.empl = a.empl and s.NameAct = a.[Activity]

union all

select cast(s.mdt as datetime)	  
	  ,NumAct 
	  ,NameAct
	  ,s.empl
	  ,NaumenLogin
	  ,DomainLogin
	  ,tm ts
	  ,convert(nvarchar ,cast(isnull(tm,0) as datetime) ,8) tm2
      ,[Activity]
	  ,'По месяцам' [Periodical]

from #Structure_User_month s
left join (select * from #UserActivity2 where mdt is not null) a on s.mdt = a.mdt and s.empl = a.empl and s.NameAct = a.[Activity]



-- select * from #tbl_res where [Periodical]='По месяцам'
-- select * from #tbl_res where [Periodical]='По дням' and empl = 'КОНЧИКОВА ЕЛЕНА ЕВГЕНЬЕВНА' order by 1 desc
 

-- Обновим таблицу
declare @dtmax date

set @dtmax = (select max(dt) from [Feodor].dbo.UserActivity_dwh563)
--select * from [Feodor].dbo.UserActivity_dwh563

delete from [Feodor].dbo.UserActivity_dwh563 where cast(dt as date) >= dateadd(day,-10 ,cast(@dtmax as date))
--delete from [Feodor].dbo.UserActivity_dwh563 where cast(dt as date) > cast(getdate() as date)
-- drop table [Feodor].dbo.UserActivity_dwh563
set @dtmax = (select max(dt) from [Feodor].dbo.UserActivity_dwh563)

--select * from [Feodor].dbo.UserActivity_dwh563 order by 2 asc ,1 desc

insert into [Feodor].dbo.UserActivity_dwh563
(
dt
,NumAct
,empl
,NaumenLogin
,DomainLogin
,ts
,tm2
,[Activity]
,[Periodical]
,Empl_Status
)
select 
	  dateadd(minute ,NumAct*10 ,dt) dt /*смещение на 10 минут в одном интервале для каждого номера активности*/
	  ,NumAct
	  ,t.empl
	  ,NaumenLogin
	  ,DomainLogin
	  ,ts
	  ,tm2
      ,[NameAct] [Activity]
	  ,[Periodical]
	  ,[Status_name] Empl_Status
--into [Feodor].dbo.UserActivity_dwh563	  
from #tbl_res t
left join #Empl_Status e on upper(t.empl) = upper(e.empl)
where cast(dt as date) >= cast(@dtmax as date) 
		and cast(dt as date) <= cast(getdate() as date)
		and NumAct<>4
--and not [Activity] is null
--		and [Periodical]='По дням' and t.empl = 'КОНЧИКОВА ЕЛЕНА ЕВГЕНЬЕВНА'
order by 1 desc /*,2 asc*/ ,3 asc

--select * from #tbl_res where [Periodical]='По дням' and empl = 'КОНЧИКОВА ЕЛЕНА ЕВГЕНЬЕВНА' order by 1 desc

/*

select * from #tbl_res where [Periodical]='По дням' and empl = 'КОНЧИКОВА ЕЛЕНА ЕВГЕНЬЕВНА' order by 1 desc
select * from [Feodor].dbo.UserActivity_dwh563 where [Periodical]='По дням' and NumAct<>4 and empl = 'КОНЧИКОВА ЕЛЕНА ЕВГЕНЬЕВНА' order by 1 desc, 3 asc ,2 asc

*/

/*
select 
	  cast([CreatedOn] as date) dt
	  ,empl
	  ,NaumenLogin
	  ,DomainLogin
	  ,datediff(second ,[CreatedOn] ,[StopDateTime]) ts
	  ,convert(nvarchar ,tm,8) tm2
      ,[Activity]
--into [Feodor].dbo.UserActivity_dwh560	  
from #UserActivity 
where cast([CreatedOn] as date) >= @dtmax
order by 2 asc ,1 desc
*/

*/
 
 END