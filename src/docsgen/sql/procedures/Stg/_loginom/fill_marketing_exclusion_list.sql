--DWH-958
--DWH-1248
--DWH-1283
--DWH-1639
--DWH-1877
--@mode = 0 - полное заполнение таблицы marketing_exclusion_list
--@mode = 1 - обработка только тех телефонных номеров, по которым были звонки за последние 2 дня
-- Usage: запуск процедуры с параметрами
-- EXEC [_loginom].[fill_marketing_exclusion_list]
--      @mode = 0,
--      @isDebug = 0;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   PROC [_loginom].[fill_marketing_exclusion_list]
	@mode int = 0,
	@isDebug int = 0
as
begin

	SET XACT_ABORT ON

    DECLARE @StartDate datetime, @row_count int
	DECLARE @sql nvarchar(max), @day_2 date

	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @mode = isnull(@mode, 0)

	declare @date_start date=dateadd(mm, -8, getdate()) /*Внесли изменения согласно DWH-1639*/
	SELECT @day_2 = cast(dateadd(DAY, -2, getdate()) AS date)

	--Нужные проекты
	drop table if exists #tCallProject
	SELECT 
		Name = P.Name COLLATE Cyrillic_General_CI_AS
		,IdExternal = P.IdExternal COLLATE Cyrillic_General_CI_AS
	INTO #tCallProject
	--DWH-1502 Использовать локальный справочник _fedor.dictionary_CallProject
	--from [PRODSQL02].[Fedor.Core].[dictionary].[CallProject]
	FROM _fedor.dictionary_CallProject AS P

	DROP TABLE IF EXISTS #t_2_day_client_number
	CREATE TABLE #t_2_day_client_number(client_number nvarchar(200))

	IF @mode = 1 BEGIN
		SELECT @StartDate = getdate(), @row_count = 0

		INSERT #t_2_day_client_number(client_number)
		SELECT 	iif(substring(N.client_number, 1, 1) = '8'
				,substring(N.client_number, 2, len(N.client_number))
				,trim(client_number)
				)
		FROM NaumenDbReport.dbo.detail_outbound_sessions AS N WITH(INDEX=[columnStore_ix], NOLOCK)
		WHERE N.attempt_start >= @day_2
		GROUP BY 	iif(substring(N.client_number, 1, 1) = '8'
				,substring(N.client_number, 2, len(N.client_number))
				,trim(client_number)
				)

		SELECT @row_count = @@ROWCOUNT
		IF @isDebug = 1 BEGIN
			SELECT 'INSERT #t_2_day_client_number', @row_count, datediff(SECOND, @StartDate, getdate())
		END

		CREATE clustered INDEX ix1 ON #t_2_day_client_number(client_number)
	END

	--телефоны, с нужным кол-вом звонков
	--SELECT @StartDate = getdate(), @row_count = 0

	--DROP TABLE IF EXISTS #t_Naumen_client_number
	--CREATE TABLE #t_Naumen_client_number(client_number nvarchar(200))


	--@mode = 0 - полное заполнение таблицы marketing_exclusion_list
	--IF @mode = 0 BEGIN
	--	INSERT #t_Naumen_client_number(client_number)
	--	SELECT N.client_number
	--	FROM NaumenDbReport.dbo.detail_outbound_sessions AS N WITH(INDEX=[ClusteredColumnStoreIndex-20191024-184724], NOLOCK)
	--	WHERE N.attempt_start >= @date_start
	--		AND EXISTS(
	--			SELECT TOP(1) 1 FROM #tCallProject AS P
	--			WHERE P.IdExternal = N.project_id
	--		)
	--	GROUP BY N.client_number
	--	HAVING count(*) >= 4

	--	SELECT @row_count = @@ROWCOUNT
	--END


	--@mode = 1 - обработка только тех телефонных номеров, по которым были звонки за последние 2 дня
	--IF @mode = 1 BEGIN
	--	INSERT #t_Naumen_client_number(client_number)
	--	SELECT N.client_number
	--	FROM NaumenDbReport.dbo.detail_outbound_sessions AS N WITH(INDEX=[ClusteredColumnStoreIndex-20191024-184724], NOLOCK)
	--		INNER JOIN #t_2_day_client_number AS C
	--			ON C.client_number = N.client_number
	--	WHERE N.attempt_start >= @date_start
	--		AND EXISTS(
	--			SELECT TOP(1) 1 FROM #tCallProject AS P
	--			WHERE P.IdExternal = N.project_id
	--		)
	--	GROUP BY N.client_number
	--	HAVING count(*) >= 4

	--	SELECT @row_count = @@ROWCOUNT
	--END

	--IF @isDebug = 1 BEGIN
	--	SELECT 'INSERT #t_Naumen_client_number', @row_count, datediff(SECOND, @StartDate, getdate())
	--END


	--SELECT @StartDate = getdate(), @row_count = 0

	--CREATE UNIQUE INDEX ix1 ON #t_Naumen_client_number(client_number)

	--IF @isDebug = 1 BEGIN
	--	SELECT 'CREATE INDEX ON #t_Naumen_client_number', @row_count, datediff(SECOND, @StartDate, getdate())
	--END


	SELECT @StartDate = getdate(), @row_count = 0

	DROP TABLE IF EXISTS #t_exclusion_list
	CREATE TABLE #t_exclusion_list(client_number nvarchar(200))

	IF @mode = 0
	BEGIN
		-- динамический sql нужен для использования индекса ix_attempt_start_3 с фильтром attempt_start >= <date>
		SELECT @sql = concat(
'INSERT #t_exclusion_list(client_number)
SELECT Y.client_number
FROM (
		SELECT 
			S.client_number,
			S.flag_attempt_result
		FROM (
			SELECT  
				N.client_number,
				flag_attempt_result = 
					CASE 
						WHEN N.attempt_result IN (''amd'', ''amd_cti'', ''no_answer'', ''no_answer_cti'', ''abandoned'', ''not_found'')
						THEN convert(tinyint, 1)
						ELSE convert(tinyint, 0)
					END,
				nRow = row_number()
					OVER(
						PARTITION BY N.client_number
						ORDER BY N.attempt_end DESC, N.attempt_number DESC
					)
			FROM NaumenDbReport.dbo.detail_outbound_sessions AS N WITH(INDEX=ix_attempt_start_3, NOLOCK)
			WHERE N.attempt_start >= ''', convert(varchar(10), @date_start, 120), '''',
'
				AND EXISTS(
					SELECT TOP(1) 1 
					FROM #tCallProject AS P
					WHERE P.IdExternal = N.project_id
				)
		) AS S
		WHERE S.nRow <= 4
	) AS Y
GROUP BY Y.client_number
HAVING min(Y.flag_attempt_result) = 1 AND count(1) = 4'
		)
	END
	-- // mode = 0


	--@mode = 1 - обработка только тех телефонных номеров, по которым были звонки за последние 2 дня
	IF @mode = 1
	BEGIN
		-- динамический sql нужен для использования индекса ix_attempt_start_3 с фильтром attempt_start >= <date>
		SELECT @sql = concat(
'INSERT #t_exclusion_list(client_number)
SELECT Y.client_number
FROM (
		SELECT 
			S.client_number,
			S.flag_attempt_result
		FROM (
			SELECT  
				N.client_number,
				flag_attempt_result = 
					CASE 
						WHEN N.attempt_result IN (''amd'', ''amd_cti'', ''no_answer'', ''no_answer_cti'', ''abandoned'', ''not_found'')
						THEN convert(tinyint, 1)
						ELSE convert(tinyint, 0)
					END,
				nRow = row_number()
					OVER(
						PARTITION BY N.client_number
						ORDER BY N.attempt_end DESC, N.attempt_number DESC
					)
			FROM NaumenDbReport.dbo.detail_outbound_sessions AS N WITH(INDEX=ix_attempt_start_3, NOLOCK)
				INNER JOIN #t_2_day_client_number AS C
					ON C.client_number = N.client_number
			WHERE N.attempt_start >= ''', convert(varchar(10), @date_start, 120), '''',
'
				AND EXISTS(
					SELECT TOP(1) 1 
					FROM #tCallProject AS P
					WHERE P.IdExternal = N.project_id
				)
		) AS S
		WHERE S.nRow <= 4
	) AS Y
GROUP BY Y.client_number
HAVING min(Y.flag_attempt_result) = 1 AND count(1) = 4'
		)
	END
	-- // mode = 1


	--SELECT @sql
	EXEC sp_executesql @sql


	/*
	INSERT #t_exclusion_list(client_number)
	SELECT Y.client_number
	FROM (
			SELECT 
				S.client_number,
				S.flag_attempt_result
			FROM (
				SELECT  
					N.client_number,
					flag_attempt_result = 
						CASE 
							WHEN N.attempt_result IN ('amd', 'amd_cti', 'no_answer', 'no_answer_cti', 'abandoned', 'not_found')
							THEN convert(tinyint, 1)
							ELSE convert(tinyint, 0)
						END,
					nRow = row_number()
						OVER(
							PARTITION BY N.client_number
							ORDER BY N.attempt_end DESC, N.attempt_number DESC
						)
				FROM NaumenDbReport.dbo.detail_outbound_sessions AS N WITH(INDEX=ix_attempt_start_3, NOLOCK)
					INNER JOIN #t_Naumen_client_number AS C
						ON C.client_number = N.client_number
				WHERE N.attempt_start >= '2022-04-29' -- нужно для использования индекса ix_attempt_start_3
					AND N.attempt_start >= @date_start
					AND EXISTS(
						SELECT TOP(1) 1 
						FROM #tCallProject AS P
						WHERE P.IdExternal = N.project_id
					)
			) AS S
			WHERE S.nRow <= 4 --4 последних коммуникации
		) AS Y
	GROUP BY Y.client_number
	HAVING min(Y.flag_attempt_result) = 1 -- все 4 последних коммуникации должны быть из списка
	*/


	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_exclusion_list', @row_count, datediff(SECOND, @StartDate, getdate())
	END


	BEGIN TRAN

		--@mode = 0 - полное заполнение таблицы marketing_exclusion_list
		IF @mode = 0 BEGIN
			TRUNCATE TABLE _loginom.marketing_exclusion_list
		END

		--@mode = 1 - обработка только тех телефонных номеров, по которым были звонки за последние 2 дня
		IF @mode = 1 BEGIN
			SELECT @StartDate = getdate(), @row_count = 0

			--UPDATE C
			--SET client_number = substring(C.client_number, 2, len(C.client_number))
			--FROM #t_2_day_client_number AS C
			--WHERE substring(C.client_number, 1, 1) = '8'

			DELETE L
			FROM _loginom.marketing_exclusion_list AS L
				INNER JOIN #t_2_day_client_number AS C
					ON C.client_number = L.client_number

			SELECT @row_count = @@ROWCOUNT
			IF @isDebug = 1 BEGIN
				SELECT 'DELETE FROM _loginom.marketing_exclusion_list', @row_count, datediff(SECOND, @StartDate, getdate())
			END
		END

		SELECT @StartDate = getdate(), @row_count = 0

		INSERT _loginom.marketing_exclusion_list(client_number, InsertedDate)
		SELECT DISTINCT 
			client_number =
				CASE 
					WHEN substring(S.client_number, 1, 1) = '8'  
						THEN substring(S.client_number, 2, len(S.client_number))
				ELSE S.client_number END,
			InsertedDate = getdate()
		FROM #t_exclusion_list AS S

		SELECT @row_count = @@ROWCOUNT
		IF @isDebug = 1 BEGIN
			SELECT 'INSERT _loginom.marketing_exclusion_list', @row_count, datediff(SECOND, @StartDate, getdate())
		END
	COMMIT TRAN

	--OLD
	--значение ответа которые нас интересуют
	--declare @t_attempt_result table ([attempt_result] varchar(255), [description] varchar(255))

	--insert into @t_attempt_result
	--select * from (values
	--	 ('amd', 'Автоответчик')
	--	,('amd_cti', 'Автоответчик (CTI)')
	--	,('no_answer', 'Нет ответа')
	--	,('no_answer_cti', 'Нет ответа (CTI)')
	--	,('abandoned', 'Потерян')
	--	,('not_found', 'not_found')
	--	) t([attempt_result], [description])

--  -- Если 5 предыдущих коммуникаций, совершенные в разные дни, по лиду с этим же номером телефона завершились результатом "Автоответчик" и "Нет ответа", то такие лиды НЕ нужно отправлять в Naumen для обзвона.
--  IF object_id('tempdb..#t_Naumen_Communication_result') IS NOT NULL
--	DROP TABLE #t_Naumen_Communication_result
	
--	 SELECT 
--	 [client_number],
--	 attempt_result,
--	 [attempt_date],
--	 project_id
--	INTO #t_Naumen_Communication_result  
--	FROM 
--	(
--  SELECT  
	  
--	     --[attempt_date] = cast(isnull(attempt_end, attempt_start) as date)
--		 [attempt_date] = isnull(attempt_end, attempt_start)
--		,[client_number]
--		,attempt_result
--		,attempt_number
--		,project_id
--	--	,nRow = ROW_NUMBER() over(partition by [client_number], cast(isnull(attempt_end, attempt_start) as date) order by attempt_number desc) 
--		,nRow = row_number() OVER(PARTITION BY [client_number] ORDER BY  isnull(attempt_end, attempt_start) DESC, attempt_number DESC)
--		,nTotalOutbound_sessions = count(1) OVER(PARTITION BY [client_number])
--    --  ,[last_attempt] = max([attempt_number])
--	  FROM NaumenDbReport.dbo.detail_outbound_sessions AS N WITH(INDEX=ix_attempt_start_3, NOLOCK)
--	  WHERE N.attempt_start >= '2022-04-29' -- нужно для использования индекса ix_attempt_start_3
--		AND attempt_start >= @date_start
--		AND EXISTS(
--			SELECT TOP(1) 1 FROM #tCallProject cl 
--			--WHERE cl.IdExternal =  namumen.project_id COLLATE SQL_Latin1_General_CP1_CI_AS
--			WHERE cl.IdExternal = N.project_id
--		)
--	--7min-10min without check in l_lcrm 
	
--	) s
	
--	--Изменили в рамках BP-1455
--	WHERE nRow <=4--5 последних коммуникаций
--	AND nTotalOutbound_sessions>=4 --всего коммуникаций должно быть более 5
--	/*
--	where nRow <=5--5 последних коммуникаций
--	and nTotalOutbound_sessions>=5 --всего коммуникаций должно быть более 5
--	*/
		
	 
--	CREATE INDEX ix_client_number ON #t_Naumen_Communication_result(client_number,attempt_result )
--	--create index ix_UF_PHONE on #t_lcrm(UF_PHONE)


--	IF object_id('tempdb..#t_result') IS NOT NULL DROP TABLE #t_result
	
	
--	SELECT DISTINCT
--	 client_number =
--		CASE 
--			WHEN substring(client_number, 1, 1) = '8'  
--				THEN substring(client_number, 2, len(client_number))
--		ELSE client_number END
--	INTO #t_result
--	FROM (SELECT  client_number
--	 FROM #t_Naumen_Communication_result r
--	 --BP-1531
--	 --Коммуниикации были только в рамках обзвона лидов
	 
--	 EXCEPT   --Исключаем телефоны которые не отвечают критерию, последние N звонков имели другие статутсы кроме как в @t_attempt_result
--	 select client_number from #t_Naumen_Communication_result
--	 --ответы были любые, а не которые указаны в @t_attempt_result
--	 where attempt_result not in ( select [attempt_result] from @t_attempt_result)
	 
--	 ) t
--	 /*в рамках BP-1531 убрали т.к. есть фильтр по проекту*/
--	 --INTERSECT--реализация через  INTERSECT получилась быстрее чем различные варианты JOIN
--	 --	select UF_PHONE  from #t_lcrm

--set xact_abort on 
--begin tran
--	--удалить записи которы были добавлены более 3хмесяц назад
--	/*
--	delete top(@batchSize) from _loginom.marketing_exclusion_list
--	where InsertedDate <=@date_start
--	while @@ROWCOUNT>0
--	begin
--		delete top(@batchSize) from _loginom.marketing_exclusion_list
--		where InsertedDate <=@date_start
--	end
--	--Добавили новые данные
--	insert into _loginom.marketing_exclusion_list (client_number, InsertedDate)
--	select s.client_number, getdate() as InsertedDate
--	from #t_result s
--	where not exists(select top(1) 1 from _loginom.marketing_exclusion_list t where t.client_number  = s.client_number)
--	*/
--	--В рамках BP приняли решение обновлять всю таблицу
--	truncate table _loginom.marketing_exclusion_list
--	insert into _loginom.marketing_exclusion_list (client_number, InsertedDate)
--	select distinct s.client_number, getdate() as InsertedDate
--	from #t_result s

--commit tran
  
end
