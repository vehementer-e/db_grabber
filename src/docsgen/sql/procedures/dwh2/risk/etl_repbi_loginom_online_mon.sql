
--exec [risk].[etl_repbi_loginom_online_mon];
CREATE PROCEDURE [risk].[etl_repbi_loginom_online_mon]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		EXEC risk.set_debug_info @sp_name
			,'START';

		-- в Original_response смотрим следующий показатель:
		-- за последние 100 заявок, отсортированных по request_date, смотрим количество заявок с ошибками (заявок, у которых:
		-- или Original_response.[JSON] is null ИЛИ [JSON] = '' или Original_response.ErrorID>0 или Original_response.validReport_flg=0)
		-- если заявок с ошибками c source='FSSP' больше 20 или заявок с ошибками с source<>'FSSP' больше 10, то аллерт на почту
		DROP TABLE

		IF EXISTS #src_loginom_monitoring;
			SELECT a.request_date
				,a.person_id
				,a.json
				,CASE 
					WHEN a.source LIKE '%bankrupts%'
						THEN 'bankrupts'
					WHEN a.source LIKE '%checkFile%'
						THEN 'checkFile'
					WHEN a.source LIKE '%equifax%'
						THEN 'equifax'
					WHEN a.source LIKE '%ExchangeRates%'
						THEN 'ExchangeRates'
					WHEN a.source LIKE '%fincard%'
						THEN 'fincard'
					WHEN a.source LIKE '%fms%'
						THEN 'fms'
					WHEN a.source LIKE '%fnp%'
						THEN 'fnp'
					WHEN a.source LIKE '%fssp%'
						THEN 'fssp'
					WHEN a.source LIKE '%gibdd%'
						THEN 'gibdd'
					WHEN a.source LIKE '%nbch%'
						THEN 'nbch'
					WHEN a.source LIKE '%okbscore%'
						THEN 'okbscore'
					WHEN a.source LIKE '%qiwi%'
						THEN 'qiwi'
					WHEN a.source LIKE '%rsa%'
						THEN 'rsa'
					WHEN a.source LIKE '%spectrum%'
						THEN 'spectrum'
					WHEN a.source LIKE '%xneo%'
						THEN 'xneo'
					ELSE a.source
					END AS source
				,a.ErrorID
				,a.validReport_flg
			INTO #src_loginom_monitoring
			FROM stg._loginom.Original_response a
			WHERE a.request_date > getdate() - 1
				AND a.process <> 'Monitoring'
			ORDER BY a.request_date;

		DROP TABLE

		IF EXISTS #selected_100_person_id;
			WITH cte
			AS (
				SELECT a.*
					,ROW_NUMBER() OVER (
						PARTITION BY a.person_id ORDER BY a.request_date
						) AS rn_request
				FROM #src_loginom_monitoring a
				)
				,src
			AS (
				SELECT a.request_date
					,a.person_id
					,a.source
					,ROW_NUMBER() OVER (
						ORDER BY a.request_date DESC
						) AS rn_person_id
				FROM cte a
				WHERE a.rn_request = 1
				)
			SELECT DISTINCT person_id
				,request_date
			INTO #selected_100_person_id
			FROM src
			WHERE rn_person_id <= 100;

		DROP TABLE

		IF EXISTS #trigger;
			SELECT DISTINCT s.request_date
				,s.person_id
				,CASE 
					WHEN lm.person_id IS NULL
						THEN 0
					ELSE 1
					END AS error_flag
				,lm.source
			INTO #trigger
			FROM #selected_100_person_id s
			LEFT JOIN #src_loginom_monitoring lm ON lm.person_id = s.person_id
				AND (
					lm.[JSON] IS NULL
					OR substring(lm.[JSON], 1, 5) = ''
					OR lm.ErrorID > 0
					OR lm.validReport_flg = 0
					)
			ORDER BY 2;

		DECLARE @cnt_fssp INT
			,@cnt_not_fssp INT
			,@cnt INT
			,@message_text VARCHAR(8000)
			,@source_text VARCHAR(8000)
			,@body_html VARCHAR(8000)
			,@monitor_dt DATETIME;

		DROP TABLE

		IF EXISTS #trigger_src;
			SELECT source
				,count(*) AS cnt
			INTO #trigger_src
			FROM #trigger
			WHERE error_flag = 1
			GROUP BY source;

		DELETE
		FROM #trigger_src
		WHERE (
				source <> 'FSSP'
				AND cnt <= 10
				)
			OR (
				source = 'FSSP'
				AND cnt <= 20
				);

		SELECT @cnt_fssp = count(*)
		FROM #trigger_src
		WHERE source = 'FSSP';

		SELECT @cnt_not_fssp = count(*)
		FROM #trigger_src
		WHERE source <> 'FSSP';

		SELECT @cnt = sum(cnt)
		FROM #trigger_src;

		SELECT @monitor_dt = min(request_date)
		FROM #trigger;

		SELECT @message_text = CONCAT (
				'Внимание, количество запросов во внешние сервисы без ответа превышает установленные значения ('
				,@cnt
				,' шт. из 100 за период с '
				,format(@monitor_dt, 'dd/MM/yyyy hh:mm tt')
				,'). <br>'
				);

		WITH src
		AS (
			SELECT CONCAT (
					source
					,' - '
					,sum(cnt)
					,' шт.'
					) AS source_cnt
			FROM #trigger_src
			GROUP BY source
			)
		SELECT @source_text = COALESCE(@source_text + ', ', '') + source_cnt
		FROM src;

		SELECT @body_html = CONCAT (
				'<p style="margin-left:0cm; margin-right:0cm"><span style="font-family:Verdana,Geneva,sans-serif"><span style="font-size:11pt"><em><span style="font-size:14.0pt"><span style="color:red">'
				,CONCAT (
					@message_text
					,@source_text
					)
				,'</span></span></em></span></span></p>'
				);

		IF @source_text IS NOT NULL
			EXEC risk.set_debug_info @sp_name
				,@source_text;

		IF @cnt_fssp > 0
			OR @cnt_not_fssp > 0
			EXEC msdb.dbo.sp_send_dbmail @recipients = 'AlA.Kurikalov@smarthorizon.ru; risk_portfolio@carmoney.ru; risk-technology@carmoney.ru;'--p.chesnokova@techmoney.ru; a.stavnichaya@techmoney.ru; d.starikov@carmoney.ru; p.prokopenko@techmoney.ru; n.zhideleva@carmoney.ru'
				,@subject = 'Loginom, онлайн мониторинг'
				,@body = @body_html
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

		EXEC msdb.dbo.sp_send_dbmail @recipients = 'risk-technology@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;
