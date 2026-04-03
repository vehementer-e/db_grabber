
--exec [risk].[etl_repbi_loginom_online_mon_services];
CREATE PROCEDURE [risk].[etl_repbi_loginom_online_mon_services]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		EXEC risk.set_debug_info @sp_name
			,'START';

		-- В Original_response за последние 4 часа смотрим количество вызовов с ошибками в разрезе 
		-- каждого из сервиса (вне зависимости от того, сколько вызовов было за эти 4 часа/вне зависимости 
		-- от того, сколько было вызовов в разрезе каждой заявки). Если при вызове сервиса или 
		-- Original_response.[JSON] is null или [JSON] = '' или Original_response.ErrorID>0 или 
		-- Original_response.validReport_flg=0, то считаем что вызов сервиса был с ошибкой. Если доля 
		-- вызовов сервиса с ошибками больше 30% для FSSP или больше 20% для остальных сервисов - письмо с аллертом на почту
		--Список сервисок с и целевыми показателямии для Alter
		declare @sourceService table (sourceService nvarchar(255), targetPercentage smallmoney)
		insert into @sourceService 
		select sourceService, targetPercentage
		from(
			VALUES 
			  ('fssp', 0.3)
			,('checkFile', 0.3)
			,('KbkiEqx', 0.3)
			,('JuicyScore', 0.1)
			,('default', 0.2)
			)  t(sourceService, targetPercentage)

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
			WHERE a.request_date > getdate() - 0.5
				AND a.process <> 'Monitoring'
			ORDER BY a.request_date;

		DROP TABLE

		IF EXISTS #src_loginom_monitoring_row_num;
			SELECT a.*
				,ROW_NUMBER() OVER (
					PARTITION BY a.source ORDER BY a.request_date DESC
					) AS rn_source
				,CASE 
					WHEN a.[JSON] IS NULL
						OR substring(a.[JSON], 1, 5) = ''
						OR a.ErrorID > 0
						OR a.validReport_flg = 0
						THEN 1
					ELSE 0
					END AS error_flag
			INTO #src_loginom_monitoring_row_num
			FROM #src_loginom_monitoring a;

		DROP TABLE

		IF EXISTS #trigger_src;
			SELECT source
				,cnt = count(*)
				,summ = sum(error_flag)
				,prc = sum(error_flag) / nullif(cast(count(*) AS FLOAT),0)
				,targetPercentage =  min(ss.targetPercentage)
			INTO #trigger_src
			FROM #src_loginom_monitoring_row_num t
			inner join @sourceService ss on 
			(ss.sourceService = t.source or sourceService=  'default')
			WHERE request_date > getdate() - 0.16666
				AND source IN ('fms', 
					'equifax', 
					'okbscore', 
					'nbch PV2 score', 
					'ExchangeRates', 
					'DBrain', 
					'photosByRequest', 
					'nbch',
					'JuicyScore', --DWH-2652
					'KbkiEqx'	  --DWH-2652
					)
			GROUP BY source;
		
		DELETE t
		FROM #trigger_src t
		where t.prc<=targetPercentage
		--WHERE (
		--		source <> 'FSSP'
		--		AND prc <= 0.2
		--		)
		--	OR (
		--		source IN ('FSSP', 'checkFile','KbkiEqx')
		--		AND prc <= 0.3
		--		)
		--	or (source IN ('JuicyScore')
		--		AND prc <= 0.1
		--		);

		DECLARE @cnt INT
			,@message_text VARCHAR(8000)
			,@source_text VARCHAR(8000)
			,@body_html VARCHAR(8000)

		SELECT @cnt = sum(cnt)
		FROM #trigger_src;

		SELECT @message_text = 'Внимание! За последние 4 часа количество запросов во внешние сервисы, выполнившихся с ошибками или оставшихся без ответа, превышает установленные значения: <br>';

		WITH src
		AS (
			SELECT CONCAT (
					upper(source)
					,' - '
					,summ
					,' шт. из '
					,cnt
					,' ('
					, FORMAT(round(prc, 2), 'p2') ,'
						)'
					,'при целевом значении в ', format(targetPercentage, 'p2')

					) AS source_cnt
			FROM #trigger_src
			)
		SELECT @source_text = COALESCE(@source_text + '; ', '') + source_cnt
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

		IF @cnt > 0
			EXEC msdb.dbo.sp_send_dbmail @recipients = 'AlA.Kurikalov@smarthorizon.ru; risk_portfolio@carmoney.ru; risk-technology@carmoney.ru;'
				--
				,@subject = 'Loginom, онлайн мониторинг в разрезе сервисов'
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
