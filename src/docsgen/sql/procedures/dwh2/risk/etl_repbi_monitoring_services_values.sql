
--exec [dwh2].[risk].[etl_repbi_monitoring_services_values]
CREATE PROCEDURE [risk].[etl_repbi_monitoring_services_values]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		DROP TABLE IF EXISTS #results;
		SELECT 
		DISTINCT 'Origination_fnp_fedresurs_parse' AS [Таблица]
		,cast('messages_type' as nvarchar(255)) AS [Поле]
		,a.messages_type AS [Значение]
		INTO #results
		FROM [stg].[_loginom].[Origination_fnp_fedresurs_parse] a
		LEFT JOIN risk.det_monitoring_services_values s 
			ON isnull(a.messages_type, 'xxxx') = isnull(s.[Значение], 'xxxx')
			AND s.[Таблица] = 'Origination_fnp_fedresurs_parse'
			AND s.[Поле] = 'messages_type'
		WHERE s.[Значение] IS NULL
		and a.userName = 'service' --18/03/26 чеснокова
		AND a.messages_type IS NOT NULL
		AND a.call_date > getdate() - 5;

		INSERT INTO #results
		SELECT 
		DISTINCT 'Origination_fnp_fedresurs_parse' AS [Таблица]
		,'messages_related_messages_name' AS [Поле]
		,a.messages_related_messages_name AS [Значение]
		FROM [stg].[_loginom].[Origination_fnp_fedresurs_parse] a
		LEFT JOIN risk.det_monitoring_services_values s 
			ON isnull(a.messages_related_messages_name, 'xxxx') = isnull(s.[Значение], 'xxxx')
			AND s.[Таблица] = 'Origination_fnp_fedresurs_parse'
			AND s.[Поле] = 'messages_related_messages_name'
		WHERE s.[Значение] IS NULL
		and a.userName = 'service' --18/03/26 чеснокова
		AND a.messages_related_messages_name IS NOT NULL
		AND a.call_date > getdate() - 5;

		INSERT INTO #results
		SELECT 
		DISTINCT 'Origination_fnp_fedresurs_parse' AS [Таблица]
		,'success' AS [Поле]
		,a.success AS [Значение]
		FROM [stg].[_loginom].[Origination_fnp_fedresurs_parse] a
		LEFT JOIN risk.det_monitoring_services_values s 
			ON isnull(a.success, 'xxxx') = isnull(s.[Значение], 'xxxx')
			AND s.[Таблица] = 'Origination_fnp_fedresurs_parse'
			AND s.[Поле] = 'success'
		WHERE s.[Значение] IS NULL
		and a.userName = 'service' --18/03/26 чеснокова
		AND a.success IS NOT NULL
		AND a.call_date > getdate() - 5;

		INSERT INTO #results
		SELECT 
		DISTINCT 'Origination_fnp_parse' AS [Таблица]
		,'reestr_done' AS [Поле]
		,a.reestr_done AS [Значение]
		FROM [stg].[_loginom].Origination_fnp_parse a
		LEFT JOIN risk.det_monitoring_services_values s 
			ON (
				isnull(a.reestr_done, 'xxxx') = isnull(s.[Значение], 'xxxx')
				OR a.reestr_done = ''
				OR a.reestr_done IS NULL
				)
			AND s.[Таблица] = 'Origination_fnp_parse'
			AND s.[Поле] = 'reestr_done'
		WHERE s.[Значение] IS NULL
		and a.userName = 'service' --18/03/26 чеснокова
		AND a.reestr_done IS NOT NULL
		AND a.call_date > getdate() - 5;

		INSERT INTO #results
		SELECT 
		DISTINCT 'Origination_gibdd_parse' AS [Таблица]
		,'accidents_accidentType' AS [Поле]
		,a.accidents_accidentType AS [Значение]
		FROM [stg].[_loginom].Origination_gibdd_parse a
		LEFT JOIN risk.det_monitoring_services_values s 
			ON (
				isnull(a.accidents_accidentType, 'xxxx') = isnull(s.[Значение], 'xxxx')
				OR a.accidents_accidentType = ''
				OR a.accidents_accidentType IS NULL
				)
			AND s.[Таблица] = 'Origination_gibdd_parse'
			AND s.[Поле] = 'accidents_accidentType'
		WHERE s.[Значение] IS NULL
		and a.userName = 'service' --18/03/26 чеснокова
		AND a.accidents_accidentType IS NOT NULL
		AND a.call_date > getdate() - 5;
		
		DECLARE @cnt INT
			,@tableHTML NVARCHAR(MAX);

		SET @tableHTML = N'<H2> Новые значения при ответе сервисов! </H2>' + N'<table border="1" cellspacing="0" cellpadding="0">' + N'<tr><th>Таблица</th>' + N'<th>Поле</th>' + N'<th>Значение</th>' + CAST((
				SELECT DISTINCT td = a.[Таблица]
					,' '
					,td = a.[Поле]
					,' '
					,td = a.[Значение]
				FROM #results a
				FOR XML PATH('tr')
					,TYPE
				) AS NVARCHAR(MAX)) + N'</table>';

		SELECT @cnt = count(*)
		FROM #results;

		IF @cnt > 0
			EXEC msdb.dbo.sp_send_dbmail @recipients = 'risk_team@carmoney.ru; Полина Прокопенко <p.prokopenko@techmoney.ru>'
				,@profile_name = 'Default'
				,@subject = 'Мониторинг значений ответов сервисов'
				,@body = @tableHTML
				,@body_format = 'HTML';

		EXEC risk.set_debug_info @sp_name
			,'FINISH';
	END TRY

	BEGIN CATCH
		DECLARE @msg NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		DECLARE @subject NVARCHAR(255) = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'risk_tech@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;
