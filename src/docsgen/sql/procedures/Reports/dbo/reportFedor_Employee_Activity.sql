--DWH-2880
--exec dbo.reportFedor_Employee_Activity  'KD.Daily' 
CREATE PROC dbo.reportFedor_Employee_Activity
	@page nvarchar(100)
  , @DtFrom date = null
  , @DtTo date =null
  , @isDebug int = 0
AS
BEGIN
	
SET NOCOUNT ON;

	SELECT @isDebug = isnull(@isDebug, 0)

	if @dtFrom is null BEGIN
		SELECT @dtFrom = cast(dateadd(DAY, 1, eomonth(getdate(),-1)) AS date)
	END

	if @dtTo is NULL BEGIN
		set @DtTo = cast(getdate() AS date)
	END

	--сотрудники QA
	drop table if exists #curr_employee_test
	create table #curr_employee_test(Employee nvarchar(255))

	INSERT #curr_employee_test(Employee)
	----select *
	--select substring(trim(U.DisplayName), 1, 255)
	--FROM [dwh-ex].bot.dbo.[vw_ActiveDirectoryUsers] AS U
	--where U.Department ='Отдел тестирования'
	--and u.DomainAccount !='r.mekshinev' -- перешел в отдел тестирование из отдела верификации
	--UNION
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
	WHERE U.IsQAUser = 1

	-- сотрудники КД
	drop table if exists #curr_employee_cd
	create table #curr_employee_cd(Id uniqueidentifier, Employee nvarchar(255))

	INSERT #curr_employee_cd(Id, Employee)
	SELECT DISTINCT
		U.Id,
		Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
		AND (U.IsDeleted = 0
			OR (U.IsDeleted = 1 AND U.DeleteDate >= @dtFrom)
		)

		--DWH-522
		--AND UR.IsDeleted = 0 -- было
		AND (UR.IsDeleted = 0
			OR (UR.IsDeleted = 1 AND UR.deleted_at >= @dtFrom)
		)

		AND R.Name IN ('Чекер')
		AND concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
			NOT IN (SELECT Employee FROM #curr_employee_test)
	union 
	select Id, Employee 
	from (
		select 
			u.Id
			,Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
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

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##curr_employee_cd
		SELECT * INTO ##curr_employee_cd FROM #curr_employee_cd
	END


	-- Верификаторы
	drop table if exists #curr_employee_vr
	create table #curr_employee_vr(Id uniqueidentifier, Employee nvarchar(255))

	INSERT #curr_employee_vr(Id, Employee)
	SELECT DISTINCT
		U.Id,
		Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
		AND (U.IsDeleted = 0
			OR (U.IsDeleted = 1 AND U.DeleteDate >= @dtFrom)
		)

		--DWH-522
		--AND UR.IsDeleted = 0 -- было
		AND (UR.IsDeleted = 0
			OR (UR.IsDeleted = 1 AND UR.deleted_at >= @dtFrom)
		)

		AND R.Name IN ('Верификатор')
		AND concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
			NOT IN (SELECT Employee FROM #curr_employee_test)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##curr_employee_vr
		SELECT * INTO ##curr_employee_vr FROM #curr_employee_vr
	END


	drop table if exists #log

	select 
		cast(a.createdOn as date) Date,
		UserId = u.Id,
		LastName   + N' '
		+ FirstName + N' '
		+ MiddleName FIO
		, dateadd(hour,3,a.CreatedOn) StartDateTime
		, dateadd(hour,3,StopDateTime) StopDateTime
		--, datediff(second,a.CreatedOn,StopDateTime) duration
		, d.Name Activity
		--,case when kd.employee is not null then 'Контроль данных' 
		--      when v.employee is not null then 'Верификация' 
		--      when kd.employee is not null  and v.employee is not null then 'Контроль данных и Верификация' 
		--      else '-'
		-- end Stage
		--,'Контроль данных' AS Stage
		,Stage = 
		CASE
			WHEN uak.Name = 'Чекер' THEN 'Контроль данных'
			WHEN uak.Name = 'Верификатор' THEN 'Верификация'
			ELSE NULL
		END
    into #log
    from Stg._fedor.core_UserActivity AS a
		LEFT join Stg._fedor.core_UserActivityDictionary AS d on a.IdActivity = d.Id 
		LEFT join Stg._fedor.core_user AS u on a.IdOwner = u.Id
		LEFT JOIN Stg._fedor.dictionary_UserActivityKind AS uak	ON uak.Id = a.IdActivityKind
		LEFT JOIN #curr_employee_cd AS kd ON kd.Id = a.IdOwner
		LEFT JOIN #curr_employee_vr AS vr ON vr.Id = a.IdOwner
	where 1=1
		AND a.CreatedOn>'20200901'
		AND a.IsDeleted <> 1
		AND a.CreatedOn>@dtFrom and a.CreatedOn<dateadd(day,1,@DtTo)
		AND isnull(kd.Id, vr.Id) IS NOT NULL

	/*
		--1 'Контроль данных'
	  select cast(a.createdOn as date) Date,
		   LastName   + N' '
		   + FirstName + N' '
		   + MiddleName FIO
		   , dateadd(hour,3,a.CreatedOn) StartDateTime
		   , dateadd(hour,3,StopDateTime) StopDateTime
		   --, datediff(second,a.CreatedOn,StopDateTime) duration
		   , d.Name Activity
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
   */

	/*
	Корнеева Вероника Игоревна
	сменила фамилию на
	Столица Вероника Игоревна
	*/
	UPDATE T
	--SET FIO = replace(FIO, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна')
	SET FIO = 'Столица Вероника Игоревна'
	FROM #log AS T
	WHERE FIO = 'Корнеева Вероника Игоревна'

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##log
		SELECT * INTO ##log FROM #log
	END


-- лог выполнения
drop table if exists #detail
;
with l as (
  select  Stage
       , Date
	   , UserId
       , FIO
       , StartDateTime
       , StopDateTime = case when StopDateTime is null then lead (StartDatetime) over ( partition by  date,fio order by StartDateTime) else StopDateTime end
       , Activity
    from #log 
    
),
l1 as (
      select  Stage
       , Date
	   , UserId
       , FIO
       , StartDateTime
       , StopDateTime
       , datediff(second,StartDateTime,StopDateTime) duration
       , Activity
    from l
)
  select  Stage
       , Date
	   , UserId
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

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##detail
		SELECT * INTO ##detail FROM #detail
	END

	IF @page='Detail' BEGIN
		select Stage, Date, FIO, StartDateTime, StopDateTime
			, format(duration/60/60,'00')+N':'+format(duration/60 -  60* (duration/60/60),'00')+N':'+ format(duration-60*(duration/60),'00') duration
			, Activity, hours, minutes, seconds 
		from #detail
		order by stage,date,fio,StartDateTime

		RETURN 0                   
	END

	IF @page='KD.Detail' BEGIN
		select Stage, Date, FIO, StartDateTime, StopDateTime
			, format(duration/60/60,'00')+N':'+format(duration/60 -  60* (duration/60/60),'00')+N':'+ format(duration-60*(duration/60),'00') duration
			, Activity, hours, minutes, seconds 
		from #detail AS d
			LEFT JOIN #curr_employee_cd AS u ON u.Id = d.UserId
		WHERE Stage='Контроль данных' 
			OR (Stage IS NULL AND u.Id IS NOT NULL)
		order by stage,date,fio,StartDateTime

		RETURN 0                   
	END

	IF @page='V.Detail' BEGIN
		select Stage, Date, FIO, StartDateTime, StopDateTime
			, format(duration/60/60,'00')+N':'+format(duration/60 -  60* (duration/60/60),'00')+N':'+ format(duration-60*(duration/60),'00') duration
			, Activity, hours, minutes, seconds 
		from #detail AS d
			LEFT JOIN #curr_employee_vr AS u ON u.Id = d.UserId
		WHERE Stage='Верификация'
			OR (Stage IS NULL AND u.Id IS NOT NULL)
		order by stage,date,fio,StartDateTime

		RETURN 0                   
	END


	if @page='KD.Daily' BEGIN
		-- аггрегированные
		select Date=case when Activity='В работе'           then dateadd(hour,1,cast(Date as datetime))
						when Activity='В ожидании заявки'  then dateadd(hour,2,cast(Date as datetime))
						when Activity='Пауза'              then dateadd(hour,3,cast(Date as datetime))
					end
			, FIO
			, Activity
			--, sum(duration) duration
			, format(sum(duration)/60/60,'00')+N':'+format(sum(duration)/60 -  60* (sum(duration)/60/60),'00')+N':'+ format(sum(duration)-60*(sum(duration)/60),'00') duration
		from #detail AS d
			LEFT JOIN #curr_employee_cd AS u ON u.Id = d.UserId
		WHERE (Stage='Контроль данных' OR (Stage IS NULL AND u.Id IS NOT NULL))
			AND Activity in ('Пауза' ,'В ожидании заявки','В работе' )
		group by Date
			, FIO
			, Activity
		order by Date, FIO
			, Activity

		RETURN 0                   
	END



	if @page='V.Daily' BEGIN
		-- аггрегированные
		select Date=case when Activity='В работе'           then dateadd(hour,1,cast(Date as datetime))
						when Activity='В ожидании заявки'  then dateadd(hour,2,cast(Date as datetime))
						when Activity='Пауза'              then dateadd(hour,3,cast(Date as datetime))
					end
			, FIO
			, Activity
			--, sum(duration) duration
			, format(sum(duration)/60/60,'00')+N':'+format(sum(duration)/60 -  60* (sum(duration)/60/60),'00')+N':'+ format(sum(duration)-60*(sum(duration)/60),'00') duration
		from #detail AS d
			LEFT JOIN #curr_employee_vr AS u ON u.Id = d.UserId
		WHERE (Stage='Верификация' OR (Stage IS NULL AND u.Id IS NOT NULL))
			AND Activity in ('Пауза' ,'В ожидании заявки','В работе')
		group by Date
			, FIO
			, Activity
		order by Date, FIO
			, Activity

		RETURN 0                   
	END



	if @page='KD.Monthly' BEGIN
		-- аггрегированные
		select Date=case when Activity='В работе'           then dateadd(hour,1,cast(format(Date,'yyyyMM01') as datetime))
						when Activity='В ожидании заявки'  then dateadd(hour,2,cast(format(Date,'yyyyMM01') as datetime))
						when Activity='Пауза'              then dateadd(hour,3,cast(format(Date,'yyyyMM01') as datetime))
					end
			, FIO
			, Activity
			--, sum(duration) duration
			, format(sum(duration)/60/60,'00')+N':'+format(sum(duration)/60 -  60* (sum(duration)/60/60),'00')+N':'+ format(sum(duration)-60*(sum(duration)/60),'00') duration
		from #detail AS d
			LEFT JOIN #curr_employee_cd AS u ON u.Id = d.UserId
		WHERE (Stage='Контроль данных' OR (Stage IS NULL AND u.Id IS NOT NULL))
			AND Activity in ('Пауза' ,'В ожидании заявки','В работе' )
		group by format(Date,'yyyyMM01')
			, FIO
			, Activity
		order by format(Date,'yyyyMM01'), FIO
			, Activity

		RETURN 0                   
	END

	if @page='V.Monthly' BEGIN
		-- аггрегированные
		select Date=case when Activity='В работе'           then dateadd(hour,1,cast(format(Date,'yyyyMM01') as datetime))
					when Activity='В ожидании заявки'  then dateadd(hour,2,cast(format(Date,'yyyyMM01') as datetime))
					when Activity='Пауза'              then dateadd(hour,3,cast(format(Date,'yyyyMM01') as datetime))
				end
			, FIO
			, Activity
			--, sum(duration) duration
			, format(sum(duration)/60/60,'00')+N':'+format(sum(duration)/60 -  60* (sum(duration)/60/60),'00')+N':'+ format(sum(duration)-60*(sum(duration)/60),'00') duration
		from #detail AS d
			LEFT JOIN #curr_employee_vr AS u ON u.Id = d.UserId
		WHERE (Stage='Верификация' OR (Stage IS NULL AND u.Id IS NOT NULL))
			AND Activity in ('Пауза' ,'В ожидании заявки','В работе' )
		group by format(Date,'yyyyMM01')
			, FIO
			, Activity
		order by format(Date,'yyyyMM01'), FIO
			, Activity

		RETURN 0                   
	END



END
