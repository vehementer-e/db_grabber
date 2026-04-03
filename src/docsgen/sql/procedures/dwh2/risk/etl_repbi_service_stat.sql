
--exec [risk].[etl_repbi_service_stat];
CREATE PROCEDURE [risk].[etl_repbi_service_stat]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		--Статистика по работе внешних сервисов: Кобальт и ГИБДД
		--для автоотчета по Кобальту
		DROP TABLE

		IF EXISTS #cobalt
			SELECT DISTINCT number
				,min(stage_date)over(partition by number) as stage_date
				,CASE 
					WHEN stage_date < cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE)
						THEN FORMAT(stage_date, 'MMM-yyyy')
					ELSE CASE 
							WHEN day(stage_date) <= 7
								THEN CONCAT (
										'01-07.'
										,lower(FORMAT(stage_date, 'MM.yyyy'))
										)
							WHEN day(stage_date) <= 14
								THEN CONCAT (
										'08-14.'
										,lower(FORMAT(stage_date, 'MM.yyyy'))
										)
							WHEN day(stage_date) <= 21
								THEN CONCAT (
										'15-21.'
										,lower(FORMAT(stage_date, 'MM.yyyy'))
										)
							WHEN day(stage_date) <= 28
								THEN CONCAT (
										'22-28.'
										,lower(FORMAT(stage_date, 'MM.yyyy'))
										)
							ELSE CONCAT (
									'29-'
									,day(cast(dateadd(m, datediff(m, - 1, getdate()), - 1) AS DATE))
									,'.'
									,lower(FORMAT(stage_date, 'MM.yyyy'))
									)
							END
					END AS STAGE_DATE_AGG
				,CASE 
					WHEN stage_date < cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE)
						THEN cast(dateadd(m, datediff(m, 0, stage_date), 0) AS DATE)
					WHEN day(stage_date) <= 7
						THEN dateadd(dd, 7, cast(dateadd(m, datediff(m, 0, stage_date), 0) AS DATE))
					WHEN day(stage_date) <= 14
						THEN dateadd(dd, 14, cast(dateadd(m, datediff(m, 0, stage_date), 0) AS DATE))
					WHEN day(stage_date) <= 21
						THEN dateadd(dd, 21, cast(dateadd(m, datediff(m, 0, stage_date), 0) AS DATE))
					WHEN day(stage_date) <= 28
						THEN dateadd(dd, 28, cast(dateadd(m, datediff(m, 0, stage_date), 0) AS DATE))
					ELSE dateadd(dd, 29, cast(dateadd(m, datediff(m, 0, stage_date), 0) AS DATE))
					END AS STAGE_DATE_AGG_DT
				,Facial_Resemblance_Kobalt
				,Facial_Resamblance_Operator
			INTO #cobalt
			FROM [Stg].[_loginom].[application]
			WHERE stage = 'Call 1.5'
				AND stage_date > '20230419 19:10'
				AND number NOT IN (
					'19061300000088'
					,'20101300041806'
					,'21011900071506'
					,'21011900071507'
					)

		TRUNCATE TABLE risk.repbi_service_stat_cobalt;

		INSERT INTO risk.repbi_service_stat_cobalt
		SELECT STAGE_DATE_AGG
			,STAGE_DATE_AGG_DT
			,sum(CASE 
					WHEN Facial_Resemblance_Kobalt IS NULL
						THEN 1
					ELSE 0
					END) AS cob_null
			,sum(CASE 
					WHEN Facial_Resemblance_Kobalt IS NULL
						THEN 1
					ELSE 0
					END) / cast(count(DISTINCT number) AS FLOAT) per_cob_null
			,sum(CASE 
					WHEN Facial_Resemblance_Kobalt IS NOT NULL
						THEN 1
					ELSE 0
					END) AS cob_not_null
			,sum(CASE 
					WHEN Facial_Resemblance_Kobalt IS NOT NULL
						THEN 1
					ELSE 0
					END) / cast(count(DISTINCT number) AS FLOAT) per_cob_not_null
			,sum(CASE 
					WHEN Facial_Resemblance_Kobalt >= 75
						THEN 1
					ELSE 0
					END) AS cnt_75
			,sum(CASE 
					WHEN Facial_Resemblance_Kobalt >= 75
						THEN 1
					ELSE 0
					END) / cast(count(DISTINCT number) AS FLOAT) per_cnt_75
			,sum(CASE 
					WHEN Facial_Resemblance_Kobalt < 75
						AND Facial_Resamblance_Operator >= 75
						THEN 1
					ELSE 0
					END) AS cnt_ch_no
			,sum(CASE 
					WHEN Facial_Resemblance_Kobalt < 75
						AND Facial_Resamblance_Operator >= 75
						THEN 1
					ELSE 0
					END) / cast(count(DISTINCT number) AS FLOAT) per_cnt_ch_no
			,sum(CASE 
					WHEN Facial_Resemblance_Kobalt < 75
						AND Facial_Resamblance_Operator < 75
						THEN 1
					ELSE 0
					END) AS cnt_ch_yes
			,sum(CASE 
					WHEN Facial_Resemblance_Kobalt < 75
						AND Facial_Resamblance_Operator < 75
						THEN 1
					ELSE 0
					END) / cast(count(DISTINCT number) AS FLOAT) per_cnt_ch_yes
			,sum(CASE 
					WHEN Facial_Resemblance_Kobalt < 75
						AND Facial_Resamblance_Operator IS NULL
						THEN 1
					ELSE 0
					END) AS cnt_ch_null
			,sum(CASE 
					WHEN Facial_Resemblance_Kobalt < 75
						AND Facial_Resamblance_Operator IS NULL
						THEN 1
					ELSE 0
					END) / cast(count(DISTINCT number) AS FLOAT) per_cnt_ch_null
			,count(DISTINCT number) AS cnt_total
		FROM #cobalt
		GROUP BY STAGE_DATE_AGG
			,STAGE_DATE_AGG_DT
		ORDER BY 2 DESC;

		---для автоотчета по ГИБДД
		DROP TABLE

		IF EXISTS #gibdd
			SELECT DISTINCT o.number
				,min(o.call_date)over(partition by o.number) as call_date
				,CASE 
					WHEN o.call_date < cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE)
						THEN FORMAT(o.call_date, 'MMM-yyyy')
					ELSE CASE 
							WHEN day(o.call_date) <= 7
								THEN CONCAT (
										'01-07.'
										,lower(FORMAT(o.call_date, 'MM.yyyy'))
										)
							WHEN day(o.call_date) <= 14
								THEN CONCAT (
										'08-14.'
										,lower(FORMAT(o.call_date, 'MM.yyyy'))
										)
							WHEN day(o.call_date) <= 21
								THEN CONCAT (
										'15-21.'
										,lower(FORMAT(o.call_date, 'MM.yyyy'))
										)
							WHEN day(o.call_date) <= 28
								THEN CONCAT (
										'22-28.'
										,lower(FORMAT(o.call_date, 'MM.yyyy'))
										)
							ELSE CONCAT (
									'29-'
									,day(cast(dateadd(m, datediff(m, - 1, getdate()), - 1) AS DATE))
									,'.'
									,lower(FORMAT(o.call_date, 'MM.yyyy'))
									)
							END
					END AS STAGE_DATE_AGG
				,CASE 
					WHEN o.call_date < cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE)
						THEN cast(dateadd(m, datediff(m, 0, o.call_date), 0) AS DATE)
					WHEN day(o.call_date) <= 7
						THEN dateadd(dd, 7, cast(dateadd(m, datediff(m, 0, o.call_date), 0) AS DATE))
					WHEN day(o.call_date) <= 14
						THEN dateadd(dd, 14, cast(dateadd(m, datediff(m, 0, o.call_date), 0) AS DATE))
					WHEN day(o.call_date) <= 21
						THEN dateadd(dd, 21, cast(dateadd(m, datediff(m, 0, o.call_date), 0) AS DATE))
					WHEN day(o.call_date) <= 28
						THEN dateadd(dd, 28, cast(dateadd(m, datediff(m, 0, o.call_date), 0) AS DATE))
					ELSE dateadd(dd, 29, cast(dateadd(m, datediff(m, 0, o.call_date), 0) AS DATE))
					END AS STAGE_DATE_AGG_DT
				,gibdd_history_ownershipPeriods_count
				,ga.gibdd_restrictions_done
				,ga.gibdd_accidents_done
				,ga.gibdd_searches_done
			INTO #gibdd
			FROM [stg].[_loginom].[Originationlog] o WITH (NOLOCK)
			LEFT JOIN stg._loginom.[Origination_gibdd_aggregates] ga ON o.number = ga.number
			WHERE o.stage = 'Call 3'
				AND o.call_date > '20230323'
				AND Is_installment = 0
				AND o.number NOT IN (
					'19061300000088'
					,'20101300041806'
					,'21011900071506'
					,'21011900071507'
					)

		--считаем заполняемость блока ГИБДД
		TRUNCATE TABLE risk.repbi_service_stat_gibdd;

		INSERT INTO risk.repbi_service_stat_gibdd
		SELECT STAGE_DATE_AGG
			,STAGE_DATE_AGG_DT
			,sum(CASE 
					WHEN gibdd_history_ownershipPeriods_count IS NOT NULL
						AND gibdd_history_ownershipPeriods_count <> 0
						THEN 1
					ELSE 0
					END) AS cnt_owner
			,sum(CASE 
					WHEN gibdd_history_ownershipPeriods_count IS NOT NULL
						AND gibdd_history_ownershipPeriods_count <> 0
						THEN 1
					ELSE 0
					END) / cast(count(DISTINCT number) AS FLOAT) AS per_cnt_owner
			,sum(CASE 
					WHEN gibdd_restrictions_done = 1
						THEN 1
					ELSE 0
					END) AS cnt_res
			,sum(CASE 
					WHEN gibdd_restrictions_done = 1
						THEN 1
					ELSE 0
					END) / cast(count(DISTINCT number) AS FLOAT) AS per_cnt_res
			,sum(CASE 
					WHEN gibdd_accidents_done = 1
						THEN 1
					ELSE 0
					END) AS cnt_acc
			,sum(CASE 
					WHEN gibdd_accidents_done = 1
						THEN 1
					ELSE 0
					END) / cast(count(DISTINCT number) AS FLOAT) per_cnt_acc
			,sum(CASE 
					WHEN gibdd_searches_done = 1
						THEN 1
					ELSE 0
					END) AS cnt_sear
			,sum(CASE 
					WHEN gibdd_searches_done = 1
						THEN 1
					ELSE 0
					END) / cast(count(DISTINCT number) AS FLOAT) per_cnt_sear
			,sum(CASE 
					WHEN gibdd_restrictions_done = 1
						AND gibdd_accidents_done = 1
						AND gibdd_searches_done = 1
						AND gibdd_history_ownershipPeriods_count IS NOT NULL
						AND gibdd_history_ownershipPeriods_count <> 0
						THEN 1
					ELSE 0
					END) AS cnt_all_done
			,sum(CASE 
					WHEN gibdd_restrictions_done = 1
						AND gibdd_accidents_done = 1
						AND gibdd_searches_done = 1
						AND gibdd_history_ownershipPeriods_count IS NOT NULL
						AND gibdd_history_ownershipPeriods_count <> 0
						THEN 1
					ELSE 0
					END) / cast(count(DISTINCT number) AS FLOAT) AS per_cnt_all_done
			,cast(count(DISTINCT number) AS FLOAT) AS cnt_total
		FROM #gibdd
		GROUP BY STAGE_DATE_AGG
			,STAGE_DATE_AGG_DT
		ORDER BY STAGE_DATE_AGG_DT

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
			--,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;
