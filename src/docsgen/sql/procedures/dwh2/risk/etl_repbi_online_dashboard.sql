
--exec [risk].[etl_repbi_online_dashboard];
CREATE PROCEDURE [risk].[etl_repbi_online_dashboard]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		--AR Dashboard
		DROP TABLE

		IF EXISTS #product_cli_type;
			WITH call1
			AS (
				SELECT DISTINCT number
					,probation
					,branch_id
					,strategy_version
					,client_type_2
					,client_type_1
					,ROW_NUMBER() OVER (
						PARTITION BY number ORDER BY call_date DESC
						) rn
				FROM stg._loginom.OriginationLog
				WHERE stage = 'Call 1' AND call_date >= dateadd(m, - 6, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE))
					--AND call_date < cast(getdate() AS DATE)
					AND stage IS NOT NULL
				)
				,call2
			AS (
				SELECT DISTINCT number
					,probation
					,branch_id
					,strategy_version
					,client_type_2
					,client_type_1
					,ROW_NUMBER() OVER (
						PARTITION BY number ORDER BY call_date DESC
						) rn
				FROM stg._loginom.OriginationLog
				WHERE stage = 'Call 2' AND call_date >= dateadd(m, - 6, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE))
					--AND call_date < cast(getdate() AS DATE)
					AND stage IS NOT NULL
				)
			SELECT DISTINCT a.number
				,CASE WHEN c1.PROBATION = 1 THEN 'Испытательный срок' WHEN (c1.Branch_id IN ('3645', '5271') OR c2.Branch_id IN ('3645', '5271')) THEN 'Рефин' WHEN c1.strategy_version = 'INST_V1' THEN 'Беззалог' ELSE 'ПТС_остальные' END AS product
				,CASE WHEN (c2.client_type_2 = 'docred' OR c2.client_type_2 = 'parallel') THEN '2.ACTIVE' WHEN (c2.client_type_2 = 'repeated') THEN '3.REPEATED' WHEN (c1.client_type_1 = 'repeated') THEN '3.REPEATED' WHEN (c1.client_type_1 = 'active') THEN '2.ACTIVE' ELSE '1.NEW' END AS client_type
			INTO #product_cli_type
			FROM stg._loginom.OriginationLog a
			LEFT JOIN call1 c1 ON c1.number = a.number AND c1.rn = 1
			LEFT JOIN call2 c2 ON c2.number = a.number AND c2.rn = 1
			WHERE call_date >= dateadd(m, - 6, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE))
				--AND call_date < cast(getdate() AS DATE)
				AND stage IS NOT NULL;

		DROP TABLE

		IF EXISTS #repbi_approval_rate_dashboard;
			WITH src
			AS (
				SELECT number
					,Call_date
					,cast(call_date AS DATE) AS call_date_dt
					,Stage
					,Decision
					,Decision_Code
					,CONCAT (
						format(dateadd(dd, 1 - CASE WHEN DATEPART(dw, call_date) = 1 THEN 7 WHEN DATEPART(dw, call_date) = 2 THEN 1 WHEN DATEPART(dw, call_date) = 3 THEN 2 WHEN DATEPART(dw, call_date) = 4 THEN 3 WHEN DATEPART(dw, call_date) = 5 THEN 4 WHEN DATEPART(dw, call_date) = 6 THEN 5 WHEN DATEPART(dw, call_date) = 7 THEN 6 END, call_date), 'dd/MM')
						,' - '
						,format(dateadd(dd, 7 - CASE WHEN DATEPART(dw, call_date) = 1 THEN 7 WHEN DATEPART(dw, call_date) = 2 THEN 1 WHEN DATEPART(dw, call_date) = 3 THEN 2 WHEN DATEPART(dw, call_date) = 4 THEN 3 WHEN DATEPART(dw, call_date) = 5 THEN 4 WHEN DATEPART(dw, call_date) = 6 THEN 5 WHEN DATEPART(dw, call_date) = 7 THEN 6 END, call_date), 'dd/MM/yyyy')
						) AS rep_period
					,cast(dateadd(dd, 7 - CASE WHEN DATEPART(dw, call_date) = 1 THEN 7 WHEN DATEPART(dw, call_date) = 2 THEN 1 WHEN DATEPART(dw, call_date) = 3 THEN 2 WHEN DATEPART(dw, call_date) = 4 THEN 3 WHEN DATEPART(dw, call_date) = 5 THEN 4 WHEN DATEPART(dw, call_date) = 6 THEN 5 WHEN DATEPART(dw, call_date) = 7 THEN 6 END, call_date) AS DATE) AS rep_period_dt
					,'2. Неделя' AS metric
				FROM stg._loginom.Originationlog a
				WHERE call_date >= dateadd(m, - 6, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE))
					--AND call_date < cast(getdate() AS DATE)
					AND stage IS NOT NULL
				)
			SELECT stage
				,call_date
				,call_date_dt
				,p.client_type
				,p.product
				,rep_period
				,metric
				,decision
				,Decision_Code
				,s.number
				,CASE WHEN decision = 'Accept' THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS accept_flag
				,cast(1 AS INT) AS cnt_flag
				,ROW_NUMBER() OVER (
					PARTITION BY s.number
					,stage
					,call_date_dt ORDER BY call_date DESC
					) rn
				,- cast(format(rep_period_dt, 'yyyyMMdd') AS BIGINT) AS rep_period_sort
				,cast(NULL AS DATETIME) AS dt_dml
			INTO #repbi_approval_rate_dashboard
			FROM src S
			LEFT JOIN #product_cli_type P ON S.NUMBER = P.Number
			WHERE s.Number IS NOT NULL AND s.number NOT IN ('19061300000088', '20101300041806', '21011900071506', '21011900071507');

		WITH src
		AS (
			SELECT number
				,Call_date
				,cast(call_date AS DATE) AS call_date_dt
				,Stage
				,Decision
				,Decision_Code
				,format(call_date, 'dd/MM/yyyy') AS rep_period
				,cast(call_date AS DATE) AS rep_period_dt
				,'1. День' AS metric
			FROM stg._loginom.Originationlog a
			WHERE call_date >= dateadd(m, - 6, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE))
				--AND call_date < cast(getdate() AS DATE)
				AND stage IS NOT NULL
			)
		INSERT INTO #repbi_approval_rate_dashboard
		SELECT stage
			,call_date
			,call_date_dt
			,client_type
			,product
			,rep_period
			,metric
			,decision
			,Decision_Code
			,s.number
			,CASE WHEN decision = 'Accept' THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS accept_flag
			,cast(1 AS INT) AS cnt_flag
			,ROW_NUMBER() OVER (
				PARTITION BY s.number
				,stage
				,call_date_dt ORDER BY call_date DESC
				) rn
			,- cast(format(rep_period_dt, 'yyyyMMdd') AS BIGINT) AS rep_period_sort
			,cast(NULL AS DATETIME) AS dt_dml
		FROM src s
		LEFT JOIN #product_cli_type p ON p.Number = s.Number
		WHERE s.Number IS NOT NULL AND s.number NOT IN ('19061300000088', '20101300041806', '21011900071506', '21011900071507');

		WITH src
		AS (
			SELECT number
				,Call_date
				,cast(call_date AS DATE) AS call_date_dt
				,Stage
				,Decision
				,Decision_Code
				,format(cast(dateadd(m, datediff(m, 0, cast(call_date AS DATE)), 0) AS DATE), 'dd/MM/yyyy') AS rep_period
				,cast(cast(dateadd(m, datediff(m, 0, cast(call_date AS DATE)), 0) AS DATE) AS DATE) AS rep_period_dt
				,'3. Месяц' AS metric
			FROM stg._loginom.Originationlog a
			WHERE call_date >= dateadd(m, - 6, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE))
				--AND call_date < cast(getdate() AS DATE)
				AND stage IS NOT NULL
			)
		INSERT INTO #repbi_approval_rate_dashboard
		SELECT stage
			,call_date
			,call_date_dt
			,client_type
			,product
			,rep_period
			,metric
			,decision
			,Decision_Code
			,s.number
			,CASE WHEN decision = 'Accept' THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS accept_flag
			,cast(1 AS INT) AS cnt_flag
			,ROW_NUMBER() OVER (
				PARTITION BY s.number
				,stage
				,call_date_dt ORDER BY call_date DESC
				) rn
			,- cast(format(rep_period_dt, 'yyyyMMdd') AS BIGINT) AS rep_period_sort
			,cast(NULL AS DATETIME) AS dt_dml
		FROM src s
		LEFT JOIN #product_cli_type p ON p.Number = s.Number
		WHERE s.Number IS NOT NULL AND s.number NOT IN ('19061300000088', '20101300041806', '21011900071506', '21011900071507');

		DELETE
		FROM #repbi_approval_rate_dashboard
		WHERE rn <> 1;

		UPDATE #repbi_approval_rate_dashboard
		SET dt_dml = getdate();

		ALTER TABLE #repbi_approval_rate_dashboard ADD [age] [numeric] (
			3
			,0
			) NULL
			,[region_fact] [varchar] (20) NULL
			,[gender] [varchar] (7) NULL
			,[RBP_GR] [varchar] (100) NULL;

		WITH cte_to_update
		AS (
			SELECT a.*
				,app.age AS age_upd
				,app.region_fact AS region_fact_upd
				,isnull(app.gender, 'unknown') AS gender_upd
				,app.RBP_GR AS rbp_gr_upd
			FROM #repbi_approval_rate_dashboard a
			LEFT JOIN risk.applications app ON app.number = a.number
			)
		UPDATE t
		SET t.age = t.age_upd
			,t.region_fact = t.region_fact_upd
			,t.gender = t.gender_upd
			,t.RBP_GR = t.rbp_gr_upd
		FROM cte_to_update t;

		BEGIN TRANSACTION

		TRUNCATE TABLE risk.repbi_approval_rate_dashboard;

		INSERT INTO risk.repbi_approval_rate_dashboard
		SELECT a.*
		FROM #repbi_approval_rate_dashboard a
		INNER JOIN risk.applications app ON app.number = a.number;

		WITH src
		AS (
			SELECT a.*
				,ROW_NUMBER() OVER (
					PARTITION BY a.number ORDER BY a.call_date DESC
					) rn_ar
			FROM #repbi_approval_rate_dashboard a
			INNER JOIN risk.applications app ON app.number = a.number
			)
		INSERT INTO risk.repbi_approval_rate_dashboard
		SELECT 'Итоговый AR' AS stage
			,call_date
			,call_date_dt
			,client_type
			,product
			,rep_period
			,metric
			,Decision
			,Decision_code
			,Number
			,accept_flag
			,cnt_flag
			,rn
			,rep_period_sort
			,dt_dml
			,age
			,region_fact
			,gender
			,rbp_gr
		FROM src
		WHERE rn_ar = 1;

		COMMIT TRANSACTION;

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
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject
	END CATCH
END;
