
--Онлайн мониторинг 0-х метрик по БКИ
--exec [risk].[etl_repbi_loginom_online_mon_bki_metrics];
CREATE PROCEDURE [risk].[etl_repbi_loginom_online_mon_bki_metrics]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		EXEC risk.set_debug_info @sp_name
			,'START';

		DROP TABLE
		
		IF EXISTS #src_loginom_monitoring_metics;
		
		create table #src_loginom_monitoring_metics
		(
			metric nvarchar(200)
			,prc smallmoney
			,target_value smallmoney
		)

		insert  into #src_loginom_monitoring_metics(
			metric
			,prc
			,target_value
		)
		select 
			metric = 'Мониторинг на 0-е метрики ПДН (Доходы). Доля нулевых значений'
			,prc = sum(case when isnull(eqxAverageMonthlyIncomePdn,0) = 0 then 1 else 0 end)/cast(count(*) AS FLOAT)
			,target_value = 0.15
		from stg._loginom.Origination_equifax_aggregates_4
		 where call_date > dateadd(hh, -4, getdate())

		 insert  into #src_loginom_monitoring_metics(
			metric
			,prc
			,target_value
		)
		select 
			metric = 'Мониторинг на 0-е метрики ПДН (Расходы). Доля нулевых значений'
			,prc = sum(case when isnull(kbkiEqxAverageMonthlyPaymentTotalAmtPdn,0) = 0 then 1 else 0 end)/cast(count(*) AS FLOAT)
			,target_value = 0.10
		from stg._loginom.Origination_kbkiEqxAggregates
		 where call_date > dateadd(hh, -4, getdate())
		/*
			SELECT cast('Мониторинг на 0-е метрики ПДН. Доля нулевых значений' AS VARCHAR(200)) AS metric
				,sum(CASE WHEN bki_income = 0 AND bki_exp_amount = 0 THEN 1 ELSE 0 END) / cast(count(*) AS FLOAT) AS prc
				,CASE WHEN sum(CASE WHEN bki_income = 0 AND bki_exp_amount = 0 THEN 1 ELSE 0 END) / cast(count(*) AS FLOAT) > 0.1 THEN 1 ELSE 0 END AS alert_flag
				,0.1 AS target_value
			
			FROM stg._loginom.bki_income_exp_pdn
			WHERE call_date > dateadd(hh, -4, getdate());
			*/
		--INSERT INTO #src_loginom_monitoring_metics
		--SELECT 'Мониторинг на 0-е метрики ПДН. Доля нулевых значений при "толстом" хите' AS metric
		--	,sum(CASE WHEN bki_income = 0 AND bki_exp_amount = 0 AND e.thick_hit_equi = 1 THEN 1 ELSE 0 END) / cast(count(*) AS FLOAT) AS prc
		--	,CASE WHEN sum(CASE WHEN bki_income = 0 AND bki_exp_amount = 0 AND e.thick_hit_equi = 1 THEN 1 ELSE 0 END) / cast(count(*) AS FLOAT) > 0.02 THEN 1 ELSE 0 END AS alert_flag
		--	,'2%' AS target_value
		--FROM stg._loginom.bki_income_exp_pdn a
		--INNER JOIN stg._loginom.Origination_equifax_aggregates_4 e ON a.number = e.number AND isnull(a.run_id, 0) = isnull(e.run_id, 0) AND a.stage = e.stage
		--WHERE a.call_date > dateadd(hh, -4, getdate());

		INSERT INTO #src_loginom_monitoring_metics
		(
			metric
			,prc
			,target_value
		)
		SELECT 'Мониторинг 0-х метрик по БКИ. НБКИ - мониторинг доли заявок без активных договоров' AS metric
			,sum(CASE WHEN isnull(CNT_ACT_ACCS_NBKI,0) + isnull(CNT_DQ_ACCS_NBKI,0) = 0 THEN 1 ELSE 0 END) / cast(count(*) AS FLOAT) AS prc
			--,CASE WHEN sum(CASE WHEN CNT_ACT_ACCS_NBKI + CNT_DQ_ACCS_NBKI = 0 THEN 1 ELSE 0 END) / cast(count(*) AS FLOAT) > 0.04 THEN 1 ELSE 0 END AS alert_flag
			,0.10 AS target_value
		FROM stg._loginom.Origination_nbch_aggregates a
		WHERE a.call_date > dateadd(hh, -4, getdate()) AND thick_hit_nbki = 1;

		INSERT INTO #src_loginom_monitoring_metics
		(
			metric
			,prc
			,target_value
		)
		SELECT 'Мониторинг 0-х метрик по БКИ. НБКИ - мониторинг доли заявок с нулевой суммой просроченных платежей' AS metric
			,sum(CASE WHEN thick_hit_nbki = 1 AND SUM_DQ_PMTS_NBKI = 0 THEN 1 ELSE 0 END) / cast(count(*) AS FLOAT) AS prc
			--,CASE WHEN sum(CASE WHEN thick_hit_nbki = 1 AND SUM_DQ_PMTS_NBKI = 0 THEN 1 ELSE 0 END) / cast(count(*) AS FLOAT) > 0.6 THEN 1 ELSE 0 END AS alert_flag
			,0.6 AS target_value
		FROM stg._loginom.Origination_nbch_aggregates a
		WHERE a.call_date > dateadd(hh, -4, getdate());

		INSERT INTO #src_loginom_monitoring_metics
		(
			metric
			,prc
			,target_value
		)
		SELECT 'Мониторинг 0-х метрик по БКИ. ЭКС - мониторинг доли заявок без активных договоров' AS metric
			,sum(CASE WHEN isnull(CNT_ACT_ACCS_EQUI,0) + isnull(CNT_DQ_ACCS_EQUI,0) = 0 THEN 1 ELSE 0 END) / cast(count(*) AS FLOAT) AS prc
			--,CASE WHEN sum(CASE WHEN CNT_ACT_ACCS_EQUI + CNT_DQ_ACCS_EQUI = 0 THEN 1 ELSE 0 END) / cast(count(*) AS FLOAT) > 0.03 THEN 1 ELSE 0 END AS alert_flag
			,0.1 AS target_value
		FROM stg._loginom.Origination_equifax_aggregates_4 a
		WHERE a.call_date > dateadd(hh, -4, getdate()) AND thick_hit_equi = 1;

		INSERT INTO #src_loginom_monitoring_metics
		(
			metric
			,prc
			,target_value
		)
		SELECT 'Мониторинг 0-х метрик по БКИ. ЭКС - мониторинг доли заявок с нулевой суммой просроченных платежей' AS metric
			,sum(CASE WHEN thick_hit_equi = 1 AND SUM_DQ_PMTS_EQUI = 0 THEN 1 ELSE 0 END) / cast(count(*) AS FLOAT) AS prc
			--,CASE WHEN sum(CASE WHEN thick_hit_equi = 1 AND SUM_DQ_PMTS_EQUI = 0 THEN 1 ELSE 0 END) / cast(count(*) AS FLOAT) > 0.60 THEN 1 ELSE 0 END AS alert_flag
			,0.6 AS target_value
		FROM stg._loginom.Origination_equifax_aggregates_4 a
		WHERE a.call_date > dateadd(hh, -4, getdate());

		DROP TABLE

		IF EXISTS #trigger_src;
			SELECT *
			INTO #trigger_src
			FROM #src_loginom_monitoring_metics
			WHERE prc>=target_value
			
			--alert_flag = 1;

		DECLARE @cnt INT
			,@message_text VARCHAR(8000)
			,@source_text VARCHAR(8000)
			,@body_html VARCHAR(8000)

		SELECT @cnt = count(*)
		FROM #trigger_src;

		SELECT @message_text = 'Внимание! Доля метрик по БКИ, по которым есть превышение установленных значений за последние 4 часа: <br>';


		WITH src
		AS (
			SELECT CONCAT (
					metric
					,' - '
					,FORMAT(round(prc, 2), 'p2')
					,'% при целевом значении в '
					,format(target_value, 'p2')
					) AS source_cnt
			FROM #trigger_src
			)
		SELECT @source_text = COALESCE(@source_text + ';<br> ', '') + source_cnt
		FROM src;

		SELECT @body_html = CONCAT (
				'<p style="margin-left:0cm; margin-right:0cm"><span style="font-family:Verdana,Geneva,sans-serif"><span style="font-size:11pt"><em><span style="font-size:14.0pt"><span style="color:red">'
				,@message_text
				,'</span></span></em></span></span></p>'
				,'<p style="margin-left:0cm; margin-right:0cm"><span style="font-family:Verdana,Geneva,sans-serif"><span style="font-size:11pt"><em><span style="font-size:10.0pt"><span style="color:black">'
				,@source_text
				,'</span></span></em></span></span></p>'
				);

		IF @source_text IS NOT NULL
			EXEC risk.set_debug_info @sp_name
				,'Errors';

		IF @cnt > 0
			EXEC msdb.dbo.sp_send_dbmail @recipients = 'AlA.Kurikalov@smarthorizon.ru; risk_portfolio@carmoney.ru; risk-technology@carmoney.ru;'
				,@subject = 'Loginom, онлайн мониторинг в разрезе метрик по БКИ'
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
