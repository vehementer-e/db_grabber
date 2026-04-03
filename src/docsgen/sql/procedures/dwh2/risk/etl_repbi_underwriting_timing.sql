--exec [risk].[etl_repbi_underwriting_timing];

CREATE PROCEDURE [risk].[etl_repbi_underwriting_timing]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		DROP TABLE

		IF EXISTS #risk_par;
			WITH src
			AS (
				SELECT DISTINCT number
					,stage
					,call_date
					,strategy_version
					,client_type_1
					,client_type_2
					,Decision
					,Decision_Code
					,APR
					,Branch_id
					,probation
					,offername
					,last_name
				FROM [stg].[_loginom].[Originationlog]
				WHERE call_date >= '20220101' AND call_date < cast(getdate() AS DATE) AND (number <> '19061300000088' AND number <> '20101300041806' AND number <> '21011900071506' AND number <> '21011900071507')
				)
			SELECT a.Number
				,a.C1_date
				,day(C1_date) AS [DAY]
				,month(C1_date) AS MON
				,CONCAT (
					month(C1_date)
					,'_'
					,year(C1_date)
					) AS STAGE_DATE_AGG
				,--ПЕРИОД
				CASE 
					WHEN c1_date < cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE)
						THEN FORMAT(C1_date, 'MMM-yyyy')
					ELSE CASE 
							WHEN day(C1_date) <= 7
								THEN CONCAT (
										'01-07.'
										,lower(FORMAT(C1_date, 'MM.yyyy'))
										)
							WHEN day(C1_date) <= 14
								THEN CONCAT (
										'08-14.'
										,lower(FORMAT(C1_date, 'MM.yyyy'))
										)
							WHEN day(C1_date) <= 21
								THEN CONCAT (
										'15-21.'
										,lower(FORMAT(C1_date, 'MM.yyyy'))
										)
							WHEN day(C1_date) <= 28
								THEN CONCAT (
										'22-28.'
										,lower(FORMAT(C1_date, 'MM.yyyy'))
										)
							ELSE CONCAT (
									'29-'
									,day(cast(dateadd(m, datediff(m, - 1, getdate()), - 1) AS DATE))
									,'.'
									,lower(FORMAT(C1_date, 'MM.yyyy'))
									)
							END
					END AS rep_period
				,CASE 
					WHEN AB.strategy_version IS NOT NULL
						THEN AB.strategy_version
					ELSE a.strategy_version
					END AS strategy_version_last
				,--стратегия
				--определяем тип клиента
				CASE 
					WHEN (AB.client_type_2 = 'docred' OR AB.client_type_2 = 'parallel')
						THEN 'ACTIVE' --если на С2 докредит или паралел, то это активный клиент
					WHEN (AB.client_type_2 = 'repeated')
						THEN 'REPEATED' --если С2 повторный, значит это повторный клиент
					WHEN (A.client_type_1 = 'repeated')
						THEN 'REPEATED' --если на С1 повторный, значит повторный клиент
					WHEN (A.client_type_1 = 'active')
						THEN 'ACTIVE' --если на С1 активный, значит активный клиент
					ELSE 'NEW' --все остальные новые
					END AS CLIENT_TYPE
				,
				--определяем тип стратегии
				CASE 
					WHEN (AB.client_type_2 = 'docred' OR AB.client_type_2 = 'parallel' OR AB.client_type_2 = 'repeated')
						THEN 'REP' --по типу клиента определяем повторного клиента, если нет на С2, то смотрим на С1
					WHEN (A.client_type_1 = 'repeated' OR A.client_type_1 = 'active')
						THEN 'REP'
					ELSE 'NEW'
					END AS STRAT_TYPE
				,
				--определяем макисмальную стадию
				CASE 
					WHEN AE.C4_decision IS NOT NULL
						THEN 'Call 4' --дошел до С4
					WHEN AD.C3_decision IS NOT NULL
						THEN 'Call 3' --дошел до С3
					WHEN AB.C2_decision IS NOT NULL
						THEN 'Call 2' --дошел до С2
					WHEN AC.C15_decision IS NOT NULL
						THEN 'Call 1.5' --дошел до С15
					ELSE 'Call 1'
					END AS MAX_STAGE
				,a.C1_decision
				,AC.C15_decision
				,AB.C2_decision
				,AD.C3_decision
				,AE.C4_decision
				,--решения на С1, С15, С2, С3, С4
				CASE 
					WHEN a.REFIN_FL = 1 OR AB.REFIN_FL = 1
						THEN 1
					ELSE 0
					END AS REFIN_FL_
				,--признак рефинансирования
				-- other-для воронки	
				CASE 
					WHEN C1_decision = 'Decline'
						THEN 0
					ELSE 1
					END AS AR_CALL1
				,--подсчет неотказов (если решение на С1 отказ, то 0, иначе (положительно или доработка) , то 1)
				CASE 
					WHEN AC.C15_decision = 'Decline' OR AC.C15_decision IS NULL
						THEN 0
					ELSE 1
					END AS AR_CALL15
				,--подсчет полож.решений (если решение на С15 отказ или не принято, то 0, иначе положительно), то 1)
				CASE 
					WHEN AB.C2_decision = 'Decline' OR AB.C2_decision IS NULL
						THEN 0
					ELSE 1
					END AS AR_CALL2
				,CASE 
					WHEN AD.C3_decision = 'Decline' OR AD.C3_decision IS NULL
						THEN 0
					ELSE 1
					END AS AR_CALL3
				,CASE 
					WHEN AE.C4_decision = 'Decline' OR AE.C4_decision IS NULL
						THEN 0
					ELSE 1
					END AS AR_CALL4
			INTO #risk_par
			FROM
				--определение решений на С1, С15, С2, С3, С4
				(
				SELECT DISTINCT number
					,call_date AS C1_date
					,APR AS C1_APR
					,probation
					,offername AS C1_offername
					,client_type_1
					,decision AS C1_decision
					,decision_code AS C1_dec_code
					,CASE 
						WHEN (Branch_id = '3645' OR Branch_id = '5271')
							THEN 1
						ELSE 0
						END AS REFIN_FL
					,strategy_version
					,ROW_NUMBER() OVER (
						PARTITION BY number ORDER BY call_date DESC
						) rn
				FROM src
				WHERE stage = 'Call 1' AND Last_name NOT LIKE '%Тест%'
				) a
			LEFT JOIN (
				SELECT b.*
				FROM (
					SELECT DISTINCT number
						,client_type_2
						,decision AS C2_decision
						,decision_code AS C2_dec_code
						,strategy_version
						,CASE 
							WHEN (Branch_id = '3645' OR Branch_id = '5271')
								THEN 1
							ELSE 0
							END AS REFIN_FL
						,ROW_NUMBER() OVER (
							PARTITION BY number ORDER BY call_date DESC
							) rn
					FROM src
					WHERE stage = 'Call 2'
					) b
				WHERE b.rn = 1
				) AB
				ON a.number = AB.number
			LEFT JOIN (
				SELECT c.*
				FROM (
					SELECT DISTINCT number
						,decision AS C15_decision
						,decision_code AS C15_dec_code
						,ROW_NUMBER() OVER (
							PARTITION BY number ORDER BY call_date DESC
							) rn
					FROM src
					WHERE stage = 'Call 1.5'
					) c
				WHERE c.rn = 1
				) AC
				ON a.number = AC.number
			LEFT JOIN (
				SELECT D.*
				FROM (
					SELECT DISTINCT number
						,decision AS C3_decision
						,decision_code AS C3_dec_code
						,ROW_NUMBER() OVER (
							PARTITION BY number ORDER BY call_date DESC
							) rn
					FROM src
					WHERE stage = 'Call 3'
					) D
				WHERE D.rn = 1
				) AD
				ON a.number = AD.number
			LEFT JOIN (
				SELECT E.*
				FROM (
					SELECT DISTINCT number
						,decision AS C4_decision
						,decision_code AS C4_dec_code
						,ROW_NUMBER() OVER (
							PARTITION BY number ORDER BY call_date DESC
							) rn
					FROM src
					WHERE stage = 'Call 4'
					) E
				WHERE E.rn = 1
				) AE
				ON a.number = AE.number
			LEFT JOIN (
				SELECT B.*
				FROM (
					SELECT DISTINCT number
						,APR_SEGMENT AS C1_APR_SEGMENT
						,micro_ever
						,ROW_NUMBER() OVER (
							PARTITION BY number ORDER BY score_carmoney DESC
							) rn
					FROM [stg].[_loginom].[score]
					WHERE stage = 'Call 1'
					) B
				WHERE b.rn = 1
				) BA
				ON a.number = BA.number
			WHERE a.rn = 1;

		--определяем каналы привлечения
		DROP TABLE

		IF EXISTS #sampleChannel
			SELECT DISTINCT c.Номер
				,c.[Канал от источника]
				,c.[Группа каналов]
				,CASE 
					WHEN [Группа каналов] = 'CPA'
						THEN [Канал от источника]
					WHEN [Группа каналов] = 'CPC'
						THEN [Группа каналов]
					WHEN [Группа каналов] = 'Органика'
						THEN [Группа каналов]
					WHEN [Группа каналов] = 'Партнеры'
						THEN [Группа каналов]
					ELSE 'ДРУГОЕ'
					END AS CHANNEL
			INTO #sampleChannel
			FROM [Reports].[dbo].[dm_Factor_Analysis] c
			INNER JOIN #risk_par rp
				ON rp.Number = c.Номер;

		CREATE UNIQUE INDEX index1 ON #risk_par (number);

		--select distinct max_stage from risk.repbi_underwriting_timing;
		TRUNCATE TABLE risk.repbi_underwriting_timing;
			
		--определяем время рассмотрения, количество доработок
		INSERT INTO risk.repbi_underwriting_timing
			SELECT DISTINCT #risk_par.*
				,s.CHANNEL
				,[Канал от источника]
				,[Группа каналов]
				,term_pts_C15
				,term_pts_C3
				,TERM_C4
				,cnt_C15
				,CNT_C4
				,cnt_C3
				,term_pts_dorab_C15
				,term_pts_dorab_C3
				,TERM_DORAB_C4
				,cnt_dorab_C15
				,cnt_dorab_C3
				,CNT_DORAB_C4
				,sum(CASE 
						WHEN cnt_dorab_c15 > 0 AND max_stage <> 'Call 1'
							THEN 1
						ELSE 0
						END) OVER (PARTITION BY rep_period) AS max_cnt_dorab_c15
				,CASE 
					WHEN cnt_dorab_c15 < 5
						THEN CONCAT (
								' '
								,cnt_dorab_c15
								)
					WHEN cnt_dorab_c15 >= 5
						THEN '5+'
					END AS cnt_dorab_c15_text
				,sum(CASE 
						WHEN cnt_dorab_c3 > 0 AND max_stage IN ('Call 3', 'Call 4')
							THEN 1
						ELSE 0
						END) OVER (PARTITION BY rep_period) AS max_cnt_dorab_c3
				,CASE 
					WHEN cnt_dorab_c3 < 5
						THEN CONCAT (
								' '
								,cnt_dorab_c3
								)
					WHEN cnt_dorab_c3 >= 5
						THEN '5+'
					END AS cnt_dorab_c3_text
				,sum(CASE 
						WHEN cnt_dorab_c4 > 0 AND max_stage IN ('Call 4')
							THEN 1
						ELSE 0
						END) OVER (PARTITION BY rep_period) AS max_cnt_dorab_c4
				,CASE 
					WHEN cnt_dorab_c4 < 5
						THEN CONCAT (
								' '
								,cnt_dorab_c4
								)
					WHEN cnt_dorab_c4 >= 5
						THEN '5+'
					END AS cnt_dorab_c4_text
				,sum(CASE 
						WHEN (isnull(cnt_dorab_C15, 0) + isnull(cnt_dorab_C3, 0) + isnull(CNT_DORAB_C4, 0)) > 0 AND max_stage <> 'Call 1'
							THEN 1
						ELSE 0
						END) OVER (PARTITION BY rep_period) AS max_CNT_DOR_TOTAL
				,CASE 
					WHEN (isnull(cnt_dorab_C15, 0) + isnull(cnt_dorab_C3, 0) + isnull(CNT_DORAB_C4, 0)) < 5
						THEN CONCAT (
								' '
								,(isnull(cnt_dorab_C15, 0) + isnull(cnt_dorab_C3, 0) + isnull(CNT_DORAB_C4, 0))
								)
					WHEN (isnull(cnt_dorab_C15, 0) + isnull(cnt_dorab_C3, 0) + isnull(CNT_DORAB_C4, 0)) >= 5
						THEN '5+'
					END AS CNT_DOR_TOTAL_text
				,CASE 
					WHEN (cnt_dorab_C15 IS NOT NULL)
						THEN 1 --флаг была/не была заявка на доработке на С15
					ELSE 0
					END AS DOR_C15_FL
				,CASE 
					WHEN (cnt_dorab_C3 IS NOT NULL)
						THEN 1 --флаг была/не была заявка на доработке на С3
					ELSE 0
					END AS DOR_C3_FL
				,CASE 
					WHEN CNT_DORAB_C4 IS NOT NULL
						THEN 1 --флаг была/не была заявка на доработке на С4
					ELSE 0
					END AS DOR_C4_FL
				,CASE 
					WHEN (cnt_C15 IS NOT NULL)
						THEN 1 --флаг была/не была заявка на С15
					ELSE 0
					END AS CH_FL
				,CASE 
					WHEN (cnt_C3 IS NOT NULL)
						THEN 1 --флаг была/не была заявка на С3
					ELSE 0
					END AS UW_C3_FL
				,CASE 
					WHEN CNT_C4 IS NOT NULL
						THEN 1 --флаг была/не была заявка на С4
					ELSE 0
					END AS UW_C4_FL
				,CASE 
					WHEN (cnt_dorab_C15 IS NOT NULL OR cnt_dorab_C3 IS NOT NULL OR CNT_DORAB_C4 IS NOT NULL)
						THEN 1 --флаг была/не была заявка на доработке на любой стадии
					ELSE 0
					END AS DOR_TOTAL_FL
				,(isnull(term_pts_C15, 0) + isnull(term_pts_C3, 0) + isnull(TERM_C4, 0)) AS TERM_TOTAL
				,(isnull(cnt_C15, 0) + isnull(cnt_C3, 0) + isnull(CNT_C4, 0)) AS CNT_TOTAL
				,(isnull(term_pts_dorab_C15, 0) + isnull(term_pts_dorab_C3, 0) + isnull(TERM_DORAB_C4, 0)) AS TERM_DOR_TOTAL
				,(isnull(cnt_dorab_C15, 0) + isnull(cnt_dorab_C3, 0) + isnull(CNT_DORAB_C4, 0)) AS CNT_DOR_TOTAL
			FROM #risk_par
			LEFT JOIN (
				SELECT [Номер]
					,[Канал от источника]
					,[Группа каналов]
					,CHANNEL
				FROM #sampleChannel
				) s
				ON s.[Номер] = #risk_par.number
			LEFT JOIN (
				SELECT [Номер заявки]
					,sum([ВремяЗатрачено]) * 24 * 60 AS term_pts_C15
					,count([Номер заявки]) cnt_C15
				FROM [reports].[dbo].[dm_FedorVerificationRequests]
				WHERE [Статус] = 'Контроль данных' AND [Состояние заявки] = 'В работе'
				GROUP BY [Номер заявки]
				) AS t
				ON t.[Номер заявки] = #risk_par.number
			LEFT JOIN (
				SELECT [Номер заявки]
					,sum([ВремяЗатрачено]) * 24 * 60 AS term_pts_C3
					,count([Номер заявки]) cnt_C3
				FROM [reports].[dbo].[dm_FedorVerificationRequests]
				WHERE [Статус] = 'Верификация клиента' AND [Состояние заявки] = 'В работе'
				GROUP BY [Номер заявки]
				) AS t1
				ON t1.[Номер заявки] = #risk_par.number
			LEFT JOIN (
				SELECT [Номер заявки]
					,sum([ВремяЗатрачено]) * 24 * 60 AS TERM_C4
					,count([Номер заявки]) CNT_C4
				FROM [reports].[dbo].[dm_FedorVerificationRequests]
				WHERE [Статус] = 'Верификация ТС' AND [Состояние заявки] = 'В работе'
				GROUP BY [Номер заявки]
				) AS t2
				ON #risk_par.number = t2.[Номер заявки]
			LEFT JOIN (
				SELECT [Номер заявки]
					,sum([ВремяЗатрачено]) * 24 AS term_pts_dorab_C15
					,count([Номер заявки]) cnt_dorab_C15
				FROM [reports].[dbo].[dm_FedorVerificationRequests]
				WHERE [Статус] = 'Контроль данных' AND [Задача] = 'task:Требуется доработка'
				GROUP BY [Номер заявки]
				) AS t3
				ON t3.[Номер заявки] = #risk_par.number
			LEFT JOIN (
				SELECT [Номер заявки]
					,sum([ВремяЗатрачено]) * 24 AS term_pts_dorab_C3
					,count([Номер заявки]) cnt_dorab_C3
				FROM [reports].[dbo].[dm_FedorVerificationRequests]
				WHERE [Статус] = 'Верификация клиента' AND [Задача] = 'task:Требуется доработка'
				GROUP BY [Номер заявки]
				) AS t4
				ON t4.[Номер заявки] = #risk_par.number
			LEFT JOIN (
				SELECT [Номер заявки]
					,sum([ВремяЗатрачено]) * 24 AS TERM_DORAB_C4
					,count([Номер заявки]) CNT_DORAB_C4
				FROM [reports].[dbo].[dm_FedorVerificationRequests]
				WHERE [Статус] = 'Верификация ТС' AND [Задача] = 'task:Требуется доработка'
				GROUP BY [Номер заявки]
				) AS t5
				ON #risk_par.number = t5.[Номер заявки]
			WHERE strategy_version_last <> 'INST_V1';

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
			,@subject = @subject
		;throw 51000, @msg, 1
	END CATCH
END;
