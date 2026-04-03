
-- ============================================= 
-- Author: А. Никитин
-- Create date: 22.10.2022 
-- Description: DWH-1951 DQ dwh2.dbo.dm_CMRStatBalance
-- ============================================= 
CREATE PROC Monitoring.DQ_dm_CMRStatBalance
	@isDebug int = 0,
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@SendEmail int = 0
AS
BEGIN
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @isWarning int = 0,
		@message nvarchar(1024) = '',
		@description nvarchar(1024), 
		@eventType varchar(1024), -- например: 'error', 'info', 'warning'
		@eventName varchar(1024), -- например: 'task_start', 'create_balance', 'create_indexes', 'data_quality_check'
		--@event_name varchar(256), -- например: 'Заполнение витрины ...', 'Расчет баланса'
		@eventMessageText nvarchar(max) -- большое сообщение для расширенного логирования
	DECLARE @count_duplicate int
	DECLARE @table_name varchar(256) = 'dwh2.dbo.dm_CMRStatBalance'
	DECLARE @SumOD numeric(38, 2), @SumOD_1 numeric(38, 2)
	DECLARE @SumOD_Overdue numeric(38, 2), @SumOD_Overdue_1 numeric(38, 2)
	DECLARE @DiffOD_proc numeric(38, 2), @DiffOD_Overdue_proc numeric(38, 2)
	DECLARE @contractGuid nvarchar(36)

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @SendEmail = isnull(@SendEmail, 0)

	SELECT @eventName = 'Monitoring_DQ_dm_CMRStatBalance'
	--SELECT @event_name = concat('Мониторинг качества данных ', @table_name)

	drop table if exists #t_duplicate
	CREATE TABLE #t_duplicate(
		external_id nvarchar(30),
		balance_dt date,
		count_duplicates int
	)

	INSERT #t_duplicate
	(
		external_id,
		balance_dt,
		count_duplicates
	)
	SELECT B.external_id, balance_dt = B.d, count_duplicates = count(*)
	FROM dwh2.dbo.dm_CMRStatBalance AS B (NOLOCK)
	WHERE 1=1
		--and B.d = cast(getdate() AS date)
	GROUP BY B.external_id, B.d
	HAVING count(*) > 1
	--test
	--UNION SELECT 'test_22052610000011', 3

	SELECT @count_duplicate = count(*) FROM #t_duplicate

	DROP TABLE IF EXISTS #t_contract
	CREATE TABLE #t_contract(contractGuid nvarchar(36))

	IF @count_duplicate > 0
	BEGIN
		SELECT @message = concat(
			@message, 
			' Найдены дубли договоров. Количество дублей: ', 
			convert(varchar(10), @count_duplicate), '.'
		)
		SELECT @isWarning = 1

		INSERT #t_contract(contractGuid)
		SELECT top(20) contractGuid = H.GuidДоговораЗайма 
		FROM #t_duplicate AS D
			INNER JOIN dwh2.hub.ДоговорЗайма AS H
				ON H.КодДоговораЗайма = D.external_id
		WHERE NOT EXISTS (
			SELECT TOP(1) 1
			FROM Stg.etl.ReloadData4Contract AS R
			WHERE R.CreatedAt >= cast(dateadd(MONTH, -1, getdate()) AS date)
				AND R.external_id = D.external_id
				AND R.StatusCode = 'Finished'
			)
		group by H.GuidДоговораЗайма
	END

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_duplicate
		SELECT * INTO ##t_duplicate FROM #t_duplicate AS T

		RETURN 0
	END

	--4. Портфель (ОД) за текущую дату не отличается от портфеля за предыдущую дату более чем на 10%
	SELECT @SumOD = sum(B.[остаток од])
	FROM dwh2.dbo.dm_CMRStatBalance AS B (NOLOCK)
	WHERE B.d = cast(getdate() AS date)

	SELECT @SumOD_1 = sum(B.[остаток од])
	FROM dwh2.dbo.dm_CMRStatBalance AS B (NOLOCK)
	WHERE B.d = dateadd(DAY, -1, cast(getdate() AS date))

	SELECT @DiffOD_proc = iif(isnull(@SumOD_1, 0) <> 0, 100.0 * (@SumOD - @SumOD_1) / @SumOD_1, 0)

	--5. Портфель (ОД) для Клиентов в просрочке (dpd>0) за текущую дату не отличается 
	--	 от портфеля в просрочке за предыдущую дату более чем на 10%
	SELECT @SumOD_Overdue = sum(B.[остаток од])
	FROM dwh2.dbo.dm_CMRStatBalance AS B (NOLOCK)
	WHERE B.d = cast(getdate() AS date)
		AND isnull(B.dpd, 0) > 0

	SELECT @SumOD_Overdue_1 = sum(B.[остаток од])
	FROM dwh2.dbo.dm_CMRStatBalance AS B (NOLOCK)
	WHERE B.d = dateadd(DAY, -1, cast(getdate() AS date))
		AND isnull(B.dpd, 0) > 0

	SELECT @DiffOD_Overdue_proc = iif(isnull(@SumOD_Overdue_1, 0) <> 0, 100.0 * (@SumOD_Overdue - @SumOD_Overdue_1) / @SumOD_Overdue_1, 0)

	IF abs(@DiffOD_proc) >= 10.0
	BEGIN
		SELECT @message = concat(
			@message, 
			' Портфель (ОД) за текущую дату (', convert(varchar(20), @SumOD), ')',
			' отличается от портфеля за предыдущую дату (', convert(varchar(20), @SumOD_1), ')',
			' более чем на 10%: ', convert(varchar(10), @DiffOD_proc), '.'
		)
		SELECT @isWarning = 1
	END

	IF abs(@DiffOD_Overdue_proc) >= 10.0
	BEGIN
		SELECT @message = concat(
			@message, 
			' Портфель (ОД) в просрочке за текущую дату (', convert(varchar(20), @SumOD_Overdue), ')',
			' отличается от портфеля в просрочке за предыдущую дату (', convert(varchar(20), @SumOD_Overdue_1), ')',
			' более чем на 10%: ', convert(varchar(10), @DiffOD_Overdue_proc), '.'
		)
		SELECT @isWarning = 1
	END

	IF @isWarning = 1
	BEGIN
		SELECT @eventType = 'warning'

		SELECT @message = concat('Таблица ', @table_name, '. ', @message)

		SELECT @description = 
			(SELECT
				'TableName' = @table_name,
				'Message' = 'Найдены дубли договоров. Количество дублей: ' + convert(varchar(10), @count_duplicate),
				'SumOD' = 'Портфель (ОД) за текущую дату: ' + convert(varchar(20), @SumOD),
				'SumOD_1' = 'Портфель (ОД) за предыдущую дату: ' + convert(varchar(20), @SumOD_1),
				'DiffOD_proc' = 'Изменение Портфеля (ОД), %: ' + convert(varchar(20), @DiffOD_proc),
				'SumOD_Overdue' = 'Портфель (ОД) в просрочке за текущую дату: ' + convert(varchar(20), @SumOD_Overdue),
				'SumOD_Overdue_1' = 'Портфель (ОД) в просрочке за предыдущую дату: ' + convert(varchar(20), @SumOD_Overdue_1),
				'DiffOD_Overdue_proc' = 'Изменение Портфеля (ОД) в просрочке, %: ' + convert(varchar(20), @DiffOD_Overdue_proc)
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)

		--var.1 json
		--SELECT @event_message_text = 
		--	(
		--		SELECT r = T.request_number, c = T.count_duplicates
		--		FROM #t_duplicate AS T
		--		FOR JSON PATH, INCLUDE_NULL_VALUES --, WITHOUT_ARRAY_WRAPPER
		--	)

		--var.2 html
		SELECT @eventMessageText = concat(
			'<table cellspacing="0" border="1" cellpadding="5">',
			'<tr><td><b>Договор</b></td><td><b>Дата</b></td><td><b>Количество дублей</b></td></tr>', 
			(
			SELECT string_agg(
				cast(
					concat(
						'<tr><td>', 
						T.external_id, 
						'</td><td>', 
						convert(varchar(10), T.balance_dt, 104), 
						'</td><td>', 
						convert(varchar(10), T.count_duplicates), '</td></tr>'
					)
					as nvarchar(max)
				), ' '
			)
			FROM #t_duplicate AS T
			
			),
			'</table>'
		)

	END
	ELSE BEGIN
		SELECT @eventType = 'info'
		SET @message = concat('Таблица ', @table_name, '. ',
			'Ошибки не найдены.'
			)
		SELECT @description = 
			(SELECT
				'TableName' = @table_name,
				'Message' = 'Ошибки не найдены.'
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		SELECT @eventMessageText = NULL, @SendEmail = 0
	END

	/*
	--новая версия лога
	EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
	*/

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @eventName,
		@eventType = @eventType,
		@message = @message,
		@description = @description,
		@SendEmail = @SendEmail,
		@ProcessGUID = @ProcessGUID,
		@eventMessageText = @eventMessageText

	--перезагрузка
	IF EXISTS(SELECT TOP 1 1 FROM #t_contract)
	BEGIN
		DECLARE cur_contract CURSOR FOR
		SELECT DISTINCT TOP 100 C.contractGuid
		FROM #t_contract AS C
		ORDER BY C.contractGuid

		OPEN cur_contract
		FETCH NEXT FROM cur_contract INTO @contractGuid
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @isDebug = 1 BEGIN
				SELECT @contractGuid
			END
			ELSE BEGIN
				begin try
					EXEC Stg.etl.runProcessContractUpdate 
						@contractGuid = @contractGuid,
						@processType = 'ReloadData4StrategyDatamartByContract'
				end try
				begin catch
					print ERROR_MESSAGE()
				end catch
		     END

			FETCH NEXT FROM cur_contract INTO @contractGuid
		END

		CLOSE cur_contract
		DEALLOCATE cur_contract
	END
END


