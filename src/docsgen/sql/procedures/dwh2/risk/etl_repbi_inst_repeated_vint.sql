
--exec [dwh2].[risk].[etl_repbi_inst_repeated_vint]
CREATE PROCEDURE [risk].[etl_repbi_inst_repeated_vint]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		DROP TABLE IF EXISTS #base;
			WITH src
			AS (
				SELECT DISTINCT c.external_id as Number
					,c.startdate
					,c.factenddate
					,c.generation
					,CASE 
						WHEN c.factenddate IS NULL
							THEN c.dob
						ELSE datediff(dd, c.startdate, c.factenddate)
						END AS dob
					,max(cast(a.call_date AS DATE)) OVER (PARTITION BY a.number) AS call_date --дубли по Originationlog
					,a.okbscore
					,a.client_type_2
					,CASE 
						WHEN isnull(a.Call_date, c.startdate) >= '2022-11-07'
							THEN 'new'
						ELSE 'old'
						END AS fl_new_old
					,p.passport_number AS pass_key
					,p.person_id2 AS fio_key
					,CASE 
						WHEN c.credit_type_init = 'PDL'
							THEN 'PDL'
						WHEN c.credit_type_init = 'INST'
							THEN 'INST'
						ELSE 'PTS'
						END AS credit_type_init
				FROM risk.credits c 
				INNER JOIN risk.person p ON p.person_id = c.person_id
				LEFT JOIN stg._loginom.Originationlog a ON c.external_id = a.Number AND a.stage = 'Call 2' AND a.Decision = 'Accept')
			SELECT a.*
				,row_number() OVER (
					PARTITION BY a.fio_key ORDER BY a.startdate ASC
					) rn_1
			INTO #base
			FROM src a;

		--определяем максимальное количество договоров в рамках fio_key
		DROP TABLE IF EXISTS #base_for_fl_repeated;
			WITH src
			AS (
				SELECT DISTINCT fio_key
				FROM #base
				WHERE credit_type_init = 'INST'
				) --отбираем только тех клиентов, у которых был хотя бы один инстолл
			SELECT a.*
				,max(a.rn_1) OVER (PARTITION BY a.fio_key) AS max_rn
			INTO #base_for_fl_repeated
			FROM #base a
			INNER JOIN src s ON s.fio_key = a.fio_key;

		--кол-во закрытых! птс и инст
		DROP TABLE IF EXISTS #base_cnt
			SELECT fio_key
				,sum(CASE 
						WHEN credit_type_init <> 'INST'
							AND factenddate IS NOT NULL
							THEN 1
						ELSE 0
						END) AS cnt_pts
				,sum(CASE 
						WHEN credit_type_init = 'INST'
							AND factenddate IS NOT NULL
							THEN 1
						ELSE 0
						END) AS cnt_inst
			INTO #base_cnt
			FROM #base_for_fl_repeated
			GROUP BY fio_key;

		--выберем первый продукт
		DROP TABLE IF EXISTS #first_product
			SELECT fio_key
				,credit_type_init AS first_product
			INTO #first_product
			FROM #base_for_fl_repeated
			WHERE rn_1 = 1

		--выберем первый rn_1 для инстолла и птс
		DROP TABLE IF EXISTS #first_rn_pts
			SELECT fio_key
				,min(rn_1) AS min_rn_pts
			INTO #first_rn_pts
			FROM #base_for_fl_repeated
			WHERE credit_type_init = 'PTS'
			GROUP BY fio_key;

		DROP TABLE IF EXISTS #first_rn_inst
			SELECT fio_key
				,min(rn_1) AS min_rn_inst_pdl
			INTO #first_rn_inst
			FROM #base_for_fl_repeated
			WHERE credit_type_init in ('INST', 'PDL')
			GROUP BY fio_key;

		--вид повторного клиента
		DROP TABLE IF EXISTS #base_total
			SELECT a.*
				,c.first_product
				,b.cnt_pts
				,b.cnt_inst
				,CASE 
					WHEN a.rn_1 = 1
						THEN 'New'
					WHEN c.first_product = 'PTS'
						AND a.rn_1 <= fri.min_rn_inst_pdl
						THEN 'PTS only'
					WHEN c.first_product = 'PTS'
						AND a.rn_1 > fri.min_rn_inst_pdl
						THEN 'PTS first'
					WHEN c.first_product = 'INST'
						AND a.rn_1 <= isnull(frp.min_rn_pts, 999999)
						THEN 'INST/PDL only'
					WHEN c.first_product = 'INST'
						AND a.rn_1 > isnull(frp.min_rn_pts, 999999)
						THEN 'INST first'
					WHEN c.first_product = 'PDL'
						THEN 'PDL first'
					END AS repeated_client_type
			INTO #base_total
			FROM #base_for_fl_repeated a
			LEFT JOIN #base_cnt b ON a.fio_key = b.fio_key
			LEFT JOIN #first_product c ON a.fio_key = c.fio_key
			LEFT JOIN #first_rn_pts frp ON a.fio_key = frp.fio_key
			LEFT JOIN #first_rn_inst fri ON a.fio_key = fri.fio_key

		--базовый датасет для винтажей
		DROP TABLE IF EXISTS #data_prep
			SELECT 1 AS cnt
				,a.Number
				,a.startdate
				,a.factenddate
				,cast(a.generation AS DATE) AS generation
				,format(a.generation, 'dd/MM/yyyy') AS generation_char
				,a.dob
				,a.call_date
				,a.okbscore
				,a.client_type_2
				,a.fl_new_old
				,a.pass_key
				,a.fio_key
				,a.credit_type_init
				,a.rn_1
				,a.max_rn
				,a.first_product
				,a.cnt_pts
				,a.cnt_inst
				,a.repeated_client_type
				,CASE 
					WHEN a.repeated_client_type in ('INST/PDL only', 'INST first')
						THEN 'Повторные ИНСТ'
					WHEN a.repeated_client_type in ('INST/PDL only', 'PDL first')
						THEN 'Повторные PDL'
					WHEN a.repeated_client_type = 'New'
						THEN 'Первичные'
					WHEN a.repeated_client_type = 'PTS first'
						THEN 'Повторный ПТС'
					WHEN a.repeated_client_type = 'PTS only'
						THEN 'Повторный ПТС'
					END AS repeated_client_type_char
				,month(b.StartDate) AS vintage
				,isnull(b.fpd0, -1) as fpd0
				,isnull(b.fpd4, -1) as fpd4
				,isnull(b.fpd7, -1) as fpd7
				,isnull(b.spd0, -1) as spd0
				,isnull(b.tpd0, -1) as tpd0 
				,isnull(b.spd0_not_fpd0, -1) as spd0_not_fpd0
				--,isnull(b._15_4_MFO, -1) as _15_4_MFO
				,isnull(b._15_4_CMR, -1) as _15_4_MFO --CMR c 14/10/25
				,b.IsActive
				,b.InitialEndDate
				,b.CurrentMOB_initial
				,b.CurrentMOB
				,1 AS fl
				,cast(b.amount as float) as amount
				,CAST(c.gen7_mfo_il_score AS FLOAT) AS score_from_nookb
				,isnull(okbscore, CAST(c.gen7_mfo_il_score AS FLOAT)) AS score
			INTO #data_prep
			FROM #base_total a
			INNER JOIN dbo.dm_OverdueIndicators b ON a.number = b.Number
			LEFT JOIN RiskDWH.dbo.bki_resp_okb_20221231_IL c --скор по заявкам, по которым его не получили в ноябре 2022
				ON a.number = c.applicationNumber
			WHERE a.credit_type_init = 'INST'
			ORDER BY Number;

		TRUNCATE TABLE risk.repbi_inst_repeated_vint;

		INSERT INTO risk.repbi_inst_repeated_vint
		SELECT *
			,CASE 
				WHEN CAST(score AS FLOAT) < 410
					THEN '01.<410'
				WHEN CAST(score AS FLOAT) < 430
					THEN '02.410-430'
				WHEN CAST(score AS FLOAT) < 450
					THEN '03. 430-450'
				WHEN CAST(score AS FLOAT) < 465
					THEN '04. 450-465'
				WHEN CAST(score AS FLOAT) < 480
					THEN '05. 465-480'
				WHEN CAST(score AS FLOAT) < 500
					THEN '06. 480-500'
				WHEN CAST(score AS FLOAT) < 520
					THEN '07. 500-520'
				WHEN CAST(score AS FLOAT) < 540
					THEN '08. 520-540'
				WHEN CAST(score AS FLOAT) < 560
					THEN '09. 540-560'
				WHEN CAST(score AS FLOAT) < 580
					THEN '10. 560-580'
				WHEN CAST(score AS FLOAT) < 600
					THEN '11. 580-600'
				WHEN CAST(score AS FLOAT) < 640
					THEN '12. 600-640'
				WHEN CAST(score AS FLOAT) >= 640
					THEN '13. >=640'
				WHEN CAST(score AS FLOAT) IS NULL
					THEN 'NULL'
				END AS okb_backet
			,CASE 
				WHEN fpd0 = 1
					THEN cast(amount AS FLOAT)
				ELSE 0
				END AS amount_fpd0
			,CASE 
				WHEN fpd4 = 1
					THEN cast(amount AS FLOAT)
				ELSE 0
				END AS amount_fpd4
			,CASE 
				WHEN fpd7 = 1
					THEN cast(amount AS FLOAT)
				ELSE 0
				END AS amount_fpd7
			,CASE 
				WHEN spd0_not_fpd0 = 1
					THEN cast(amount AS FLOAT)
				ELSE 0
				END AS amount_spd0_not_fpd0
			,CASE 
				WHEN spd0 = 1
					THEN cast(amount AS INT)
				ELSE 0
				END AS amount_spd0
			,CASE 
				WHEN tpd0 = 1
					THEN cast(amount AS FLOAT)
				ELSE 0
				END AS amount_tpd0
			,CASE 
				WHEN _15_4_MFO = 1
					THEN cast(amount AS FLOAT)
				ELSE 0
				END AS amount_15_4
		FROM #data_prep;

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
