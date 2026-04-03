
-- Author:		Artem Orlov
-- Create date: 24.04.2019
-- Description:	скрипт для сегментации повторных клиентов
-- exec dbo.povt
-- =============================================
--exec [dbo].[povt];
CREATE PROC [dbo].[povt]
AS
BEGIN
	SET NOCOUNT ON;

	DROP TABLE

	IF EXISTS #tmp_v_requests
		SELECT r.Id
			,r.external_id
			,r.person_id
			,request_date
			,new_status = CASE 
				WHEN rs.new_status IS NULL
					THEN 'NaN'
				ELSE rs.new_status
				END
			,r.point_of_sale
			,chanel = isnull(r.[chanel], - 1)
			,PersonData = CONCAT (
				rtrim(ltrim(last_name))
				,' '
				,rtrim(ltrim(first_name))
				,' '
				,rtrim(ltrim(middle_name))
				,' '
				,isnull(birth_date, '19000101')
				)
		INTO #tmp_v_requests
		FROM [dbo].[v_final_requests] r
		LEFT JOIN requests_statuses rs ON rs.request_id = r.id
		INNER JOIN v_persons p ON p.id = r.person_id
		WHERE NOT EXISTS (
				SELECT TOP (1) 1
				FROM requests_history rh
				JOIN verifiers v ON rh.verifier = v.id
				WHERE STATUS = 13
					AND verifier != 10
					AND r.id = rh.request_id
				)

	CREATE INDEX cix ON #tmp_v_requests (external_id)

	PRINT ('#tmp_v_requests ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #tmp_v_credits
		SELECT t.external_id
			,t.person_id
			,t.start_date
			,t.collateral_id
			,t.amount
			,t.credit_date
			,t.request_id
			,personData = CONCAT (
				rtrim(ltrim(p.last_name))
				,' '
				,rtrim(ltrim(p.first_name))
				,' '
				,rtrim(ltrim(p.middle_name))
				,' '
				,isnull(p.birth_date, '19000101')
				)
		INTO #tmp_v_credits
		FROM (
			SELECT a.external_id
				,a.person_id
				,a.start_date
				,a.collateral_id
				,a.amount
				,a.credit_date
				,a.request_id
				,row_number() OVER (
					PARTITION BY a.external_id ORDER BY a.credit_date DESC
					) AS rn
			FROM tmp_v_credits a
			) t
		JOIN persons p ON p.id = t.person_id
		WHERE t.rn = 1

	CREATE CLUSTERED INDEX cix ON #tmp_v_credits (external_id)

	PRINT ('#tmp_v_credits ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #PersonCredit
		SELECT person_id
			,external_id
		INTO #PersonCredit
		FROM (
			SELECT CONCAT (
					rtrim(ltrim(last_name))
					,' '
					,rtrim(ltrim(first_name))
					,' '
					,rtrim(ltrim(middle_name))
					,' '
					,birth_date
					) AS person_id
				,c.external_id
				,ROW_NUMBER() OVER (
					PARTITION BY CONCAT (
						rtrim(ltrim(last_name))
						,' '
						,rtrim(ltrim(first_name))
						,' '
						,rtrim(ltrim(middle_name))
						,' '
						,birth_date
						) ORDER BY start_date DESC
						,c.external_id DESC
					) AS rn
			FROM tmp_v_credits C
			JOIN persons p ON c.person_id = p.id
			) a
		WHERE rn = 1

	PRINT ('#PersonCredit ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #scores;
		SELECT DISTINCT person_id2
			,FICO3_score_fin
			,request_date AS score_date
		INTO #scores
		FROM (
			SELECT a.external_id
				,a.request_date
				,a.new_status
				,a.PersonData AS person_id2
				,s.FICO3_score
				,ROW_NUMBER() OVER (
					PARTITION BY PersonData ORDER BY request_date DESC
					) rn
				,ss.FICO3_score FICO3_score2
				,CASE 
					WHEN request_date < '20191115'
						AND ss.FICO3_score IS NULL
						THEN s.FICO3_score
					WHEN request_date > '20191115'
						THEN s.FICO3_score
					ELSE ss.FICO3_score
					END FICO3_score_fin
			FROM #tmp_v_requests a
			LEFT JOIN (
				SELECT Number
					,FICO3_score
				FROM (
					SELECT DISTINCT a.*
						,ROW_NUMBER() OVER (
							PARTITION BY number ORDER BY right(stage, 1) DESC
							) AS ROW
					FROM Stg._loginom.[score] a
						--[LoginomDB].[dbo].[score] a ----переписали в рамках задачи DWH-1140 03/06/2021
					) aa
				WHERE ROW = 1
				) s ON cast(s.Number AS NVARCHAR(50)) = cast(a.external_id AS NVARCHAR(50))
			LEFT JOIN [dbo].[FICO3_scores_1511] ss ON ss.external_id = a.external_id collate Cyrillic_General_CI_AS
			) a
		WHERE FICO3_score_fin IS NOT NULL
			AND rn = 1

	PRINT ('#scores ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #main;(
			SELECT DISTINCT person_id = CONCAT (
					rtrim(ltrim(last_name))
					,' '
					,rtrim(ltrim(first_name))
					,' '
					,rtrim(ltrim(middle_name))
					,' '
					,isnull(birth_date, '19000101')
					)
				,collateral_id
			INTO #main
			FROM tmp_v_credits c
			JOIN persons p ON p.id = c.person_id
			)
		CREATE CLUSTERED INDEX ix_person_id ON #main (person_id);

	PRINT ('#main ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #rests;
		SELECT m.collateral_id
			,a.rest pers_rest
		INTO #rests
		FROM (
			SELECT person_id = c.personData
				,sum(b.[остаток од]) AS rest
			FROM [dwh2].[dbo].[dm_CMRStatBalance] b
			JOIN #tmp_v_credits c ON b.external_id = c.external_id
			WHERE b.d=dateadd(dd, -1, cast(CURRENT_TIMESTAMP AS date))
			GROUP BY personData
			) a
		JOIN #main m ON a.person_id = m.person_id

	PRINT ('#rests ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #days_by_person;(
			SELECT person_id
				,sum(num_active_days) num_active_days
			INTO #days_by_person
			FROM (
				SELECT person_id
					,vnutri_new
					,datediff(dd, st_date, end_date) AS num_active_days
				FROM (
					SELECT person_id
						,vnutri_new
						,min(st_date) AS st_date
						,max(end_date) AS end_date
					FROM (
						SELECT external_id
							,person_id
							,st_date
							,end_date
							,rn
							,(
								CASE 
									WHEN rn = 1
										THEN vnutri_2
									ELSE vnutri
									END
								) AS vnutri_new
						FROM (
							SELECT external_id
								,st_date
								,end_date
								,person_id
								,last_st_date
								,last_end_date
								,rn
								,max(rn) OVER (PARTITION BY a.person_id) AS max_rn
								,min(last_st_date) OVER (PARTITION BY a.person_id) AS min_st_date
								,(
									CASE 
										WHEN st_date >= last_st_date
											AND st_date <= last_end_date
											THEN 1
										ELSE 0
										END
									) AS vnutri
								,(
									CASE 
										WHEN end_date >= lead_st_date
											AND end_date <= lead_end_date
											THEN 1
										ELSE 0
										END
									) AS vnutri_2
							FROM (
								SELECT a.external_id
									,cast(credit_date AS DATE) AS st_date
									,(
										CASE 
											WHEN b.end_date IS NULL
												THEN cast(getdate() AS DATE)
											ELSE b.end_date
											END
										) AS end_date
									,CONCAT (
										rtrim(ltrim(last_name))
										,' '
										,rtrim(ltrim(first_name))
										,' '
										,rtrim(ltrim(middle_name))
										,' '
										,isnull(birth_date, '19000101')
										) person_id
									,last_st_date = lag(cast(credit_date AS DATE)) OVER (
										PARTITION BY a.person_id ORDER BY cast(credit_date AS DATE)
										)
									,last_end_date = lag(cast(end_date AS DATE)) OVER (
										PARTITION BY a.person_id ORDER BY cast(credit_date AS DATE)
										)
									,lead_st_date = lead(cast(credit_date AS DATE)) OVER (
										PARTITION BY a.person_id ORDER BY cast(credit_date AS DATE)
										)
									,lead_end_date = lead(cast(end_date AS DATE)) OVER (
										PARTITION BY a.person_id ORDER BY cast(credit_date AS DATE)
										)
									,row_number() OVER (
										PARTITION BY a.person_id ORDER BY cast(credit_date AS DATE)
										) AS rn
								FROM tmp_v_credits a
								LEFT JOIN (
									SELECT a.external_id
										,b.end_date
										,row_number() OVER (
											PARTITION BY a.external_id ORDER BY a.credit_date
											) AS rn
									FROM tmp_v_credits a
									LEFT JOIN (
										SELECT DISTINCT request_id
											,person_id
											,cast(stage_time AS DATE) end_date
										FROM requests_history rh
										JOIN (
											SELECT id
												,person_id
											FROM requests
											) r ON r.id = rh.request_id
										WHERE STATUS = 16
										) b ON a.request_id = b.request_id
									) b ON a.external_id = b.external_id
								JOIN persons p ON person_id = p.id
								) a
							) a
						) a
					GROUP BY person_id
						,vnutri_new
					) a
				) A
			GROUP BY person_id
			)
		PRINT ('#days_by_person ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #pre_portfel;
		SELECT b.external_id
			
			,max(isnull(b.dpd_p_coll, 0)) AS max_dpd
			,max(b.contractstartdate) AS start_date
			,max(b.ContractEndDate) AS end_date
			,sign(sum(CASE 
						WHEN b.ContractEndDate IS NULL
							THEN 1
						ELSE 0
						END)) AS not_end
			,max(datediff(d, b.ContractEndDate, CURRENT_TIMESTAMP)) AS was_closed_ago
			,max(datediff(d, b.contractstartdate, b.ContractEndDate)) days
		INTO #pre_portfel
		FROM [dwh2].[dbo].[dm_CMRStatBalance] b
		GROUP BY b.external_id;

	DROP TABLE

	IF EXISTS #portfel;
		SELECT p.*
			,c.collateral_id
			,c.personData AS person_id
		INTO #portfel
		FROM #pre_portfel p
		JOIN #tmp_v_credits c ON p.external_id = c.external_id;


	PRINT ('#portfel ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #not_end;
		SELECT sign(sum(CASE 
						WHEN rh.end_date IS NULL
							THEN 1
						ELSE 0
						END)) AS not_end
			,
			--concat(rtrim(ltrim(last_name)), ' ', rtrim(ltrim(first_name)), ' ', rtrim(ltrim(middle_name)), ' ', isnull(birth_date, '19000101')) 
			rh.PersonData AS person_id
		INTO #not_end
		FROM (
			SELECT c.person_id
				,a.end_date
				,c.PersonData
			--c.pe
			FROM #tmp_v_requests C
			LEFT JOIN (
				SELECT request_id
					,end_date
				FROM (
					SELECT request_id
						,STATUS
						,stage_time end_date
						,ROW_NUMBER() OVER (
							PARTITION BY request_id ORDER BY stage_time DESC
							) rn
					FROM requests_history
					) a
				WHERE rn = 1
					AND STATUS = 16
				) a ON a.request_id = c.id
			JOIN tmp_v_credits r ON r.request_id = c.id
			) rh
		--JOIN persons p ON p.id=rh.person_id
		GROUP BY rh.PersonData

	--concat(rtrim(ltrim(last_name)), ' ', rtrim(ltrim(first_name)), ' ', rtrim(ltrim(middle_name)), ' ', isnull(birth_date, '19000101'))
	PRINT ('#not_end ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #t_mfo
		SELECT *
		INTO #t_mfo
		FROM (
			SELECT a.Номер AS external_id
				,b.[СерияПаспорта] AS doc_ser
				,b.[НомерПаспорта] AS doc_num
				,(
					CASE 
						WHEN a.ТелефонМобильный = ''
							THEN 'Nan'
						ELSE a.ТелефонМобильный
						END
					) AS [ТелефонМобильный]
				,b.АдресПроживания AS adress_projivaniya
				,b.АдресРегистрации AS adress_registracii
				,ltrim(rtrim(substring(substring(substring(b.АдресПроживания, 8, 200), charindex(',', substring(b.АдресПроживания, 8, 40)) + 1, 200), 1, charindex(',', substring(substring(b.АдресПроживания, 8, 200), charindex(',', substring(b.АдресПроживания, 8, 200)) + 1, 200))))) AS region
				,row_number() OVER (
					PARTITION BY a.Номер ORDER BY a.Номер
					) AS rn
			FROM Stg._1cMFO.[Документ_ГП_Договор] a
			LEFT JOIN Stg._1cMFO.[Документ_ГП_Заявка] b ON b.ссылка = a.Заявка
			) a

	--  WHERE rn = 1
	--) b 
	DELETE
	FROM #t_mfo
	WHERE rn > 1

	PRINT ('#t_mfo ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #regions;(
			SELECT a.external_id
				,a.pos
				,a.rp
				,a.channel
				,b.doc_ser
				,b.doc_num
				,b.ТелефонМобильный
				,isnull(rtrim(replace(replace(replace(replace(replace(replace(replace(ltrim(rtrim(b.region)), ',', '.'), '.', ''), ' область', ''), ' Республика', ''), ' Респ', ''), ' обл', ''), ' г', '')), 'Nan') AS region_projivaniya
			INTO #regions
			FROM (
				SELECT a.external_id
					,cast(c.credit_date AS DATE) AS credit_date
					,c.amount AS credit_amount
					,isnull(b.name, 'Nan') AS pos
					,isnull(d.name, 'Nan') AS channel
					,isnull((
							CASE 
								WHEN b.name = 'Мобильное приложение'
									THEN 'Мобильное приложение'
								WHEN b.name = 'Личный кабинет клиента'
									THEN 'Личный кабинет клиента'
								ELSE b.regional_office
								END
							), 'Nan') AS rp
				--row_number() OVER (PARTITION BY a.external_id
				--                   ORDER BY a.request_date) AS rn
				FROM #tmp_v_requests a
				JOIN points_of_sale b ON a.point_of_sale = b.id
				JOIN chanels d ON a.chanel = d.id
				JOIN #tmp_v_credits c ON a.external_id = c.external_id
				) a
			LEFT JOIN (
				SELECT external_id
					,doc_ser
					,doc_num
					,[ТелефонМобильный]
					,(
						CASE 
							WHEN external_id IN ('18111508950001')
								THEN 'Кировская обл.'
							WHEN external_id IN ('18011013840001', '18051623260001')
								THEN 'Калужская обл.'
							WHEN external_id IN ('18011615200001', '18050516640001')
								THEN 'Марий Эл Респ.'
							WHEN external_id IN ('18022204570003', '151001840003', '18110225860002', '151001840003')
								THEN 'Москва г.'
							WHEN external_id IN ('18102727610001')
								THEN 'Новгородская обл.'
							WHEN external_id IN ('1705128770001', '17120918970002')
								THEN 'Саратовская обл.'
							WHEN external_id IN ('17082314160001', '17121915700002')
								THEN 'Ростовская обл.'
							WHEN external_id IN ('150713490001', '150604490003')
								THEN 'Смоленская обл.'
							WHEN external_id IN ('150421600006', '140925600009')
								THEN 'Воронежская обл.'
							WHEN external_id IN ('1601121000004')
								THEN 'Рязанская обл.'
							WHEN external_id IN ('160115840007', '160202470002', '151115690005', '151103470007', '151021910001', '150228690007', '150109490001', '150129440007', '141117440005')
								THEN 'Nan'
							WHEN (
									region = ''
									OR region = 'Новофедоровское п,'
									)
								THEN 'Nan'
							WHEN region = 'Нижнегородская область,'
								THEN 'Нижегородская обл.'
							WHEN region = 'Чувашская - Чувашия Респ,'
								THEN 'Чувашская Республика - Чувашия'
							WHEN region = 'город Белорецк,'
								THEN 'Башкортостан Респ.'
							WHEN region = 'ул. трудовой славы,'
								THEN 'Краснодарский край'
							ELSE region
							END
						) AS region
				FROM #t_mfo
				) b ON a.external_id = b.external_id
				--WHERE a.rn = 1
			);
		PRINT ('#regions ' + format(getdate(), 'HH:mm:ss'))

	/*****************************************************************************************/
	--новые рисковые переменные от 15.12.20 для RBP
	---суммарная длина КИ
	DROP TABLE

	IF EXISTS #stg_cred_hist_length;
		SELECT a.person_id
			,sum(DATEDIFF(dd, a.start_date, isnull(a.end_date, cast(getdate() AS DATE)))) AS cred_hist_length
		INTO #stg_cred_hist_length
		FROM #portfel a
		GROUP BY a.person_id;

	PRINT ('#stg_cred_hist_length ' + format(getdate(), 'HH:mm:ss'))

	--срок с момента закрытия последнего кредита в днях (на текущую дату)
	DROP TABLE

	IF EXISTS #stg_term_from_last_clsd;
		SELECT a.person_id
			,datediff(dd, max(isnull(a.end_date, cast(getdate() AS DATE))), cast(getdate() AS DATE)) AS term_from_last_closed
		INTO #stg_term_from_last_clsd
		FROM #portfel a
		GROUP BY a.person_id;

	PRINT ('#stg_term_from_last_clsd ' + format(getdate(), 'HH:mm:ss'))

	--процентная ставка по последнему договору клиента
	DROP TABLE

	IF EXISTS #pre_int_rates;
		WITH base
		AS (
			SELECT a.ДоговорНомер
				,max(cast(a.ПроцСтавкаКредит AS FLOAT)) AS int_rate
			FROM Reports.dbo.report_Agreement_InterestRate a
			GROUP BY a.ДоговорНомер
			)
		SELECT a.person_id
			,a.external_id
			,isnull(b.int_rate, cast(c.[percent] AS FLOAT)) AS int_rate
			,ROW_NUMBER() OVER (
				PARTITION BY a.person_id ORDER BY a.start_date DESC
					,isnull(b.int_rate, cast(c.[percent] AS FLOAT)) DESC
				) AS rown
		INTO #pre_int_rates
		FROM #portfel a
		LEFT JOIN base b ON a.external_id = b.ДоговорНомер
		LEFT JOIN tmp_v_credits c ON a.external_id = c.external_id;

	PRINT ('#pre_int_rates ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #stg_int_rates;
		SELECT s.person_id
			,s.int_rate AS last_int_rate
		INTO #stg_int_rates
		FROM #pre_int_rates s
		WHERE s.rown = 1;

	PRINT ('#stg_int_rates ' + format(getdate(), 'HH:mm:ss'))

	--16/08/2021 - перечень клиентов с договорами цессии (прощения и пр), которые маркируются красным цветом
	DROP TABLE

	IF EXISTS #cession;
		WITH base
		AS (
			SELECT m.person_id
				,iif(z1.external_id IS NOT NULL, 1, 0) AS flag1
				,iif(z2.external_id IS NOT NULL, 1, 0) AS flag2
				,iif(z3.external_id IS NOT NULL, 1, 0) AS flag3
			FROM #main m
			LEFT JOIN (
				SELECT person_id
					,external_id
				FROM (
					SELECT CONCAT (
							rtrim(ltrim(last_name))
							,' '
							,rtrim(ltrim(first_name))
							,' '
							,rtrim(ltrim(middle_name))
							,' '
							,birth_date
							) AS person_id
						,c.external_id
						,ROW_NUMBER() OVER (
							PARTITION BY CONCAT (
								rtrim(ltrim(last_name))
								,' '
								,rtrim(ltrim(first_name))
								,' '
								,rtrim(ltrim(middle_name))
								,' '
								,birth_date
								) ORDER BY start_date DESC
							) AS rn
					FROM tmp_v_credits C
					JOIN persons p ON c.person_id = p.id
					) a
				WHERE rn = 1
				) a ON a.person_id = m.person_id
			LEFT JOIN #regions re ON a.external_id = re.external_id
			--присоединяем по ФИО+ДР
			LEFT JOIN RiskDWH.dbo.det_crm_redzone z1 ON m.person_id = CONCAT (
					rtrim(ltrim(z1.last_name))
					,' '
					,rtrim(ltrim(z1.first_name))
					,' '
					,rtrim(ltrim(z1.patronymic))
					,' '
					,z1.birth_date
					)
			--по паспорту
			LEFT JOIN RiskDWH.dbo.det_crm_redzone z2 ON re.doc_num = z2.passport_num
				AND re.doc_ser = z2.passport_series
			--по номеру договора
			LEFT JOIN RiskDWH.dbo.det_crm_redzone z3 ON a.external_id = z3.external_id
			)
		SELECT DISTINCT a.person_id
		INTO #cession
		FROM base a
		WHERE a.flag1 + a.flag2 + a.flag3 > 0;

	PRINT ('#cession ' + format(getdate(), 'HH:mm:ss'))

	--17/08/2021 - отказные заявки на уровне клиента
	DROP TABLE

	IF EXISTS #client_declines;
		WITH base
		AS (
			SELECT m.person_id
				,iif(d1.fio_bd IS NOT NULL, 1, 0) AS flag1
				,iif(d2.passport_number IS NOT NULL, 1, 0) AS flag2
			FROM #main m
			LEFT JOIN (
				SELECT person_id
					,external_id
				FROM (
					SELECT CONCAT (
							rtrim(ltrim(last_name))
							,' '
							,rtrim(ltrim(first_name))
							,' '
							,rtrim(ltrim(middle_name))
							,' '
							,birth_date
							) AS person_id
						,c.external_id
						,ROW_NUMBER() OVER (
							PARTITION BY CONCAT (
								rtrim(ltrim(last_name))
								,' '
								,rtrim(ltrim(first_name))
								,' '
								,rtrim(ltrim(middle_name))
								,' '
								,birth_date
								) ORDER BY start_date DESC
							) AS rn
					FROM tmp_v_credits C
					JOIN persons p ON c.person_id = p.id
					) a
				WHERE rn = 1
				) a ON a.person_id = m.person_id
			LEFT JOIN #regions re ON a.external_id = re.external_id
			--присоединяем по ФИО+ДР
			LEFT JOIN dwh2.risk.docr_povt_fio_db_red_decline d1 ON m.person_id = d1.fio_bd
				AND d1.cdate = cast(getdate() AS DATE)
			--по паспорту
			LEFT JOIN dwh2.risk.docr_povt_passport_red_decline d2 ON re.doc_num = d2.passport_number
				AND re.doc_ser = d2.passport_series
				AND d2.cdate = cast(getdate() AS DATE)
			)
		SELECT DISTINCT a.person_id
		INTO #client_declines
		FROM base a
		WHERE a.flag1 + a.flag2 > 0;

	PRINT ('#client_declines ' + format(getdate(), 'HH:mm:ss'))

	--01/12/2021 - Факт подачи иска в суд
	-- дата подачи иска в суд или дата решения суда (судебное производтсво)
	DROP TABLE

	IF EXISTS #isk_sp_space
		SELECT DISTINCT Deal.Number AS external_id
			,pd.LastName
			,pd.FirstName
			,pd.MiddleName
			,cast(pd.BirthdayDt AS DATE) AS birth_dt
			,CONCAT (
				rtrim(ltrim(pd.LastName))
				,' '
				,rtrim(ltrim(pd.FirstName))
				,' '
				,rtrim(ltrim(pd.MiddleName))
				,' '
				,isnull(cast(pd.BirthdayDt AS DATE), '19000101')
				) AS person_id
			,pd.Series AS passport_series
			,pd.Number AS passport_number
		-- СП
		--, min(jc.CourtClaimSendingDate) as CourtClaimSendingDate
		--, jc.ReceiptOfJudgmentDate 'Дата решения суда' 
		--, jc.ResultOfCourtsDecision 'Решение суда'
		--, jc.AmountJudgment 'Сумма по решению суда' 
		INTO #isk_sp_space
		FROM Stg._Collection.Deals AS Deal
		LEFT JOIN Stg._Collection.JudicialProceeding AS jp ON Deal.Id = jp.DealId
		LEFT JOIN Stg._Collection.JudicialClaims AS jc ON jp.Id = jc.JudicialProceedingId
		LEFT JOIN stg._collection.customerpersonaldata AS pd ON deal.idcustomer = pd.idcustomer
		INNER JOIN stg._Collection.customers c ON c.Id = Deal.IdCustomer
		WHERE (
				isnull(jc.CourtClaimSendingDate, jc.ReceiptOfJudgmentDate) IS NOT NULL
				OR ISNULL(c.ClaimantExecutiveProceedingId, c.ClaimantLegalId) IS NOT NULL
				);

	PRINT ('#isk_sp_space ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #client_court_decisions;
		WITH base
		AS (
			SELECT m.person_id
				,m.collateral_id
				,a.external_id
				,r.doc_num
				,r.doc_ser
				,iif(i.person_id IS NOT NULL, 1, 0) AS flag1
				,iif(ii.passport_series IS NOT NULL, 1, 0) AS flag2
				,iif(iii.external_id IS NOT NULL, 1, 0) AS flag3
			FROM #main m
			LEFT JOIN (
				SELECT person_id
					,external_id
				FROM (
					SELECT CONCAT (
							rtrim(ltrim(last_name))
							,' '
							,rtrim(ltrim(first_name))
							,' '
							,rtrim(ltrim(middle_name))
							,' '
							,birth_date
							) AS person_id
						,c.external_id
						,ROW_NUMBER() OVER (
							PARTITION BY CONCAT (
								rtrim(ltrim(last_name))
								,' '
								,rtrim(ltrim(first_name))
								,' '
								,rtrim(ltrim(middle_name))
								,' '
								,birth_date
								) ORDER BY start_date DESC
							) AS rn
					FROM tmp_v_credits C
					JOIN persons p ON c.person_id = p.id
					) a
				WHERE rn = 1
				) a ON a.person_id = m.person_id
			LEFT JOIN #regions r ON a.external_id = r.external_id
			--по ФИО+ДР
			LEFT JOIN #isk_sp_space i ON m.person_id = i.person_id
			--по паспорту
			LEFT JOIN #isk_sp_space ii ON r.doc_ser = ii.passport_series
				AND r.doc_num = ii.passport_number
			--по номеру договора
			LEFT JOIN #isk_sp_space iii ON a.external_id = iii.external_id
			)
		SELECT DISTINCT b.person_id
		INTO #client_court_decisions
		FROM base b
		WHERE b.flag1 + b.flag2 + b.flag3 > 0;

	PRINT ('#client_court_decisions ' + format(getdate(), 'HH:mm:ss'))

	--01/12/2021 - Инстолменты - исключаются из CRM-предложений
	--Статусы договоров из ЦМР
	DROP TABLE

	IF EXISTS #cred_CMR_status;
		SELECT b.Код AS external_id
			,b.Клиент AS client_cmr_id
			,b.IsInstallment
			,dateadd(yy, - 2000, a.Период) AS dt_status
			,c.Наименование AS cred_status
			,ROW_NUMBER() OVER (
				PARTITION BY b.Код ORDER BY a.Период DESC
				) AS rown
		INTO #cred_CMR_status
		FROM stg._1cCMR.РегистрСведений_СтатусыДоговоров a
		INNER JOIN stg._1cCMR.Справочник_Договоры b ON a.Договор = b.Ссылка
		INNER JOIN stg._1cCMR.Справочник_СтатусыДоговоров c ON a.Статус = c.Ссылка;

	PRINT ('#cred_CMR_status ' + format(getdate(), 'HH:mm:ss'))

	--Все договоры
	DROP TABLE

	IF EXISTS #all_cred;
		SELECT a.external_id
			,isnull(a.IsInstallment, 0) AS flag_installment
			,b.Фамилия AS last_name
			,b.Имя AS first_name
			,b.Отчество AS middle_name
			,dateadd(yy, - 2000, cast(b.ДатаРождения AS DATE)) AS birth_dt
			,CONCAT (
				rtrim(ltrim(b.Фамилия))
				,' '
				,rtrim(ltrim(b.Имя))
				,' '
				,rtrim(ltrim(b.Отчество))
				,' '
				,isnull(dateadd(yy, - 2000, cast(b.ДатаРождения AS DATE)), '19000101')
				) AS person_id
			,CASE 
				WHEN c.Series <> ''
					THEN c.Series
				ELSE b.ПаспортСерия
				END AS passport_series
			,CASE 
				WHEN c.Number <> ''
					THEN c.Number
				ELSE b.ПаспортНомер
				END AS passport_number
		INTO #all_cred
		FROM #cred_CMR_status a
		LEFT JOIN stg._1cCMR.Справочник_Клиенты b ON a.client_cmr_id = b.Ссылка
		LEFT JOIN stg._Collection.Deals d ON a.external_id = d.Number
		LEFT JOIN stg._Collection.CustomerPersonalData c ON d.IdCustomer = c.IdCustomer
		WHERE a.rown = 1
			AND a.cred_status NOT IN ('Аннулирован', 'Внебаланс', 'Зарегистрирован');

	PRINT ('#all_cred ' + format(getdate(), 'HH:mm:ss'))

	--вспомогательная таблица для исключения из базы клиентов, у которых были договора только инстолменты
	DROP TABLE

	IF EXISTS #for_elimination;
		SELECT a.person_id
			,min(CASE 
					WHEN a.flag_installment = 1
						THEN 1
					ELSE 0
					END) AS flag_cli_installment
		INTO #for_elimination
		FROM #all_cred a
		GROUP BY a.person_id;

	PRINT ('#for_elimination ' + format(getdate(), 'HH:mm:ss'))

	/*****************************************************************************************/
	DROP TABLE

	IF EXISTS #good_after_bad
		SELECT person_id
			,max(CASE 
					WHEN max_dpd < 61
						AND start_date > lag_end_date
						AND lag_max_dpd > 60
						AND days > 180
						THEN 1
					ELSE 0
					END) AS flag
		INTO #good_after_bad
		FROM (
			SELECT person_id
				,max_dpd
				,start_date
				,days
				,lag(end_date) OVER (
					PARTITION BY person_id ORDER BY end_date
					) AS lag_end_date
				,lag(max_dpd) OVER (
					PARTITION BY person_id ORDER BY end_date
					) AS lag_max_dpd
			FROM #portfel
			WHERE not_end = 0
			) a
		GROUP BY person_id

	PRINT ('#good_after_bad ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #dpd_all
		SELECT person_id
			,max(max_dpd) AS max_dpd_all
		INTO #dpd_all
		FROM #portfel
		GROUP BY person_id

	PRINT ('#dpd_all ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #was_closed_ago
		SELECT person_id
			,min(was_closed_ago) AS was_closed_ago
		INTO #was_closed_ago
		FROM #portfel
		GROUP BY person_id

	PRINT ('#was_closed_ago ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #newest_loan
		SELECT person_id
			,days AS dod
		INTO #newest_loan
		FROM (
			SELECT *
				,ROW_NUMBER() OVER (
					PARTITION BY person_id ORDER BY start_date DESC
						,/*15.12.20*/ end_date DESC
					) AS rn
			FROM #portfel
			) a
		WHERE rn = 1
			AND not_end = 0

	PRINT ('#newest_loan ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #pers
		SELECT person_id2
			,fio
			,birth_date
			,last_name = trim(last_name)
			,first_name = trim(first_name)
			,middle_name = trim(middle_name)
		INTO #pers
		FROM (
			SELECT *
				,CONCAT (
					trim(last_name)
					,' '
					,trim(first_name)
					,' '
					,trim(middle_name)
					,' '
					,isnull(birth_date, '19000101')
					) person_id2
				,CONCAT (
					trim(last_name)
					,' '
					,trim(first_name)
					,' '
					,trim(middle_name)
					) fio
			FROM persons P
			) a

	PRINT ('#pers ' + format(getdate(), 'HH:mm:ss'))

	DROP TABLE

	IF EXISTS #Result
		SELECT DISTINCT --15.12.20
			a.external_id
			,CASE 
				WHEN is_red = 1
					THEN 'Красный'
				WHEN (1 - is_red) * is_orange = 1
					THEN 'Оранжевый'
				WHEN (1 - is_red) * (1 - is_orange) * is_green = 1
					THEN 'Зеленый'
				WHEN (1 - is_red) * (1 - is_orange) * (1 - is_green) * is_blue = 1
					THEN 'Синий'
				ELSE 'Желтый'
				END AS category
			,'Повторный заём с известным залогом' AS TYPE
			,CASE 
				WHEN (1 - is_red) * (1 - is_orange) * (1 - is_green) * is_blue = 1 --синий 
					THEN convert(INT, LIMIT / 1000 * 0.9) * 1000
				WHEN (1 - is_red) * (1 - is_orange) * is_green = 1 --зеленый
					OR (1 - is_red) * (1 - is_orange) * (1 - is_green) * (1 - is_blue) = 1 --желтый
					OR (1 - is_red) * is_orange = 1 --оранжевый
					THEN convert(INT, LIMIT / 1000) * 1000
				ELSE 0
				END AS main_limit
			,NULL AS [Минимальный срок кредитования]
			,
			/*15.12.20*/
			/*28.12.20 - v.2 - ЦБ понизил максмально возможную ставку*/
			CASE 
				WHEN a.rbp_gr_action = '01. Max APR'
					THEN 79.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate >= 66
					THEN 79.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate >= 79
					THEN 79.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate >= 79
					THEN 79.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate >= 84
					THEN 79.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate >= 90
					THEN 79.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate >= 60
					AND a.last_int_rate < 66
					THEN 74.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate >= 74
					AND a.last_int_rate < 79
					THEN 74.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate >= 76
					AND a.last_int_rate < 79
					THEN 74.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate > 80
					AND a.last_int_rate < 84
					THEN 74.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate >= 85
					AND a.last_int_rate < 90
					THEN 74.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate >= 56
					AND a.last_int_rate < 60
					THEN 70.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate >= 68
					AND a.last_int_rate < 74
					THEN 70.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate >= 72
					AND a.last_int_rate < 76
					THEN 70.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate > 74
					AND a.last_int_rate <= 80
					THEN 70.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate >= 80
					AND a.last_int_rate < 85
					THEN 70.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate >= 50
					AND a.last_int_rate < 56
					THEN 62.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate >= 60
					AND a.last_int_rate < 68
					THEN 62.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate >= 66
					AND a.last_int_rate < 72
					THEN 62.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate > 66
					AND a.last_int_rate <= 74
					THEN 62.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate >= 72
					AND a.last_int_rate < 80
					THEN 62.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate >= 46
					AND a.last_int_rate < 50
					THEN 56.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate >= 56
					AND a.last_int_rate < 60
					THEN 56.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate >= 60
					AND a.last_int_rate < 66
					THEN 56.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate > 60
					AND a.last_int_rate <= 66
					THEN 56.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate >= 68
					AND a.last_int_rate < 72
					THEN 56.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate >= 40
					AND a.last_int_rate < 46
					THEN 50.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate > 40
					AND a.last_int_rate < 56
					THEN 50.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate >= 50
					AND a.last_int_rate < 60
					THEN 50.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate > 50
					AND a.last_int_rate <= 60
					THEN 50.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate >= 60
					AND a.last_int_rate < 68
					THEN 50.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate < 40
					THEN 40.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate <= 40
					THEN 40.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate < 50
					THEN 40.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate <= 50
					THEN 40.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate < 60
					THEN 40.0
				END AS [Ставка %]
			,NULL AS [Сумма платежа]
			,NULL AS [Рекомендуемая дата повторного обращения]
			,fio
			,birth_date
			,Auto
			,vin
			,pos
			,rp
			,channel
			,doc_ser
			,doc_num
			,ТелефонМобильный
			,region_projivaniya
			,'Не брать ПТС' Berem_pt
			,'ПТС не в компании' AS Nalichie_pts
			,not_end
			,max_dpd_all
			,dod
			,was_closed_ago
			,flag
			,LIMIT
			,num_active_days
			,market_price
			,collateral_id
			,price_date
			,days
			,discount_price
			,(
				CASE 
					WHEN score > 600
						THEN 0.9
					ELSE 0.7
					END
				) AS koeff
			,discount_price * (
				CASE 
					WHEN score > 600
						THEN 0.
					ELSE 0.7
					END
				) limit_car
			,red_lim
			,0 red_7days
			,red_dpd
			,is_red
			,(1 - is_red) * (1 - is_orange) * is_green AS is_green
			,(1 - is_red) * (1 - is_orange) * (1 - is_green) * is_blue AS is_blue
			,(1 - is_red) * (1 - is_orange) * (1 - is_green) * (1 - is_blue) AS is_yellow
			,(1 - is_red) * is_orange AS is_orange
			,score
			,score_date
			,NULL [group]
			,NULL guid
			,
			/*15.12.20*/
			a.cred_hist_length
			,a.term_from_last_closed
			,a.last_int_rate
			,a.last_name AS [last_name]
			,a.first_name AS first_name
			,a.middle_name AS middle_name
		INTO #Result
		FROM (
			SELECT a.external_id external_id2
				,fio
				,birth_date
				,Auto
				,a.vin
				,not_end
				,max_dpd_all
				,dod
				,was_closed_ago
				,flag
				,CASE 
					WHEN discount_price * (
							CASE 
								WHEN score > 600
									THEN 0.9
								ELSE 0.7
								END
							) > 1000000
						THEN 1000000
					ELSE discount_price * (
							CASE 
								WHEN score > 600
									THEN 0.9
								ELSE 0.7
								END
							)
					END AS LIMIT
				,num_active_days
				,CASE 
					WHEN (
							discount_price * 0.7 < 50000
							OR discount_price IS NULL
							)
						THEN 1
					ELSE 0
					END AS red_lim
				,CASE 
					WHEN (discount_price * 0.7 >= 50000)
						AND (
							max_dpd_all > /*60*/ 180 /*15.12.20*/
							AND flag = 0
							)
						THEN 1
							--01/12/2021 - был суд
					WHEN crt.person_id IS NOT NULL
						THEN 1
					ELSE 0
					END AS red_dpd
				,
				--КРАСНАЯ ЗОНА - продублировать условия полей red_***
				CASE 
					WHEN (
							(
								discount_price * 0.7 < 50000
								OR discount_price IS NULL
								) --red_lim                  
							OR (
								max_dpd_all > /*60*/ 180 /*15.12.20*/
								AND flag = 0
								) --red_dpd
							OR (
								car_age > 20
								AND car_age IS NOT NULL
								) /*03.02.21*/
							OR ces.person_id IS NOT NULL --16/08/2021 - цессии
							OR cli_dec.person_id IS NOT NULL --17/08/2021 - отказные заявки клиента
							OR auto_dec.vin IS NOT NULL --17/08/2021 - отказные заявки машина
							OR crt.person_id IS NOT NULL --01/12/2021 - был суд
							)
						THEN 1
					ELSE 0
					END AS is_red
				,
				--ОРАНЖЕВАЯ ЗОНА (НЕ красная + условие оранжевой)
				CASE 
					WHEN (dod <= 7)
						THEN 1
					ELSE 0
					END AS is_orange
				,
				--ЗЕЛЕНАЯ ЗОНА (НЕ красная И НЕ оранжевая + условия зеленой)
				CASE 
					WHEN (was_closed_ago <= 90)
						AND (num_active_days >= 280)
						AND (max_dpd_all <= 14)
						THEN 1
					ELSE 0
					END AS is_green
				,
				--СИНЯЯ ЗОНА (НЕ красная И НЕ оранжевая И НЕ зеленая + условия синей)		  
				CASE 
					WHEN was_closed_ago > 90
						AND was_closed_ago < 367
						AND (discount_price * 0.7 * 0.9 >= 50000)
						THEN 1
					ELSE 0
					END AS is_blue
				,market_price
				,collateral_id
				,price_date
				,DATEDIFF(d, price_date, dateadd(dd, - 1, cast(CURRENT_TIMESTAMP AS DATE))) days
				,discount_price
				,CASE 
					WHEN score > 600
						THEN 0.9
					ELSE 0.7
					END AS koeff
				,score
				,score_date
				,discount_price * (
					CASE 
						WHEN score > 600
							THEN 0.9
						ELSE 0.7
						END
					) limit_car
				,re.*
				,
				/*15.12.20*/
				a.cred_hist_length
				,a.term_from_last_closed
				,a.last_int_rate
				,a.rbp_gr_action
				,a.last_name AS [last_name]
				,a.first_name AS first_name
				,a.middle_name AS middle_name
			FROM (
				SELECT m.*
					,FICO3_score_fin score
					,score_date
					,not_end
					,fio
					,birth_date
					,da.max_dpd_all
					,nl.dod
					,wca.was_closed_ago
					,gab.flag
					,dbp.num_active_days
					,d.discount_price
					,d.price_date
					,a.external_id
					,CONCAT (
						c.brand
						,' '
						,c.model
						,' '
						,c.year
						) AS Auto
					,d.market_price
					,c.vin
					,ROW_NUMBER() OVER (
						PARTITION BY c.vin ORDER BY a.person_id DESC
						) rn
					,
					--15.12.20 - новые переменные для RBP
					schl.cred_hist_length
					,stflc.term_from_last_closed
					,sir.last_int_rate
					,
					--15.12.20 сегмент для RBP
					CASE 
						WHEN da.max_dpd_all > 60
							THEN '01. Max APR'
						WHEN da.max_dpd_all BETWEEN 31
								AND 60
							THEN '02. +10 b.p.'
						WHEN schl.cred_hist_length <= 60
							THEN '03. The Same'
						WHEN schl.cred_hist_length > 180
							AND stflc.term_from_last_closed <= 180
							AND da.max_dpd_all BETWEEN 15
								AND 30
							THEN '04. 5 b.p. discount'
						WHEN schl.cred_hist_length BETWEEN 61
								AND 180
							AND stflc.term_from_last_closed <= 180
							AND da.max_dpd_all BETWEEN 15
								AND 30
							THEN '03. The Same'
						WHEN schl.cred_hist_length > 60
							AND stflc.term_from_last_closed > 180
							AND da.max_dpd_all BETWEEN 15
								AND 30
							THEN '03. The Same'
						WHEN schl.cred_hist_length > 180
							AND stflc.term_from_last_closed > 180
							AND da.max_dpd_all BETWEEN 8
								AND 14
							THEN '05. 10 b.p. discount'
						WHEN schl.cred_hist_length > 180
							AND stflc.term_from_last_closed > 180
							AND da.max_dpd_all BETWEEN 0
								AND 7
							THEN '06. 15 b.p. discount'
						WHEN schl.cred_hist_length BETWEEN 61
								AND 180
							AND stflc.term_from_last_closed > 180
							AND da.max_dpd_all BETWEEN 0
								AND 14
							THEN '05. 10 b.p. discount'
						WHEN schl.cred_hist_length > 180
							AND stflc.term_from_last_closed <= 180
							AND da.max_dpd_all BETWEEN 0
								AND 14
							THEN '06. 15 b.p. discount'
						WHEN schl.cred_hist_length BETWEEN 61
								AND 180
							AND stflc.term_from_last_closed <= 180
							AND da.max_dpd_all BETWEEN 0
								AND 14
							THEN '05. 10 b.p. discount'
						ELSE '00. Empty'
						END AS rbp_gr_action
					--03.02.21 возраст залога
					,year(getdate()) - CASE 
						WHEN c.[year] IS NULL
							THEN NULL
						WHEN c.[year] < 1900
							THEN NULL
						WHEN c.[year] > year(getdate())
							THEN NULL
						ELSE c.[year]
						END AS car_age
					,pe.first_name
					,pe.last_name
					,pe.middle_name
				FROM #main m
				LEFT JOIN #not_end ne ON m.person_id = ne.person_id
				LEFT JOIN #days_by_person dbp ON dbp.person_id = m.person_id
				LEFT JOIN #dpd_all da ON da.person_id = m.person_id
				LEFT JOIN #newest_loan nl ON nl.person_id = m.person_id
				LEFT JOIN #good_after_bad gab ON gab.person_id = m.person_id
				LEFT JOIN #pers pe ON pe.person_id2 = m.person_id
				LEFT JOIN #was_closed_ago wca ON wca.person_id = m.person_id
				LEFT JOIN GetCollateralsMarketPrice(dateadd(dd, - 1, cast(CURRENT_TIMESTAMP AS DATE))) d ON d.collateral_id = m.collateral_id
				LEFT JOIN collaterals c ON m.collateral_id = c.id
				LEFT JOIN #scores s ON s.person_id2 = m.person_id
				/*15.12.20*/
				LEFT JOIN #stg_cred_hist_length schl ON schl.person_id = m.person_id
				LEFT JOIN #stg_int_rates sir ON sir.person_id = m.person_id
				LEFT JOIN #stg_term_from_last_clsd stflc ON stflc.person_id = m.person_id
				LEFT JOIN #PersonCredit a ON a.person_id = m.person_id
				WHERE not_end = 0
				) a
			LEFT JOIN #regions re ON re.external_id = a.external_id
			--16/08/2021 - цессированные
			LEFT JOIN #cession ces ON a.person_id = ces.person_id
			--17/08/2021 - отказные заявки клиента
			LEFT JOIN #client_declines cli_dec ON a.person_id = cli_dec.person_id
			--17/08/2021 - отказные заявки машина
			LEFT JOIN dwh2.risk.docr_povt_vin_red_decline auto_dec ON a.vin = auto_dec.vin
				AND auto_dec.cdate = cast(getdate() AS DATE)
			--01/12/2021 - был суд 
			LEFT JOIN #client_court_decisions crt ON a.person_id = crt.person_id
			WHERE rn = 1
				AND pos IS NOT NULL
				AND market_price IS NOT NULL
				--01/12/2021 - исключение клиентов, у которых были только InstallMent-ы
				AND NOT EXISTS (
					SELECT 1
					FROM #for_elimination elm
					WHERE a.person_id = elm.person_id
						AND elm.flag_cli_installment = 1
					)
			) a
		
		UNION ALL
		
		SELECT DISTINCT --15.12.20
			a.external_id
			,CASE 
				WHEN is_red = 1
					THEN 'Красный'
				WHEN (1 - is_red) * is_orange = 1
					THEN 'Оранжевый'
				WHEN is_green = 1
					THEN 'Зеленый'
				WHEN (1 - is_red) * (1 - is_orange) = 1
					THEN 'Желтый'
				END AS category
			,'Повторный заём с новым залогом' AS TYPE
			,0 AS main_limit
			,NULL AS [Минимальный срок кредитования]
			,
			/*15.12.20*/
			/*28.12.20 - v.2 - ЦБ понизил максмально возможную ставку*/
			CASE 
				WHEN a.rbp_gr_action = '01. Max APR'
					THEN 79.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate >= 66
					THEN 79.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate >= 79
					THEN 79.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate >= 79
					THEN 79.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate >= 84
					THEN 79.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate >= 90
					THEN 79.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate >= 60
					AND a.last_int_rate < 66
					THEN 74.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate >= 74
					AND a.last_int_rate < 79
					THEN 74.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate >= 76
					AND a.last_int_rate < 79
					THEN 74.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate > 80
					AND a.last_int_rate < 84
					THEN 74.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate >= 85
					AND a.last_int_rate < 90
					THEN 74.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate >= 56
					AND a.last_int_rate < 60
					THEN 70.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate >= 68
					AND a.last_int_rate < 74
					THEN 70.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate >= 72
					AND a.last_int_rate < 76
					THEN 70.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate > 74
					AND a.last_int_rate <= 80
					THEN 70.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate >= 80
					AND a.last_int_rate < 85
					THEN 70.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate >= 50
					AND a.last_int_rate < 56
					THEN 62.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate >= 60
					AND a.last_int_rate < 68
					THEN 62.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate >= 66
					AND a.last_int_rate < 72
					THEN 62.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate > 66
					AND a.last_int_rate <= 74
					THEN 62.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate >= 72
					AND a.last_int_rate < 80
					THEN 62.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate >= 46
					AND a.last_int_rate < 50
					THEN 56.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate >= 56
					AND a.last_int_rate < 60
					THEN 56.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate >= 60
					AND a.last_int_rate < 66
					THEN 56.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate > 60
					AND a.last_int_rate <= 66
					THEN 56.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate >= 68
					AND a.last_int_rate < 72
					THEN 56.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate >= 40
					AND a.last_int_rate < 46
					THEN 50.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate > 40
					AND a.last_int_rate < 56
					THEN 50.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate >= 50
					AND a.last_int_rate < 60
					THEN 50.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate > 50
					AND a.last_int_rate <= 60
					THEN 50.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate >= 60
					AND a.last_int_rate < 68
					THEN 50.0
				WHEN a.rbp_gr_action = '02. +10 b.p.'
					AND a.last_int_rate < 40
					THEN 40.0
				WHEN a.rbp_gr_action = '03. The Same'
					AND a.last_int_rate <= 40
					THEN 40.0
				WHEN a.rbp_gr_action = '04. 5 b.p. discount'
					AND a.last_int_rate < 50
					THEN 40.0
				WHEN a.rbp_gr_action = '05. 10 b.p. discount'
					AND a.last_int_rate <= 50
					THEN 40.0
				WHEN a.rbp_gr_action = '06. 15 b.p. discount'
					AND a.last_int_rate < 60
					THEN 40.0
				END AS [Ставка %]
			,NULL AS [Сумма платежа]
			,NULL AS [Рекомендуемая дата повторного обращения]
			,fio
			,birth_date
			,Auto
			,vin
			,pos
			,rp
			,channel
			,doc_ser
			,doc_num
			,ТелефонМобильный
			,region_projivaniya
			,'Не брать ПТС' AS Berem_pt
			,'ПТС не в компании' AS Nalichie_pts
			,not_end
			,max_dpd_all
			,dod
			,was_closed_ago
			,flag
			,LIMIT
			,num_active_days
			,market_price
			,collateral_id
			,price_date
			,days
			,discount_price
			,(
				CASE 
					WHEN score > 600
						THEN 0.9
					ELSE 0.7
					END
				) AS koeff
			,discount_price * 0.7 limit_car
			,red_lim
			,0 red_7days
			,red_dpd
			,is_red
			,is_green
			,is_blue
			,(1 - is_red) * (1 - is_orange) AS is_yellow
			,(1 - is_red) * is_orange AS is_orange
			,score
			,score_date
			,NULL [group]
			,NULL guid
			,
			/*15.12.20*/
			a.cred_hist_length
			,a.term_from_last_closed
			,a.last_int_rate
			,a.last_name AS [last_name]
			,a.first_name AS first_name
			,a.middle_name AS middle_name
		FROM (
			SELECT a.external_id external_id2
				,fio
				,birth_date
				,Auto
				,vin
				,not_end
				,max_dpd_all
				,dod
				,score
				,score_date
				,was_closed_ago
				,flag
				,0 AS LIMIT
				,num_active_days
				,0 AS red_lim
				,CASE 
					WHEN (
							max_dpd_all > /*60*/ 180 /*15.12.20*/
							AND flag = 0
							)
						THEN 1
							--01/12/2021 - был суд
					WHEN crt.person_id IS NOT NULL
						THEN 1
					ELSE 0
					END AS red_dpd
				,
				--КРАСНАЯ ЗОНА
				CASE 
					WHEN (
							(
								max_dpd_all > /*60*/ 180 /*15.12.20*/
								AND flag = 0
								)
							)
						OR ces.person_id IS NOT NULL --16/08/2021 - цессии
						OR cli_dec.person_id IS NOT NULL --17/08/2021 - отказные заявки клиента
						OR crt.person_id IS NOT NULL --01/12/2021 - был суд
						THEN 1
					ELSE 0
					END AS is_red
				,
				--ОРАНЖЕВАЯ ЗОНА
				CASE 
					WHEN (dod <= 7)
						THEN 1
					ELSE 0
					END AS is_orange
				,
				--СИНЯЯ ЗОНА
				0 AS is_blue
				,
				--ЗЕЛЕНАЯ ЗОНА
				0 AS is_green
				,NULL market_price
				,NULL collateral_id
				,NULL price_date
				,DATEDIFF(d, price_date, dateadd(dd, - 1, cast(CURRENT_TIMESTAMP AS DATE))) days
				,NULL discount_price
				,(
					CASE 
						WHEN score > 600
							THEN 0.9
						ELSE 0.7
						END
					) AS koeff
				,NULL limit_car
				,re.*
				,
				/*15.12.20*/
				a.cred_hist_length
				,a.term_from_last_closed
				,a.last_int_rate
				,a.rbp_gr_action
				,a.first_name
				,a.last_name
				,a.middle_name
			FROM (
				SELECT m.*
					,not_end
					,fio
					,birth_date
					,da.max_dpd_all
					,nl.dod
					,wca.was_closed_ago
					,gab.flag
					,FICO3_score_fin score
					,score_date
					,dbp.num_active_days
					,NULL discount_price
					,NULL price_date
					,a.external_id
					,NULL AS Auto
					,NULL market_price
					,NULL vin
					,ROW_NUMBER() OVER (
						PARTITION BY c.vin ORDER BY a.person_id DESC
						) rn
					,
					--15.12.20 - новые переменные для RBP
					schl.cred_hist_length
					,stflc.term_from_last_closed
					,sir.last_int_rate
					,
					--15.12.20 сегмент для RBP
					CASE 
						WHEN da.max_dpd_all > 60
							THEN '01. Max APR'
						WHEN da.max_dpd_all BETWEEN 31
								AND 60
							THEN '02. +10 b.p.'
						WHEN schl.cred_hist_length <= 60
							THEN '03. The Same'
						WHEN schl.cred_hist_length > 180
							AND stflc.term_from_last_closed <= 180
							AND da.max_dpd_all BETWEEN 15
								AND 30
							THEN '04. 5 b.p. discount'
						WHEN schl.cred_hist_length BETWEEN 61
								AND 180
							AND stflc.term_from_last_closed <= 180
							AND da.max_dpd_all BETWEEN 15
								AND 30
							THEN '03. The Same'
						WHEN schl.cred_hist_length > 60
							AND stflc.term_from_last_closed > 180
							AND da.max_dpd_all BETWEEN 15
								AND 30
							THEN '03. The Same'
						WHEN schl.cred_hist_length > 180
							AND stflc.term_from_last_closed > 180
							AND da.max_dpd_all BETWEEN 8
								AND 14
							THEN '05. 10 b.p. discount'
						WHEN schl.cred_hist_length > 180
							AND stflc.term_from_last_closed > 180
							AND da.max_dpd_all BETWEEN 0
								AND 7
							THEN '06. 15 b.p. discount'
						WHEN schl.cred_hist_length BETWEEN 61
								AND 180
							AND stflc.term_from_last_closed > 180
							AND da.max_dpd_all BETWEEN 0
								AND 14
							THEN '05. 10 b.p. discount'
						WHEN schl.cred_hist_length > 180
							AND stflc.term_from_last_closed <= 180
							AND da.max_dpd_all BETWEEN 0
								AND 14
							THEN '06. 15 b.p. discount'
						WHEN schl.cred_hist_length BETWEEN 61
								AND 180
							AND stflc.term_from_last_closed <= 180
							AND da.max_dpd_all BETWEEN 0
								AND 14
							THEN '05. 10 b.p. discount'
						ELSE '00. Empty'
						END AS rbp_gr_action
					,pe.first_name
					,pe.last_name
					,pe.middle_name
				FROM #main m
				LEFT JOIN #not_end ne ON m.person_id = ne.person_id
				LEFT JOIN #days_by_person dbp ON dbp.person_id = m.person_id
				LEFT JOIN #dpd_all da ON da.person_id = m.person_id
				LEFT JOIN #newest_loan nl ON nl.person_id = m.person_id
				LEFT JOIN #good_after_bad gab ON gab.person_id = m.person_id
				LEFT JOIN #pers pe ON pe.person_id2 = m.person_id
				LEFT JOIN #was_closed_ago wca ON wca.person_id = m.person_id
				LEFT JOIN GetCollateralsMarketPrice(dateadd(dd, - 1, cast(CURRENT_TIMESTAMP AS DATE))) d ON d.collateral_id = m.collateral_id
				LEFT JOIN collaterals c ON m.collateral_id = c.id
				LEFT JOIN #scores s ON s.person_id2 = m.person_id
				/*15.12.20*/
				LEFT JOIN #stg_cred_hist_length schl ON schl.person_id = m.person_id
				LEFT JOIN #stg_int_rates sir ON sir.person_id = m.person_id
				LEFT JOIN #stg_term_from_last_clsd stflc ON stflc.person_id = m.person_id
				LEFT JOIN #PersonCredit a ON a.person_id = m.person_id
				WHERE not_end = 0
				) a
			LEFT JOIN #regions re ON re.external_id = a.external_id
			--16/08/2021 - цессированные
			LEFT JOIN #cession ces ON a.person_id = ces.person_id
			--17/08/2021 - отказные заявки клиента
			LEFT JOIN #client_declines cli_dec ON a.person_id = cli_dec.person_id
			--01/12/2021 - был суд
			LEFT JOIN #client_court_decisions crt ON a.person_id = crt.person_id
			WHERE rn = 1
				AND pos IS NOT NULL
				AND channel IS NOT NULL
				--01/12/2021 - исключение клиентов, у которых были только InstallMent-ы
				AND NOT EXISTS (
					SELECT 1
					FROM #for_elimination elm
					WHERE a.person_id = elm.person_id
						AND elm.flag_cli_installment = 1
					)
			) a;

	PRINT ('#Result ' + format(getdate(), 'HH:mm:ss'))

	IF EXISTS (
			SELECT TOP (1) 1
			FROM #Result
			)
	BEGIN
		--DWH-2055 Сохранять GUID клиента и основной телефон клиента (как в CRM)
		ALTER TABLE #Result ADD CRMClientGUID VARCHAR(36)
			,ОсновнойТелефонКлиента VARCHAR(20)

		UPDATE R
		SET CRMClientGUID = dwh2.dbo.getGUIDFrom1C_IDRREF(D.Клиент)
			,ОсновнойТелефонКлиента = coalesce(nullif(nullif(trim(CRM_КонтактнаяИнформация.НомерТелефонаБезКодов), ''), '0'), nullif(nullif(trim(CMR_Клиент.Телефон), ''), '0'))
		FROM #Result AS R
		INNER JOIN Stg._1cCMR.Справочник_Договоры AS D(NOLOCK) ON D.Код = R.external_id
		INNER JOIN stg._1cCMR.Справочник_Клиенты AS CMR_Клиент ON CMR_Клиент.Ссылка = D.Клиент
		LEFT JOIN Stg._1cCRM.Справочник_Партнеры AS CRM_Клиент ON CRM_Клиент.Ссылка = D.Клиент
		LEFT JOIN (
			SELECT Партнер = CRM_КонтактнаяИнформация.Ссылка
				,НомерТелефонаБезКодов
				,nRow = Row_Number() OVER (
					PARTITION BY CRM_КонтактнаяИнформация.Ссылка ORDER BY ДатаЗаписи DESC
						,НомерСтроки DESC
					)
			FROM stg._1cCRM.Справочник_Партнеры_КонтактнаяИнформация CRM_КонтактнаяИнформация
			WHERE CRM_КонтактнаяИнформация.CRM_ОсновнойДляСвязи = 0x01
				AND CRM_КонтактнаяИнформация.Актуальный = 0x01
				AND CRM_КонтактнаяИнформация.Тип = 0xA873CB4AD71D17B2459F9A70D4E2DA66
			) AS CRM_КонтактнаяИнформация ON CRM_КонтактнаяИнформация.Партнер = CRM_Клиент.Ссылка
			AND CRM_КонтактнаяИнформация.nRow = 1

		IF object_id('dwh_new.dbo.povt_buffer') IS NOT NULL
			TRUNCATE TABLE dbo.povt_buffer;

		--drop table  dwh_new.dbo.povt_buffer
		INSERT INTO dwh_new.dbo.povt_buffer (
			[external_id]
			,[category]
			,[TYPE]
			,[main_limit]
			,[Минимальный срок кредитования]
			,[Ставка %]
			,[Сумма платежа]
			,[Рекомендуемая дата повторного обращения]
			,[fio]
			,[birth_date]
			,[Auto]
			,[vin]
			,[pos]
			,[rp]
			,[channel]
			,[doc_ser]
			,[doc_num]
			,[ТелефонМобильный]
			,[region_projivaniya]
			,[Berem_pt]
			,[Nalichie_pts]
			,[not_end]
			,[max_dpd_all]
			,[dod]
			,[was_closed_ago]
			,[flag]
			,[LIMIT]
			,[num_active_days]
			,[market_price]
			,[collateral_id]
			,[price_date]
			,[days]
			,[discount_price]
			,[koeff]
			,[limit_car]
			,[red_lim]
			,[red_7days]
			,[red_dpd]
			,[is_red]
			,[is_green]
			,[is_blue]
			,[is_yellow]
			,[is_orange]
			,[score]
			,[score_date]
			,[group]
			,[GUID]
			,[cred_hist_length]
			,[term_from_last_closed]
			,[last_int_rate]
			,CRMClientGUID
			,ОсновнойТелефонКлиента
			,[last_name]
			,first_name
			,middle_name
			)
		SELECT [external_id]
			,[category]
			,[TYPE]
			,[main_limit]
			,[Минимальный срок кредитования]
			,[Ставка %]
			,[Сумма платежа]
			,[Рекомендуемая дата повторного обращения]
			,[fio]
			,[birth_date]
			,[Auto]
			,[vin]
			,[pos]
			,[rp]
			,[channel]
			,[doc_ser]
			,[doc_num]
			,[ТелефонМобильный]
			,[region_projivaniya]
			,[Berem_pt]
			,[Nalichie_pts]
			,[not_end]
			,[max_dpd_all]
			,[dod]
			,[was_closed_ago]
			,[flag]
			,[LIMIT]
			,[num_active_days]
			,[market_price]
			,[collateral_id]
			,[price_date]
			,[days]
			,[discount_price]
			,[koeff]
			,[limit_car]
			,[red_lim]
			,[red_7days]
			,[red_dpd]
			,[is_red]
			,[is_green]
			,[is_blue]
			,[is_yellow]
			,[is_orange]
			,[score]
			,[score_date]
			,[group]
			,[GUID]
			,[cred_hist_length]
			,[term_from_last_closed]
			,[last_int_rate]
			,CRMClientGUID
			,ОсновнойТелефонКлиента
			,[last_name]
			,first_name
			,middle_name
		FROM #Result;

		PRINT ('insert povt_buffer ' + format(getdate(), 'HH:mm:ss'))

		DELETE
		FROM [dwh_new].[dbo].[povt_history]
		WHERE cdate = cast(getdate() AS DATE)

		PRINT ('delete povt_history ' + format(getdate(), 'HH:mm:ss'))

		INSERT INTO [dbo].[povt_history] (
			[cdate]
			,[external_id]
			,[category]
			,[TYPE]
			,[main_limit]
			,[Минимальный срок кредитования]
			,[Ставка %]
			,[Сумма платежа]
			,[Рекомендуемая дата повторного обращения]
			,[fio]
			,[birth_date]
			,[Auto]
			,[vin]
			,[pos]
			,[rp]
			,[channel]
			,[doc_ser]
			,[doc_num]
			,[ТелефонМобильный]
			,[region_projivaniya]
			,[Berem_pt]
			,[Nalichie_pts]
			,[not_end]
			,[max_dpd_all]
			,[dod]
			,[was_closed_ago]
			,[flag]
			,[LIMIT]
			,[num_active_days]
			,[market_price]
			,[collateral_id]
			,[price_date]
			,[days]
			,[discount_price]
			,[koeff]
			,[limit_car]
			,red_lim
			,red_7days
			,red_dpd
			,is_red
			,is_green
			,is_blue
			,is_yellow
			,is_orange
			,score
			,score_date
			,[group]
			,guid
			,
			/*15.12.20*/
			cred_hist_length
			,term_from_last_closed
			,last_int_rate
			,CRMClientGUID
			,ОсновнойТелефонКлиента
			,[last_name]
			,first_name
			,middle_name
			)
		SELECT cdate = cast(getdate() AS DATE)
			,[external_id]
			,[category]
			,[TYPE]
			,[main_limit]
			,[Минимальный срок кредитования]
			,[Ставка %]
			,[Сумма платежа]
			,[Рекомендуемая дата повторного обращения]
			,[fio]
			,[birth_date]
			,[Auto]
			,[vin]
			,[pos]
			,[rp]
			,[channel]
			,[doc_ser]
			,[doc_num]
			,[ТелефонМобильный]
			,[region_projivaniya]
			,[Berem_pt]
			,[Nalichie_pts]
			,[not_end]
			,[max_dpd_all]
			,[dod]
			,[was_closed_ago]
			,[flag]
			,[LIMIT]
			,[num_active_days]
			,[market_price]
			,[collateral_id]
			,[price_date]
			,[days]
			,[discount_price]
			,[koeff]
			,[limit_car]
			,red_lim
			,red_7days
			,red_dpd
			,is_red
			,is_green
			,is_blue
			,is_yellow
			,is_orange
			,score
			,score_date
			,[group]
			,guid
			,
			/*15.12.20*/
			cred_hist_length
			,term_from_last_closed
			,last_int_rate
			,CRMClientGUID
			,ОсновнойТелефонКлиента
			,[last_name]
			,first_name
			,middle_name
		--     into  [dwh_new].[dbo].[povt_history]
		FROM [dwh_new].[dbo].[povt_buffer]

		PRINT ('insert povt_history ' + format(getdate(), 'HH:mm:ss'))
	END
	ELSE
	BEGIN
			;

		throw 51000
			,'Нет данных для вставки в таблицу - povt_buffer'
			,16
	END
END
