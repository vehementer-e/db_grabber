
--exec [risk].[etl_repbi_monitoring_customer_quality];
CREATE PROCEDURE [risk].[etl_repbi_monitoring_customer_quality]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		DROP TABLE

		IF EXISTS #origlog_call_1;
			WITH src
			AS (
				SELECT DISTINCT number
					,ROW_NUMBER() OVER (
						PARTITION BY number ORDER BY stage_date DESC
						) rn
				FROM stg._loginom.[Application]
				WHERE stage IN ('Call 1', 'Call 2')
					AND isnull(Is_installment, 0) = 0
				)
			SELECT ol.number
				,ol.call_date AS C1_date
				,ol.probation
				,case when ol.year_TS>1900 then ol.year_TS else null end as year_TS
				,ol.client_type_1
				,ol.request_amount
				,CASE 
					WHEN ol.Branch_id in ('3645', '5271')  
						THEN 1
					ELSE 0
					END AS REFIN_FL
				,cast(DATEADD(qq, DATEDIFF(qq, 0, GETDATE()), 0) AS DATE) AS cur_quarter
				,ROW_NUMBER() OVER (
					PARTITION BY ol.number ORDER BY ol.call_date DESC
					) rn
			INTO #origlog_call_1
			FROM stg._loginom.OriginationLog ol
			INNER JOIN src s
				ON s.number = ol.number
					AND s.rn = 1
			WHERE call_date >= '20210101'
				AND call_date < cast(getdate() AS DATE)
				AND stage = 'Call 1';


					
		DELETE
		FROM #origlog_call_1
		WHERE rn <> 1;

		DELETE
		FROM #origlog_call_1
		WHERE client_type_1 IN ('repeated', 'active');


		DELETE
		FROM #origlog_call_1
		WHERE REFIN_FL = 1;

		CREATE CLUSTERED INDEX origlog_call_1_idx ON #origlog_call_1 (number);

		DROP TABLE

		IF EXISTS #origlog_call_2
			SELECT number
				,ROW_NUMBER() OVER (
					PARTITION BY number ORDER BY call_date DESC
					) rn
				,CASE 
					WHEN Branch_id in ('3645', '5271')
						THEN 1
					ELSE 0
					END AS REFIN_FL
				,client_type_2
			INTO #origlog_call_2
			FROM stg._loginom.OriginationLog
			WHERE stage = 'Call 2';

		DELETE #origlog_call_2
		WHERE rn <> 1;

		CREATE CLUSTERED INDEX origlog_call_2_idx ON #origlog_call_2 (number);

		DROP TABLE

		IF EXISTS #cnt_accs;
			SELECT number
				,CNT_ACT_ACCS_NBKI
				,CNT_ACT_ACCS_EQUI
				,ROW_NUMBER() OVER (
					PARTITION BY number ORDER BY call_date DESC
					) rn
			INTO #cnt_accs
			FROM stg._loginom.OriginationLog
			WHERE stage IN ('Call 1', 'Call 2')
				AND (
					CNT_ACT_ACCS_NBKI IS NOT NULL
					OR CNT_ACT_ACCS_EQUI IS NOT NULL
					)

		DELETE #cnt_accs
		WHERE rn <> 1;

		CREATE CLUSTERED INDEX cnt_accs_idx ON #cnt_accs (number);

		DROP TABLE

		IF EXISTS #cnt_dq;
			SELECT DISTINCT number
				,CNT_DQ_ACCS
				,SUM_DQ_PMTS
				,year_ts
				,ROW_NUMBER() OVER (
					PARTITION BY number ORDER BY call_date DESC
					) rn
			INTO #cnt_dq
			FROM stg._loginom.OriginationLog
			WHERE stage IN ('Call 1', 'Call 2')
				AND CNT_DQ_ACCS IS NOT NULL;

		DELETE #cnt_dq
		WHERE rn <> 1;

		CREATE CLUSTERED INDEX cnt_dq_idx ON #cnt_dq (number);

		DROP TABLE

		IF EXISTS #micro;
			SELECT DISTINCT number
				,stage
				,micro_ever
				,ROW_NUMBER() OVER (
					PARTITION BY number ORDER BY call_date DESC
						,stage DESC
					) rn
			INTO #micro
			FROM stg._loginom.score
			WHERE stage IN ('Call 1', 'Call 2')
				AND micro_ever IS NOT NULL;

		DELETE #micro
		WHERE rn <> 1;

		CREATE CLUSTERED INDEX micro_idx ON #micro (number);

		DROP TABLE

		IF EXISTS #micro_last;
			SELECT DISTINCT number
				,stage
				,micro_last3Y
				,ROW_NUMBER() OVER (
					PARTITION BY number ORDER BY call_date DESC
						,stage DESC
					) rn
			INTO #micro_last
			FROM stg._loginom.score
			WHERE stage IN ('Call 1', 'Call 2')
				AND micro_last3Y IS NOT NULL;

		DELETE #micro_last
		WHERE rn <> 1;

		CREATE CLUSTERED INDEX micro_last_idx ON #micro_last (number);

		IF object_id('risk.repbi_monitoring_customer_quality') IS NOT NULL
			TRUNCATE TABLE risk.repbi_monitoring_customer_quality;

		WITH src
		AS (
			SELECT DISTINCT c.number
				,datediff(year, c.year_ts, GETDATE()) AS age
				,CASE 
					WHEN (
							req.CNT_ACT_ACCS_NBKI >= req.CNT_ACT_ACCS_EQUI
							AND req.CNT_ACT_ACCS_NBKI IS NOT NULL
							AND req.CNT_ACT_ACCS_EQUI IS NOT NULL
							)
						THEN req.CNT_ACT_ACCS_NBKI
					WHEN (
							req.CNT_ACT_ACCS_EQUI >= req.CNT_ACT_ACCS_NBKI
							AND req.CNT_ACT_ACCS_NBKI IS NOT NULL
							AND req.CNT_ACT_ACCS_EQUI IS NOT NULL
							)
						THEN req.CNT_ACT_ACCS_EQUI
					ELSE COALESCE(req.CNT_ACT_ACCS_NBKI, req.CNT_ACT_ACCS_EQUI)
					END AS active_acc_cnt
				,isnull(c2.REFIN_FL, c.REFIN_FL) AS REFIN_FL
				,c.probation
				,c.request_amount
				,c.year_TS
				,CASE 
					WHEN sc1.micro_last3Y IS NULL
						THEN 'Нет данных'
					WHEN sc1.micro_last3Y = 1
						THEN 'Был микро кредит за последние 3 года'
					WHEN sc1.micro_last3Y = 0
						THEN 'Не было микрокредита за последние 3 года'
					END AS micro_last3Y
				,CASE 
					WHEN sc.micro_ever IS NULL
						THEN 'Нет данных'
					WHEN sc.micro_ever = 1
						THEN 'Был микро кредит'
					WHEN sc.micro_ever = 0
						THEN 'Никогда не было микрокредита'
					END AS micro_ever
				,CASE 
					WHEN d.cnt_dq_accs IS NULL
						THEN 'Нет данных'
					WHEN d.cnt_dq_accs > 0
						THEN 'Есть просрочка'
					WHEN d.cnt_dq_accs = 0
						THEN 'Нет просрочки'
					END AS acc_delinq_type
				,cast(d.cnt_dq_accs AS FLOAT) AS acc_delinq_cnt
				,CASE 
					WHEN d.cnt_dq_accs IS NULL
						THEN 'Нет данных'
					WHEN d.cnt_dq_accs = 0
						THEN '0'
					WHEN d.cnt_dq_accs = 1
						THEN '1'
					WHEN d.cnt_dq_accs IN (2, 3)
						THEN '2-3'
					WHEN d.cnt_dq_accs IN (4, 5)
						THEN '4-5'
					WHEN d.cnt_dq_accs >= 6
						AND d.cnt_dq_accs <= 10
						THEN '6-10'
					WHEN d.cnt_dq_accs >= 11
						AND d.cnt_dq_accs <= 20
						THEN '11-20'
					WHEN d.cnt_dq_accs >= 20
						THEN '20+'
					END AS acc_delinq_bucket
				,cast(d.SUM_DQ_PMTS AS FLOAT) AS dlq_summ
				,CASE 
					WHEN d.SUM_DQ_PMTS IS NULL
						THEN 'Нет данных'
					WHEN d.SUM_DQ_PMTS = 0
						THEN 'Нет просрочки'
					WHEN d.SUM_DQ_PMTS > 0
						AND d.SUM_DQ_PMTS < 10000
						THEN 'До 10 К'
					WHEN d.SUM_DQ_PMTS >= 10000
						AND d.SUM_DQ_PMTS < 20000
						THEN '10К-20К'
					WHEN d.SUM_DQ_PMTS >= 20000
						AND d.SUM_DQ_PMTS < 30000
						THEN '20К-30К'
					WHEN d.SUM_DQ_PMTS >= 30000
						AND d.SUM_DQ_PMTS < 40000
						THEN '30К-40К'
					WHEN d.SUM_DQ_PMTS >= 40000
						AND d.SUM_DQ_PMTS < 50000
						THEN '40К-50К'
					WHEN d.SUM_DQ_PMTS >= 50000
						THEN '>=50К'
					END AS dlq_summ_bucket
				,CASE 
					WHEN C1_date < cur_quarter
						THEN CONCAT (
								datepart(qq, C1_date)
								,'к'
								,datepart(yyyy, C1_date)
								)
					WHEN c1_date < cast(dateadd(m, datediff(m, 0, cast(getdate() AS DATE)), 0) AS DATE)
						THEN FORMAT(c1_date, 'MMM-yyyy')
					ELSE CASE 
							WHEN day(c1_date) <= 7
								--AND day(dateadd(dd, - 1, cast(getdate() AS DATE))) >= 7
								THEN CONCAT (
										'01-07.'
										,lower(FORMAT(c1_date, 'MM.yyyy'))
										)
							WHEN day(c1_date) <= 14
								--AND day(dateadd(dd, - 1, cast(getdate() AS DATE))) >= 14
								THEN CONCAT (
										'08-14.'
										,lower(FORMAT(c1_date, 'MM.yyyy'))
										)
							WHEN day(c1_date) <= 21
								--AND day(dateadd(dd, - 1, cast(getdate() AS DATE))) >= 21
								THEN CONCAT (
										'15-21.'
										,lower(FORMAT(c1_date, 'MM.yyyy'))
										)
							WHEN day(c1_date) <= 28
								--AND day(dateadd(dd, - 1, cast(getdate() AS DATE))) >= 28
								THEN CONCAT (
										'22-28.'
										,lower(FORMAT(c1_date, 'MM.yyyy'))
										)
									--WHEN day(dateadd(dd, - 1, cast(getdate() AS DATE))) = day(cast(dateadd(m, datediff(m, - 1, cast(getdate() AS DATE)), - 1) AS DATE)) THEN
							ELSE CONCAT (
									'29-'
									,day(cast(dateadd(m, datediff(m, - 1, getdate()), - 1) AS DATE))
									,'.'
									,lower(FORMAT(c1_date, 'MM.yyyy'))
									)
							END
					END AS mperiod
				,C1_date
				,CASE 
					WHEN c2.client_type_2 IN ('docred', 'parallel')
						THEN '2.ACTIVE'
					WHEN c2.client_type_2 = 'repeated'
						THEN '3.REPEATED'
					WHEN c.client_type_1 = 'repeated'
						THEN '3.REPEATED'
					WHEN c.client_type_1 = 'active'
						THEN '2.ACTIVE'
					ELSE '1.NEW'
					END AS client_type
			FROM #origlog_call_1 C
			LEFT JOIN #origlog_call_2 c2
				ON c.number = c2.number
			LEFT JOIN #cnt_accs req
				ON c.number = req.Number
			LEFT JOIN #cnt_dq d
				ON c.number = d.Number
			LEFT JOIN #micro sc
				ON sc.number = C.number
			LEFT JOIN #micro_last sc1
				ON sc1.number = C.number
			)
		INSERT INTO risk.repbi_monitoring_customer_quality
		SELECT a.number
			,a.age
			,a.active_acc_cnt
			,a.REFIN_FL
			,a.probation
			,a.request_amount
			,a.year_TS
			,a.micro_last3Y
			,a.micro_ever
			,a.acc_delinq_type
			,a.acc_delinq_cnt
			,a.acc_delinq_bucket
			,a.dlq_summ
			,a.dlq_summ_bucket
			,a.mperiod
			,a.C1_date
			,count(*) OVER (PARTITION BY a.mperiod) AS cnt_period
			,'cq_monitor' AS metric
			,CASE 
				WHEN a.active_acc_cnt IS NULL
					THEN 'Нет данных'
				WHEN a.active_acc_cnt = 0
					THEN '0'
				WHEN a.active_acc_cnt = 1
					THEN '1'
				WHEN a.active_acc_cnt IN (2, 3)
					THEN '2-3'
				WHEN a.active_acc_cnt IN (4, 5)
					THEN '4-5'
				WHEN a.active_acc_cnt >= 6
					AND a.active_acc_cnt <= 10
					THEN '6-10'
				WHEN a.active_acc_cnt >= 11
					AND a.active_acc_cnt <= 20
					THEN '11-20'
				WHEN a.active_acc_cnt >= 20
					THEN '20+'
				END AS active_acc_bucket
			,app.age AS client_age
			,CASE 
				WHEN app.age < 25
					THEN 'До 25 лет'
				WHEN app.age BETWEEN 25
						AND 29
					THEN '25-30 лет'
				WHEN app.age BETWEEN 30
						AND 34
					THEN '30-35 лет'
				WHEN app.age BETWEEN 35
						AND 39
					THEN '35-40 лет'
				WHEN app.age BETWEEN 40
						AND 49
					THEN '40-50 лет'
				WHEN app.age BETWEEN 50
						AND 59
					THEN '50-60 лет'
				WHEN app.age >= 60
					THEN 'более 60 лет'
				ELSE 'нет данных'
				END AS client_age_group
			,isnull(app.region_fact, 'Нет данных') AS region_fact
			,CASE 
				WHEN app.gender NOT IN ('Женский', 'Мужской')
					OR app.gender IS NULL
					THEN 'Нет данных'
				ELSE app.gender
				END AS gender --INTO risk.repbi_monitoring_customer_quality
			,NULL AS region_fact_fin
			,NULL AS region_sort
		FROM src a
		INNER JOIN risk.applications app
			ON app.number = a.number
		WHERE a.client_type = '1.NEW'
			AND a.REFIN_FL = 0;

		UPDATE risk.repbi_monitoring_customer_quality
		SET micro_last3Y = 'Нет данных'
			,active_acc_bucket = 'Нет данных'
			,dlq_summ_bucket = 'Нет данных'
			,acc_delinq_bucket = 'Нет данных'
			,acc_delinq_type = 'Нет данных'
			,micro_ever = 'Нет данных'
			,dlq_summ = NULL
			,ACC_DELINQ_CNT = NULL
		WHERE active_acc_cnt IS NULL;

		DROP TABLE

		IF EXISTS #region;
			WITH src
			AS (
				SELECT max(cast(C1_date AS DATE)) AS mdate
				FROM risk.repbi_monitoring_customer_quality
				)
				,sort_period
			AS (
				SELECT DISTINCT mperiod
				FROM risk.repbi_monitoring_customer_quality a
				INNER JOIN src s
					ON s.mdate = cast(a.c1_date AS DATE)
				)
			SELECT s.region_fact
				,s.region_fact AS region_fact_fin
				,s.mperiod
				,count(s.number) / cast(avg(s.cnt_period) AS FLOAT) AS value
			INTO #region
			FROM risk.repbi_monitoring_customer_quality s
			INNER JOIN sort_period p
				ON p.mperiod = s.mperiod
			GROUP BY s.region_fact
				,s.mperiod;

		UPDATE #region
		SET region_fact_fin = 'Другие'
		WHERE value < 0.01;

		WITH src
		AS (
			SELECT a.*
				,row_number() OVER (
					PARTITION BY 1 ORDER BY value DESC
					) AS sort_num
			FROM #region a
			)
			,cte_to_update
		AS (
			SELECT s.number
				,s.region_fact
				,s.region_fact_fin
				,s.region_sort
				,r.region_fact_fin AS region_fact_fin_upd
				,CASE 
					WHEN r.region_fact_fin = 'Другие'
						THEN 10000
					ELSE r.sort_num
					END AS sort_num_upd
			FROM risk.repbi_monitoring_customer_quality s
			LEFT JOIN src r
				ON r.region_fact = s.region_fact
			)
		UPDATE t
		SET t.region_fact_fin = isnull(t.region_fact_fin_upd, 'Другие')
			,t.region_sort = isnull(t.sort_num_upd, 10000)
		FROM cte_to_update t;

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
