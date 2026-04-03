
-- ============================================= 
-- Author: А. Никитин
-- Create date: 7.01.2024
-- Description: DWH-2383 DQ проверять есть ли данные в dm_CMRStatBalance для аннулированных договоров
-- ============================================= 
CREATE PROC Monitoring.[DQ_dm_CMRStatBalance3]
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
	DECLARE @count_rows int
	DECLARE @contractGuid nvarchar(36)

	DECLARE @table_name varchar(256) = 'dwh2.dbo.dm_CMRStatBalance'

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @SendEmail = isnull(@SendEmail, 0)

	SELECT @eventName = 'Monitoring_DQ_dm_CMRStatBalance3'
	--SELECT @event_name = concat('Мониторинг качества данных ', @table_name)
	--SELECT @eventName = 'В балансе есть данные с остатком для аннулированных договоров'

	DROP TABLE IF EXISTS #t_contract_cancelled
	CREATE TABLE #t_contract_cancelled
	(
		ДоговорНомер nvarchar(30),
		ДоговорСсылка binary(16),
		ДоговорGuid nvarchar(36),
		СтатусДоговораДата datetime2(0),
		СтатусДоговораНаименование nvarchar(100)
	)

	INSERT #t_contract_cancelled
	(
	    ДоговорНомер,
	    ДоговорСсылка,
	    ДоговорGuid,
		СтатусДоговораДата,
		СтатусДоговораНаименование
	)
	SELECT 
		ДоговорНомер = D.Код, 
		ДоговорСсылка = D.Ссылка,
		ДоговорGuid = cast(dwh2.dbo.getGUIDFrom1C_IDRREF(D.Ссылка) as uniqueidentifier),
		СтатусДоговораДата = min(dateadd(YEAR, -2000, SD.Период)), 
		СтатусДоговораНаименование = S.Наименование
	FROM Stg._1ccmr.Справочник_Договоры AS D
		INNER JOIN Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS SD
			ON SD.Договор = D.Ссылка
		INNER JOIN Stg._1cCMR.Справочник_СтатусыДоговоров AS S
			ON S.Ссылка = SD.Статус
	WHERE 1=1
		AND S.Код = '000000005' --Аннулирован	cancelled
		--AND D.Код IN ('23070821042016')
	GROUP BY 
		D.Код, 
		D.Ссылка,
		cast(dwh2.dbo.getGUIDFrom1C_IDRREF(D.Ссылка) as uniqueidentifier),
		S.Наименование
	--~17492

	CREATE CLUSTERED INDEX ix1 ON #t_contract_cancelled(ДоговорНомер)

	DROP TABLE IF EXISTS #t_contract
	CREATE TABLE #t_contract(contractGuid nvarchar(36))

	DROP TABLE IF EXISTS #t_Monitoring
	CREATE TABLE #t_Monitoring
	(
		rn int,
		ДоговорНомер nvarchar(30),
		ДоговорСсылка binary(16),
		ДоговорGuid nvarchar(36),
		[СтатусДоговораДата] datetime2(0),
		[СтатусДоговораНаименование] nvarchar(100),
		[d] datetime2(0),
		ОстатокВсего money
	)


	INSERT #t_Monitoring
	(
	    rn,
	    ДоговорНомер,
	    ДоговорСсылка,
	    ДоговорGuid,
	    СтатусДоговораДата,
	    СтатусДоговораНаименование,
	    d,
	    ОстатокВсего
	)
	SELECT 
		rn = row_number() OVER(ORDER BY D2.ДоговорНомер),
	    D2.ДоговорНомер,
	    D2.ДоговорСсылка,
	    D2.ДоговорGuid,
	    D2.СтатусДоговораДата,
	    D2.СтатусДоговораНаименование,
	    B2.d,
	    ОстатокВсего = B2.[остаток всего]
	FROM (
			SELECT 
				B.external_id,
				max_d = max(B.d)
			FROM #t_contract_cancelled AS D
				INNER JOIN dwh2.dbo.dm_CMRStatBalance AS B
					ON D.ДоговорНомер = B.external_id
			GROUP BY B.external_id
		) AS L
		INNER JOIN dwh2.dbo.dm_CMRStatBalance AS B2
			ON B2.external_id = L.external_id
			AND B2.d = L.max_d
			AND B2.[остаток всего] > 0
		INNER JOIN #t_contract_cancelled AS D2
			ON D2.ДоговорНомер = L.external_id
	
	SELECT @count_rows = count(*)
	--SELECT *
	FROM #t_Monitoring AS M

	IF @count_rows > 0
	BEGIN
		SELECT @eventType = 'warning'
		SELECT @message = concat('В ', @table_name, ' есть данные с остатком для аннулированных договоров.')
		SELECT @eventName = 'В балансе есть данные с остатком для аннулированных договоров'

		INSERT #t_contract(contractGuid)
		SELECT DISTINCT M.ДоговорGuid 
		FROM #t_monitoring AS M

		SELECT @description = 
			(SELECT
				'TableName' = @table_name,
				'Message' = 'Найдены данные с остатком для аннулированных договоров. Количество записей: ' + convert(varchar(10), @count_rows)
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)

		--var.2 html
		SELECT @eventMessageText = concat(
			'<table cellspacing="0" border="1" cellpadding="5">',
			--'<tr><td><b>Договор</b></td><td><b>Количество дублей</b></td></tr>', 
			'<tr>',
			'<td><b>#</b></td>',
			'<td><b>Договор</b></td>',
			'<td><b>Статус договора</b></td>',
			'<td><b>Дата статуса</b></td>',
			'<td><b>Последняя дата<br> в балансе</b></td>',
			'<td><b>Остаток Всего</b></td>',
			'</tr>', 
			(
				SELECT string_agg(
					concat(
						'<tr>',
						'<td>',convert(varchar(5), t.rn),'</td>',
						'<td>',t.ДоговорНомер,'</td>',
						'<td>',t.СтатусДоговораНаименование,'</td>',
						'<td>',format(t.СтатусДоговораДата,'dd.MM.yyyy HH:mm:ss'),'</td>',
						'<td>',format(t.d,'dd.MM.yyyy'),'</td>',
						'<td>',convert(varchar(10), t.ОстатокВсего),'</td>',
						'</tr>'
					), ' '
				) WITHIN GROUP (ORDER BY t.rn)
				FROM #t_Monitoring AS t
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

	--DWH-??? Перегрузить данные если сработал мониторинг Monitoring_DQ_dm_CMRStatBalance3
	IF EXISTS(SELECT TOP 1 1 FROM #t_contract)
		AND @isDebug = 0
		--DWH-2463 перезагрузка данных по Аннулированным договорам
		--пока не перегружать
		--AND 1=2
	BEGIN
		DECLARE cur_contract CURSOR FOR
		SELECT DISTINCT C.contractGuid
		FROM #t_contract AS C
		ORDER BY C.contractGuid

		OPEN cur_contract
		FETCH NEXT FROM cur_contract INTO @contractGuid
		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC Stg.etl.runProcessContractUpdate 
				@contractGuid = @contractGuid,
				@processType = 'ReloadData4StrategyDatamartByContract'

			FETCH NEXT FROM cur_contract INTO @contractGuid
		END

		CLOSE cur_contract
		DEALLOCATE cur_contract
	END

	--SELECT * from dbo.Emails

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @eventName,
		@eventType = @eventType,
		@message = @message,
		@description = @description,
		@SendEmail = @SendEmail,
		@ProcessGUID = @ProcessGUID,
		@eventMessageText = @eventMessageText,
		@loggerName = 'admin_test'
END
