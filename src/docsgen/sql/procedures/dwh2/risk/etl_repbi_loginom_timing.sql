
--exec [risk].[etl_repbi_loginom_timing];
CREATE PROCEDURE [risk].[etl_repbi_loginom_timing]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		DROP TABLE

		IF EXISTS #timing_wo_bad_steps;
			WITH base
			AS (
				SELECT cast(osl.step_date AS DATE) AS repdate
					,osl.stage
					,osl.step
					,osl.number
					,osl.step_date
					,ROW_NUMBER() OVER (
						PARTITION BY osl.number
						,osl.stage
						,osl.step ORDER BY osl.step_date DESC
						) AS rn
				FROM stg._loginom.Origination_step_log osl
				WHERE osl.step_date > cast(getdate() - 30 AS DATE)
					AND cast(osl.step_date AS DATE) <= cast(getdate() - 1 AS DATE)
					AND osl.number IS NOT NULL
				)
				,lead_sd
			AS (
				SELECT a.repdate
					,a.stage
					,a.step
					,a.number
					,a.step_date
					,isnull(lead(a.step_date) OVER (
							PARTITION BY a.number ORDER BY a.step_date
							), a.step_date) AS lead_step_date
				FROM base a
				WHERE a.rn = 1
				)
				,src
			AS (
				SELECT *
				FROM lead_sd
				
				UNION ALL
				
				SELECT DISTINCT repdate
					,stage
					,CONCAT (
						'В среднем по '
						,stage
						) AS step
					,number
					,min(step_date) OVER (
						PARTITION BY stage
						,repdate
						,number
						) AS step_date
					,max(step_date) OVER (
						PARTITION BY stage
						,repdate
						,number
						) AS lead_step_date
				FROM lead_sd
				)
			SELECT s.*
				,datediff(s, s.step_date, s.lead_step_date) AS step_duration
				,'wo_bad_steps' AS metric
			INTO #timing_wo_bad_steps
			FROM src s
			WHERE s.step <> 'Step 999';

		DROP TABLE

		IF EXISTS #timing_bad_steps;
			WITH base
			AS (
				SELECT cast(osl.step_date AS DATE) AS repdate
					,osl.stage
					,osl.step
					,osl.number
					,osl.step_date
					,ROW_NUMBER() OVER (
						PARTITION BY osl.number
						,osl.stage
						,osl.step ORDER BY osl.step_date DESC
						) AS rn
				FROM stg._loginom.Origination_step_log osl
				WHERE osl.step_date > cast(getdate() - 30 AS DATE)
					AND cast(osl.step_date AS DATE) <= cast(getdate() - 1 AS DATE)
					AND osl.number IS NOT NULL
				)
				,lead_sd
			AS (
				SELECT a.repdate
					,a.stage
					,a.step
					,a.number
					,a.step_date
					,isnull(lead(a.step_date) OVER (
							PARTITION BY a.number ORDER BY a.step_date
							), a.step_date) AS lead_step_date
				FROM base a
				WHERE a.rn > 1
				)
				,src
			AS (
				SELECT *
				FROM lead_sd
				
				UNION ALL
				
				SELECT DISTINCT repdate
					,stage
					,CONCAT (
						'В среднем по '
						,stage
						) AS step
					,number
					,min(step_date) OVER (
						PARTITION BY stage
						,repdate
						,number
						) AS step_date
					,max(step_date) OVER (
						PARTITION BY stage
						,repdate
						,number
						) AS lead_step_date
				FROM lead_sd
				)
			SELECT s.*
				,datediff(s, s.step_date, s.lead_step_date) AS step_duration
				,'bad_steps' AS metric
			INTO #timing_bad_steps
			FROM src s;

		--WHERE s.step<>'Step 999';
		DROP TABLE

		IF EXISTS #installment;
			SELECT DISTINCT a.Number
			INTO #installment
			FROM stg._loginom.Originationlog a
			WHERE (a.Is_installment = 1 or a.strategy_version='INST_V1');

		IF object_id('risk.repbi_loginom_timing') IS NOT NULL
			TRUNCATE TABLE risk.repbi_loginom_timing;

		INSERT INTO risk.repbi_loginom_timing
		SELECT s.*
			,CASE 
				WHEN i.number IS NOT NULL
					THEN 1
				ELSE 0
				END AS is_inst
		FROM #timing_wo_bad_steps s
		LEFT JOIN #installment i ON i.Number = s.number;

		INSERT INTO risk.repbi_loginom_timing
		SELECT s.*
			,CASE 
				WHEN i.number IS NOT NULL
					THEN 1
				ELSE 0
				END AS is_inst
		FROM #timing_bad_steps s
		LEFT JOIN #installment i ON i.Number = s.number;

		WITH rdate
		AS (
			SELECT DISTINCT repdate
			FROM risk.repbi_loginom_timing a
			WHERE a.METRIC = 'bad_steps'
			)
			,step
		AS (
			SELECT DISTINCT step
			FROM risk.repbi_loginom_timing a
			WHERE a.METRIC = 'bad_steps'
			)
			,inst
		AS (
			SELECT DISTINCT is_inst
			FROM risk.repbi_loginom_timing a
			WHERE a.METRIC = 'bad_steps'
			)
			,stp
		AS (
			SELECT DISTINCT stage
				,step
			FROM risk.repbi_loginom_timing a
			WHERE step LIKE 'В среднем по%' AND a.METRIC = 'bad_steps'
			)
		INSERT INTO risk.repbi_loginom_timing
		SELECT DISTINCT r.repdate
			,st.stage
			,st.step
			,NULL
			,NULL
			,NULL
			,NULL
			,'bad_steps'
			,i.is_inst
		FROM rdate r
		INNER JOIN stp s ON 1 = 1
		INNER JOIN inst i ON 1 = 1
		INNER JOIN stp st ON 1 = 1;

		WITH rdate
		AS (
			SELECT DISTINCT repdate
			FROM risk.repbi_loginom_timing a
			WHERE a.METRIC = 'wo_bad_steps' and a.is_inst=1
			)
			,step
		AS (
			SELECT DISTINCT step
			FROM risk.repbi_loginom_timing a
			WHERE a.METRIC = 'wo_bad_steps' and a.is_inst=1
			)
			,inst
		AS (
			SELECT DISTINCT is_inst
			FROM risk.repbi_loginom_timing a
			WHERE a.METRIC = 'wo_bad_steps' and a.is_inst=1
			)
			,stp
		AS (
			SELECT DISTINCT stage
				,step
			FROM risk.repbi_loginom_timing a
			WHERE step LIKE 'В среднем по%' AND a.METRIC = 'wo_bad_steps' and a.is_inst=1
			)
		INSERT INTO risk.repbi_loginom_timing
		SELECT DISTINCT r.repdate
			,st.stage
			,st.step
			,NULL
			,NULL
			,NULL
			,NULL
			,'wo_bad_steps'
			,i.is_inst
		FROM rdate r
		INNER JOIN stp s ON 1 = 1
		INNER JOIN inst i ON 1 = 1
		INNER JOIN stp st ON 1 = 1;

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
			,@recipients = 'risk-technology@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;
