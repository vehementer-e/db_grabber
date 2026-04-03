
--exec [dbo].[prc$update_rep_coll_weekly_part3];
CREATE PROC [dbo].[prc$update_rep_coll_weekly_part3_2]
	-- 0 - бакеты просрочки as-is из ЦМР, 1 - фиксируем бакет просрочки на момент начала КК только в месяц начала КК
	@excludecredholid BIT = 0
	,
	-- 0 - бакеты просрочки as-is из ЦМР, 1 - исключаем полностью кредиты, которые когда-либо были на КК
	@flag_kk_total BIT = 0
AS
if (select count(*) from ##CMR_weekly) > 0
begin
	DECLARE @src_name NVARCHAR(100) = 'Roll rates for weekly report (old buckets) + 91+ CASH';
	DECLARE @rdt DATE = dateadd(dd, - 1, cast(RiskDWH.dbo.date_trunc('wk', cast(getdate() AS DATE)) AS DATE));
	DECLARE @lysd_dt_from DATE = dateadd(dd, 1, EOMONTH(@rdt, - 13));
	DECLARE @lysd_dt_to DATE = dateadd(yy, - 1, @rdt);
	DECLARE @lm_dt_from DATE = dateadd(dd, 1, EOMONTH(@rdt, - 2));
	DECLARE @lmsd_dt_to DATE = dateadd(MM, - 1, @rdt);
	DECLARE @lm_dt_to DATE = eomonth(@rdt, - 1);
	DECLARE @cm_dt_from DATE = dateadd(dd, 1, eomonth(@rdt, - 1));
	DECLARE @cw_dt_from DATE = RiskDWH.dbo.date_trunc('wk', @rdt);
	DECLARE @lw_dt_from DATE = dateadd(dd, - 7, RiskDWH.dbo.date_trunc('wk', @rdt));
	DECLARE @lw_dt_to DATE = dateadd(dd, - 1, RiskDWH.dbo.date_trunc('wk', @rdt));
	DECLARE @march2020_from DATE = cast('2020-03-01' AS DATE);
	DECLARE @march2020_to DATE = cast('2020-03-31' AS DATE);

	SET DATEFIRST 1;

	DECLARE @vinfo VARCHAR(1000) = CONCAT (
			'START rep_dt = '
			,format(@rdt, 'dd.MM.yyyy')
			,', excludecredholid = '
			,cast(@excludecredholid AS VARCHAR(1))
			,', flag_kk_total = '
			,cast(@flag_kk_total AS VARCHAR(1))
			);

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = @vinfo;

		drop table if exists #CMR;

		select r_date, 
		external_id, 
		r_day, r_month, r_year,
		overdue_days, 
		overdue_days_p, 
		last_dpd,
		dpd_bucket, 
		dpd_bucket_p, 
		dpd_bucket_last,
		principal_rest,
		prev_dpd_coll as lag_overdue_days, 
		prev_dpd_p_coll as lag_overdue_days_p,
		prev_od as last_principal_rest,
		pay_total,
		pay_total_calc
		into #CMR
		from ##CMR_weekly

	DROP INDEX

	IF EXISTS tmp_cmr_idx ON #CMR;
		CREATE CLUSTERED INDEX tmp_cmr_idx ON #CMR (
			external_id
			,r_date
			);

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#stg_product';

	DROP TABLE

	IF EXISTS #stg_product;
		SELECT a.Код AS external_id
			,CASE 
				WHEN cmr_ПодтипыПродуктов.Наименование = 'Pdl'
					THEN 'INSTALLMENT'
				WHEN a.IsInstallment = 1
					THEN 'INSTALLMENT'
				ELSE 'PTS'
				END AS product
		INTO #stg_product
		FROM stg._1cCMR.Справочник_Договоры a
		LEFT JOIN Stg._1cCMR.Справочник_Заявка cmr_Заявка ON cmr_Заявка.Ссылка = a.Заявка
		LEFT JOIN stg._1cCMR.Справочник_ПодтипыПродуктов cmr_ПодтипыПродуктов ON cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка;

	DROP TABLE

	IF EXISTS #total_kk;
		CREATE TABLE #total_kk (
			external_id VARCHAR(100)
			,dt_from DATE
			,dt_to DATE
			);

	IF @excludecredholid = 1
	BEGIN
		--исключаем кредитные каникулы
		EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
			,@info = 'CredVacations';

		INSERT INTO #total_kk
		SELECT external_id
			,dt_from
			,dt_to
		FROM RiskDWH.dbo.det_kk_cmr_and_space;
	END;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#stg_isp_proiz';

	--обрабатываем исполнительные листы для поиска даты начала/заявки/передачи производства
	DROP TABLE

	IF EXISTS #stg_isp_proiz;
		SELECT deals.Number AS external_id
			,eo.Accepted
			,cast(eo.AcceptanceDate AS DATE) AS accept_dt
			,eo.Id AS enf_ord_id
			,cast(eo.CreateDate AS DATE) AS enf_ord_create_dt
			,cast(eo.UpdateDate AS DATE) AS enf_ord_upd_dt
			,replace(replace(eo.Number, ' ', ''), '№', '') AS enf_ord_number
			,ep.Id AS enf_proc_id
			,cast(ep.CreateDate AS DATE) AS enf_proc_create_dt
			,cast(ep.UpdateDate AS DATE) AS enf_proc_upd_dt
			,NULL AS EndDate
			,--ep.EndDate,
			ep.CaseNumberInFSSP
			,jc.id AS jud_claim_id
			,cast(jc.CreateDate AS DATE) AS jud_claim_cr_dt
			,cast(jc.UpdateDate AS DATE) AS jud_claim_upd_dt
			,jp.id AS jud_proc_id
			,cast(jp.CreateDate AS DATE) AS jud_proc_cr_dt
			,cast(jp.UpdateDate AS DATE) AS jud_proc_upd_dt
			,cast(eo.DATE AS DATE) AS isp_list_dt
			,cast(eo.ReceiptDate AS DATE) AS receipt_dt
			,cast(ep.ExcitationDate AS DATE) AS excitation_dt
			,NULL AS adopt_bal_dt
			,--cast(ep.AdoptionBalanceDate as date) as adopt_bal_dt,
			cast(ep.ApplicationDeliveryDate AS DATE) AS app_delivery_dt
			,NULL AS arest_car_dt --cast(ep.ArestCarDate as date) as arest_car_dt
		INTO #stg_isp_proiz
		FROM [Stg].[_Collection].[EnforcementOrders] eo
		LEFT JOIN [Stg].[_Collection].JudicialClaims jc ON jc.id = eo.JudicialClaimId
		LEFT JOIN [Stg].[_Collection].JudicialProceeding jp ON jp.Id = jc.JudicialProceedingId
		LEFT JOIN [Stg].[_Collection].Deals ON Deals.Id = jp.DealId
		LEFT JOIN [Stg].[_Collection].EnforcementProceeding ep ON eo.id = ep.EnforcementOrderId;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#isp_proiz';

	--выбираем дату начала исп. производства
	DROP TABLE

	IF EXISTS #isp_proiz;
		SELECT aa.external_id
			,min(aa.total_dt_from) AS dt_from
		INTO #isp_proiz
		FROM (
			SELECT a.external_id
				,coalesce(a.isp_list_dt, a.receipt_dt, a.app_delivery_dt, a.excitation_dt, a.accept_dt, a.jud_proc_cr_dt, a.jud_claim_cr_dt, a.enf_proc_create_dt, a.enf_ord_create_dt, a.jud_claim_upd_dt, a.jud_proc_upd_dt) AS total_dt_from
			FROM #stg_isp_proiz a
			WHERE 1 = 1
				AND a.Accepted = 1
			) aa
		GROUP BY aa.external_id;

	--если статус по клиенту "ИП", то включаем все договоры в "ИП"
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#cli_con_stages';

	DROP TABLE

	IF EXISTS #stg1_cli_con_stages;
		SELECT r.CMRContractNumber AS external_id
			,r.CMRContractGUID
			,r.CRMClientGUID
		INTO #stg1_cli_con_stages
		FROM dwh_new.staging.CRMClient_references r
		WHERE r.CMRContractNumber IS NOT NULL
			AND r.CRMClientGUID IS NOT NULL;

	DROP TABLE

	IF EXISTS #stg2_cli_con_stages;
		/*
		--var 1
		SELECT *
		INTO #stg2_cli_con_stages
		FROM dwh_new.Dialer.ClientContractStage cc
		WHERE Cast(cc.created AS DATE) BETWEEN @lm_dt_from
				AND @rdt
			AND cc.CRMClientStage = 'ИП'
	
		UNION ALL
	
		SELECT *
		FROM dwh_new.Dialer.ClientContractStage cc
		WHERE Cast(cc.created AS DATE) BETWEEN @march2020_from
				AND @march2020_to
			AND cc.CRMClientStage = 'ИП'
	
		UNION ALL
	
		SELECT *
		FROM dwh_new.Dialer.ClientContractStage cc
		WHERE Cast(cc.created AS DATE) BETWEEN @lysd_dt_from
				AND @lysd_dt_to
			AND cc.CRMClientStage = 'ИП';
		*/

		--var 2 --DWH-2442
		SELECT 
			cc.CRMClientGUID,
			cc.CRMClientStage,
			cc.CMRContractGUID,
			cc.CMRContractNumber,
			cc.CMRContractStage,
			cc.created,
			cc.updated,
			cc.isHistory
		INTO #stg2_cli_con_stages
		FROM Stg._loginom.v_ClientContractStage_simple AS cc
		WHERE cc.created BETWEEN @lm_dt_from AND @rdt
			AND cc.CRMClientStage = 'ИП'
	
		UNION ALL
	
		SELECT 
			cc.CRMClientGUID,
			cc.CRMClientStage,
			cc.CMRContractGUID,
			cc.CMRContractNumber,
			cc.CMRContractStage,
			cc.created,
			cc.updated,
			cc.isHistory
		FROM Stg._loginom.v_ClientContractStage_simple AS cc
		WHERE cc.created BETWEEN @march2020_from AND @march2020_to
			AND cc.CRMClientStage = 'ИП'
	
		UNION ALL
	
		SELECT 
			cc.CRMClientGUID,
			cc.CRMClientStage,
			cc.CMRContractGUID,
			cc.CMRContractNumber,
			cc.CMRContractStage,
			cc.created,
			cc.updated,
			cc.isHistory
		FROM Stg._loginom.v_ClientContractStage_simple AS cc
		WHERE cc.created BETWEEN @lysd_dt_from AND @lysd_dt_to
			AND cc.CRMClientStage = 'ИП';

	DROP TABLE

	IF EXISTS #stg3_cli_con_stages;
		/*
		--var 1
		SELECT bs.*
			,cast(cc.created AS DATE) AS date_on
			,cc.CMRContractStage
			,cc.CRMClientStage
			,ROW_NUMBER() OVER (
				PARTITION BY bs.external_id
				,Cast(cc.created AS DATE) ORDER BY cc.created DESC
				) AS rown
		INTO #stg3_cli_con_stages
		FROM #stg1_cli_con_stages bs
		INNER JOIN #stg2_cli_con_stages cc ON bs.CMRContractGUID = cc.CMRContractGUID
			AND bs.CRMClientGUID = cc.CRMClientGUID;
		*/
		--var 2
		SELECT 
			external_id = cc.CMRContractNumber
			,cc.CMRContractGUID
			,cc.CRMClientGUID
			,cc.created AS date_on
			,cc.CMRContractStage
			,cc.CRMClientStage
			,row_number() OVER (
				PARTITION BY cc.CMRContractNumber,cc.created 
				ORDER BY cc.created DESC
			) AS rown
		INTO #stg3_cli_con_stages
		FROM #stg2_cli_con_stages AS cc

	DROP TABLE

	IF EXISTS #cli_con_stages;
		SELECT s.external_id
			,s.date_on
			,s.CMRContractGUID
			,s.CMRContractStage
			,s.CRMClientGUID
			,s.CRMClientStage
		INTO #cli_con_stages
		FROM #stg3_cli_con_stages s
		WHERE rown = 1;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#stg_ip_0_90';

	--расставляем флаги периодов LM/LMSD/LW/CM/CW и присоединяем информацию по агентам и статусам договора
	DROP TABLE

	IF EXISTS #stg_ip_0_90;
		SELECT a.r_date
			,a.external_id
			,isnull(d.dpd_bucket_p, a.dpd_bucket_p) AS dpd_bucket_p
			,isnull(d.overdue_days_p, a.overdue_days_p) AS overdue_days_p
			,a.pay_total
			,CASE 
				WHEN a.r_date BETWEEN @lm_dt_from
						AND @lm_dt_to
					THEN 1
				ELSE 0
				END AS flag_lm
			,CASE 
				WHEN a.r_date BETWEEN @lm_dt_from
						AND @lmsd_dt_to
					THEN 1
				ELSE 0
				END AS flag_lmsd
			,CASE 
				WHEN a.r_date BETWEEN @lw_dt_from
						AND @lw_dt_to
					THEN 1
				ELSE 0
				END AS flag_lw
			,CASE 
				WHEN a.r_date BETWEEN @cm_dt_from
						AND @rdt
					THEN 1
				ELSE 0
				END AS flag_cm
			,CASE 
				WHEN a.r_date BETWEEN @cw_dt_from
						AND @rdt
					THEN 1
				ELSE 0
				END AS flag_cw
			,CASE 
				WHEN a.r_date BETWEEN @march2020_from
						AND @march2020_to
					THEN 1
				ELSE 0
				END AS flag_mar20
			,CASE 
				WHEN a.r_date BETWEEN @lysd_dt_from
						AND @lysd_dt_to
					THEN 1
				ELSE 0
				END AS flag_lysd
			,CASE 
				WHEN isnull(c.agent_name, 'CarMoney') IN ('ACB', 'CarMoney')
					THEN 0
				ELSE 1
				END AS flag_agent
			,s.CRMClientStage AS con_stage
			,coalesce(pr.product, 'PTS') AS product --15.02.2022
		INTO #stg_ip_0_90
		FROM #CMR a
		LEFT JOIN dwh_new.dbo.v_agent_credits c ON a.external_id = c.external_id
			AND a.r_date BETWEEN c.st_date
				AND c.end_date
		LEFT JOIN RiskDWH.dbo.stg_client_stage s ON a.external_id = s.external_id
			AND a.r_date = s.cdate
		--30/10/2020 для учета КК
		LEFT JOIN #total_kk k ON a.external_id = k.external_id
			AND a.r_date BETWEEN k.dt_from
				AND k.dt_to
			AND eomonth(a.r_date) = eomonth(dateadd(dd, 1, k.dt_from))
		LEFT JOIN #CMR d ON k.external_id = d.external_id
			AND k.dt_from = d.r_date
		LEFT JOIN #stg_product pr ON a.external_id = pr.external_id
		WHERE (
				a.r_date BETWEEN @lm_dt_from
					AND @rdt
				OR a.r_date BETWEEN @march2020_from
					AND @march2020_to
				OR a.r_date BETWEEN @lysd_dt_from
					AND @lysd_dt_to
				)
			--and a.pay_total > 0	
			;

	--09/03/21 Полное исключение каникул
	IF @flag_kk_total = 1
	BEGIN
		WITH a
		AS (
			SELECT *
			FROM #stg_ip_0_90
			)
		DELETE
		FROM a
		WHERE EXISTS (
				SELECT 1
				FROM RiskDWH.dbo.det_kk_cmr_and_space b
				WHERE a.external_id = b.external_id
				)

		DELETE
		FROM #stg_ip_0_90
		WHERE product IN ('INSTALLMENT', 'PDL') --15.02.2022
	END;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#stg_pmt_91_plus';

	--все платежи 91+ и ИП
	DROP TABLE

	IF EXISTS #stg_pmt_91_plus;
		SELECT a.r_date
			,a.external_id
			,a.dpd_bucket_p
			,a.overdue_days_p
			,a.pay_total
			,a.flag_cm
			,a.flag_cw
			,a.flag_lm
			,a.flag_lmsd
			,a.flag_lw
			,a.flag_mar20
			,a.flag_lysd
			,CASE 
				WHEN i.external_id IS NOT NULL
					AND a.flag_agent = 0
					THEN 'ИП'
				WHEN ccs.external_id IS NOT NULL
					AND a.flag_agent = 0
					THEN 'ИП'
				WHEN a.flag_agent = 1
					THEN 'Агент'
				ELSE 'Хард'
				END AS seg_ip_hard_agent
			,a.product --15.02.2022
		INTO #stg_pmt_91_plus
		FROM #stg_ip_0_90 a
		LEFT JOIN #isp_proiz i ON a.external_id = i.external_id
			AND a.r_date >= i.dt_from
		LEFT JOIN #cli_con_stages ccs ON a.external_id = ccs.external_id
			AND a.r_date = ccs.date_on
		WHERE (
				a.overdue_days_p >= 91
				OR (
					a.con_stage = 'ИП'
					OR i.external_id IS NOT NULL
					OR ccs.external_id IS NOT NULL
					)
				AND a.flag_agent = 0
				--or a.flag_agent = 1
				);

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = 'rep_coll_weekly_0_90_isp_prz';

	--платежи в категории 0-90 ИП
	--drop table if exists #0_90_isp_prz_MAR20
	--select * into #0_90_isp_prz_MAR20 from RiskDWH.dbo.rep_coll_weekly_0_90_isp_prz
	--where seg = 'MAR20'

	DELETE
	FROM RiskDWH.dbo.rep_coll_weekly_0_90_isp_prz
	WHERE rep_dt = @rdt
		AND flag_exclude_kk = @flag_kk_total;

	IF @flag_kk_total = 0 --15.02.2022
	BEGIN
		DELETE
		FROM RiskDWH.dbo.rep_coll_weekly_0_90_isp_prz
		WHERE rep_dt = @rdt
			AND flag_exclude_kk = 2;
	END;

	INSERT INTO RiskDWH.dbo.rep_coll_weekly_0_90_isp_prz
	SELECT @rdt AS rep_dt
		,cast(sysdatetime() AS DATETIME) AS dt_dml
		,aa.seg
		,aa.pmt_0_90_ip
		,CASE 
			WHEN aa.product IN ('INSTALLMENT', 'PDL')
				THEN 2
			ELSE @flag_kk_total
			END AS flag_exclude_kk --15.02.2022
	FROM (
		SELECT 'CM' AS seg
			,isnull(sum(a.pay_total), 0) AS pmt_0_90_ip
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.seg_ip_hard_agent = 'ИП'
			AND a.dpd_bucket_p NOT IN ('(5)_91_360', '(6)_361+')
			AND a.flag_cm = 1
		GROUP BY a.product /*15.02.2022*/
	
		UNION ALL
	
		SELECT 'CW' AS seg
			,isnull(sum(a.pay_total), 0) AS pmt_0_90_ip
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.seg_ip_hard_agent = 'ИП'
			AND a.dpd_bucket_p NOT IN ('(5)_91_360', '(6)_361+')
			AND a.flag_cw = 1
		GROUP BY a.product /*15.02.2022*/
	
		UNION ALL
	
		SELECT 'LMSD' AS seg
			,isnull(sum(a.pay_total), 0) AS pmt_0_90_ip
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.seg_ip_hard_agent = 'ИП'
			AND a.dpd_bucket_p NOT IN ('(5)_91_360', '(6)_361+')
			AND a.flag_lmsd = 1
		GROUP BY a.product /*15.02.2022*/
	
		UNION ALL
	
		SELECT 'LM' AS seg
			,isnull(sum(a.pay_total), 0) AS pmt_0_90_ip
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.seg_ip_hard_agent = 'ИП'
			AND a.dpd_bucket_p NOT IN ('(5)_91_360', '(6)_361+')
			AND a.flag_lm = 1
		GROUP BY a.product /*15.02.2022*/
	
		UNION ALL
	
		SELECT 'LW' AS seg
			,isnull(sum(a.pay_total), 0) AS pmt_0_90_ip
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.seg_ip_hard_agent = 'ИП'
			AND a.dpd_bucket_p NOT IN ('(5)_91_360', '(6)_361+')
			AND a.flag_lw = 1
		GROUP BY a.product /*15.02.2022*/
	
		/*UNION ALL
	
		SELECT 'MAR20' AS seg
			,isnull(sum(a.pay_total), 0) AS pmt_0_90_ip
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.seg_ip_hard_agent = 'ИП'
			AND a.dpd_bucket_p NOT IN ('(5)_91_360', '(6)_361+')
			AND a.flag_mar20 = 1
		GROUP BY a.product /*15.02.2022*/*/
	
		UNION ALL
	
		SELECT 'LYSD' AS seg
			,isnull(sum(a.pay_total), 0) AS pmt_0_90_ip
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.seg_ip_hard_agent = 'ИП'
			AND a.dpd_bucket_p NOT IN ('(5)_91_360', '(6)_361+')
			AND a.flag_lysd = 1
		GROUP BY a.product /*15.02.2022*/
		) aa;
	--INSERT INTO RiskDWH.dbo.rep_coll_weekly_0_90_isp_prz select * from #0_90_isp_prz_MAR20;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = 'rep_coll_weekly_npl_pmt';

	--CASH по категориям Агент/ИП/Хард
	--drop table if exists #npl_pmt_MAR20
	--select * into #npl_pmt_MAR20 from RiskDWH.dbo.rep_coll_weekly_npl_pmt
	--where seg = 'MAR20'

	DELETE
	FROM RiskDWH.dbo.rep_coll_weekly_npl_pmt
	WHERE rep_dt = @rdt
		AND flag_exclude_kk = @flag_kk_total;

	IF @flag_kk_total = 0 --15.02.2022
	BEGIN
		DELETE
		FROM RiskDWH.dbo.rep_coll_weekly_npl_pmt
		WHERE rep_dt = @rdt
			AND flag_exclude_kk = 2;
	END;

	WITH base
	AS (
		SELECT cast('LM' AS VARCHAR(50)) AS seg
			,a.seg_ip_hard_agent
			,sum(a.pay_total) AS pmt
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.flag_lm = 1
		GROUP BY a.seg_ip_hard_agent
			,a.product /*15.02.2022*/
	
		UNION ALL
	
		SELECT 'LMSD' AS seg
			,a.seg_ip_hard_agent
			,sum(a.pay_total) AS pmt
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.flag_lmsd = 1
		GROUP BY a.seg_ip_hard_agent
			,a.product /*15.02.2022*/
	
		UNION ALL
	
		SELECT 'LYSD' AS seg
			,a.seg_ip_hard_agent
			,sum(a.pay_total) AS pmt
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.flag_lysd = 1
		GROUP BY a.seg_ip_hard_agent
			,a.product /*15.02.2022*/
	
		/*UNION ALL
	
		SELECT 'MAR20' AS seg
			,a.seg_ip_hard_agent
			,sum(a.pay_total) AS pmt
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.flag_mar20 = 1
		GROUP BY a.seg_ip_hard_agent
			,a.product /*15.02.2022*/*/
	
		UNION ALL
	
		SELECT 'CW' AS seg
			,a.seg_ip_hard_agent
			,sum(a.pay_total) AS pmt
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.flag_cw = 1
		GROUP BY a.seg_ip_hard_agent
			,a.product /*15.02.2022*/
	
		UNION ALL
	
		SELECT 'CM' AS seg
			,a.seg_ip_hard_agent
			,sum(a.pay_total) AS pmt
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.flag_cm = 1
		GROUP BY a.seg_ip_hard_agent
			,a.product /*15.02.2022*/
	
		UNION ALL
	
		SELECT 'LW' AS seg
			,a.seg_ip_hard_agent
			,sum(a.pay_total) AS pmt
			,a.product /*15.02.2022*/
		FROM #stg_pmt_91_plus a
		WHERE a.flag_lw = 1
		GROUP BY a.seg_ip_hard_agent
			,a.product /*15.02.2022*/
		)
	INSERT INTO RiskDWH.dbo.rep_coll_weekly_npl_pmt
	SELECT @rdt AS rep_dt
		,cast(sysdatetime() AS DATETIME) AS dt_dml
		,cast(CONCAT (
				b.seg
				,'#'
				,b.seg_ip_hard_agent
				) AS VARCHAR(200)) AS metric
		,b.seg
		,b.seg_ip_hard_agent
		,b.pmt + isnull(h.pmt_0_90_hard, 0) AS pmt
		,CASE 
			WHEN b.product IN ('INSTALLMENT', 'PDL')
				THEN 2
			ELSE @flag_kk_total
			END AS flag_exclude_kk --15.02.2022
	FROM base b
	LEFT JOIN RiskDWH.dbo.rep_coll_weekly_0_90_hard h ON b.seg = h.seg_high
		AND h.rep_dt = @rdt
		--and b.seg_ip_hard_agent = 'Хард'
		AND b.seg_ip_hard_agent = h.seg_agent_hard
		AND h.flag_exclude_kk = CASE 
			WHEN b.product IN ('INSTALLMENT', 'PDL')
				THEN 2
			ELSE @flag_kk_total
			END;
	--INSERT INTO RiskDWH.dbo.rep_coll_weekly_npl_pmt select * from #npl_pmt_MAR20;

	--27/11/20 Для учета платежей на стадии СБ (служба безопасности) в бакетах до 90+, которые в работе у Hard/Legal
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#stg_sb_0_90';

	DROP TABLE

	IF EXISTS #stg_sb_0_90;
		SELECT a.external_id
			,a.r_date
		INTO #stg_sb_0_90
		FROM #CMR a
		INNER JOIN RiskDWH.dbo.stg_client_stage b ON a.external_id = b.external_id
			AND a.r_date = b.cdate
		LEFT JOIN RiskDWH.dbo.stg_client_stage bb ON a.external_id = bb.external_id
			AND a.r_date = dateadd(dd, 1, bb.cdate)
		INNER JOIN Stg._Collection.Deals_history c ON a.external_id = c.Number
			AND a.r_date = c.r_date
		INNER JOIN stg._Collection.DealStatus d ON c.IdStatus = d.Id
		WHERE 1 = 1
			--стадия СБ
			AND (
				b.CRMClientStage = 'СБ'
				OR /*10/12/2020*/ bb.CRMClientStage = 'СБ'
				AND b.CRMClientStage = 'Closed'
				)
			--был платеж - не обязательно, т.к. отбираем для портфеля
			----and m.pay_total > 0
			--кроме бакетов, которые и так учитываются в 91+ 
			AND a.dpd_bucket_p NOT IN ('(5)_91_360', '(6)_361+')
			--статус договора на момент платежа Legal
			AND d.[Name] = 'Legal'
			--была просрочка более 90 дней (соответственно стадия Legal)
			AND EXISTS (
				SELECT 1
				FROM #CMR e
				WHERE a.external_id = e.external_id
					AND a.r_date > e.r_date
					AND e.overdue_days_p > 90
				)
			--в день платежа не был у агента
			AND NOT EXISTS (
				SELECT 2
				FROM dwh_new.dbo.v_agent_credits f
				WHERE a.external_id = f.external_id
					AND a.r_date BETWEEN f.st_date
						AND f.end_date
				);

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#stg_0_90_hard';

	--Платежи 0-90 Hard
	DROP TABLE

	IF EXISTS #pre_0_90_hard;
		SELECT a.external_id
			,a.r_date
			,a.pay_total
			,isnull(c.dpd_bucket_p, a.dpd_bucket_p) AS dpd_bucket_p
		INTO #pre_0_90_hard
		FROM #CMR a
		LEFT JOIN #total_kk k ON a.external_id = k.external_id
			AND a.r_date BETWEEN k.dt_from
				AND k.dt_to
			AND EOMONTH(a.r_date) = EOMONTH(dateadd(dd, 1, k.dt_from))
		LEFT JOIN #CMR c ON k.external_id = c.external_id
			AND k.dt_from = c.r_date
		WHERE 1 = 1
			AND (
				(
					a.r_date BETWEEN @lm_dt_from
						AND @rdt
					)
				OR (
					a.r_date BETWEEN @march2020_from
						AND @march2020_to
					)
				OR (
					a.r_date BETWEEN @lysd_dt_from
						AND @lysd_dt_to
							--статусы договора доступны только с 25/07/19
					AND a.r_date >= cast('2019-08-01' AS DATE)
					)
				);

	DROP TABLE

	IF EXISTS #stg_0_90_hard;
		SELECT a.external_id
			,a.r_date
			,a.dpd_bucket_p
			,a.pay_total
			,cst.CRMClientStage
		INTO #stg_0_90_hard
		FROM #pre_0_90_hard a
		LEFT JOIN RiskDWH.dbo.stg_client_stage cst ON a.external_id = cst.external_id
			AND a.r_date = cst.cdate
		LEFT JOIN dwh_new.dbo.v_agent_credits vag ON a.external_id = vag.external_id
			AND a.r_date BETWEEN vag.st_date
				AND vag.end_date
		LEFT JOIN #stg_sb_0_90 sb ON a.external_id = sb.external_id
			AND a.r_date = sb.r_date
		WHERE 1 = 1
			AND (
				(
					cst.CRMClientStage = 'Hard'
					AND a.dpd_bucket_p IN ('(2)_1_30', '(3)_31_60', '(4)_61_90')
					)
				OR (
					cst.CRMClientStage = 'Legal'
					AND a.dpd_bucket_p IN ('(1)_0', '(2)_1_30', '(3)_31_60', '(4)_61_90')
					)
				OR isnull(vag.agent_name, 'Carmoney') NOT IN ('Carmoney', 'ACB')
				AND a.dpd_bucket_p IN ('(1)_0', '(2)_1_30', '(3)_31_60', '(4)_61_90')
				OR sb.external_id IS NOT NULL
				);

	--реестр кредитов 91+ (хард/ип/агент) для сборки портфеля
	DROP TABLE

	IF EXISTS #creds_npl
		SELECT aa.external_id
			,aa.r_date
			,aa.seg_ip_hard_agent
		INTO #creds_npl
		FROM (
			SELECT a.r_date
				,a.external_id
				,a.seg_ip_hard_agent
			FROM #stg_pmt_91_plus a
		
			UNION ALL
		
			SELECT b.r_date
				,b.external_id
				,'Хард' AS seg_ip_hard_agent
			FROM #stg_0_90_hard b
			WHERE NOT EXISTS (
					SELECT 1
					FROM #stg_pmt_91_plus c
					WHERE b.external_id = c.external_id
						AND b.r_date = c.r_date
					)
			) aa;

	DROP TABLE #stg_isp_proiz;

	DROP TABLE #isp_proiz;

	DROP TABLE #cli_con_stages;

	DROP TABLE #stg_ip_0_90;

	DROP TABLE #stg_pmt_91_plus;

	DROP TABLE #stg_0_90_hard;

	DROP TABLE #stg_sb_0_90;

	DROP TABLE #pre_0_90_hard;
	DROP TABLE if exists #0_90_isp_prz_MAR20;
	DROP TABLE if exists #npl_pmt_MAR20;

	/******************************************/
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_T2';

	DROP TABLE

	IF EXISTS #_t2;
		SELECT r_year
			,r_month
			,r_day
			,r_date
			,external_id
			,overdue_days
			,
			-- overdue_days_p,
			principal_rest
			,last_principal_rest
			,dpd_bucket
			,seg1
			,seg3
			,(
				CASE 
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days > next_overdue_days
						THEN 'Improve'
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days < next_overdue_days
						THEN 'Worse'
					WHEN dpd_bucket = next_dpd_bucket
						AND next_r_day - r_day + overdue_days > next_overdue_days
						THEN 'Improve'
					ELSE 'Same'
					END
				) AS seg_rr
		INTO #_t2
		FROM (
			SELECT a.r_year
				,a.r_month
				,a.r_day
				,a.r_date
				,a.external_id
				,a.overdue_days
				,a.overdue_days_p
				,a.principal_rest
				,a.last_principal_rest
				,a.dpd_bucket
				,a.seg1
				,a.seg3
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.dpd_bucket) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.dpd_bucket
						END
					) AS next_dpd_bucket
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.overdue_days) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.overdue_days
						END
					) AS next_overdue_days
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.r_day) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.r_day
						END
					) AS next_r_day
			FROM (
				SELECT r_year
					,r_month
					,r_day
					,r_date
					,external_id
					,overdue_days
					,overdue_days_p
					,principal_rest
					,last_principal_rest
					,(
						CASE 
							WHEN overdue_days <= 0
								THEN '(1)_0'
							WHEN overdue_days <= 30
								THEN '(2)_1_30'
							WHEN overdue_days <= 60
								THEN '(3)_31_60'
							WHEN overdue_days <= 90
								THEN '(4)_61_90'
							WHEN overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'som-old' AS seg1
					,'' AS seg2
					,'LYSD' AS seg3
				FROM #CMR a
				--отчетная дата - 1 год, первый день месяца
				WHERE r_day = 1
					-- and overdue_days >= 1
					AND r_year = year(dateadd(yy, - 1, @rdt))
					AND r_month = month(dateadd(yy, - 1, @rdt))
				-- and not (overdue_days_p <> 0 and overdue_days = 0)
			
				UNION
			
				SELECT a.r_year
					,a.r_month
					,a.r_day
					,a.r_date
					,a.external_id
					,a.overdue_days
					,a.overdue_days_p
					,a.principal_rest
					,a.last_principal_rest
					,(
						CASE 
							WHEN a.overdue_days <= 0
								THEN '(1)_0'
							WHEN a.overdue_days <= 30
								THEN '(2)_1_30'
							WHEN a.overdue_days <= 60
								THEN '(3)_31_60'
							WHEN a.overdue_days <= 90
								THEN '(4)_61_90'
							WHEN a.overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'new-old' AS seg1
					,'' AS seg2
					,'LYSD' AS seg3
				FROM #CMR a
				--остальные дни месяца (меньше, чем день отчетной даты), кроме первого числа от (отчетная дата - 1 год) с переходами по бакетам
				WHERE (
						(
							r_day > 1
							AND overdue_days_p IN (1, 31, 61, 91, 361)
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 1
									AND 30
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 31
									AND 60
								)
							AND r_day <> 1
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							lag_overdue_days_p BETWEEN 91
								AND 360
							AND lag_overdue_days <= 90
							AND r_day <> 1
							)
						OR (
							lag_overdue_days_p >= 361
							AND lag_overdue_days <= 360
							AND r_day <> 1
							)
						)
					AND r_year = year(dateadd(yy, - 1, @rdt))
					AND r_month = month(dateadd(yy, - 1, @rdt))
					AND r_day < day(@rdt)
				) a
			LEFT JOIN #CMR b ON a.external_id = b.external_id
				AND a.r_year = b.r_year
				AND a.r_month = b.r_month
				AND b.r_day = day(@rdt)
			) a;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_T3';

	DROP TABLE

	IF EXISTS #_t3
		SELECT r_year
			,r_month
			,r_day
			,r_date
			,external_id
			,overdue_days
			,principal_rest
			,last_principal_rest
			,dpd_bucket
			,seg1
			,seg3
			,(
				CASE 
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days > next_overdue_days
						THEN 'Improve'
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days < next_overdue_days
						THEN 'Worse'
					WHEN dpd_bucket = next_dpd_bucket
						AND next_r_day - r_day + overdue_days > next_overdue_days
						THEN 'Improve'
					ELSE 'Same'
					END
				) AS seg_rr
			,'Not worse' AS flag
		INTO #_t3
		FROM (
			SELECT a.r_year
				,a.r_month
				,a.r_day
				,a.r_date
				,a.external_id
				,a.overdue_days
				,a.overdue_days_p
				,a.principal_rest
				,a.last_principal_rest
				,a.dpd_bucket
				,a.seg1
				,a.seg3
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.dpd_bucket) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.dpd_bucket
						END
					) AS next_dpd_bucket
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.overdue_days) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.overdue_days
						END
					) AS next_overdue_days
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.r_day) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.r_day
						END
					) AS next_r_day
			FROM (
				SELECT r_year
					,r_month
					,r_day
					,r_date
					,external_id
					,overdue_days
					,overdue_days_p
					,principal_rest
					,last_principal_rest
					,(
						CASE 
							WHEN overdue_days <= 0
								THEN '(1)_0'
							WHEN overdue_days <= 30
								THEN '(2)_1_30'
							WHEN overdue_days <= 60
								THEN '(3)_31_60'
							WHEN overdue_days <= 90
								THEN '(4)_61_90'
							WHEN overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'som-old' AS seg1
					,'' AS seg2
					,'CM' AS seg3
				FROM #CMR a
				--первый день месяца отчетной даты
				WHERE r_day = 1
					--  and overdue_days >= 1
					AND r_year = year(@rdt)
					AND r_month = month(@rdt)
				-- and not (overdue_days_p <> 0 and overdue_days = 0)
			
				UNION
			
				SELECT a.r_year
					,a.r_month
					,a.r_day
					,a.r_date
					,a.external_id
					,a.overdue_days
					,a.overdue_days_p
					,a.principal_rest
					,a.last_principal_rest
					,(
						CASE 
							WHEN a.overdue_days <= 0
								THEN '(1)_0'
							WHEN a.overdue_days <= 30
								THEN '(2)_1_30'
							WHEN a.overdue_days <= 60
								THEN '(3)_31_60'
							WHEN a.overdue_days <= 90
								THEN '(4)_61_90'
							WHEN a.overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'new-old' AS seg1
					,'' AS seg2
					,'CM' AS seg3
				FROM #CMR a
				--остальные дни месяца, кроме первого числа в месяце отчетной даты
				WHERE (
						(
							r_day > 1
							AND overdue_days_p IN (1, 31, 61, 91, 361)
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 1
									AND 30
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 31
									AND 60
								)
							AND r_day <> 1
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							lag_overdue_days_p BETWEEN 91
								AND 360
							AND lag_overdue_days <= 90
							AND r_day <> 1
							)
						OR (
							lag_overdue_days_p >= 361
							AND lag_overdue_days <= 360
							AND r_day <> 1
							)
						)
					AND r_year = year(@rdt)
					AND r_month = month(@rdt)
				) a
			LEFT JOIN #CMR b ON a.external_id = b.external_id
				AND a.r_year = b.r_year
				AND a.r_month = b.r_month
				AND b.r_day = day(@rdt)
			) a;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_T4';

	DROP TABLE

	IF EXISTS #_t4
		SELECT r_year
			,r_month
			,r_day
			,r_date
			,external_id
			,overdue_days
			,principal_rest
			,last_principal_rest
			,dpd_bucket
			,seg1
			,seg3
			,(
				CASE 
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days > next_overdue_days
						THEN 'Improve'
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days < next_overdue_days
						THEN 'Worse'
					WHEN dpd_bucket = next_dpd_bucket
						AND next_r_day - r_day + overdue_days > next_overdue_days
						THEN 'Improve'
					ELSE 'Same'
					END
				) AS seg_rr
		INTO #_t4
		FROM (
			SELECT a.r_year
				,a.r_month
				,a.r_day
				,a.r_date
				,a.external_id
				,a.overdue_days
				,a.principal_rest
				,a.last_principal_rest
				,a.dpd_bucket
				,a.seg1
				,a.seg3
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.dpd_bucket) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.dpd_bucket
						END
					) AS next_dpd_bucket
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.overdue_days) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.overdue_days
						END
					) AS next_overdue_days
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.r_day) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.r_day
						END
					) AS next_r_day
			FROM (
				SELECT r_year
					,r_month
					,r_day
					,r_date
					,external_id
					,overdue_days
					,principal_rest
					,last_principal_rest
					,(
						CASE 
							WHEN overdue_days <= 0
								THEN '(1)_0'
							WHEN overdue_days <= 30
								THEN '(2)_1_30'
							WHEN overdue_days <= 60
								THEN '(3)_31_60'
							WHEN overdue_days <= 90
								THEN '(4)_61_90'
							WHEN overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'som-old' AS seg1
					,'' AS seg2
					,'LMSD' AS seg3
				FROM #CMR a
				WHERE r_day = 1
					-- and overdue_days >= 1
					AND r_year = year(dateadd(mm, - 1, @rdt))
					AND r_month = month(dateadd(mm, - 1, @rdt))
				--and r_day <= day( @rdt )
				-- and not (overdue_days_p <> 0 and overdue_days = 0)
			
				UNION
			
				SELECT a.r_year
					,a.r_month
					,a.r_day
					,a.r_date
					,a.external_id
					,a.overdue_days
					,a.principal_rest
					,a.last_principal_rest
					,(
						CASE 
							WHEN a.overdue_days <= 0
								THEN '(1)_0'
							WHEN a.overdue_days <= 30
								THEN '(2)_1_30'
							WHEN a.overdue_days <= 60
								THEN '(3)_31_60'
							WHEN a.overdue_days <= 90
								THEN '(4)_61_90'
							WHEN a.overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'new-old' AS seg1
					,'' AS seg2
					,'LMSD' AS seg3
				FROM #CMR a
				WHERE (
						(
							r_day > 1
							AND overdue_days_p IN (1, 31, 61, 91, 361)
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 1
									AND 30
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 31
									AND 60
								)
							AND r_day <> 1
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							lag_overdue_days_p BETWEEN 91
								AND 360
							AND lag_overdue_days <= 90
							AND r_day <> 1
							)
						OR (
							lag_overdue_days_p >= 361
							AND lag_overdue_days <= 360
							AND r_day <> 1
							)
						)
					AND r_year = year(dateadd(mm, - 1, @rdt))
					AND r_month = month(dateadd(mm, - 1, @rdt))
					AND r_day < day(@rdt)
				) a
			LEFT JOIN #CMR b ON a.external_id = b.external_id
				AND a.r_year = b.r_year
				AND a.r_month = b.r_month
				AND b.r_day = day(@rdt)
			) a;

	/*
							  select * from #_cm_new_full order by r_date
							  */
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_T5';

	DROP TABLE

	IF EXISTS #_t5
		SELECT r_year
			,r_month
			,r_day
			,r_date
			,external_id
			,overdue_days
			,principal_rest
			,last_principal_rest
			,dpd_bucket
			,seg1
			,seg3
			,(
				CASE 
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days > next_overdue_days
						THEN 'Improve'
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days < next_overdue_days
						THEN 'Worse'
					WHEN dpd_bucket = next_dpd_bucket
						AND next_r_day - r_day + overdue_days > next_overdue_days
						THEN 'Improve'
					ELSE 'Same'
					END
				) AS seg_rr
		INTO #_t5
		FROM (
			SELECT a.r_year
				,a.r_month
				,a.r_day
				,a.r_date
				,a.external_id
				,a.overdue_days
				,a.principal_rest
				,a.last_principal_rest
				,a.dpd_bucket
				,a.seg1
				,a.seg3
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.dpd_bucket) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.dpd_bucket
						END
					) AS next_dpd_bucket
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.overdue_days) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.overdue_days
						END
					) AS next_overdue_days
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.r_day) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.r_day
						END
					) AS next_r_day
			FROM (
				SELECT r_year
					,r_month
					,r_day
					,r_date
					,external_id
					,overdue_days
					,principal_rest
					,last_principal_rest
					,(
						CASE 
							WHEN overdue_days <= 0
								THEN '(1)_0'
							WHEN overdue_days <= 30
								THEN '(2)_1_30'
							WHEN overdue_days <= 60
								THEN '(3)_31_60'
							WHEN overdue_days <= 90
								THEN '(4)_61_90'
							WHEN overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'som-old' AS seg1
					,'' AS seg2
					,'LM' AS seg3
				FROM #CMR a
				WHERE r_day = 1
					-- and overdue_days >= 1
					AND r_year = year(dateadd(mm, - 1, @rdt))
					AND r_month = month(dateadd(mm, - 1, @rdt))
				-- and not (overdue_days_p <> 0 and overdue_days = 0)
			
				UNION
			
				SELECT a.r_year
					,a.r_month
					,a.r_day
					,a.r_date
					,a.external_id
					,a.overdue_days
					,a.principal_rest
					,a.last_principal_rest
					,(
						CASE 
							WHEN a.overdue_days <= 0
								THEN '(1)_0'
							WHEN a.overdue_days <= 30
								THEN '(2)_1_30'
							WHEN a.overdue_days <= 60
								THEN '(3)_31_60'
							WHEN a.overdue_days <= 90
								THEN '(4)_61_90'
							WHEN a.overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'new-old' AS seg1
					,'' AS seg2
					,'LM' AS seg3
				FROM #CMR a
				WHERE (
						(
							r_day > 1
							AND overdue_days_p IN (1, 31, 61, 91, 361)
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 1
									AND 30
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 31
									AND 60
								)
							AND r_day <> 1
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							lag_overdue_days_p BETWEEN 91
								AND 360
							AND lag_overdue_days <= 90
							AND r_day <> 1
							)
						OR (
							lag_overdue_days_p >= 361
							AND lag_overdue_days <= 360
							AND r_day <> 1
							)
						)
					AND r_year = year(dateadd(mm, - 1, @rdt))
					AND r_month = month(dateadd(mm, - 1, @rdt))
				) a
			LEFT JOIN #CMR b ON a.external_id = b.external_id
				AND a.r_year = b.r_year
				AND a.r_month = b.r_month
				AND b.r_day = day(eomonth(a.r_date))
			) a;

	/****************************************************************************/
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_T6';

	DROP TABLE

	IF EXISTS #_t6
		SELECT r_year
			,r_month
			,r_day
			,r_date
			,external_id
			,overdue_days
			,principal_rest
			,last_principal_rest
			,dpd_bucket
			,seg1
			,seg3
			,(
				CASE 
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days > next_overdue_days
						THEN 'Improve'
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days < next_overdue_days
						THEN 'Worse'
					WHEN dpd_bucket = next_dpd_bucket
						AND next_r_day - r_day + overdue_days > next_overdue_days
						THEN 'Improve'
					ELSE 'Same'
					END
				) AS seg_rr
		INTO #_t6
		FROM (
			SELECT a.r_year
				,a.r_month
				,a.r_day
				,a.r_date
				,a.external_id
				,a.overdue_days
				,a.principal_rest
				,a.last_principal_rest
				,a.dpd_bucket
				,a.seg1
				,a.seg3
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.dpd_bucket) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.dpd_bucket
						END
					) AS next_dpd_bucket
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.overdue_days) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.overdue_days
						END
					) AS next_overdue_days
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.r_day) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.r_day
						END
					) AS next_r_day
			FROM (
				SELECT r_year
					,r_month
					,r_day
					,r_date
					,external_id
					,overdue_days
					,principal_rest
					,last_principal_rest
					,(
						CASE 
							WHEN overdue_days <= 0
								THEN '(1)_0'
							WHEN overdue_days <= 30
								THEN '(2)_1_30'
							WHEN overdue_days <= 60
								THEN '(3)_31_60'
							WHEN overdue_days <= 90
								THEN '(4)_61_90'
							WHEN overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'som-old' AS seg1
					,'' AS seg2
					,'LW' AS seg3
				FROM #CMR a
				WHERE r_date = @lw_dt_from --dateadd(dd,-7,RiskDWH.dbo.date_trunc('wk',@rdt)) 
					-- and overdue_days >= 1
					--and r_date between dateadd(dd,-7,RiskDWH.dbo.date_trunc('wk',@rdt)) 
					--			   and dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk',@rdt))
					-- and not (overdue_days_p <> 0 and overdue_days = 0)
			
				UNION
			
				SELECT a.r_year
					,a.r_month
					,a.r_day
					,a.r_date
					,a.external_id
					,a.overdue_days
					,a.principal_rest
					,a.last_principal_rest
					,(
						CASE 
							WHEN a.overdue_days <= 0
								THEN '(1)_0'
							WHEN a.overdue_days <= 30
								THEN '(2)_1_30'
							WHEN a.overdue_days <= 60
								THEN '(3)_31_60'
							WHEN a.overdue_days <= 90
								THEN '(4)_61_90'
							WHEN a.overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'new-old' AS seg1
					,'' AS seg2
					,'LW' AS seg3
				FROM #CMR a
				WHERE (
						(
							r_date > @lw_dt_from
							AND overdue_days_p IN (1, 31, 61, 91, 361)
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 1
									AND 30
								)
							AND (lag_overdue_days = 0)
							AND r_date <> @lw_dt_from
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (lag_overdue_days = 0)
							AND r_date <> @lw_dt_from
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_date <> @lw_dt_from
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (lag_overdue_days = 0)
							AND r_date <> @lw_dt_from
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_date <> @lw_dt_from
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 31
									AND 60
								)
							AND r_date <> @lw_dt_from
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							lag_overdue_days_p BETWEEN 91
								AND 360
							AND lag_overdue_days <= 90
							AND r_date <> @lw_dt_from
							)
						OR (
							lag_overdue_days_p >= 361
							AND lag_overdue_days <= 360
							AND r_date <> @lw_dt_from
							)
						)
					AND r_date BETWEEN @lw_dt_from
						AND @lw_dt_to
				) a
			LEFT JOIN #CMR b ON a.external_id = b.external_id
				AND b.r_date = @lw_dt_to
			) a;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_T7';

	DROP TABLE

	IF EXISTS #_t7
		SELECT r_year
			,r_month
			,r_day
			,r_date
			,external_id
			,overdue_days
			,principal_rest
			,last_principal_rest
			,dpd_bucket
			,seg1
			,seg3
			,(
				CASE 
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days > next_overdue_days
						THEN 'Improve'
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days < next_overdue_days
						THEN 'Worse'
					WHEN dpd_bucket = next_dpd_bucket
						AND next_r_day - r_day + overdue_days > next_overdue_days
						THEN 'Improve'
					ELSE 'Same'
					END
				) AS seg_rr
		INTO #_t7
		FROM (
			SELECT a.r_year
				,a.r_month
				,a.r_day
				,a.r_date
				,a.external_id
				,a.overdue_days
				,a.principal_rest
				,a.last_principal_rest
				,a.dpd_bucket
				,a.seg1
				,a.seg3
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.dpd_bucket) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.dpd_bucket
						END
					) AS next_dpd_bucket
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.overdue_days) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.overdue_days
						END
					) AS next_overdue_days
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.r_day) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.r_day
						END
					) AS next_r_day
			FROM (
				SELECT r_year
					,r_month
					,r_day
					,r_date
					,external_id
					,overdue_days
					,principal_rest
					,last_principal_rest
					,(
						CASE 
							WHEN overdue_days <= 0
								THEN '(1)_0'
							WHEN overdue_days <= 30
								THEN '(2)_1_30'
							WHEN overdue_days <= 60
								THEN '(3)_31_60'
							WHEN overdue_days <= 90
								THEN '(4)_61_90'
							WHEN overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'som-old' AS seg1
					,'' AS seg2
					,'CW' AS seg3
				FROM #CMR a
				WHERE r_date = @cw_dt_from
				-- and overdue_days >= 1
				--and r_date between RiskDWH.dbo.date_trunc('wk',@rdt) and @rdt
				-- and not (overdue_days_p <> 0 and overdue_days = 0)
			
				UNION
			
				SELECT a.r_year
					,a.r_month
					,a.r_day
					,a.r_date
					,a.external_id
					,a.overdue_days
					,a.principal_rest
					,a.last_principal_rest
					,(
						CASE 
							WHEN a.overdue_days <= 0
								THEN '(1)_0'
							WHEN a.overdue_days <= 30
								THEN '(2)_1_30'
							WHEN a.overdue_days <= 60
								THEN '(3)_31_60'
							WHEN a.overdue_days <= 90
								THEN '(4)_61_90'
							WHEN a.overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'new-old' AS seg1
					,'' AS seg2
					,'CW' AS seg3
				FROM #CMR a
				WHERE (
						(
							r_date > @cw_dt_from
							AND overdue_days_p IN (1, 31, 61, 91, 361)
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 1
									AND 30
								)
							AND (lag_overdue_days = 0)
							AND r_date <> @cw_dt_from
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (lag_overdue_days = 0)
							AND r_date <> @cw_dt_from
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_date <> @cw_dt_from
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (lag_overdue_days = 0)
							AND r_date <> @cw_dt_from
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_date <> @cw_dt_from
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 31
									AND 60
								)
							AND r_date <> @cw_dt_from
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							lag_overdue_days_p BETWEEN 91
								AND 360
							AND lag_overdue_days <= 90
							AND r_date <> @cw_dt_from
							)
						OR (
							lag_overdue_days_p >= 361
							AND lag_overdue_days <= 360
							AND r_date <> @cw_dt_from
							)
						)
					AND r_date BETWEEN @cw_dt_from
						AND @rdt
				) a
			LEFT JOIN #CMR b ON a.external_id = b.external_id
				AND b.r_date = @rdt
			) a;

	/**************************************************/
/*	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_T8';

	DROP TABLE

	IF EXISTS #_t8
		SELECT r_year
			,r_month
			,r_day
			,r_date
			,external_id
			,overdue_days
			,principal_rest
			,last_principal_rest
			,dpd_bucket
			,seg1
			,seg3
			,(
				CASE 
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days > next_overdue_days
						THEN 'Improve'
					WHEN dpd_bucket <> next_dpd_bucket
						AND overdue_days < next_overdue_days
						THEN 'Worse'
					WHEN dpd_bucket = next_dpd_bucket
						AND next_r_day - r_day + overdue_days > next_overdue_days
						THEN 'Improve'
					ELSE 'Same'
					END
				) AS seg_rr
		INTO #_t8
		FROM (
			SELECT a.r_year
				,a.r_month
				,a.r_day
				,a.r_date
				,a.external_id
				,a.overdue_days
				,a.principal_rest
				,a.last_principal_rest
				,a.dpd_bucket
				,a.seg1
				,a.seg3
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.dpd_bucket) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.dpd_bucket
						END
					) AS next_dpd_bucket
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.overdue_days) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.overdue_days
						END
					) AS next_overdue_days
				,(
					CASE 
						WHEN count(a.external_id) OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month
								) <> 1
							AND row_number() OVER (
								PARTITION BY a.external_id
								,a.r_year
								,a.r_month ORDER BY a.r_date DESC
								) <> 1
							THEN lead(a.r_day) OVER (
									PARTITION BY a.external_id
									,a.r_year
									,a.r_month ORDER BY a.r_date
									)
						ELSE b.r_day
						END
					) AS next_r_day
			FROM (
				SELECT r_year
					,r_month
					,r_day
					,r_date
					,external_id
					,overdue_days
					,principal_rest
					,last_principal_rest
					,(
						CASE 
							WHEN overdue_days <= 0
								THEN '(1)_0'
							WHEN overdue_days <= 30
								THEN '(2)_1_30'
							WHEN overdue_days <= 60
								THEN '(3)_31_60'
							WHEN overdue_days <= 90
								THEN '(4)_61_90'
							WHEN overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'som-old' AS seg1
					,'' AS seg2
					,'MAR20' AS seg3
				FROM #CMR a
				WHERE r_day = 1
					-- and overdue_days >= 1
					AND r_year = 2020
					AND r_month = 3
				-- and not (overdue_days_p <> 0 and overdue_days = 0)
			
				UNION
			
				SELECT a.r_year
					,a.r_month
					,a.r_day
					,a.r_date
					,a.external_id
					,a.overdue_days
					,a.principal_rest
					,a.last_principal_rest
					,(
						CASE 
							WHEN a.overdue_days <= 0
								THEN '(1)_0'
							WHEN a.overdue_days <= 30
								THEN '(2)_1_30'
							WHEN a.overdue_days <= 60
								THEN '(3)_31_60'
							WHEN a.overdue_days <= 90
								THEN '(4)_61_90'
							WHEN a.overdue_days <= 360
								THEN '(5)_91_360'
							ELSE '(6)_361+'
							END
						) AS dpd_bucket
					,'new-old' AS seg1
					,'' AS seg2
					,'MAR20' AS seg3
				FROM #CMR a
				WHERE (
						(
							r_day > 1
							AND overdue_days_p IN (1, 31, 61, 91, 361)
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 1
									AND 30
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 31
									AND 60
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (lag_overdue_days = 0)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 1
									AND 30
								)
							AND r_day <> 1
							)
						OR (
							(
								lag_overdue_days_p BETWEEN 61
									AND 90
								)
							AND (
								lag_overdue_days BETWEEN 31
									AND 60
								)
							AND r_day <> 1
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							lag_overdue_days_p BETWEEN 91
								AND 360
							AND lag_overdue_days <= 90
							AND r_day <> 1
							)
						OR (
							lag_overdue_days_p >= 361
							AND lag_overdue_days <= 360
							AND r_day <> 1
							)
						)
					AND r_year = 2020
					AND r_month = 3
				) a
			LEFT JOIN #CMR b ON a.external_id = b.external_id
				AND a.r_year = b.r_year
				AND a.r_month = b.r_month
				AND b.r_day = day(eomonth(a.r_date))
			) a;*/

	/****************************************************************************/
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = 'rearrange tables';

	DROP TABLE

	IF EXISTS #_t_lysd
		SELECT *
		INTO #_t_lysd
		FROM #_t2

	DROP TABLE

	IF EXISTS #_t_cm
		SELECT *
		INTO #_t_cm
		FROM #_t3

	--  select * from #_t3
	DROP TABLE

	IF EXISTS #_t_lmsd
		SELECT *
		INTO #_t_lmsd
		FROM #_t4

	DROP TABLE

	IF EXISTS #_t_lm
		SELECT *
		INTO #_t_lm
		FROM #_t5

	DROP TABLE

	IF EXISTS #_t_lw
		SELECT *
		INTO #_t_lw
		FROM #_t6

	DROP TABLE

	IF EXISTS #_t_cw
		SELECT *
		INTO #_t_cw
		FROM #_t7

	/*DROP TABLE

	IF EXISTS #_t_mar20
		SELECT *
		INTO #_t_mar20
		FROM #_t8;*/

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lysd_pre';

	DROP TABLE

	IF EXISTS #_lysd_pre;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_lysd_pre
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id
					,r_month
					,r_year ORDER BY r_day
					) l_r_date
			FROM #_t_lysd
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND a.external_id = t.external_id
		WHERE (
				(
					t.overdue_days_p > a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				OR (
					t.overdue_days < a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							t.overdue_days = 0
							AND t.overdue_days_p = 0
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				)
			AND t.r_date < (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE dateadd(yy, - 1, @rdt)
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lysd';

	DROP TABLE

	IF EXISTS #_lysd;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month
							) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id
												,a.r_year
												,a.r_month ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN a.seg_rr = 'Worse'
									AND a.dpd_bucket = '(2)_1_30'
									THEN dateadd(dd, 30 - a.overdue_days, a.r_date)
								WHEN a.seg_rr = 'Worse'
									AND a.dpd_bucket = '(3)_31_60'
									THEN dateadd(dd, 60 - a.overdue_days, a.r_date)
								WHEN a.seg_rr = 'Worse'
									AND a.dpd_bucket = '(4)_61_90'
									THEN dateadd(dd, 90 - a.overdue_days, a.r_date)
								WHEN a.seg_rr = 'Worse'
									AND a.dpd_bucket = '(5)_91_360'
									THEN dateadd(dd, 360 - a.overdue_days, a.r_date)
								ELSE (
										CASE 
											WHEN p.r_date IS NOT NULL
												THEN alt_r_end_date
											ELSE (
													CASE 
														WHEN day(@rdt) <= day(eomonth(a.r_date))
															THEN dateadd(yy, - 1, @rdt)
														ELSE eomonth(a.r_date)
														END
													)
											END
										)
								END
							)
					END
				) AS r_end_date
		INTO #_lysd
		FROM #_t_lysd a
		LEFT JOIN #_lysd_pre p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lysd_pre_w';

	DROP TABLE

	IF EXISTS #_lysd_pre_w;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_lysd_pre_w
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id
					,r_month
					,r_year ORDER BY r_day
					) l_r_date
			FROM #_t_lysd
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND a.external_id = t.external_id
		WHERE -- t.overdue_days_p in (1,31,61,91,361)
			(
				(
					t.overdue_days_p = 1
					AND a.overdue_days = 0
					OR t.overdue_days_p = 31
					AND a.overdue_days BETWEEN 1
						AND 30
					OR t.overdue_days_p = 61
					AND a.overdue_days BETWEEN 31
						AND 60
					OR t.overdue_days_p = 91
					AND a.overdue_days BETWEEN 61
						AND 90
					OR t.overdue_days_p = 361
					AND a.overdue_days BETWEEN 91
						AND 360
					)
				OR (
					t.overdue_days = 1
					AND t.last_dpd = 0
					OR t.overdue_days = 31
					AND t.last_dpd BETWEEN 1
						AND 30
					OR t.overdue_days = 61
					AND t.last_dpd BETWEEN 31
						AND 60
					OR t.overdue_days = 91
					AND t.last_dpd BETWEEN 61
						AND 90
					OR t.overdue_days = 361
					AND t.last_dpd BETWEEN 91
						AND 360
					)
				)
			AND t.r_date <= (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE dateadd(yy, - 1, @rdt)
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lysd_w';

	DROP TABLE

	IF EXISTS #_lysd_w;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month
							) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id
												,a.r_year
												,a.r_month ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN p.r_date IS NOT NULL
									THEN alt_r_end_date
								ELSE (
										CASE 
											WHEN day(@rdt) <= day(eomonth(a.r_date))
												THEN dateadd(yy, - 1, @rdt)
											ELSE eomonth(a.r_date)
											END
										)
								END
							)
					END
				) AS r_end_date
		INTO #_lysd_w
		FROM #_t_lysd a
		LEFT JOIN #_lysd_pre_w p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lmsd_pre';

	DROP TABLE

	IF EXISTS #_lmsd_pre;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_lmsd_pre
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id
					,r_month
					,r_year ORDER BY r_day
					) l_r_date
			FROM #_t_lmsd
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND a.external_id = t.external_id
		WHERE (
				(
					t.overdue_days_p > a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				OR (
					t.overdue_days < a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							t.overdue_days = 0
							AND t.overdue_days_p = 0
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				)
			AND t.r_date < (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE dateadd(mm, - 1, @rdt)
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lmsd';

	DROP TABLE

	IF EXISTS #_lmsd;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month
							) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
											-- when lead(a.r_date) over (partition by a.external_id, a.r_year, a.r_month order by a.r_date) = dateadd(dd,1,a.r_date) and overdue_days = 0 then dateadd(dd,1,a.r_date)
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id
												,a.r_year
												,a.r_month ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN a.seg_rr = 'Worse'
									AND a.dpd_bucket = '(2)_1_30'
									THEN dateadd(dd, 30 - a.overdue_days, a.r_date)
								WHEN a.seg_rr = 'Worse'
									AND a.dpd_bucket = '(3)_31_60'
									THEN dateadd(dd, 60 - a.overdue_days, a.r_date)
								WHEN a.seg_rr = 'Worse'
									AND a.dpd_bucket = '(4)_61_90'
									THEN dateadd(dd, 90 - a.overdue_days, a.r_date)
								WHEN a.seg_rr = 'Worse'
									AND a.dpd_bucket = '(5)_91_360'
									THEN dateadd(dd, 360 - a.overdue_days, a.r_date)
								ELSE (
										CASE 
											WHEN p.r_date IS NOT NULL
												THEN alt_r_end_date
											ELSE (
													CASE 
														WHEN day(@rdt) <= day(eomonth(a.r_date))
															THEN dateadd(mm, - 1, @rdt)
														ELSE eomonth(a.r_date)
														END
													)
											END
										)
								END
							)
					END
				) AS r_end_date
		INTO #_lmsd
		FROM #_t_lmsd a
		LEFT JOIN #_lmsd_pre p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lmsd_pre_w';

	DROP TABLE

	IF EXISTS #_lmsd_pre_w;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_lmsd_pre_w
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id
					,r_month
					,r_year ORDER BY r_day
					) l_r_date
			FROM #_t_lmsd
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND a.external_id = t.external_id
		WHERE --t.overdue_days_p in (1,31,61,91,361)
			(
				(
					t.overdue_days_p = 1
					AND a.overdue_days = 0
					OR t.overdue_days_p = 31
					AND a.overdue_days BETWEEN 1
						AND 30
					OR t.overdue_days_p = 61
					AND a.overdue_days BETWEEN 31
						AND 60
					OR t.overdue_days_p = 91
					AND a.overdue_days BETWEEN 61
						AND 90
					OR t.overdue_days_p = 361
					AND a.overdue_days BETWEEN 91
						AND 360
					)
				OR (
					t.overdue_days = 1
					AND t.last_dpd = 0
					OR t.overdue_days = 31
					AND t.last_dpd BETWEEN 1
						AND 30
					OR t.overdue_days = 61
					AND t.last_dpd BETWEEN 31
						AND 60
					OR t.overdue_days = 91
					AND t.last_dpd BETWEEN 61
						AND 90
					OR t.overdue_days = 361
					AND t.last_dpd BETWEEN 91
						AND 360
					)
				)
			AND t.r_date <= (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE dateadd(mm, - 1, @rdt)
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lmsd_w';

	DROP TABLE

	IF EXISTS #_lmsd_w;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month
							) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id
												,a.r_year
												,a.r_month ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN p.r_date IS NOT NULL
									THEN alt_r_end_date
								ELSE (
										CASE 
											WHEN day(@rdt) <= day(eomonth(a.r_date))
												THEN dateadd(mm, - 1, @rdt)
											ELSE eomonth(a.r_date)
											END
										)
								END
							)
					END
				) AS r_end_date
		INTO #_lmsd_w
		FROM #_t_lmsd a
		LEFT JOIN #_lmsd_pre_w p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;

	/*  select * from #_lmsd 
			  where overdue_days = 0 
			  order by external_id, r_date  */
	-- select * from #_t_cm
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cm_pre';

	DROP TABLE

	IF EXISTS #_cm_pre;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_cm_pre
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id
					,r_month
					,r_year ORDER BY r_day
					) l_r_date
			FROM #_t_cm
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND a.external_id = t.external_id
			AND t.r_date <= @rdt
		-- where t.overdue_days < a.overdue_days and not ((t.overdue_days_p-t.overdue_days)%29 > 0 and (t.overdue_days_p-t.overdue_days)%30 > 0 and (t.overdue_days_p-t.overdue_days)%31 > 0  and t.overdue_days<>0 and 
		WHERE (
				(
					t.overdue_days_p > a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				OR (
					t.overdue_days < a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							t.overdue_days = 0
							AND t.overdue_days_p = 0
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				)
			AND t.r_date < (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE @rdt
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cm';

	DROP TABLE

	IF EXISTS #_cm;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month
							) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id
												,a.r_year
												,a.r_month ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN p.r_date IS NOT NULL
									THEN alt_r_end_date
								ELSE @rdt
								END
							)
					END
				) AS r_end_date
		INTO #_cm
		FROM #_t_cm a
		LEFT JOIN #_cm_pre p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;

	--  select * from #_t_cm
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cm_pre_w';

	DROP TABLE

	IF EXISTS #_cm_pre_w;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_cm_pre_w
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id
					,r_month
					,r_year ORDER BY r_day
					) l_r_date
			FROM #_t_cm
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND a.external_id = t.external_id
			AND t.r_date <= @rdt
		WHERE --t.overdue_days_p in (1,31,61,91,361)
			(
				(
					t.overdue_days_p = 1
					AND a.overdue_days = 0
					OR t.overdue_days_p = 31
					AND a.overdue_days BETWEEN 1
						AND 30
					OR t.overdue_days_p = 61
					AND a.overdue_days BETWEEN 31
						AND 60
					OR t.overdue_days_p = 91
					AND a.overdue_days BETWEEN 61
						AND 90
					OR t.overdue_days_p = 361
					AND a.overdue_days BETWEEN 91
						AND 360
					)
				OR (
					t.overdue_days = 1
					AND t.last_dpd = 0
					OR t.overdue_days = 31
					AND t.last_dpd BETWEEN 1
						AND 30
					OR t.overdue_days = 61
					AND t.last_dpd BETWEEN 31
						AND 60
					OR t.overdue_days = 91
					AND t.last_dpd BETWEEN 61
						AND 90
					OR t.overdue_days = 361
					AND t.last_dpd BETWEEN 91
						AND 360
					)
				)
			AND t.r_date <= (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE @rdt
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cm_w';

	DROP TABLE

	IF EXISTS #_cm_w;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month
							) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id
												,a.r_year
												,a.r_month ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN p.r_date IS NOT NULL
									THEN alt_r_end_date
								ELSE @rdt
								END
							)
					END
				) AS r_end_date
		INTO #_cm_w
		FROM #_t_cm a
		LEFT JOIN #_cm_pre_w p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lm_pre';

	DROP TABLE

	IF EXISTS #_lm_pre;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_lm_pre
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id
					,r_month
					,r_year ORDER BY r_day
					) l_r_date
			FROM #_t_lm
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND a.external_id = t.external_id
		WHERE (
				(
					t.overdue_days_p > a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				OR (
					t.overdue_days < a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							t.overdue_days = 0
							AND t.overdue_days_p = 0
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				)
			AND t.r_date < (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE eomonth(t.r_date)
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lm';

	DROP TABLE

	IF EXISTS #_lm;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month
							) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id
												,a.r_year
												,a.r_month ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN p.r_date IS NOT NULL
									THEN alt_r_end_date
								ELSE eomonth(a.r_date)
								END
							)
					END
				) AS r_end_date
		INTO #_lm
		FROM #_t_lm a
		LEFT JOIN #_lm_pre p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lm_pre_w';

	DROP TABLE

	IF EXISTS #_lm_pre_w;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_lm_pre_w
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id
					,r_month
					,r_year ORDER BY r_day
					) l_r_date
			FROM #_t_lm
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND a.external_id = t.external_id
		WHERE --t.overdue_days_p in (1,31,61,91,361)
			(
				(
					t.overdue_days_p = 1
					AND a.overdue_days = 0
					OR t.overdue_days_p = 31
					AND a.overdue_days BETWEEN 1
						AND 30
					OR t.overdue_days_p = 61
					AND a.overdue_days BETWEEN 31
						AND 60
					OR t.overdue_days_p = 91
					AND a.overdue_days BETWEEN 61
						AND 90
					OR t.overdue_days_p = 361
					AND a.overdue_days BETWEEN 91
						AND 360
					)
				OR (
					t.overdue_days = 1
					AND t.last_dpd = 0
					OR t.overdue_days = 31
					AND t.last_dpd BETWEEN 1
						AND 30
					OR t.overdue_days = 61
					AND t.last_dpd BETWEEN 31
						AND 60
					OR t.overdue_days = 91
					AND t.last_dpd BETWEEN 61
						AND 90
					OR t.overdue_days = 361
					AND t.last_dpd BETWEEN 91
						AND 360
					)
				)
			AND t.r_date <= (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE eomonth(t.r_date)
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lm_w';

	DROP TABLE

	IF EXISTS #_lm_w;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month
							) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id
												,a.r_year
												,a.r_month ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN p.r_date IS NOT NULL
									THEN alt_r_end_date
								ELSE (eomonth(a.r_date))
								END
							)
					END
				) AS r_end_date
		INTO #_lm_w
		FROM #_t_lm a
		LEFT JOIN #_lm_pre_w p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;

	/******************************************************************/
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lw_pre';

	DROP TABLE

	IF EXISTS #_lw_pre;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_lw_pre
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id /*, r_month, r_year*/ ORDER BY /*r_day*/ r_date
					) l_r_date
			FROM #_t_lw
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND t.r_date <= @lw_dt_to
			AND a.external_id = t.external_id
		-- where t.overdue_days < a.overdue_days and not ((t.overdue_days_p-t.overdue_days)%29 > 0 and (t.overdue_days_p-t.overdue_days)%30 > 0 and (t.overdue_days_p-t.overdue_days)%31 > 0  and t.overdue_days<>0 and 
		WHERE (
				(
					t.overdue_days_p > a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				OR (
					t.overdue_days < a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							t.overdue_days = 0
							AND t.overdue_days_p = 0
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				)
			AND t.r_date < (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE @lw_dt_to
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lw';

	DROP TABLE

	IF EXISTS #_lw;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (PARTITION BY a.external_id /*, a.r_year, a.r_month*/) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id /*, a.r_year, a.r_month*/ ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id /*, a.r_year, a.r_month*/ ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN p.r_date IS NOT NULL
									THEN alt_r_end_date
								ELSE @lw_dt_to
								END
							)
					END
				) AS r_end_date
		INTO #_lw
		FROM #_t_lw a
		LEFT JOIN #_lw_pre p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;

	--  select * from #_t_cm
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lw_pre_w';

	DROP TABLE

	IF EXISTS #_lw_pre_w;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_lw_pre_w
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id /*, r_month, r_year*/ ORDER BY /*r_day*/ r_date
					) l_r_date
			FROM #_t_lw
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND a.external_id = t.external_id
			AND t.r_date <= @lw_dt_to
		WHERE -- t.overdue_days_p in (1,31,61,91,361)
			(
				(
					t.overdue_days_p = 1
					AND a.overdue_days = 0
					OR t.overdue_days_p = 31
					AND a.overdue_days BETWEEN 1
						AND 30
					OR t.overdue_days_p = 61
					AND a.overdue_days BETWEEN 31
						AND 60
					OR t.overdue_days_p = 91
					AND a.overdue_days BETWEEN 61
						AND 90
					OR t.overdue_days_p = 361
					AND a.overdue_days BETWEEN 91
						AND 360
					)
				OR (
					t.overdue_days = 1
					AND t.last_dpd = 0
					OR t.overdue_days = 31
					AND t.last_dpd BETWEEN 1
						AND 30
					OR t.overdue_days = 61
					AND t.last_dpd BETWEEN 31
						AND 60
					OR t.overdue_days = 91
					AND t.last_dpd BETWEEN 61
						AND 90
					OR t.overdue_days = 361
					AND t.last_dpd BETWEEN 91
						AND 360
					)
				)
			AND t.r_date <= (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE @lw_dt_to
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lw_w';

	DROP TABLE

	IF EXISTS #_lw_w;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (PARTITION BY a.external_id /*, a.r_year, a.r_month*/) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id /*, a.r_year, a.r_month*/ ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id /*, a.r_year, a.r_month*/ ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN p.r_date IS NOT NULL
									THEN alt_r_end_date
								ELSE @lw_dt_to
								END
							)
					END
				) AS r_end_date
		INTO #_lw_w
		FROM #_t_lw a
		LEFT JOIN #_lw_pre_w p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;

	/******************************************************************/
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cw_pre';

	DROP TABLE

	IF EXISTS #_cw_pre;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_cw_pre
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id /*, r_month, r_year*/ ORDER BY /*r_day*/ r_date
					) l_r_date
			FROM #_t_cw
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND a.external_id = t.external_id
			AND t.r_date <= @rdt
		-- where t.overdue_days < a.overdue_days and not ((t.overdue_days_p-t.overdue_days)%29 > 0 and (t.overdue_days_p-t.overdue_days)%30 > 0 and (t.overdue_days_p-t.overdue_days)%31 > 0  and t.overdue_days<>0 and 
		WHERE (
				(
					t.overdue_days_p > a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				OR (
					t.overdue_days < a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							t.overdue_days = 0
							AND t.overdue_days_p = 0
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				)
			AND t.r_date < (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE @rdt
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cw';

	DROP TABLE

	IF EXISTS #_cw;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (PARTITION BY a.external_id /*, a.r_year, a.r_month*/) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id /*, a.r_year, a.r_month*/ ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id /*, a.r_year, a.r_month*/ ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN p.r_date IS NOT NULL
									THEN alt_r_end_date
								ELSE @rdt
								END
							)
					END
				) AS r_end_date
		INTO #_cw
		FROM #_t_cw a
		LEFT JOIN #_cw_pre p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;

	--  select * from #_t_cm
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cw_pre_w';

	DROP TABLE

	IF EXISTS #_cw_pre_w;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_cw_pre_w
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id /*, r_month, r_year*/ ORDER BY /*r_day*/ r_date
					) l_r_date
			FROM #_t_cw
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND a.external_id = t.external_id
			AND t.r_date <= @rdt
		WHERE -- t.overdue_days_p in (1,31,61,91,361)
			(
				(
					t.overdue_days_p = 1
					AND a.overdue_days = 0
					OR t.overdue_days_p = 31
					AND a.overdue_days BETWEEN 1
						AND 30
					OR t.overdue_days_p = 61
					AND a.overdue_days BETWEEN 31
						AND 60
					OR t.overdue_days_p = 91
					AND a.overdue_days BETWEEN 61
						AND 90
					OR t.overdue_days_p = 361
					AND a.overdue_days BETWEEN 91
						AND 360
					)
				OR (
					t.overdue_days = 1
					AND t.last_dpd = 0
					OR t.overdue_days = 31
					AND t.last_dpd BETWEEN 1
						AND 30
					OR t.overdue_days = 61
					AND t.last_dpd BETWEEN 31
						AND 60
					OR t.overdue_days = 91
					AND t.last_dpd BETWEEN 61
						AND 90
					OR t.overdue_days = 361
					AND t.last_dpd BETWEEN 91
						AND 360
					)
				)
			AND t.r_date <= (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE @rdt
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cw_w';

	DROP TABLE

	IF EXISTS #_cw_w;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (PARTITION BY a.external_id /*, a.r_year, a.r_month*/) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id /*, a.r_year, a.r_month*/ ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id /*, a.r_year, a.r_month*/ ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN p.r_date IS NOT NULL
									THEN alt_r_end_date
								ELSE @rdt
								END
							)
					END
				) AS r_end_date
		INTO #_cw_w
		FROM #_t_cw a
		LEFT JOIN #_cw_pre_w p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;

	/******************************************************************/
	/*--march 2020
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_mar20_pre';

	DROP TABLE

	IF EXISTS #_mar20_pre;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_mar20_pre
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id
					,r_month
					,r_year ORDER BY r_day
					) l_r_date
			FROM #_t_mar20
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND a.external_id = t.external_id
		WHERE (
				(
					t.overdue_days_p > a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				OR (
					t.overdue_days < a.overdue_days
					AND (
						(
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 1
									AND 30
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 31
									AND 60
								)
							)
						OR (
							t.overdue_days = 0
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 1
									AND 30
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							(
								t.overdue_days BETWEEN 31
									AND 60
								)
							AND (
								t.overdue_days_p BETWEEN 61
									AND 90
								)
							)
						OR (
							t.overdue_days = 0
							AND t.overdue_days_p = 0
							)
						--Для учета переходов из  91+ в низшие бакеты
						OR (
							t.overdue_days_p BETWEEN 91
								AND 360
							AND t.overdue_days <= 90
							)
						OR (
							t.overdue_days_p >= 361
							AND t.overdue_days <= 360
							)
						)
					)
				)
			AND t.r_date < (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE eomonth(t.r_date)
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_mar20';

	DROP TABLE

	IF EXISTS #_mar20;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month
							) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id
												,a.r_year
												,a.r_month ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN p.r_date IS NOT NULL
									THEN alt_r_end_date
								ELSE eomonth(a.r_date)
								END
							)
					END
				) AS r_end_date
		INTO #_mar20
		FROM #_t_mar20 a
		LEFT JOIN #_mar20_pre p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_mar20_pre_w';

	DROP TABLE

	IF EXISTS #_mar20_pre_w;
		SELECT a.external_id
			,a.r_date
			,min(t.r_date) alt_r_end_date
		INTO #_mar20_pre_w
		FROM (
			SELECT *
				,LEAD(r_date) OVER (
					PARTITION BY external_id
					,r_month
					,r_year ORDER BY r_day
					) l_r_date
			FROM #_t_mar20
			) a
		LEFT JOIN #CMR t ON a.r_date <= t.r_date
			AND t.r_date <= eomonth(a.r_date)
			AND a.external_id = t.external_id
		WHERE --t.overdue_days_p in (1,31,61,91,361)
			(
				(
					t.overdue_days_p = 1
					AND a.overdue_days = 0
					OR t.overdue_days_p = 31
					AND a.overdue_days BETWEEN 1
						AND 30
					OR t.overdue_days_p = 61
					AND a.overdue_days BETWEEN 31
						AND 60
					OR t.overdue_days_p = 91
					AND a.overdue_days BETWEEN 61
						AND 90
					OR t.overdue_days_p = 361
					AND a.overdue_days BETWEEN 91
						AND 360
					)
				OR (
					t.overdue_days = 1
					AND t.last_dpd = 0
					OR t.overdue_days = 31
					AND t.last_dpd BETWEEN 1
						AND 30
					OR t.overdue_days = 61
					AND t.last_dpd BETWEEN 31
						AND 60
					OR t.overdue_days = 91
					AND t.last_dpd BETWEEN 61
						AND 90
					OR t.overdue_days = 361
					AND t.last_dpd BETWEEN 91
						AND 360
					)
				)
			AND t.r_date <= (
				CASE 
					WHEN l_r_date IS NOT NULL
						THEN l_r_date
					ELSE eomonth(t.r_date)
					END
				)
		GROUP BY a.external_id
			,a.r_date

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_mar20_w';

	DROP TABLE

	IF EXISTS #_mar20_w;
		SELECT a.*
			,(
				CASE 
					WHEN count(a.external_id) OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month
							) <> 1
						AND row_number() OVER (
							PARTITION BY a.external_id
							,a.r_year
							,a.r_month ORDER BY a.r_date DESC
							) <> 1
						THEN (
								CASE 
									WHEN a.seg1 IN ('som-new', 'new-new')
										THEN a.r_date
									WHEN p.r_date IS NOT NULL
										THEN alt_r_end_date
									ELSE dateadd(dd, - 1, lead(a.r_date) OVER (
												PARTITION BY a.external_id
												,a.r_year
												,a.r_month ORDER BY a.r_date
												))
									END
								)
					ELSE (
							CASE 
								WHEN p.r_date IS NOT NULL
									THEN alt_r_end_date
								ELSE (eomonth(a.r_date))
								END
							)
					END
				) AS r_end_date
		INTO #_mar20_w
		FROM #_t_mar20 a
		LEFT JOIN #_mar20_pre_w p ON a.r_date = p.r_date
			AND a.external_id = p.external_id;*/

	/******************************************************************/
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lysd_new';

	----------------------------- part "new" --------------------------------------
	DROP TABLE

	IF EXISTS #_lysd_new;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,CASE 
				WHEN (
						a.r_date = r_end_date
						AND (
							(
								b.overdue_days_p BETWEEN 1
									AND 30
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 31
									AND 60
								)
							--Для учета переходов из  91+ в низшие бакеты
							OR (
								b.overdue_days_p BETWEEN 91
									AND 360
								AND b.overdue_days <= 90
								)
							OR (
								b.overdue_days_p >= 361
								AND b.overdue_days <= 360
								)
							)
						)
					THEN a.last_principal_rest
				ELSE a.principal_rest
				END principal_rest
			,
			-- a.principal_rest,
			CASE 
				WHEN a.r_date = r_end_date
					THEN b.overdue_days_p
				ELSE isnull(a.overdue_days, 0)
				END AS overdue_days
			,CASE 
				WHEN a.r_date = r_end_date
					THEN b.dpd_bucket_p
				ELSE isnull(a.dpd_bucket, '(1)_0')
				END AS dpd_bucket
			,isnull(b.overdue_days, 0) AS overdue_days_end
			,isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_lysd_new
		FROM #_lysd a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			AND a.r_year = b.r_year
			AND a.r_month = b.r_month
			AND a.r_end_date = b.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lysd_new_w';

	DROP TABLE

	IF EXISTS #_lysd_new_w;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,a.principal_rest
			,
			--a.overdue_days,
			--a.dpd_bucket,
			CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.last_dpd
				ELSE a.overdue_days
				END overdue_days
			,CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.dpd_bucket_last
				ELSE a.dpd_bucket
				END AS dpd_bucket
			,isnull(b.overdue_days_p, 0) AS overdue_days_end
			,isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_lysd_new_w
		FROM #_lysd_w a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			AND a.r_year = b.r_year
			AND a.r_month = b.r_month
			AND a.r_end_date = b.r_date
		LEFT JOIN #CMR c ON a.external_id = c.external_id
			AND a.r_date = c.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lysd_new_full';

	DROP TABLE

	IF EXISTS #_lysd_new_full;
		SELECT *
		INTO #_lysd_new_full
		FROM (
			SELECT *
			FROM #_lysd_new
			WHERE dpd_bucket <> dpd_bucket_end
				OR r_end_date = dateadd(yy, - 1, @rdt)
		
			UNION
		
			(
				SELECT *
				FROM #_lysd_new_w
				WHERE (
						dpd_bucket = '(1)_0'
						AND dpd_bucket_end = '(2)_1_30'
						)
					OR (
						dpd_bucket = '(2)_1_30'
						AND dpd_bucket_end = '(3)_31_60'
						)
					OR (
						dpd_bucket = '(3)_31_60'
						AND dpd_bucket_end = '(4)_61_90'
						)
					OR (
						dpd_bucket = '(4)_61_90'
						AND dpd_bucket_end = '(5)_91_360'
						)
					OR (
						dpd_bucket = '(5)_91_360'
						AND dpd_bucket_end = '(6)_361+'
						)
				)
			) u

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lmsd_new';

	DROP TABLE

	IF EXISTS #_lmsd_new;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,CASE 
				WHEN (
						a.r_date = r_end_date
						AND (
							(
								b.overdue_days_p BETWEEN 1
									AND 30
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 31
									AND 60
								)
							--Для учета переходов из  91+ в низшие бакеты
							OR (
								b.overdue_days_p BETWEEN 91
									AND 360
								AND b.overdue_days <= 90
								)
							OR (
								b.overdue_days_p >= 361
								AND b.overdue_days <= 360
								)
							)
						)
					THEN a.last_principal_rest
				ELSE a.principal_rest
				END principal_rest
			,
			-- a.principal_rest,
			CASE 
				WHEN a.r_date = r_end_date
					THEN b.overdue_days_p
				ELSE isnull(a.overdue_days, 0)
				END AS overdue_days
			,CASE 
				WHEN a.r_date = r_end_date
					THEN b.dpd_bucket_p
				ELSE isnull(a.dpd_bucket, '(1)_0')
				END AS dpd_bucket
			,isnull(b.overdue_days, 0) AS overdue_days_end
			,isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_lmsd_new
		FROM #_lmsd a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			AND a.r_year = b.r_year
			AND a.r_month = b.r_month
			AND a.r_end_date = b.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lmsd_new_w';

	DROP TABLE

	IF EXISTS #_lmsd_new_w;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,a.principal_rest
			,
			--a.overdue_days,
			--a.dpd_bucket,
			CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.last_dpd
				ELSE a.overdue_days
				END overdue_days
			,CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.dpd_bucket_last
				ELSE a.dpd_bucket
				END AS dpd_bucket
			,isnull(b.overdue_days_p, 0) AS overdue_days_end
			,isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_lmsd_new_w
		FROM #_lmsd_w a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			AND a.r_year = b.r_year
			AND a.r_month = b.r_month
			AND a.r_end_date = b.r_date
		LEFT JOIN #CMR c ON a.external_id = c.external_id
			AND a.r_date = c.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lmsd_new_full';

	DROP TABLE

	IF EXISTS #_lmsd_new_full;
		SELECT *
		INTO #_lmsd_new_full
		FROM (
			SELECT *
			FROM #_lmsd_new
			WHERE dpd_bucket <> dpd_bucket_end
				OR r_end_date = dateadd(mm, - 1, @rdt)
		
			UNION
		
			(
				SELECT *
				FROM #_lmsd_new_w
				WHERE (
						dpd_bucket = '(1)_0'
						AND dpd_bucket_end = '(2)_1_30'
						)
					OR (
						dpd_bucket = '(2)_1_30'
						AND dpd_bucket_end = '(3)_31_60'
						)
					OR (
						dpd_bucket = '(3)_31_60'
						AND dpd_bucket_end = '(4)_61_90'
						)
					OR (
						dpd_bucket = '(4)_61_90'
						AND dpd_bucket_end = '(5)_91_360'
						)
					OR (
						dpd_bucket = '(5)_91_360'
						AND dpd_bucket_end = '(6)_361+'
						)
				)
			) u

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cm_new';

	DROP TABLE

	IF EXISTS #_cm_new;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,
			-- case when dpd_bucket = '(2)_1_30' and dpd_bucket_end
			CASE 
				WHEN (
						a.r_date = r_end_date
						AND (
							(
								b.overdue_days_p BETWEEN 1
									AND 30
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 31
									AND 60
								)
							--Для учета переходов из  91+ в низшие бакеты
							OR (
								b.overdue_days_p BETWEEN 91
									AND 360
								AND b.overdue_days <= 90
								)
							OR (
								b.overdue_days_p >= 361
								AND b.overdue_days <= 360
								)
							)
						)
					THEN a.last_principal_rest
				ELSE a.principal_rest
				END principal_rest
			,
			-- a.principal_rest,
			CASE 
				WHEN a.r_date = r_end_date
					THEN b.overdue_days_p
				ELSE isnull(a.overdue_days, 0)
				END AS overdue_days
			,CASE 
				WHEN a.r_date = r_end_date
					THEN b.dpd_bucket_p
				ELSE isnull(a.dpd_bucket, '(1)_0')
				END AS dpd_bucket
			,isnull(b.overdue_days, 0) AS overdue_days_end
			,
			/*case when (b.overdue_days-b.overdue_days_p) = 31 and b.overdue_days_p <> 0 then b.overdue_days_p
						  else isnull(b.overdue_days,0) end as overdue_days_end,
					 case when (b.overdue_days-b.overdue_days_p) = 31 and b.overdue_days_p <> 0 then b.dpd_bucket_p
						  else isnull(b.dpd_bucket,'(1)_0') end as dpd_bucket_end,*/
			isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_cm_new
		FROM #_cm a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			AND a.r_year = b.r_year
			AND a.r_month = b.r_month
			AND a.r_end_date = b.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cm_new_w';

	DROP TABLE

	IF EXISTS #_cm_new_w;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,a.principal_rest
			,
			--a.overdue_days,
			--a.dpd_bucket,
			CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.last_dpd
				ELSE a.overdue_days
				END overdue_days
			,CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.dpd_bucket_last
				ELSE a.dpd_bucket
				END AS dpd_bucket
			,isnull(b.overdue_days_p, 0) AS overdue_days_end
			,isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_cm_new_w
		FROM #_cm_w a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			AND a.r_year = b.r_year
			AND a.r_month = b.r_month
			AND a.r_end_date = b.r_date
		LEFT JOIN #CMR c ON a.external_id = c.external_id
			AND a.r_date = c.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cm_new_full';

	DROP TABLE

	IF EXISTS #_cm_new_full;
		SELECT *
		INTO #_cm_new_full
		FROM
			--  ( select *, 'Not worse' migr_seg 
			(
			SELECT *
			FROM #_cm_new
			WHERE dpd_bucket <> dpd_bucket_end
				OR r_end_date = @rdt
		
			UNION
		
			--  ( select *, 'Worse' as migr_seg
			(
				SELECT *
				FROM #_cm_new_w
				WHERE (
						dpd_bucket = '(1)_0'
						AND dpd_bucket_end = '(2)_1_30'
						)
					OR (
						dpd_bucket = '(2)_1_30'
						AND dpd_bucket_end = '(3)_31_60'
						)
					OR (
						dpd_bucket = '(3)_31_60'
						AND dpd_bucket_end = '(4)_61_90'
						)
					OR (
						dpd_bucket = '(4)_61_90'
						AND dpd_bucket_end = '(5)_91_360'
						)
					OR (
						dpd_bucket = '(5)_91_360'
						AND dpd_bucket_end = '(6)_361+'
						)
				)
			) u

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lm_new';

	DROP TABLE

	IF EXISTS #_lm_new;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,CASE 
				WHEN (
						a.r_date = r_end_date
						AND (
							(
								b.overdue_days_p BETWEEN 1
									AND 30
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 31
									AND 60
								)
							--Для учета переходов из  91+ в низшие бакеты
							OR (
								b.overdue_days_p BETWEEN 91
									AND 360
								AND b.overdue_days <= 90
								)
							OR (
								b.overdue_days_p >= 361
								AND b.overdue_days <= 360
								)
							)
						)
					THEN a.last_principal_rest
				ELSE a.principal_rest
				END principal_rest
			,
			-- a.principal_rest,
			CASE 
				WHEN a.r_date = r_end_date
					THEN b.overdue_days_p
				ELSE isnull(a.overdue_days, 0)
				END AS overdue_days
			,CASE 
				WHEN a.r_date = r_end_date
					THEN b.dpd_bucket_p
				ELSE isnull(a.dpd_bucket, '(1)_0')
				END AS dpd_bucket
			,isnull(b.overdue_days, 0) AS overdue_days_end
			,isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_lm_new
		FROM #_lm a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			AND a.r_year = b.r_year
			AND a.r_month = b.r_month
			AND a.r_end_date = b.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lm_new_w';

	DROP TABLE

	IF EXISTS #_lm_new_w;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,a.principal_rest
			,
			--a.overdue_days,
			--a.dpd_bucket,
			CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.last_dpd
				ELSE a.overdue_days
				END overdue_days
			,CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.dpd_bucket_last
				ELSE a.dpd_bucket
				END AS dpd_bucket
			,isnull(b.overdue_days_p, 0) AS overdue_days_end
			,isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_lm_new_w
		FROM #_lm_w a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			AND a.r_year = b.r_year
			AND a.r_month = b.r_month
			AND a.r_end_date = b.r_date
		LEFT JOIN #CMR c ON a.external_id = c.external_id
			AND a.r_date = c.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lm_new_full';

	DROP TABLE

	IF EXISTS #_lm_new_full;
		SELECT *
		INTO #_lm_new_full
		FROM (
			SELECT *
			FROM #_lm_new
			WHERE dpd_bucket <> dpd_bucket_end
				OR r_end_date = eomonth(dateadd(mm, - 1, @rdt))
		
			UNION
		
			(
				SELECT *
				FROM #_lm_new_w
				WHERE (
						dpd_bucket = '(1)_0'
						AND dpd_bucket_end = '(2)_1_30'
						)
					OR (
						dpd_bucket = '(2)_1_30'
						AND dpd_bucket_end = '(3)_31_60'
						)
					OR (
						dpd_bucket = '(3)_31_60'
						AND dpd_bucket_end = '(4)_61_90'
						)
					OR (
						dpd_bucket = '(4)_61_90'
						AND dpd_bucket_end = '(5)_91_360'
						)
					OR (
						dpd_bucket = '(5)_91_360'
						AND dpd_bucket_end = '(6)_361+'
						)
				)
			) u

	/**************************************************************/
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lw_new';

	DROP TABLE

	IF EXISTS #_lw_new;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,
			-- case when dpd_bucket = '(2)_1_30' and dpd_bucket_end
			CASE 
				WHEN (
						a.r_date = r_end_date
						AND (
							(
								b.overdue_days_p BETWEEN 1
									AND 30
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 31
									AND 60
								)
							--Для учета переходов из  91+ в низшие бакеты
							OR (
								b.overdue_days_p BETWEEN 91
									AND 360
								AND b.overdue_days <= 90
								)
							OR (
								b.overdue_days_p >= 361
								AND b.overdue_days <= 360
								)
							)
						)
					THEN a.last_principal_rest
				ELSE a.principal_rest
				END principal_rest
			,
			-- a.principal_rest,
			CASE 
				WHEN a.r_date = r_end_date
					THEN b.overdue_days_p
				ELSE isnull(a.overdue_days, 0)
				END AS overdue_days
			,CASE 
				WHEN a.r_date = r_end_date
					THEN b.dpd_bucket_p
				ELSE isnull(a.dpd_bucket, '(1)_0')
				END AS dpd_bucket
			,isnull(b.overdue_days, 0) AS overdue_days_end
			,
			/*case when (b.overdue_days-b.overdue_days_p) = 31 and b.overdue_days_p <> 0 then b.overdue_days_p
						  else isnull(b.overdue_days,0) end as overdue_days_end,
					 case when (b.overdue_days-b.overdue_days_p) = 31 and b.overdue_days_p <> 0 then b.dpd_bucket_p
						  else isnull(b.dpd_bucket,'(1)_0') end as dpd_bucket_end,*/
			isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_lw_new
		FROM #_lw a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			--and a.r_year        = b.r_year
			--and a.r_month       = b.r_month
			AND a.r_end_date = b.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lw_new_w';

	DROP TABLE

	IF EXISTS #_lw_new_w;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,a.principal_rest
			,
			--a.overdue_days,
			--a.dpd_bucket,
			CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.last_dpd
				ELSE a.overdue_days
				END overdue_days
			,CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.dpd_bucket_last
				ELSE a.dpd_bucket
				END AS dpd_bucket
			,isnull(b.overdue_days_p, 0) AS overdue_days_end
			,isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_lw_new_w
		FROM #_lw_w a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			--and a.r_year        = b.r_year
			--and a.r_month       = b.r_month
			AND a.r_end_date = b.r_date
		LEFT JOIN #CMR c ON a.external_id = c.external_id
			AND a.r_date = c.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_lw_new_full';

	DROP TABLE

	IF EXISTS #_lw_new_full;
		SELECT *
		INTO #_lw_new_full
		FROM
			--  ( select *, 'Not worse' migr_seg 
			(
			SELECT *
			FROM #_lw_new
			WHERE dpd_bucket <> dpd_bucket_end
				OR r_end_date = @lw_dt_to
		
			UNION
		
			--  ( select *, 'Worse' as migr_seg
			(
				SELECT *
				FROM #_lw_new_w
				WHERE (
						dpd_bucket = '(1)_0'
						AND dpd_bucket_end = '(2)_1_30'
						)
					OR (
						dpd_bucket = '(2)_1_30'
						AND dpd_bucket_end = '(3)_31_60'
						)
					OR (
						dpd_bucket = '(3)_31_60'
						AND dpd_bucket_end = '(4)_61_90'
						)
					OR (
						dpd_bucket = '(4)_61_90'
						AND dpd_bucket_end = '(5)_91_360'
						)
					OR (
						dpd_bucket = '(5)_91_360'
						AND dpd_bucket_end = '(6)_361+'
						)
				)
			) u

	/*************************************************************/
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cw_new';

	DROP TABLE

	IF EXISTS #_cw_new;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,
			-- case when dpd_bucket = '(2)_1_30' and dpd_bucket_end
			CASE 
				WHEN (
						a.r_date = r_end_date
						AND (
							(
								b.overdue_days_p BETWEEN 1
									AND 30
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 31
									AND 60
								)
							--Для учета переходов из  91+ в низшие бакеты
							OR (
								b.overdue_days_p BETWEEN 91
									AND 360
								AND b.overdue_days <= 90
								)
							OR (
								b.overdue_days_p >= 361
								AND b.overdue_days <= 360
								)
							)
						)
					THEN a.last_principal_rest
				ELSE a.principal_rest
				END principal_rest
			,
			-- a.principal_rest,
			CASE 
				WHEN a.r_date = r_end_date
					THEN b.overdue_days_p
				ELSE isnull(a.overdue_days, 0)
				END AS overdue_days
			,CASE 
				WHEN a.r_date = r_end_date
					THEN b.dpd_bucket_p
				ELSE isnull(a.dpd_bucket, '(1)_0')
				END AS dpd_bucket
			,isnull(b.overdue_days, 0) AS overdue_days_end
			,
			/*case when (b.overdue_days-b.overdue_days_p) = 31 and b.overdue_days_p <> 0 then b.overdue_days_p
						  else isnull(b.overdue_days,0) end as overdue_days_end,
					 case when (b.overdue_days-b.overdue_days_p) = 31 and b.overdue_days_p <> 0 then b.dpd_bucket_p
						  else isnull(b.dpd_bucket,'(1)_0') end as dpd_bucket_end,*/
			isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_cw_new
		FROM #_cw a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			--and a.r_year        = b.r_year
			--and a.r_month       = b.r_month
			AND a.r_end_date = b.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cw_new_w';

	DROP TABLE

	IF EXISTS #_cw_new_w;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,a.principal_rest
			,
			--a.overdue_days,
			--a.dpd_bucket,
			CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.last_dpd
				ELSE a.overdue_days
				END overdue_days
			,CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.dpd_bucket_last
				ELSE a.dpd_bucket
				END AS dpd_bucket
			,isnull(b.overdue_days_p, 0) AS overdue_days_end
			,isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_cw_new_w
		FROM #_cw_w a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			--and a.r_year        = b.r_year
			--and a.r_month       = b.r_month
			AND a.r_end_date = b.r_date
		LEFT JOIN #CMR c ON a.external_id = c.external_id
			AND a.r_date = c.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_cw_new_full';

	DROP TABLE

	IF EXISTS #_cw_new_full;
		SELECT *
		INTO #_cw_new_full
		FROM
			--  ( select *, 'Not worse' migr_seg 
			(
			SELECT *
			FROM #_cw_new
			WHERE dpd_bucket <> dpd_bucket_end
				OR r_end_date = @rdt
		
			UNION
		
			--  ( select *, 'Worse' as migr_seg
			(
				SELECT *
				FROM #_cw_new_w
				WHERE (
						dpd_bucket = '(1)_0'
						AND dpd_bucket_end = '(2)_1_30'
						)
					OR (
						dpd_bucket = '(2)_1_30'
						AND dpd_bucket_end = '(3)_31_60'
						)
					OR (
						dpd_bucket = '(3)_31_60'
						AND dpd_bucket_end = '(4)_61_90'
						)
					OR (
						dpd_bucket = '(4)_61_90'
						AND dpd_bucket_end = '(5)_91_360'
						)
					OR (
						dpd_bucket = '(5)_91_360'
						AND dpd_bucket_end = '(6)_361+'
						)
				)
			) u

	/**************************************************************/
	/*--march 2020
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_mar20_new';

	DROP TABLE

	IF EXISTS #_mar20_new;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,CASE 
				WHEN (
						a.r_date = r_end_date
						AND (
							(
								b.overdue_days_p BETWEEN 1
									AND 30
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 31
									AND 60
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days = 0
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 1
									AND 30
								)
							OR (
								b.overdue_days_p BETWEEN 61
									AND 90
								AND b.overdue_days BETWEEN 31
									AND 60
								)
							--Для учета переходов из  91+ в низшие бакеты
							OR (
								b.overdue_days_p BETWEEN 91
									AND 360
								AND b.overdue_days <= 90
								)
							OR (
								b.overdue_days_p >= 361
								AND b.overdue_days <= 360
								)
							)
						)
					THEN a.last_principal_rest
				ELSE a.principal_rest
				END principal_rest
			,
			-- a.principal_rest,
			CASE 
				WHEN a.r_date = r_end_date
					THEN b.overdue_days_p
				ELSE isnull(a.overdue_days, 0)
				END AS overdue_days
			,CASE 
				WHEN a.r_date = r_end_date
					THEN b.dpd_bucket_p
				ELSE isnull(a.dpd_bucket, '(1)_0')
				END AS dpd_bucket
			,isnull(b.overdue_days, 0) AS overdue_days_end
			,isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_mar20_new
		FROM #_mar20 a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			AND a.r_year = b.r_year
			AND a.r_month = b.r_month
			AND a.r_end_date = b.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_mar20_new_w';

	DROP TABLE

	IF EXISTS #_mar20_new_w;
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,a.principal_rest
			,
			--a.overdue_days,
			--a.dpd_bucket,
			CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.last_dpd
				ELSE a.overdue_days
				END overdue_days
			,CASE 
				WHEN a.r_date = a.r_end_date
					THEN c.dpd_bucket_last
				ELSE a.dpd_bucket
				END AS dpd_bucket
			,isnull(b.overdue_days_p, 0) AS overdue_days_end
			,isnull(b.dpd_bucket, '(1)_0') AS dpd_bucket_end
			,a.seg3
			,(
				CASE 
					WHEN b.dpd_bucket IS NULL
						THEN 'Improve'
					ELSE a.seg_rr
					END
				) AS seg_rr
		INTO #_mar20_new_w
		FROM #_mar20_w a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			AND a.r_year = b.r_year
			AND a.r_month = b.r_month
			AND a.r_end_date = b.r_date
		LEFT JOIN #CMR c ON a.external_id = c.external_id
			AND a.r_date = c.r_date;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_mar20_new_full';

	DROP TABLE

	IF EXISTS #_mar20_new_full;
		SELECT *
		INTO #_mar20_new_full
		FROM (
			SELECT *
			FROM #_mar20_new
			WHERE dpd_bucket <> dpd_bucket_end
				OR r_end_date = cast('2020-03-31' AS DATE)
		
			UNION
		
			(
				SELECT *
				FROM #_mar20_new_w
				WHERE (
						dpd_bucket = '(1)_0'
						AND dpd_bucket_end = '(2)_1_30'
						)
					OR (
						dpd_bucket = '(2)_1_30'
						AND dpd_bucket_end = '(3)_31_60'
						)
					OR (
						dpd_bucket = '(3)_31_60'
						AND dpd_bucket_end = '(4)_61_90'
						)
					OR (
						dpd_bucket = '(4)_61_90'
						AND dpd_bucket_end = '(5)_91_360'
						)
					OR (
						dpd_bucket = '(5)_91_360'
						AND dpd_bucket_end = '(6)_361+'
						)
				)
			) u*/

	/**************************************************************/
	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_t00';

	DROP TABLE

	IF EXISTS #_t00
		SELECT a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,a.principal_rest
			,a.overdue_days
			,a.dpd_bucket
			,a.overdue_days_end
			,a.dpd_bucket_end
			,a.seg3
			,a.seg_rr
			,sum(isnull(b.pay_total, 0)) AS pay_total
			,coalesce(pr.product, 'PTS') AS product --15.02.2022
		INTO #_t00
		FROM (
			SELECT *
			FROM #_lysd_new_full
		
			UNION
		
			SELECT *
			FROM #_lmsd_new_full
		
			UNION
		
			SELECT *
			FROM #_cm_new_full
		
			UNION
		
			SELECT *
			FROM #_lm_new_full
		
			UNION
		
			SELECT *
			FROM #_lw_new_full
		
			UNION
		
			SELECT *
			FROM #_cw_new_full
		
			/*UNION
		
			SELECT *
			FROM #_mar20_new_full*/
			) a
		LEFT JOIN #CMR b ON a.external_id = b.external_id
			AND b.r_date >= a.r_date
			AND b.r_date <= a.r_end_date
		LEFT JOIN #stg_product pr --15.02.2022
			ON a.external_id = pr.external_id
		GROUP BY a.r_year
			,a.r_month
			,a.r_day
			,a.r_date
			,a.r_end_date
			,a.external_id
			,a.principal_rest
			,a.overdue_days
			,a.dpd_bucket
			,a.overdue_days_end
			,a.dpd_bucket_end
			,a.seg3
			,a.seg_rr
			,coalesce(pr.product, 'PTS');

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = '#_t00_new';

	-- select * from #_t00_new
	DROP TABLE

	IF EXISTS #_t00_new;
		SELECT t.*
		INTO #_t00_new
		FROM #_t00 t
		WHERE NOT (
				(
					t.dpd_bucket = '(1)_0'
					AND t.dpd_bucket_end = '(1)_0'
					AND t.r_end_date <> @rdt
					AND t.seg3 IN ('CM', 'CW')
					)
				OR (
					t.dpd_bucket = '(1)_0'
					AND t.dpd_bucket_end = '(1)_0'
					AND t.r_end_date <> dateadd(yy, - 1, @rdt)
					AND t.seg3 IN ('LYSD')
					)
				OR (
					t.dpd_bucket = '(1)_0'
					AND t.dpd_bucket_end = '(1)_0'
					AND t.r_end_date <> dateadd(mm, - 1, @rdt)
					AND t.seg3 IN ('LMSD')
					)
				OR (
					t.dpd_bucket = '(1)_0'
					AND t.dpd_bucket_end = '(1)_0'
					AND t.r_end_date <> eomonth(@rdt, - 1)
					AND t.r_date = t.r_end_date
					AND t.seg3 IN ('LM')
					)
				OR (
					t.dpd_bucket = '(1)_0'
					AND t.dpd_bucket_end = '(1)_0'
					AND t.r_end_date <> cast('2020-03-31' AS DATE)
					AND t.r_date = t.r_end_date
					AND t.seg3 IN ('MAR20')
					)
				OR (
					t.dpd_bucket = '(1)_0'
					AND t.dpd_bucket_end = '(1)_0'
					AND t.r_end_date <> @lw_dt_to
					AND t.r_date = t.r_end_date
					AND t.seg3 IN ('LW')
					)
				);

	WITH dst
	AS (
		SELECT *
		FROM #_t00_new
		)
	DELETE
	FROM dst
	WHERE EXISTS (
			SELECT 1
			FROM #_t00_new b
			INNER JOIN (
				SELECT a.seg3
					,a.external_id
					,a.r_end_date
					,a.dpd_bucket
					,a.dpd_bucket_end
				FROM #_t00_new a
				GROUP BY a.seg3
					,a.external_id
					,a.r_end_date
					,a.dpd_bucket
					,a.dpd_bucket_end
				HAVING count(*) > 1
				) aa ON b.external_id = aa.external_id
				AND b.r_end_date = aa.r_end_date
				AND b.dpd_bucket = aa.dpd_bucket
				AND b.dpd_bucket_end = aa.dpd_bucket_end
				AND b.seg3 = aa.seg3
			WHERE 1 = 1
				AND b.r_date = b.r_end_date
				AND dst.external_id = b.external_id
				AND dst.r_date = b.r_date
				AND dst.r_end_date = b.r_end_date
				AND dst.dpd_bucket = b.dpd_bucket
				AND dst.dpd_bucket_end = b.dpd_bucket_end
				AND dst.seg3 = b.seg3
			);

	--учет КК 
	WITH a
	AS (
		SELECT *
		FROM #_t00_new
		)
	UPDATE a
	SET a.overdue_days_end = a.overdue_days
		,a.dpd_bucket_end = a.dpd_bucket
		,a.seg_rr = 'Same'
	WHERE EXISTS (
			SELECT 1
			FROM #total_kk b
			WHERE a.external_id = b.external_id
				AND eomonth(a.r_date) = eomonth(dateadd(dd, 1, b.dt_from))
				AND a.r_date BETWEEN b.dt_from
					AND b.dt_to
			)
		--and a.r_date between '2020-10-01' and '2020-10-31'
		AND a.overdue_days > a.overdue_days_end;

	--09/03/21 Полное исключение каникул
	IF @flag_kk_total = 1
	BEGIN
		WITH a
		AS (
			SELECT *
			FROM #_t00_new
			)
		DELETE
		FROM a
		WHERE EXISTS (
				SELECT 1
				FROM RiskDWH.dbo.det_kk_cmr_and_space b
				WHERE a.external_id = b.external_id
				);

		DELETE
		FROM #_t00_new
		WHERE product IN ('INSTALLMENT', 'PDL') --15.02.2022
	END;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = 'rep_coll_weekly_migr_old_buck';

	--drop table if exists #migr_old_buck_MAR20
	--select * into #migr_old_buck_MAR20 from dbo.rep_coll_weekly_migr_old_buck
	--where seg3 = 'MAR20'

	DELETE
	FROM dbo.rep_coll_weekly_migr_old_buck
	WHERE rep_dt = @rdt
		AND flag_exclude_kk = @flag_kk_total;

	IF @flag_kk_total = 0 --15.02.2022
	BEGIN
		DELETE
		FROM dbo.rep_coll_weekly_migr_old_buck
		WHERE rep_dt = @rdt
			AND flag_exclude_kk = 2;
	END;

	WITH znam
	AS (
		SELECT a.seg3
			,a.dpd_bucket
			,sum(a.principal_rest) AS principal_rest
			,a.product /*15.02.2022*/
		FROM #_t00_new a
		GROUP BY a.seg3
			,a.dpd_bucket
			,a.product /*15.02.2022*/
		)
		,chisl
	AS (
		SELECT a.seg3
			,a.dpd_bucket
			,CASE 
				WHEN (
						a.dpd_bucket = '(5)_91_360'
						AND a.dpd_bucket_end IN ('(1)_0', '(2)_1_30', '(3)_31_60', '(4)_61_90')
						)
					OR (
						a.dpd_bucket = '(6)_361+'
						AND a.dpd_bucket_end IN ('(1)_0', '(2)_1_30', '(3)_31_60', '(4)_61_90', '(5)_91_360')
						)
					THEN ''
				ELSE a.dpd_bucket_end
				END AS dpd_bucket_end
			,sum(a.principal_rest) AS principal_rest
			,a.product /*15.02.2022*/
		FROM #_t00_new a
		GROUP BY a.seg3
			,a.dpd_bucket
			,CASE 
				WHEN (
						a.dpd_bucket = '(5)_91_360'
						AND a.dpd_bucket_end IN ('(1)_0', '(2)_1_30', '(3)_31_60', '(4)_61_90')
						)
					OR (
						a.dpd_bucket = '(6)_361+'
						AND a.dpd_bucket_end IN ('(1)_0', '(2)_1_30', '(3)_31_60', '(4)_61_90', '(5)_91_360')
						)
					THEN ''
				ELSE a.dpd_bucket_end
				END
			,a.product /*15.02.2022*/
		)
	INSERT INTO dbo.rep_coll_weekly_migr_old_buck
	SELECT @rdt AS rep_dt
		,cast(sysdatetime() AS DATETIME) AS dt_dml
		,CONCAT (
			c.seg3
			,'#'
			,c.dpd_bucket
			,'#'
			,c.dpd_bucket_end
			) AS metric
		,c.seg3
		,c.dpd_bucket
		,c.dpd_bucket_end
		,c.principal_rest
		,CASE 
			WHEN z.principal_rest = 0
				THEN 0
			ELSE c.principal_rest / z.principal_rest
			END AS principal_rest_rate
		,CASE 
			WHEN c.product IN ('INSTALLMENT', 'PDL')
				THEN 2
			ELSE @flag_kk_total
			END AS flag_exclude_kk --15.02.2022
	FROM chisl c
	LEFT JOIN znam z ON c.seg3 = z.seg3
		AND c.dpd_bucket = z.dpd_bucket
		AND c.product = z.product;
	--INSERT INTO dbo.rep_coll_weekly_migr_old_buck select * from #migr_old_buck_MAR20;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = 'rep_coll_weekly_recov_alt_old_buck';

	--Рекавери по методу месячной презентации (на переходах)
	--drop table if exists #recov_alt_old_buck_MAR20
	--select * into #recov_alt_old_buck_MAR20 from dbo.rep_coll_weekly_recov_alt_old_buck
	--where seg3 = 'MAR20'

	DELETE
	FROM dbo.rep_coll_weekly_recov_alt_old_buck
	WHERE rep_dt = @rdt
		AND flag_exclude_kk = @flag_kk_total;

	IF @flag_kk_total = 0 --15.02.2022
	BEGIN
		DELETE
		FROM dbo.rep_coll_weekly_recov_alt_old_buck
		WHERE rep_dt = @rdt
			AND flag_exclude_kk = 2;
	END;

	INSERT INTO dbo.rep_coll_weekly_recov_alt_old_buck
	SELECT @rdt AS rep_dt
		,cast(sysdatetime() AS DATETIME) AS dt_dml
		,CONCAT (
			aa.seg3
			,'#'
			,aa.dpd_bucket
			) AS metric
		,aa.seg3
		,aa.dpd_bucket
		,aa.principal_rest
		,aa.pay_total
		,aa.recovery_rate
		,CASE 
			WHEN aa.product IN ('INSTALLMENT', 'PDL')
				THEN 2
			ELSE @flag_kk_total
			END AS flag_exclude_kk --15.02.2022
	FROM (
		SELECT a.seg3
			,a.dpd_bucket
			,sum(a.principal_rest) AS principal_rest
			,sum(a.pay_total) AS pay_total
			,CASE 
				WHEN sum(a.principal_rest) = 0
					THEN 0
				ELSE sum(a.pay_total) / sum(a.principal_rest)
				END AS recovery_rate
			,a.product /*15.02.2022*/
		FROM #_t00_new a
		WHERE a.dpd_bucket <> '(1)_0'
		GROUP BY a.seg3
			,a.dpd_bucket
			,a.product /*15.02.2022*/
	
		UNION ALL
	
		SELECT a.seg3
			,CASE 
				WHEN a.dpd_bucket IN ('(2)_1_30', '(3)_31_60', '(4)_61_90')
					THEN '(4#)_1_90'
				WHEN a.dpd_bucket IN ('(5)_91_360', '(6)_361+')
					THEN '(6#)_91+'
				END AS dpd_bucket
			,sum(a.principal_rest) AS principal_rest
			,sum(a.pay_total) AS pay_total
			,CASE 
				WHEN sum(a.principal_rest) = 0
					THEN 0
				ELSE sum(a.pay_total) / sum(a.principal_rest)
				END AS recovery_rate
			,a.product /*15.02.2022*/
		FROM #_t00_new a
		WHERE a.dpd_bucket <> '(1)_0'
		GROUP BY a.seg3
			,CASE 
				WHEN a.dpd_bucket IN ('(2)_1_30', '(3)_31_60', '(4)_61_90')
					THEN '(4#)_1_90'
				WHEN a.dpd_bucket IN ('(5)_91_360', '(6)_361+')
					THEN '(6#)_91+'
				END
			,a.product /*15.02.2022*/
		) aa;
	--INSERT INTO dbo.rep_coll_weekly_recov_alt_old_buck select * from #recov_alt_old_buck_MAR20;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = 'rep_coll_weekly_npl_portf';

	--drop table if exists #npl_portf_MAR20
	--select * into #npl_portf_MAR20 from  RiskDWH.dbo.rep_coll_weekly_npl_portf
	--where metric like ('%MAR20%')

	DELETE
	FROM RiskDWH.dbo.rep_coll_weekly_npl_portf
	WHERE rep_dt = @rdt
		AND flag_exclude_kk = @flag_kk_total;

	IF @flag_kk_total = 0
	BEGIN
		DELETE
		FROM RiskDWH.dbo.rep_coll_weekly_npl_portf
		WHERE rep_dt = @rdt
			AND flag_exclude_kk = 2;
	END;

	INSERT INTO RiskDWH.dbo.rep_coll_weekly_npl_portf
	SELECT @rdt AS rep_dt
		,cast(SYSDATETIME() AS DATETIME) AS dt_dml
		,CONCAT (
			a.seg3
			,'#'
			,c.seg_ip_hard_agent
			) AS metric
		,sum(principal_rest) AS principal_rest
		,CASE 
			WHEN a.product IN ('INSTALLMENT', 'PDL')
				THEN 2
			ELSE @flag_kk_total
			END AS flag_exclude_kk --15.02.2022
	FROM #_t00_new a
	INNER JOIN #creds_npl c ON a.external_id = c.external_id
		AND a.r_date = c.r_date
	GROUP BY a.seg3
		,c.seg_ip_hard_agent
		,CASE 
			WHEN a.product IN ('INSTALLMENT', 'PDL')
				THEN 2
			ELSE @flag_kk_total
			END --15.02.2022
		;
	--INSERT INTO RiskDWH.dbo.rep_coll_weekly_npl_portf  select * from #npl_portf_MAR20;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = 'drop temp (#) tables';

	--Удаление временных таблиц
	DROP TABLE #_t2;

	DROP TABLE #_t3;

	DROP TABLE #_t4;

	DROP TABLE #_t5;

	DROP TABLE #_t6;

	DROP TABLE #_t7;

	--DROP TABLE #_t8;

	DROP TABLE #_t_cm;

	DROP TABLE #_t_lm;

	DROP TABLE #_t_cw;

	DROP TABLE #_t_lmsd;

	DROP TABLE #_t_lw;

	DROP TABLE #_t_lysd;

	--DROP TABLE #_t_mar20;

	DROP TABLE #_cm;

	DROP TABLE #_cm_new;

	DROP TABLE #_cm_new_full;

	DROP TABLE #_cm_new_w;

	DROP TABLE #_cm_pre;

	DROP TABLE #_cm_pre_w;

	DROP TABLE #_cm_w;

	DROP TABLE #_cw;

	DROP TABLE #_cw_new;

	DROP TABLE #_cw_new_full;

	DROP TABLE #_cw_new_w;

	DROP TABLE #_cw_pre;

	DROP TABLE #_cw_pre_w;

	DROP TABLE #_cw_w;

	DROP TABLE #_lm;

	DROP TABLE #_lm_new;

	DROP TABLE #_lm_new_full;

	DROP TABLE #_lm_new_w;

	DROP TABLE #_lm_pre;

	DROP TABLE #_lm_pre_w;

	DROP TABLE #_lm_w;

	DROP TABLE #_lmsd;

	DROP TABLE #_lmsd_new;

	DROP TABLE #_lmsd_new_full;

	DROP TABLE #_lmsd_new_w;

	DROP TABLE #_lmsd_pre;

	DROP TABLE #_lmsd_pre_w;

	DROP TABLE #_lmsd_w;

	DROP TABLE #_lw;

	DROP TABLE #_lw_new;

	DROP TABLE #_lw_new_full;

	DROP TABLE #_lw_new_w;

	DROP TABLE #_lw_pre;

	DROP TABLE #_lw_pre_w;

	DROP TABLE #_lw_w;

	DROP TABLE #_lysd;

	DROP TABLE #_lysd_new;

	DROP TABLE #_lysd_new_full;

	DROP TABLE #_lysd_new_w;

	DROP TABLE #_lysd_pre;

	DROP TABLE #_lysd_pre_w;

	DROP TABLE #_lysd_w;

	--DROP TABLE #_mar20;

	--DROP TABLE #_mar20_new;

	--DROP TABLE #_mar20_new_full;

	--DROP TABLE #_mar20_new_w;

	--DROP TABLE #_mar20_pre;

	--DROP TABLE #_mar20_pre_w;

	--DROP TABLE #_mar20_w;

	DROP TABLE #_t00;

	DROP TABLE #_t00_new;

	DROP TABLE #creds_npl;

	DROP TABLE #total_kk;

	DROP TABLE #stg_product;

	DROP TABLE #stg1_cli_con_stages;

	DROP TABLE #stg2_cli_con_stages;

	DROP TABLE #stg3_cli_con_stages;

	DROP TABLE #CMR;
	
	
	DROP TABLE if exists #migr_old_buck_MAR20;
	DROP TABLE if exists #recov_alt_old_buck_MAR20;
	DROP TABLE if exists #npl_portf_MAR20;

	EXEC RiskDWH.dbo.prc$set_debug_info @src = @src_name
		,@info = 'FINISH';
end;