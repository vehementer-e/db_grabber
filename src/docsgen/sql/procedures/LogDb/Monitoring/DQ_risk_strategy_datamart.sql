
-- ============================================= 
-- Author: А. Никитин
-- Create date: 15.02.2023
-- Description: DWH-1947 DQ данных risk.strategy_datamart
-- ============================================= 
CREATE PROC [Monitoring].[DQ_risk_strategy_datamart]
	@isDebug int = 0,
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@SendEmail int = 0
AS
BEGIN
SET NOCOUNT ON;
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @html_table nvarchar(max)
	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024), @description nvarchar(1024)
	DECLARE @eventMessageText nvarchar(max) = '' -- большое сообщение для расширенного логирования
	DECLARE @deal_count int, @deal_count_all int = 0
	DECLARE @table_name varchar(256) = 'dwh2.risk.strategy_datamart'
	DECLARE @contractGuid nvarchar(36)

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @SendEmail = isnull(@SendEmail, 0)

	SELECT @eventName = 'Monitoring_DQ_risk_strategy_datamart'

	DROP TABLE IF EXISTS #t_monitoring
	CREATE TABLE #t_monitoring(
		КодДоговора nvarchar(20),
		ДоговорСсылка binary(16),
		ДоговорGuid nvarchar(36),
		ДатаДоговора datetime2(0),
		--ДатаПоследнегоСтатуса datetime2(0),
		--ПоследнийСтатус nvarchar(100),
		ФИО nvarchar(255)
	)

	DROP TABLE IF EXISTS #t_contract
	CREATE TABLE #t_contract(contractGuid nvarchar(36))

	--1 is_active = 0 AND end_date IS NULL
	INSERT #t_monitoring
	(
		КодДоговора,
		ДоговорСсылка,
		ДоговорGuid,
		ДатаДоговора,
		--ДатаПоследнегоСтатуса,
		--ПоследнийСтатус
		ФИО
	)
	SELECT 
		КодДоговора = S.external_id,
		ДоговорСсылка = D.Ссылка,
		ДоговорGuid = dwh2.dbo.getGUIDFrom1C_IDRREF(D.Ссылка),
		ДатаДоговора = S.start_date,
		ФИО = S.fio
		--D.ДатаПоследнегоСтатуса,
		--D.ПоследнийСтатус
	--FROM Stg.tmp.TMP_AND_risk_strategy_datamart AS S
	FROM dwh2.risk.strategy_datamart AS S
		LEFT JOIN Stg._1cCMR.Справочник_Договоры AS D
			ON D.Код = S.external_id
	WHERE 1=1
		AND S.is_active = 0
		AND S.end_date IS NULL
		--test
		--OR S.external_id IN ('21031800089281')

	SELECT @deal_count = count(*)
	FROM #t_monitoring AS M

	--IF @deal_count = 0 BEGIN
	--	RETURN 0
	--END

	IF @deal_count > 0
	BEGIN
		SELECT @deal_count_all = @deal_count_all + @deal_count

		INSERT #t_contract(contractGuid)
		SELECT DISTINCT M.ДоговорGuid 
		FROM #t_monitoring AS M

		--SELECT @description = 
		--	(SELECT
		--		'TableName' = @table_name,
		--		'Message' = 'Количество договоров, у которых is_active = 0 and end_date IS NULL: ' + convert(varchar(10), @deal_count)
		--	FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)

		SELECT @html_table = (
			SELECT concat(
					'<tr>',
						'<td>', M.КодДоговора, '</td>',
						'<td>', convert(varchar(19), M.ДатаДоговора, 120), '</td>',
						'<td>', M.ФИО, '</td>',
					'</tr>'
				)
			FROM #t_monitoring AS M
			ORDER BY M.КодДоговора
			FOR XML PATH('')
		)
		SELECT @html_table = replace(@html_table, '&lt;', '<')
		SELECT @html_table = replace(@html_table, '&gt;', '>')

		--test
		IF @isDebug = 1 BEGIN
			--SELECT @html_table
			--SELECT * FROM #t_monitoring AS TM ORDER BY TM.КодДоговора
			DROP TABLE IF EXISTS ##t_monitoring
			SELECT * INTO ##t_monitoring FROM #t_monitoring AS TM

			SELECT @deal_count
			--RETURN 0
		END

		SELECT @html_table = 
			concat(
				'<h3>Договора, у которых is_active = 0 and end_date IS NULL. ',
				' (всего: ', convert(varchar(10), @deal_count), ')</h3>',
				'<br>',
				'<table cellspacing="0" border="1" cellpadding="5">',
				'<tr>',
					'<td><b>Код договора</b></td>',
					'<td><b>Дата договора</b></td>',
					'<td><b>ФИО</b></td>',
				'</tr>',
				@html_table,
				'</table><br><br>'
			)

		SELECT @eventMessageText = @eventMessageText + @html_table
	END



	--2 is_active = 0 AND total_rest <> 0
	TRUNCATE TABLE #t_monitoring


	INSERT #t_monitoring
	(
		КодДоговора,
		ДоговорСсылка,
		ДоговорGuid,
		ДатаДоговора,
		--ДатаПоследнегоСтатуса,
		--ПоследнийСтатус
		ФИО
	)
	SELECT 
		КодДоговора = S.external_id,
		ДоговорСсылка = D.Ссылка,
		ДоговорGuid = dwh2.dbo.getGUIDFrom1C_IDRREF(D.Ссылка),
		ДатаДоговора = S.start_date,
		ФИО = S.fio
		--D.ДатаПоследнегоСтатуса,
		--D.ПоследнийСтатус
	--FROM Stg.tmp.TMP_AND_risk_strategy_datamart AS S
	FROM dwh2.risk.strategy_datamart AS S
		LEFT JOIN Stg._1cCMR.Справочник_Договоры AS D
			ON D.Код = S.external_id
	WHERE 1=1
		AND S.is_active = 0
		AND S.total_rest <> 0
		--test
		--OR S.external_id IN ('21031800089281')

	SELECT @deal_count = count(*)
	FROM #t_monitoring AS M

	IF @deal_count > 0
	BEGIN
		SELECT @deal_count_all = @deal_count_all + @deal_count

		INSERT #t_contract(contractGuid)
		SELECT DISTINCT M.ДоговорGuid 
		FROM #t_monitoring AS M
		WHERE NOT EXISTS(SELECT TOP 1 1 FROM #t_contract AS X WHERE X.contractGuid = M.ДоговорGuid)

		SELECT @html_table = (
			SELECT concat(
					'<tr>',
						'<td>', M.КодДоговора, '</td>',
						'<td>', convert(varchar(19), M.ДатаДоговора, 120), '</td>',
						'<td>', M.ФИО, '</td>',
					'</tr>'
				)
			FROM #t_monitoring AS M
			ORDER BY M.КодДоговора
			FOR XML PATH('')
		)
		SELECT @html_table = replace(@html_table, '&lt;', '<')
		SELECT @html_table = replace(@html_table, '&gt;', '>')

		SELECT @html_table = 
			concat(
				'<h3>Договора, у которых is_active = 0 and total_rest <> 0. ',
				' (всего: ', convert(varchar(10), @deal_count), ')</h3>',
				'<br>',
				'<table cellspacing="0" border="1" cellpadding="5">',
				'<tr>',
					'<td><b>Код договора</b></td>',
					'<td><b>Дата договора</b></td>',
					'<td><b>ФИО</b></td>',
				'</tr>',
				@html_table,
				'</table><br><br>'
			)

		SELECT @eventMessageText = @eventMessageText + @html_table
	END

	--test
	--IF @isDebug = 1 BEGIN
	--	SELECT @deal_count_all
	--	SELECT @eventMessageText
	--	RETURN 0
	--END

	IF @deal_count_all > 0
	BEGIN
		SELECT @eventType = 'warning'
		SELECT @message = concat('Таблица ', @table_name, '.')
		SELECT @description = 
			(SELECT
				'TableName' = @table_name,
				'Message' = 'Количество ошибок: ' + convert(varchar(10), @deal_count_all)
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
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

	--DWH-2220 Обновление данных по результатам Monitoring_DQ_risk_strategy_datamart
	IF EXISTS(SELECT TOP 1 1 FROM #t_contract)
	BEGIN
		DECLARE cur_contract CURSOR FOR
		SELECT DISTINCT C.contractGuid
		FROM #t_contract AS C
		ORDER BY C.contractGuid

		OPEN cur_contract
		FETCH NEXT FROM cur_contract INTO @contractGuid
		WHILE @@FETCH_STATUS = 0
		BEGIN
			begin try
			EXEC Stg.etl.runProcessContractUpdate 
					@contractGuid = @contractGuid,
					@processType = 'ReloadData4StrategyDatamartByContract'
			end try
			begin catch
				print ERROR_MESSAGE()
			end catch
			FETCH NEXT FROM cur_contract INTO @contractGuid
		END

		CLOSE cur_contract
		DEALLOCATE cur_contract
	END

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @eventName,
		@eventType = @eventType,
		@message = @message,
		@description = @description,
		@SendEmail = @SendEmail,
		@ProcessGUID = @ProcessGUID,
		@eventMessageText = @eventMessageText,
		@loggerName = 'admin_risk'
		--@loggerName = 'admin_test'
END 

