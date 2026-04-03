--exec [dwh2].[risk].[etl_povt_inst_pdl_buffer]
CREATE    PROC [risk].[etl_povt_inst_pdl_buffer]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		EXEC risk.set_debug_info @sp_name
			,'START';

		DROP TABLE IF EXISTS #portfolio;
			WITH src
			AS (
				SELECT DISTINCT c.external_id
					,c.startdate
					,c.factenddate
					,c.generation
					,CASE WHEN c.factenddate IS NULL THEN c.dob ELSE datediff(dd, c.startdate, c.factenddate) END AS dob
					,p.person_id2
					,p.person_id
					,p.first_name
					,p.last_name
					,p.patronymic
					,[dwh2].[dbo].[getGUIDFrom1C_IDRREF](p.person_id) AS CMRClientGUID
					,p.doc_ser AS passport_series
					,p.doc_num AS passport_number
					,p.birth_date
					,CASE WHEN c.credit_type_init = 'INST' THEN 'INST' WHEN c.credit_type_init = 'PDL' THEN 'PDL' ELSE 'PTS' END AS credit_type_init
					,isnull(ro.okbscore, app.okbscore) AS okbscore
					,cast(CASE WHEN ro.okbscore IS NOT NULL THEN app.c2_date WHEN app.okbscore IS NOT NULL THEN app.okbscore_date ELSE NULL END AS DATE) AS okbscore_date
					,CASE WHEN p.age >= 20 AND p.age < 45 AND p.passport_date < dateadd(dd, - 10, dateadd(yyyy, 20, p.birth_date)) THEN 1 WHEN p.age >= 45 AND p.passport_date < dateadd(dd, - 10, dateadd(yyyy, 45, p.birth_date)) THEN 1 ELSE 0 END AS fl_passport_date
					,CASE WHEN p.age < 21 OR p.age > 65 THEN 1 ELSE 0 END AS fl_age
					,CASE WHEN bl.fio IS NOT NULL THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS fl_blacklist
					,isnull(app.c1_date, cast(c.startdate AS DATETIME)) AS c1_date
					,isnull(app.fl_override, 0) AS fl_override
					--новые переменные
					,c.amount AS current_amount
				FROM risk.credits c
				INNER JOIN risk.person p 
					ON p.person_id = c.person_id
				LEFT JOIN risk.applications app 
					ON app.number = c.external_id
				LEFT JOIN risk.REG_RETROOKB ro 
					ON ro.number = app.number
				LEFT JOIN dm.blacklists bl 
					ON p.person_id2 = CONCAT (bl.fio,' ',cast(bl.birthdate AS DATE))
				where c.credit_type not in ('bigInstallmentMarket', 'bigInstallment') --RDWH-47
				)
			SELECT a.*
				,row_number() OVER (PARTITION BY a.person_id2 ORDER BY a.startdate DESC) rn_1
				,row_number() OVER (PARTITION BY a.person_id2 ORDER BY a.factenddate ASC) rn_closed
				,max(fl_override) OVER (PARTITION BY a.person_id2) AS fl_override_povt
			INTO #portfolio
			FROM src a;

		DROP TABLE IF EXISTS #current_okbscore_source;
			WITH src
			AS (
				SELECT person_id2
					,okbscore
					,okbscore_date
					,c1_date
				FROM #portfolio
				WHERE okbscore IS NOT NULL
				
				UNION ALL
				
				SELECT CONCAT_ws (' ', Last_name,First_name,Patronymic,birth_date) AS person_id2
					,okbscore
					,okbscore_date
					,c1_date
				FROM risk.applications
				WHERE okbscore IS NOT NULL
				)
			SELECT person_id2
				,okbscore
				,okbscore_date
				,ROW_NUMBER() OVER (PARTITION BY person_id2 ORDER BY okbscore_date DESC	,c1_date DESC) AS rn
			INTO #current_okbscore_source
			FROM src;

		DROP TABLE IF EXISTS #MAX_CREDIT_LIMIT_INST;
			WITH src
			AS (
				SELECT CONCAT_ws (' ', app.Last_name,app.First_name,app.Patronymic,app.birth_date) AS person_id2
					,app.c1_date
					,cta.MAX_CREDIT_LIMIT_INST
				FROM risk.applications app
				INNER JOIN stg._loginom.calculated_term_and_amount_installment cta 
					ON cta.number = app.number 
					AND cta.MAX_CREDIT_LIMIT_INST IS NOT NULL
				)
			SELECT person_id2
				,MAX_CREDIT_LIMIT_INST
				,ROW_NUMBER() OVER (pARTITION BY person_id2 ORDER BY c1_date DESC) AS rn
			INTO #MAX_CREDIT_LIMIT_INST
			FROM src;

		DROP TABLE IF EXISTS #MAX_CREDIT_LIMIT_PDL;
			WITH src
			AS (
				SELECT CONCAT_ws (' ',app.Last_name,app.First_name,app.Patronymic,app.birth_date) AS person_id2
					,app.c1_date
					,cta.MAX_CREDIT_LIMIT_PDL
				FROM risk.applications app
				INNER JOIN stg._loginom.calculated_term_and_amount_installment cta 
					ON cta.number = app.number 
					AND cta.MAX_CREDIT_LIMIT_PDL IS NOT NULL
				)
			SELECT person_id2
				,MAX_CREDIT_LIMIT_PDL
				,ROW_NUMBER() OVER (PARTITION BY person_id2 ORDER BY c1_date DESC) AS rn
			INTO #MAX_CREDIT_LIMIT_PDL
			FROM src;

		DROP TABLE IF EXISTS #current_incoming_dti;
			WITH src
			AS (
				SELECT CONCAT_ws (' ',app.Last_name,app.First_name,app.Patronymic,app.birth_date) AS person_id2
					,app.c1_date
					,cta.incoming_dti
				FROM risk.applications app
				INNER JOIN stg._loginom.calculated_term_and_amount_installment cta 
					ON cta.number = app.number 
					AND cta.incoming_dti IS NOT NULL 
					AND cta.stage IN ('Call 1', 'Call 2')
				)
			SELECT person_id2
				,incoming_dti AS current_incoming_dti
				,ROW_NUMBER() OVER (PARTITION BY person_id2 ORDER BY c1_date DESC) AS rn
			INTO #current_incoming_dti
			FROM src;

		DROP TABLE IF EXISTS #current_fl_override;
			WITH src
			AS (
				SELECT 
					CONCAT_ws (' ',app.Last_name,app.First_name,app.Patronymic,app.birth_date) AS person_id2
					,app.c1_date
					,app.fl_override
				FROM risk.applications app
				WHERE app.fl_override IS NOT NULL
				)
			SELECT person_id2
				,fl_override AS current_fl_override
				,ROW_NUMBER() OVER (PARTITION BY person_id2 ORDER BY c1_date DESC) AS rn
			INTO #current_fl_override
			FROM src;

		--отбираем только тех клиентов, у которых был хотя бы один закрытый кредит
		DROP TABLE IF EXISTS #inst;
			WITH src
			AS (
				SELECT DISTINCT person_id2
				FROM #portfolio
				WHERE factenddate IS NOT NULL
				)
			SELECT a.*
				,max(CASE WHEN a.factenddate IS NULL THEN 0 ELSE a.rn_closed END) OVER (PARTITION BY a.person_id2) AS max_rn_closed
			INTO #inst
			FROM #portfolio a
			INNER JOIN src s 
				ON s.person_id2 = a.person_id2;

		--кол-во закрытых птс, инст, pdl
		DROP TABLE IF EXISTS #base_cnt
			SELECT 
				person_id2
				,sum(CASE WHEN credit_type_init <> 'INST' AND credit_type_init <> 'PDL' AND factenddate IS NOT NULL THEN 1 ELSE 0 END) AS cnt_closed_pts
				,sum(CASE WHEN credit_type_init = 'INST' AND factenddate IS NOT NULL THEN 1 ELSE 0 END) AS cnt_closed_inst
				,sum(CASE WHEN credit_type_init <> 'INST' AND credit_type_init <> 'PDL' AND factenddate IS NULL THEN 1 ELSE 0 END) AS cnt_active_pts
				,sum(CASE WHEN credit_type_init = 'INST' AND factenddate IS NULL THEN 1 ELSE 0 END) AS cnt_active_inst
				,sum(CASE WHEN credit_type_init = 'PDL' AND factenddate IS NOT NULL THEN 1 ELSE 0 END) AS cnt_closed_pdl
				,sum(CASE WHEN credit_type_init = 'PDL' AND factenddate IS NULL THEN 1 ELSE 0 END) AS cnt_active_pdl
			INTO #base_cnt
			FROM #inst
			GROUP BY person_id2;

		--Cовокупный период обслуживания кредитных договоров клиента в компании
		DROP TABLE IF EXISTS #person_id;
			SELECT 
				p.person_id2
				,external_id
				,c.startdate
				,factenddate = isnull(cast(c.factenddate AS DATE), getdate())
			INTO #person_id
			FROM risk.credits c
			INNER JOIN risk.person p 
				ON p.person_id = c.person_id
			WHERE c.startdate != isnull(cast(c.factenddate AS DATE), getdate())

		CREATE CLUSTERED INDEX cix_external_id ON #person_id (external_id);

		--CREATE CLUSTERED INDEX cix_external_id ON #person_id2_external_id (external_id)
		--SELECT p.person_id2
		--	,count(DISTINCT d) AS lifetime_days
		--INTO #lifetime_days
		--FROM #person_id2_external_id p
		--INNER JOIN dbo.dm_CMRStatBalance b ON p.external_id = b.external_id
		--WHERE b.d <> b.ContractStartDate
		--GROUP BY person_id2;
		DROP TABLE IF EXISTS #lifetime_days;
			--Cовокупный период обслуживания кредитных договоров клиента в компании
			--
			--	SELECT DISTINCT p.person_id2
			--		,count(DISTINCT cal.dt) AS num_active_days
			--	INTO #num_active_days
			--	FROM risk.credits c
			--	INNER JOIN risk.person p ON p.person_id = c.person_id
			--	INNER JOIN risk.calendar cal ON cal.dt BETWEEN dateadd(dd, 1, c.startdate)
			--			AND isnull(cast(c.factenddate AS DATE), getdate())
			--	GROUP BY p.person_id2;
			-- Описание алгоритма тут.
			--https://fastcode.im/Templates/6887/opredelenie-summarnogo-pokrytiya-perekryvayushhixsya-intervalov
			DECLARE @dd DATETIME2 = ('0001-01-01')

		SELECT person_id2
			,sum(t.Разность) AS lifetime_days
		INTO #lifetime_days
		FROM (
			SELECT DISTINCT 1 - datediff(dd, @dd, dateadd(dd, 1, Дано.startdate)) AS Разность
				,Дано.person_id2
			FROM #person_id AS Дано
			LEFT JOIN #person_id AS Левее ON Дано.person_id2 = Левее.person_id2 AND (Левее.startdate < Дано.startdate) AND Дано.startdate <= Левее.factenddate
			WHERE Левее.startdate IS NULL
			
			UNION ALL
			
			SELECT DISTINCT datediff(dd, @dd, Дано.factenddate)
				,Дано.person_id2
			FROM #person_id AS Дано
			LEFT JOIN #person_id AS Правее ON Дано.person_id2 = Правее.person_id2 AND (Правее.startdate <= Дано.factenddate) AND Дано.factenddate < Правее.factenddate
			WHERE Правее.factenddate IS NULL
			) AS t
		GROUP BY person_id2;

		DROP TABLE IF EXISTS #fl_reg_region_source;
			WITH src
			AS (
				SELECT 
					number
					,Region
					,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC) as rn
				FROM stg._loginom.Originationlog
				WHERE Region IS NOT NULL
				)
			SELECT DISTINCT number
				,'1' AS flag
			INTO #fl_reg_region_source
			FROM src
			--LEFT JOIN stg._loginom.dict_region drg 
			--	on drg.regioncode=src.Region
			WHERE rn = 1 
			and exists(select top(1) 1 from stg._loginom.dict_region drg 
				where drg.regioncode=src.Region
				AND drg.archiveflag=0 
				and drg.Reg=0)
				

		DROP TABLE IF EXISTS #fl_fact_region_source;
			WITH src
			AS (
				SELECT number
					,application_fact_region
					,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC) as rn
				FROM stg._loginom.Originationlog
				WHERE application_fact_region IS NOT NULL
				)
			SELECT DISTINCT number
				,'1' AS flag
			INTO #fl_fact_region_source
			FROM src
			where rn = 1  
			and exists(select top(1) 1 from stg._loginom.dict_region drg 
				where drg.regioncode=src.application_fact_region
				AND drg.archiveflag=0 
				and drg.fact=0)
			

		DROP TABLE IF EXISTS #client_court_decisions;
			WITH isk_sp_space
			AS (
				SELECT DISTINCT Deal.Number AS external_id
					,CONCAT_WS (' ',
						rtrim(ltrim(pd.LastName))
						,rtrim(ltrim(pd.FirstName))
						,rtrim(ltrim(pd.MiddleName))
						,isnull(cast(pd.BirthdayDt AS DATE), '19000101')
						) AS person_id2
					,pd.Series AS doc_ser
					,pd.Number AS doc_num
				FROM Stg._Collection.Deals AS Deal
				LEFT JOIN Stg._Collection.JudicialProceeding jp 
					ON Deal.Id = jp.DealId
				LEFT JOIN Stg._Collection.JudicialClaims jc 
					ON jp.Id = jc.JudicialProceedingId
				LEFT JOIN stg._collection.customerpersonaldata pd 
					ON deal.idcustomer = pd.idcustomer
				INNER JOIN stg._Collection.customers c 
					ON c.Id = Deal.IdCustomer
				WHERE ISNULL(jc.CourtClaimSendingDate, jc.ReceiptOfJudgmentDate) IS NOT NULL 
				OR ISNULL(c.ClaimantExecutiveProceedingId, c.ClaimantLegalId) IS NOT NULL
				)
			SELECT DISTINCT p.person_id2
				,cast(1 AS INT) AS flag
			INTO #client_court_decisions
			FROM risk.credits c
			INNER JOIN risk.person p 
				ON p.person_id = c.person_id
			--по ФИО+ДР
			LEFT JOIN isk_sp_space i 
				ON p.person_id2 = i.person_id2
			--по паспорту
			LEFT JOIN isk_sp_space ii 
				ON p.doc_ser = ii.doc_ser 
				AND p.doc_num = ii.doc_num
			--по номеру договора
			LEFT JOIN isk_sp_space iii 
				ON c.external_id = iii.external_id
			WHERE i.person_id2 IS NOT NULL 
			OR ii.doc_ser IS NOT NULL 
			OR iii.doc_num IS NOT NULL;

		DROP TABLE IF EXISTS #fl_delay_source;
			SELECT DISTINCT p.person_id2
				,cast(1 AS INT) AS flag
			INTO #fl_delay_source
			FROM risk.person p
			INNER JOIN risk.credits pmt_delay 
				ON pmt_delay.person_id = p.person_id 
				AND datediff(dd, pmt_delay.pmt_delay_dt, getdate()) < 65 
				AND pmt_delay.factenddate IS NOT NULL;

		DROP TABLE IF EXISTS #fl_inst_max_overdue_source;
			SELECT DISTINCT p.person_id2
				,cast(1 AS INT) AS flag
			INTO #fl_inst_max_overdue_source
			FROM risk.credits c
			INNER JOIN risk.person p 
				ON p.person_id = c.person_id
			WHERE c.max_dpd > 45 
			--AND c.credit_type = 'INST'; --RDWH-47
			and c.credit_type not in ('pts', 'PTS_31', 'PTS_REFIN'); --RDWH-47 макс кол-во дней в просрочке по иному продукту > 45 дней

		DROP TABLE IF EXISTS #fl_pdl_max_overdue_source;
			SELECT DISTINCT p.person_id2
				,cast(1 AS INT) AS flag
			INTO #fl_pdl_max_overdue_source
			FROM risk.credits c
			INNER JOIN risk.person p 
				ON p.person_id = c.person_id
			WHERE c.max_dpd > 45 
			AND c.credit_type = 'PDL'; --RDWH-47, рудимент, правило учтено выше

		DROP TABLE IF EXISTS #fl_pts_max_overdue_source;
			SELECT DISTINCT p.person_id2
				,cast(1 AS INT) AS flag
			INTO #fl_pts_max_overdue_source
			FROM risk.credits c
			INNER JOIN risk.person p 
				ON p.person_id = c.person_id
			WHERE c.max_dpd > 90 
			AND c.credit_type in ('pts', 'PTS_31', 'PTS_REFIN'); --RDWH-47 макс кол-во дней в просрочке по продуктам PTS  > 90 дней

		DROP TABLE IF EXISTS #fl_cooling_7_source;
			SELECT DISTINCT CONCAT_WS (' '
				,a.Last_name
				,a.First_name
				,a.Patronymic
				,a.birth_date
					) AS person_id2
				,1 AS flag
			INTO #fl_cooling_7_source
			FROM stg._loginom.decision_code d
			INNER JOIN risk.applications a 
				ON a.number = d.Number
			WHERE d.DATETIME > dateadd(dd, - 7, cast(getdate() AS DATE)) 
			AND d.[Values] IN (
				SELECT [reasonCode]
				FROM stg._loginom.Origination_dict_reason_codes with (nolock)
				where [coolingDaysPerson]=7 
				and isActive=1
					);

		DROP TABLE IF EXISTS #fl_cooling_30_source;
			SELECT DISTINCT CONCAT_ws (' '
					,a.Last_name
					,a.First_name
					,a.Patronymic
					,a.birth_date
					) AS person_id2
				,1 AS flag
			INTO #fl_cooling_30_source
			FROM stg._loginom.decision_code d
			INNER JOIN risk.applications a ON a.number = d.Number
			WHERE d.DATETIME > dateadd(dd, - 30, cast(getdate() AS DATE))
			AND d.[Values] IN (
				SELECT [reasonCode]
				FROM stg._loginom.Origination_dict_reason_codes with (nolock)
				where [coolingDaysPerson]=30  and isActive=1
				)
			
		DROP TABLE IF EXISTS #fl_cooling_90_source;             
			SELECT DISTINCT CONCAT_WS (' ',
				a.Last_name                     
				,a.First_name                     
				,a.Patronymic                     
				,a.birth_date                     
				) AS person_id2,
				1 AS flag             
			INTO #fl_cooling_90_source             
			FROM stg._loginom.decision_code d             
			INNER JOIN risk.applications a 
				ON a.number = d.Number             
			WHERE d.DATETIME > dateadd(dd, - 90, cast(getdate() AS DATE)) 
			AND d.[Values] IN (
				SELECT [reasonCode]   
				FROM stg._loginom.Origination_dict_reason_codes with (nolock)   
				where [coolingDaysPerson]=90  and isActive=1
				); 


			drop table if exists #t_equifax
			SELECT 
			person_id2 = CONCAT_WS (' ',
			a.Last_name                     
			,a.First_name                     
			,a.Patronymic                     
			,a.birth_date                     
			) 
			,EqxScore_date  = [call_date]
			,[EqxScore]
			,external_id = t.[number] 
			,rn_person = ROW_NUMBER() OVER (PARTITION BY CONCAT_WS (' ',a.Last_name,a.First_name,a.Patronymic,a.birth_date) ORDER BY t.[call_date] DESC)
			,rn_external_id = ROW_NUMBER() OVER (PARTITION BY t.[number] ORDER BY [call_date] DESC)
			,t.PD --DWH-157
			into #t_equifax
			FROM stg._Loginom.[Origination_equifax_aggregates_4] t with (nolock)
			INNER JOIN risk.applications a 
				ON a.number = t.Number       
			where t.number not in ('19061300000088') 
			and [EqxScore] is not null 
			--DWH-2888
		
		drop table if exists #t_equifax_aggregates_person
		select 
			person_id2 = person_id2
			,EqxScore_date
			,[EqxScore]
			,pd 
			into #t_equifax_aggregates_person
		from #t_equifax t
		  where rn_person = 1
		  create clustered index cxi on #t_equifax_aggregates_person(person_id2)

		--DWH-2841
		drop table if exists #t_equifax_aggregates_external_id
		select 
			external_id
			,EqxScore_date
			,[EqxScore]
			,pd
			into #t_equifax_aggregates_external_id
		from #t_equifax t
		where rn_external_id = 1
		create clustered index cxi on #t_equifax_aggregates_external_id(external_id)
	
		DROP TABLE IF EXISTS #result;
			WITH days_closed
			AS (
				SELECT 
					person_id2
					,datediff(dd, factenddate, cast(getdate() AS DATE)) AS days_after_close
				FROM #inst
				WHERE max_rn_closed = rn_closed
				)
			SELECT i.external_id
				,i.CMRClientGUID
				,i.person_id
				,i.person_id2
				,i.last_name
				,i.first_name
				,i.patronymic
				,i.birth_date
				,i.passport_series
				,i.passport_number
				,i.okbscore
				,i.okbscore_date
				,co.okbscore AS current_okbscore
				,co.okbscore_date AS current_okbscore_date
				,b.cnt_closed_inst
				,b.cnt_closed_pts
				,ISNULL(l.lifetime_days, 0) AS lifetime_days
				,dc.days_after_close
				,cast(0 AS FLOAT) AS approved_limit
				,cast(i.fl_passport_date AS INT) AS fl_passport_date
				,cast(i.fl_age AS INT) AS fl_age
				,CASE WHEN rr.flag = '1' THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS fl_reg_region
				,CASE WHEN rf.flag = '1' THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS fl_fact_region
				,cast(i.fl_blacklist AS INT) AS fl_blacklist
				,CASE WHEN b.cnt_active_inst > 0 THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS fl_inst_active
				,CASE WHEN b.cnt_active_pts > 0 THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS fl_pts_active
				,CASE WHEN ccd.flag = 1 THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS fl_isk_sp_space
				,CASE WHEN imo.flag = 1 THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS fl_inst_max_overdue
				,CASE WHEN pmo.flag = 1 THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS fl_pts_max_overdue
				,CASE WHEN ds.flag = 1 THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS fl_delay
				,cast(0 AS INT) AS fl_bankruptcy
				,cast(0 AS INT) AS fl_CheckPassport
				,cast(0 AS INT) AS fl_fssp
				,CASE WHEN fc7.flag = 1 THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS fl_cooling_7
				,CASE WHEN fc30.flag = 1 THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS fl_cooling_30
				,CASE WHEN DATEDIFF(dd, co.okbscore_date, cast(getdate() AS DATE)) < 30 
					AND co.okbscore < 410 THEN cast(1 AS INT) ELSE cast(0 AS INT) END AS fl_low_okbscore
				,cast('Зеленый' AS NVARCHAR(50)) AS category
				,CASE WHEN ISNULL(l.lifetime_days, 0) < 15 AND b.cnt_closed_inst + b.cnt_closed_pdl < 4 THEN 100 WHEN ((ISNULL(l.lifetime_days, 0) >= 15 AND ISNULL(l.lifetime_days, 0) < 40 AND (b.cnt_closed_inst + b.cnt_closed_pdl >= 1 OR b.cnt_closed_pts >= 1)) OR ISNULL(l.lifetime_days, 0) < 15 AND b.cnt_closed_inst + b.cnt_closed_pdl >= 4) AND dc.days_after_close > 30 THEN 101 WHEN ((ISNULL(l.lifetime_days, 0) >= 15 AND ISNULL(l.lifetime_days, 0) < 40 AND (b.cnt_closed_inst + b.cnt_closed_pdl >= 1 OR b.cnt_closed_pts >= 1)) OR (ISNULL(l.lifetime_days, 0) < 15 AND b.cnt_closed_inst + b.cnt_closed_pdl >= 4)) AND dc.days_after_close <= 30 THEN 200 WHEN ((ISNULL(l.lifetime_days, 0) >= 40 AND (b.cnt_closed_inst + b.cnt_closed_pdl >= 1 OR b.cnt_closed_pts >= 1)) OR ISNULL(l.lifetime_days, 0) < 40 AND b.cnt_closed_inst + b.cnt_closed_pdl >= 4
							) AND dc.days_after_close > 30 THEN 201 WHEN ((ISNULL(l.lifetime_days, 0) >= 40 AND (b.cnt_closed_inst + b.cnt_closed_pdl >= 1 OR b.cnt_closed_pts >= 1)) OR ISNULL(l.lifetime_days, 0) < 40 AND b.cnt_closed_inst + b.cnt_closed_pdl >= 4) AND dc.days_after_close <= 30 THEN 300 END AS segment
				,i.factenddate
				,fl_override_povt
				--новые поля 14/12/2023
				,i.current_amount
				,CLI.MAX_CREDIT_LIMIT_INST
				,CLP.MAX_CREDIT_LIMIT_PDL
				,CID.current_incoming_dti
				,CFO.current_fl_override
				,b.cnt_closed_pdl
				,b.cnt_active_pdl
				,CASE WHEN pdmo.flag = 1 THEN cast(1 AS tinyint) ELSE cast(0 AS tinyint) END AS fl_pdl_max_overdue
				,EqxScore.EqxScore		--DWH-2841
				,EqxScore.EqxScore_date	--DWH-2841

				,EqxScore_ByPerson		=  EqxScore_person.EqxScore			 --DWH-2888
				,EqxScore_date_ByPerson =  EqxScore_person.EqxScore_date --DWH-2888
				,fl_low_EQUIscore_ByPerson = 
				cast(iif(datediff(dd, EqxScore_person.EqxScore_date, cast(getdate() AS DATE))<30
					and EqxScore_person.EqxScore < 540, 1, 0) as tinyint)

				,pd_ByPerson			= EqxScore_person.pd	--DWH-157
				,pd_byExternal			= EqxScore.pd			--DWH-157
				,fl_low_PDscore_ByPerson = case 
					when EqxScore_person.pd>0.55 then cast(0 as tinyint)
					when EqxScore_person.pd<=0.55 then cast(1 as tinyint)
					when EqxScore_person.pd is null then null
					end --BP-451
									
			INTO #result
			FROM #inst i
			LEFT JOIN #lifetime_days l ON l.person_id2 = i.person_id2
			LEFT JOIN #base_cnt b ON b.person_id2 = i.person_id2
			LEFT JOIN days_closed dc ON dc.person_id2 = i.person_id2
			LEFT JOIN #fl_reg_region_source rr ON rr.Number = i.external_id
			LEFT JOIN #fl_fact_region_source rf ON rf.Number = i.external_id
			LEFT JOIN #client_court_decisions ccd ON ccd.person_id2 = i.person_id2
			LEFT JOIN #fl_delay_source ds ON ds.person_id2 = i.person_id2
			LEFT JOIN #fl_inst_max_overdue_source imo ON imo.person_id2 = i.person_id2
			LEFT JOIN #fl_pdl_max_overdue_source pdmo ON pdmo.person_id2 = i.person_id2
			LEFT JOIN #fl_pts_max_overdue_source pmo ON pmo.person_id2 = i.person_id2
			LEFT JOIN #current_okbscore_source co ON co.person_id2 = i.person_id2 AND co.rn = 1
			LEFT JOIN #fl_cooling_7_source fc7 ON fc7.person_id2 = i.person_id2
			LEFT JOIN #fl_cooling_30_source fc30 ON fc30.person_id2 = i.person_id2
			LEFT JOIN #MAX_CREDIT_LIMIT_INST CLI ON CLI.person_id2 = i.person_id2 AND CLI.rn = 1
			LEFT JOIN #MAX_CREDIT_LIMIT_PDL CLP ON CLP.person_id2 = i.person_id2 AND CLP.rn = 1
			LEFT JOIN #current_incoming_dti CID ON CID.person_id2 = i.person_id2 AND CID.rn = 1
			LEFT JOIN #current_fl_override CFO ON CFO.person_id2 = i.person_id2 AND CFO.rn = 1			
			LEFT JOIN #t_equifax_aggregates_external_id EqxScore on EqxScore.external_id = i.external_id --DWH-2841
			left join #t_equifax_aggregates_person EqxScore_person on EqxScore_person.person_id2 = i.person_id2
			WHERE i.rn_1 = 1;

		UPDATE #result
		SET category = 'Красный'
		WHERE fl_age = 1 OR fl_blacklist = 1 OR fl_pts_active = 1
			--OR fl_inst_active = 1
			OR fl_isk_sp_space = 1 
			OR fl_reg_region = 1 
			OR fl_fact_region = 1 
			OR fl_inst_max_overdue = 1 
			OR fl_pdl_max_overdue = 1 
			OR fl_pts_max_overdue = 1 
			OR fl_delay = 1 
			OR fl_cooling_30 = 1 
			OR fl_cooling_7 = 1 
			OR fl_bankruptcy = 1 
			OR fl_CheckPassport = 1 
			OR fl_fssp = 1 
			OR COALESCE(fl_low_PDscore_ByPerson, fl_low_EQUIscore_ByPerson, fl_low_okbscore) = 1;--BP-451

			/*
			если значение скора из п. 1 
				не пустое- использовать его, 
				если пустое- использовать скор Equifax (fl_low_EQUIscore_ByPerson)
				, если скор Equifax (fl_low_EQUIscore_ByPerson) 
				пустое значение- использовать значение okbscore (fl_low_okbscore )
				*/


		UPDATE #result
		SET category = 'Розовый'
		WHERE fl_age = 0 
			AND fl_blacklist = 0 
			AND fl_pts_active = 0 
			AND (fl_inst_active = 1 OR cnt_active_pdl > 0) 
			AND fl_isk_sp_space = 0 
			AND fl_reg_region = 0 
			AND fl_fact_region = 0 
			AND fl_inst_max_overdue = 0 
			AND fl_pdl_max_overdue = 0 
			AND fl_pts_max_overdue = 0 
			AND fl_delay = 0 
			AND fl_cooling_30 = 0 
			AND fl_cooling_7 = 0 
			AND fl_bankruptcy = 0 
			AND fl_CheckPassport = 0 
			AND fl_fssp = 0 
			and COALESCE(fl_low_PDscore_ByPerson, fl_low_EQUIscore_ByPerson, fl_low_okbscore) = 0;--BP-451
			
			;

		DROP TABLE

		IF EXISTS #result_pdl;
			SELECT *
			INTO #result_pdl
			FROM #result;

		UPDATE #result
		SET approved_limit = CASE WHEN category = 'Красный' THEN 0
						
				else 100000 --22.01.2025 -- Николай Фомин DWH-2888
				/*--Жиделева Н. 14/12/2023
				WHEN MAX_CREDIT_LIMIT_INST <= 15000 AND MAX_CREDIT_LIMIT_PDL <= 15000 AND CURRENT_AMOUNT <= 15000 THEN 0 WHEN fl_override_povt = 1 THEN 5000 WHEN current_okbscore IS NULL AND segment IN (100, 101) THEN 9900 WHEN current_okbscore >= 0 AND current_okbscore < 430 AND segment IN (100, 101) THEN 9900 WHEN current_okbscore >= 430 AND current_okbscore < 450 AND segment IN (100, 101) THEN 9900 WHEN current_okbscore >= 450 AND current_okbscore < 465 AND segment IN (100, 101) THEN 9900 WHEN current_okbscore >= 465 AND current_okbscore < 480 AND segment IN (100, 101) THEN 9900 WHEN current_okbscore >= 480 AND current_okbscore < 500 AND segment IN (100, 101) THEN 9900 WHEN current_okbscore >= 500 AND current_okbscore < 520 AND segment IN (100, 101) THEN 30000 WHEN current_okbscore >= 520 AND current_okbscore < 540 AND segment IN (100, 101) THEN 30000 WHEN current_okbscore >= 540 AND current_okbscore < 560 AND segment IN (100, 101
						) THEN 60000 WHEN current_okbscore >= 560 AND current_okbscore < 580 AND segment IN (100, 101) THEN 100000 WHEN current_okbscore >= 580 AND current_okbscore < 600 AND segment IN (100, 101) THEN 100000 WHEN current_okbscore >= 600 AND current_okbscore < 640 AND segment IN (100, 101) THEN 100000 WHEN current_okbscore >= 640 AND segment IN (100, 101) THEN 100000 WHEN current_okbscore IS NULL AND segment IN (200, 201) THEN 30000 WHEN current_okbscore >= 0 AND current_okbscore < 430 AND segment IN (200, 201) THEN 9900 WHEN current_okbscore >= 430 AND current_okbscore < 450 AND segment IN (200, 201) THEN 9900 WHEN current_okbscore >= 450 AND current_okbscore < 465 AND segment IN (200, 201) THEN 15000 WHEN current_okbscore >= 465 AND current_okbscore < 480 AND segment IN (200, 201) THEN 15000 WHEN current_okbscore >= 480 AND current_okbscore < 500 AND segment IN (200, 201
						) THEN 20000 WHEN current_okbscore >= 500 AND current_okbscore < 520 AND segment IN (200, 201) THEN 30000 WHEN current_okbscore >= 520 AND current_okbscore < 540 AND segment IN (200, 201) THEN 75000 WHEN current_okbscore >= 540 AND current_okbscore < 560 AND segment IN (200, 201) THEN 75000 WHEN current_okbscore >= 560 AND current_okbscore < 580 AND segment IN (200, 201) THEN 100000 WHEN current_okbscore >= 580 AND current_okbscore < 600 AND segment IN (200, 201) THEN 100000 WHEN current_okbscore >= 600 AND current_okbscore < 640 AND segment IN (200, 201) THEN 100000 WHEN current_okbscore >= 640 AND segment IN (200, 201) THEN 100000 WHEN current_okbscore IS NULL AND segment = 300 THEN 40000 WHEN current_okbscore >= 0 AND current_okbscore < 430 AND segment = 300 THEN 9900 WHEN current_okbscore >= 430 AND current_okbscore < 450 AND segment = 300 THEN 9900 WHEN current_okbscore >= 450 AND current_okbscore < 465 AND segment = 300 THEN 25000 WHEN 
					current_okbscore >= 465 AND current_okbscore < 480 AND segment = 300 THEN 25000 WHEN current_okbscore >= 480 AND current_okbscore < 500 AND segment = 300 THEN 30000 WHEN current_okbscore >= 500 AND current_okbscore < 520 AND segment = 300 THEN 40000 WHEN current_okbscore >= 520 AND current_okbscore < 540 AND segment = 300 THEN 75000 WHEN current_okbscore >= 540 AND current_okbscore < 560 AND segment = 300 THEN 75000 WHEN current_okbscore >= 560 AND current_okbscore < 580 AND segment = 300 THEN 100000 WHEN current_okbscore >= 580 AND current_okbscore < 600 AND segment = 300 THEN 100000 WHEN current_okbscore >= 600 AND current_okbscore < 640 AND segment = 300 THEN 100000 WHEN current_okbscore >= 640 AND segment = 300 THEN 100000 END;
					*/
					end
		UPDATE #result_pdl
		SET approved_limit = CASE WHEN category = 'Красный' THEN 0
			else 30000 end ---22.01.2025 -- Николай Фомин DWH-2888

		/*
		= CASE WHEN current_fl_override = 1 AND current_okbscore IS NULL THEN 5000 WHEN current_fl_override = 1 AND current_okbscore < 450 THEN 5000 WHEN current_fl_override = 1 AND current_okbscore < 500 THEN 7000 WHEN current_fl_override = 1 AND current_okbscore >= 500 THEN 9900 WHEN current_fl_override = 0 AND current_incoming_dti > 0.8 AND current_okbscore IS NULL THEN 5000 WHEN current_fl_override = 0 AND current_incoming_dti > 0.8 AND current_okbscore < 465 THEN 5000 WHEN current_fl_override = 0 AND current_incoming_dti > 0.8 AND current_okbscore < 480 THEN 7500 WHEN current_fl_override = 0 AND current_incoming_dti > 0.8 AND current_okbscore < 540 THEN 9900 WHEN current_fl_override = 0 AND current_incoming_dti > 0.8 AND current_okbscore < 560 THEN 12000 WHEN current_fl_override = 0 AND current_incoming_dti > 0.8 AND current_okbscore >= 560 THEN 15000 WHEN current_fl_override = 0 AND current_incoming_dti <= 0.8 AND current_okbscore IS NULL THEN 15000 WHEN current_fl_override = 0 AND current_incoming_dti <= 0.8 AND current_okbscore < 520 THEN 15000 WHEN current_fl_override = 0 AND current_incoming_dti <= 0.8 AND 
					current_okbscore < 580 THEN 20000 WHEN current_fl_override = 0 AND current_incoming_dti <= 0.8 AND current_okbscore >= 580 THEN 30000 WHEN current_fl_override = 0 AND current_incoming_dti IS NULL AND current_okbscore IS NULL THEN 15000
						--2023-12-20 Жиделева Н.
				WHEN current_fl_override IS NULL AND current_incoming_dti IS NULL AND current_okbscore IS NULL THEN 15000 WHEN current_fl_override = 0 AND current_incoming_dti IS NULL AND current_okbscore < 520 THEN 15000 WHEN current_fl_override = 0 AND current_incoming_dti IS NULL AND current_okbscore < 580 THEN 20000 WHEN current_fl_override = 0 AND current_incoming_dti IS NULL AND current_okbscore >= 580 THEN 30000 ELSE 0 END;
			*/
		IF object_id('risk.povt_inst_buffer') IS NULL
		BEGIN
			SELECT TOP (0) *
			INTO risk.povt_inst_buffer
			FROM #result;

			CREATE UNIQUE INDEX uix_povt_inst_buffer_external_id ON risk.povt_inst_buffer (external_id);

			CREATE UNIQUE INDEX uix_povt_inst_buffer_person_id2 ON risk.povt_inst_buffer (person_id2);
		END

		IF EXISTS (
				SELECT TOP (1) 1
				FROM #result
				)
		BEGIN

			BEGIN TRANSACTION

			TRUNCATE TABLE risk.povt_inst_buffer;
			--alter table risk.povt_inst_buffer
			--	add EqxScore int, EqxScore_date datetime
			/*alter table risk.povt_inst_buffer
				add EqxScore_ByPerson int ,
					EqxScore_date_ByPerson datetime
			alter table risk.povt_inst_buffer
				add fl_low_EQUIscore_ByPerson tinyint 
			alter table risk.povt_inst_buffer
				add pd_ByPerson float 
			alter table risk.povt_inst_buffer
				add pd_byExternal float
			alter table risk.povt_inst_buffer
				add fl_low_PDscore_ByPerson tinyint

				*/
			INSERT INTO risk.povt_inst_buffer (
				[external_id]
				,[CMRClientGUID]
				,[person_id]
				,[person_id2]
				,[last_name]
				,[first_name]
				,[patronymic]
				,[birth_date]
				,[passport_series]
				,[passport_number]
				,[okbscore]
				,[okbscore_date]
				,[current_okbscore]
				,[current_okbscore_date]
				,[cnt_closed_inst]
				,[cnt_closed_pts]
				,[lifetime_days]
				,[days_after_close]
				,[approved_limit]
				,[fl_passport_date]
				,[fl_age]
				,[fl_reg_region]
				,[fl_fact_region]
				,[fl_blacklist]
				,[fl_inst_active]
				,[fl_pts_active]
				,[fl_isk_sp_space]
				,[fl_inst_max_overdue]
				,[fl_pts_max_overdue]
				,[fl_delay]
				,[fl_bankruptcy]
				,[fl_CheckPassport]
				,[fl_fssp]
				,[fl_cooling_7]
				,[fl_cooling_30]
				,[fl_low_okbscore]
				,[category]
				,[segment]
				,[factenddate]
				,[fl_override_povt]
				--
				,[MAX_CREDIT_LIMIT_INST]
				,[MAX_CREDIT_LIMIT_PDL]
				,[current_incoming_dti]
				,[current_fl_override]
				,[current_amount]
				,[cnt_closed_pdl]
				,[cnt_active_pdl]
				,[fl_pdl_max_overdue]
				,EqxScore		--DWH-2841
				,EqxScore_date	--DWH-2841
				,EqxScore_ByPerson
				,EqxScore_date_ByPerson
				,fl_low_EQUIscore_ByPerson
				,pd_ByPerson			--DWH-157
				,pd_byExternal			--DWH-157
				,fl_low_PDscore_ByPerson
				)
			SELECT [external_id]
				,[CMRClientGUID]
				,[person_id]
				,[person_id2]
				,[last_name]
				,[first_name]
				,[patronymic]
				,[birth_date]
				,[passport_series]
				,[passport_number]
				,[okbscore]
				,[okbscore_date]
				,[current_okbscore]
				,[current_okbscore_date]
				,[cnt_closed_inst]
				,[cnt_closed_pts]
				,[lifetime_days]
				,[days_after_close]
				,[approved_limit]
				,[fl_passport_date]
				,[fl_age]
				,[fl_reg_region]
				,[fl_fact_region]
				,[fl_blacklist]
				,[fl_inst_active]
				,[fl_pts_active]
				,[fl_isk_sp_space]
				,[fl_inst_max_overdue]
				,[fl_pts_max_overdue]
				,[fl_delay]
				,[fl_bankruptcy]
				,[fl_CheckPassport]
				,[fl_fssp]
				,[fl_cooling_7]
				,[fl_cooling_30]
				,[fl_low_okbscore]
				,[category]
				,[segment]
				,[factenddate]
				,[fl_override_povt]
				,[MAX_CREDIT_LIMIT_INST]
				,[MAX_CREDIT_LIMIT_PDL]
				,[current_incoming_dti]
				,[current_fl_override]
				,[current_amount]
				,[cnt_closed_pdl]
				,[cnt_active_pdl]
				,[fl_pdl_max_overdue]
				,EqxScore		--DWH-2841
				,EqxScore_date	--DWH-2841
				,EqxScore_ByPerson			--DWH-2888
				,EqxScore_date_ByPerson		--DWH-2888
				,fl_low_EQUIscore_ByPerson	--DWH-2888
				,pd_ByPerson			--DWH-157
				,pd_byExternal			--DWH-157
				,fl_low_PDscore_ByPerson --BP-451
			FROM #result;

			COMMIT TRANSACTION
		END

		--PDL
		IF object_id('risk.povt_pdl_buffer') IS NULL
		BEGIN
			SELECT TOP (0) *
			INTO risk.povt_pdl_buffer
			FROM #result_pdl;

			CREATE UNIQUE INDEX uix_povt_pdl_buffer_external_id ON risk.povt_pdl_buffer (external_id);

			CREATE UNIQUE INDEX uix_povt_pdl_buffer_person_id2 ON risk.povt_pdl_buffer (person_id2);
		END

		IF EXISTS (
				SELECT TOP (1) 1
				FROM #result_pdl
				)
		BEGIN

			BEGIN TRANSACTION

			TRUNCATE TABLE risk.povt_pdl_buffer;

			/*alter table risk.povt_pdl_buffer
				add EqxScore_ByPerson int ,
					EqxScore_date_ByPerson datetime
			alter table risk.povt_pdl_buffer
				add fl_low_EQUIscore_ByPerson tinyint 

			alter table risk.povt_pdl_buffer
				add pd_ByPerson float 
			alter table risk.povt_pdl_buffer
				add pd_byExternal float
			alter table risk.povt_pdl_buffer
					add fl_low_PDscore_ByPerson tinyint --BP-451

			*/

			INSERT INTO risk.povt_pdl_buffer (
				[external_id]
				,[CMRClientGUID]
				,[person_id]
				,[person_id2]
				,[last_name]
				,[first_name]
				,[patronymic]
				,[birth_date]
				,[passport_series]
				,[passport_number]
				,[okbscore]
				,[okbscore_date]
				,[current_okbscore]
				,[current_okbscore_date]
				,[cnt_closed_inst]
				,[cnt_closed_pts]
				,[lifetime_days]
				,[days_after_close]
				,[approved_limit]
				,[fl_passport_date]
				,[fl_age]
				,[fl_reg_region]
				,[fl_fact_region]
				,[fl_blacklist]
				,[fl_inst_active]
				,[fl_pts_active]
				,[fl_isk_sp_space]
				,[fl_inst_max_overdue]
				,[fl_pts_max_overdue]
				,[fl_delay]
				,[fl_bankruptcy]
				,[fl_CheckPassport]
				,[fl_fssp]
				,[fl_cooling_7]
				,[fl_cooling_30]
				,[fl_low_okbscore]
				,[category]
				,[segment]
				,[factenddate]
				,[fl_override_povt]
				,[MAX_CREDIT_LIMIT_INST]
				,[MAX_CREDIT_LIMIT_PDL]
				,[current_incoming_dti]
				,[current_fl_override]
				,[current_amount]
				,[cnt_closed_pdl]
				,[cnt_active_pdl]
				,[fl_pdl_max_overdue]
				,EqxScore		--DWH-2841
				,EqxScore_date	--DWH-2841
				,EqxScore_ByPerson			--DWH-2888
				,EqxScore_date_ByPerson		--DWH-2888
				,fl_low_EQUIscore_ByPerson	--DWH-2888
				,pd_ByPerson			--DWH-157
				,pd_byExternal			--DWH-157
				,fl_low_PDscore_ByPerson --bp-451
				)
			SELECT [external_id]
				,[CMRClientGUID]
				,[person_id]
				,[person_id2]
				,[last_name]
				,[first_name]
				,[patronymic]
				,[birth_date]
				,[passport_series]
				,[passport_number]
				,[okbscore]
				,[okbscore_date]
				,[current_okbscore]
				,[current_okbscore_date]
				,[cnt_closed_inst]
				,[cnt_closed_pts]
				,[lifetime_days]
				,[days_after_close]
				,[approved_limit]
				,[fl_passport_date]
				,[fl_age]
				,[fl_reg_region]
				,[fl_fact_region]
				,[fl_blacklist]
				,[fl_inst_active]
				,[fl_pts_active]
				,[fl_isk_sp_space]
				,[fl_inst_max_overdue]
				,[fl_pts_max_overdue]
				,[fl_delay]
				,[fl_bankruptcy]
				,[fl_CheckPassport]
				,[fl_fssp]
				,[fl_cooling_7]
				,[fl_cooling_30]
				,[fl_low_okbscore]
				,[category]
				,[segment]
				,[factenddate]
				,[fl_override_povt]
				,[MAX_CREDIT_LIMIT_INST]
				,[MAX_CREDIT_LIMIT_PDL]
				,[current_incoming_dti]
				,[current_fl_override]
				,[current_amount]
				,[cnt_closed_pdl]
				,[cnt_active_pdl]
				,[fl_pdl_max_overdue]
				,EqxScore		--DWH-2841
				,EqxScore_date	--DWH-2841
				,EqxScore_ByPerson			--DWH-2888
				,EqxScore_date_ByPerson		--DWH-2888
				,fl_low_EQUIscore_ByPerson	--DWH-2888
				,pd_ByPerson			--DWH-157
				,pd_byExternal			--DWH-157
				,fl_low_PDscore_ByPerson --bp-451
			FROM #result_pdl;

			COMMIT TRANSACTION
		END

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

		EXEC msdb.dbo.sp_send_dbmail @recipients = 'risk_tech@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;
