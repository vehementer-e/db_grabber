
--Отчет "Мониторинг входящего потока и уровня одобрения стратегии"
--exec [risk].[etl_repbi_monitoring_ar];
CREATE PROCEDURE [risk].[etl_repbi_monitoring_ar]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		DROP TABLE

		IF EXISTS #risk_par
			SELECT A.number
				,A.c1_date
				,A.c1_nbchPV2score
				,A.c1_okbscore
				,A.c1_decision
				,A.c1_date AS stage_date
				,day(A.c1_date) AS [DAY]
				,month(A.c1_date) AS MON
				,CASE 
					WHEN A.strategy_version LIKE '%NEW%'
						THEN 'NEW'
					WHEN A.strategy_version LIKE '%Rep%'
						THEN 'REP'
					WHEN A.strategy_version LIKE 'INST%'
						THEN 'INST'
					ELSE 'NEW'
					END AS STRATEGY_TYPE
			INTO #risk_par
			FROM [risk].[applications] a
			WHERE c1_date >= '20201001'
				AND c1_date < cast(current_timestamp AS DATE);

		DROP TABLE

		IF EXISTS #sample
			SELECT R.number
				,R.c1_date
				,R.[DAY]
				,R.MON
				,CASE 
					WHEN year(dateadd(day, - 1, Getdate())) * 100 + month(dateadd(day, - 1, Getdate())) = year(R.c1_date) * 100 + month(R.c1_date)
						THEN '2.CM'
					WHEN year(dateadd(month, - 1, dateadd(day, - 1, Getdate()))) * 100 + month(dateadd(month, - 1, dateadd(day, - 1, Getdate()))) = year(R.c1_date) * 100 + month(R.c1_date)
						THEN '1.LM'
					ELSE cast(year(R.c1_date) * 100 + month(R.c1_date) AS VARCHAR)
					END AS period_
				,R.STRATEGY_TYPE
				,CASE 
					WHEN R.c1_decision IS NOT NULL
						THEN 1
					ELSE 0
					END AS IS_COUNT
				,CASE 
					WHEN R.c1_decision = 'Accept'
						THEN 1
					ELSE 0
					END AS IS_APPROVED
				,CASE 
					WHEN c1_nbchPV2score IS NULL
						THEN '1.НБКИ-скор не рассчитан'
					WHEN c1_nbchPV2score < 56
						THEN '2. НБКИ 1-55'
					WHEN c1_nbchPV2score < 110
						THEN '3. НБКИ 56-109' 
					WHEN c1_nbchPV2score < 170
						THEN '4. НБКИ 110-169'
					WHEN c1_nbchPV2score >= 170 
						THEN'5. НБКИ >= 170'
					WHEN (
							c1_nbchPV2score = 0
							OR c1_nbchPV2score = ''
							)
						THEN '6.НБКИ 0'
					END AS nbki_gr
				,CASE 
					WHEN c1_okbscore IS NULL
						THEN '1. ОКБ-скор не рассчитан'
					WHEN c1_okbscore < 430
						THEN '2. <430'
					WHEN c1_okbscore < 450
						THEN '3. 430-449'
					WHEN c1_okbscore < 500
						THEN '4. 450-499'
					WHEN c1_okbscore < 520
						THEN '5. 500-519'
					WHEN c1_okbscore < 540
						THEN '6. 520-539'
					WHEN c1_okbscore < 560
						THEN '7. 540-559'
					WHEN c1_okbscore < 580
						THEN '8. 560-579'
					ELSE '9. >580'
					END AS okb_gr
				,r.stage_date
			INTO #sample
			FROM #risk_par R;

		/*final decision*/
		DROP TABLE

		IF EXISTS #sample_last
			SELECT number
				,stage_date
				,[DAY]
				,MON
				,period_
				,STRATEGY_TYPE
				,IS_COUNT
				,IS_APPROVED
				,nbki_gr
				,okb_gr
			INTO #sample_last
			FROM (
				SELECT S.*
					,ROW_NUMBER() OVER (
						PARTITION BY number ORDER BY stage_date DESC
						) rn
				FROM #sample S
				) SL
			WHERE SL.rn = 1;

		/*last day*/
		DROP TABLE

		IF EXISTS #CD
			SELECT number
				,stage_date
				,[DAY]
				,MON
				,CASE 
					WHEN cast(stage_date AS DATE) = dateadd(day, - 2, cast(current_timestamp AS DATE))
						THEN '3.LD'
					ELSE '4.CD'
					END AS period_
				,STRATEGY_TYPE
				,IS_COUNT
				,IS_APPROVED
				,nbki_gr
				,okb_gr
			INTO #CD
			FROM #sample_last
			WHERE stage_date >= dateadd(day, - 1, cast(current_timestamp AS DATE));

		/*the last but one day*/
		DROP TABLE

		IF EXISTS #LD
			SELECT number
				,stage_date
				,[DAY]
				,MON
				,period_ = '3.LD'
				,STRATEGY_TYPE
				,IS_COUNT
				,IS_APPROVED
				,nbki_gr
				,okb_gr
			INTO #LD
			FROM (
				SELECT S.*
					,ROW_NUMBER() OVER (
						PARTITION BY number ORDER BY stage_date DESC
						) rn
				FROM #sample S
				WHERE stage_date < dateadd(day, - 1, cast(current_timestamp AS DATE))
					AND stage_date >= dateadd(day, - 2, cast(current_timestamp AS DATE))
				) SLD
			WHERE SLD.rn = 1;

		IF object_id('risk.repbi_monitoring_ar') IS NOT NULL
			TRUNCATE TABLE risk.repbi_monitoring_ar;

		INSERT INTO risk.repbi_monitoring_ar
		SELECT number
			,iif(STRATEGY_TYPE = 'INST', 'INST', 'PTS') AS product
			,stage_date
			,[DAY]
			,MON
			,period_
			,STRATEGY_TYPE
			,IS_COUNT
			,IS_APPROVED
			,nbki_gr
			,okb_gr
			,getdate() AS dt_dml
		FROM (
			SELECT *
			FROM #sample_last
			
			UNION
			
			SELECT *
			FROM #LD
			
			UNION
			
			SELECT *
			FROM #CD
			) a
		WHERE period_ IN (
				'1.LM'
				,'2.CM'
				,'3.LD'
				,'4.CD'
				);

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
			,@recipients = 'a.kuznecov@techmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;
