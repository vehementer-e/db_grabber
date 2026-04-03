
--exec [risk].[base_etl_applications];
--exec [risk].[base_etl_credits];
CREATE PROCEDURE [risk].[base_etl_applications]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)

BEGIN TRY

DROP TABLE IF EXISTS #t_originationlog_call_1;
	SELECT * INTO #t_originationlog_call_1
	FROM (
		SELECT 
		number
		,call_date AS c1_date
		,APR AS c1_APR
		,client_type_1
		,CASE WHEN upper(strategy_version) LIKE '%INST%' THEN 1 ELSE 0 END IsInstallment
		,probation
		,no_probation
		,strategy_version AS C1_strategy_version --Настя - добавила тип стратегии
		,isnull(datediff(year, birth_date, call_date) - CASE 
				WHEN month(Birth_date) < month(call_date) THEN 0
				WHEN month(Birth_date) > month(call_date) THEN 1
				WHEN day(Birth_date) > day(call_date) THEN 1
				ELSE 0
				END, years) AS age
		,CASE WHEN Branch_id IN ('3645', '5271') THEN 1 ELSE 0 END refin_fl
		,APR_SEGMENT
		,decision AS c1_decision
		,EqxScore
		,productTypeCode
		,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC) as rn
		FROM stg._loginom.Originationlog
		WHERE stage = 'Call 1'
		AND number IS NOT NULL
		--and userName = 'service' --01/12/25 Прокопенко-kurikalov
		AND number NOT IN ('19061300000088', '20101300041806', '21011900071506', '21011900071507')
			AND (
				(
					Last_name NOT LIKE '%Тест%'
					AND number NOT IN ('19061300000088', '20101300041806', '21011900071506', '21011900071507')
					AND ISNULL(userName, 'xxx') NOT IN ('shoshina', 'P.Chesnokova')
					)
				OR number IN ('20031010000096', '22013020224271')
				)
		) t;

DROP TABLE IF EXISTS #originationlog_call_2
	SELECT * INTO #originationlog_call_2
	FROM 
		(
		SELECT 
		number
		,call_date AS c2_date
		,APR
		,APR_SEGMENT
		,client_type_2
		,probation
		,strategy_version AS C2_strategy_version --Настя - добавила тип стратегии
		,CASE WHEN upper(strategy_version) LIKE '%INST%' THEN 1 ELSE 0 END IsInstallment
		,CASE WHEN Branch_id IN ('3645', '5271') THEN 1 ELSE 0 END refin_fl
		,EqxScore
		,productTypeCode
		,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC) as rn
		FROM stg._loginom.Originationlog
		WHERE stage = 'Call 2'
		) t;

DROP TABLE IF EXISTS #okbscore_src_c12;
	SELECT * INTO #okbscore_src_c12
	FROM 
		(
		SELECT number
		,cast([value] AS INT) AS okbscore
		,call_date AS okbscore_date
		,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC	,stage DESC) as rn
		FROM stg._loginom.[Origination_okbscore_parse] a
		WHERE stage IN ('Call 1', 'Call 2')
		AND [key] = 'score'
		AND [value] IS NOT NULL
		) t
	WHERE rn = 1;

DROP TABLE IF EXISTS #nbchPV2score_src_c12;
	SELECT * INTO #nbchPV2score_src_c12
	FROM 
		(
		SELECT 
		number
		,nbchPV2score
		,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC) as rn
		FROM stg._loginom.OriginationLog
		WHERE stage IN ('Call 1', 'Call 2')
		AND nbchPV2score IS NOT NULL
		) t
	WHERE rn = 1;

DROP TABLE IF EXISTS #okbscore_src_c1;
	SELECT * INTO #okbscore_src_c1
	FROM 
	(
	SELECT 
	number
	,cast([value] AS INT) AS okbscore
	,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC ,stage DESC) as rn
	FROM stg._loginom.[Origination_okbscore_parse] a
	WHERE stage = 'Call 1'
		AND [key] = 'score'
		AND [value] IS NOT NULL
		) t
	WHERE rn = 1;

DROP TABLE IF EXISTS #nbchPV2score_src_c1;
	SELECT * INTO #nbchPV2score_src_c1
	FROM (
		SELECT 
		number
		,nbchPV2score
		,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC) as rn
		FROM stg._loginom.OriginationLog
		WHERE stage = 'Call 1'
		AND nbchPV2score IS NOT NULL
		) t
	WHERE t.rn = 1;

DROP TABLE IF EXISTS #okbscore_src_c2;
	SELECT * INTO #okbscore_src_c2
	FROM 
		(
		SELECT 
		number
		,cast([value] AS INT) AS okbscore
		,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC,stage DESC) as rn
		FROM stg._loginom.[Origination_okbscore_parse] a
		WHERE stage = 'Call 2'
		AND [key] = 'score'
		AND [value] IS NOT NULL
		) t
	WHERE t.rn = 1;

DROP TABLE IF EXISTS #nbchPV2score_src_c2;
	SELECT * INTO #nbchPV2score_src_c2
	FROM 
		(
		SELECT 
		number
		,nbchPV2score
		,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC) as rn
		FROM stg._loginom.OriginationLog
		WHERE stage = 'Call 2'
		AND nbchPV2score IS NOT NULL
		) t
	WHERE rn = 1;

DROP TABLE IF EXISTS #c12_score;
	SELECT 
	olc1.Number
	,oc12.okbscore
	,oc12.okbscore_date
	,nc12.nbchPV2score AS nbchPV2score
	,oc1.okbscore AS c1_okbscore
	,nc1.nbchPV2score AS c1_nbchPV2score
	,oc2.okbscore AS c2_okbscore
	,nc2.nbchPV2score AS c2_nbchPV2score
	INTO #c12_score
	FROM #t_originationlog_call_1 olc1
	LEFT JOIN #okbscore_src_c12 oc12 
		ON oc12.Number = olc1.Number
	LEFT JOIN #nbchPV2score_src_c12 nc12 
		ON nc12.Number = olc1.Number
	LEFT JOIN #okbscore_src_c1 oc1 
		ON oc1.Number = olc1.Number
	LEFT JOIN #nbchPV2score_src_c1 nc1 
		ON nc1.Number = olc1.Number
	LEFT JOIN #okbscore_src_c2 oc2 
		ON oc2.Number = olc1.Number
	LEFT JOIN #nbchPV2score_src_c2 nc2 
		ON nc2.Number = olc1.Number
	where olc1.rn=1;

--Флаг заявки, дошедшей до чекера
DROP TABLE IF EXISTS #checker_flag;
	SELECT 
	DISTINCT cr.number collate Cyrillic_General_CI_AS AS number
	,cast(1 AS INT) AS checker_flag
	INTO #checker_flag
	FROM stg.[_fedor].[core_ClientRequestHistory] crh
	INNER JOIN stg.[_fedor].[core_ClientRequest] cr 
		ON crh.IdClientRequest = cr.id
	INNER JOIN stg.[_fedor].[dictionary_TaskStatus] dts 
		ON dts.id = crh.IdClientRequestStatus
		AND dts.IsDeleted = 0
		AND dts.name = 'В работе'
	INNER JOIN stg.[_fedor].[dictionary_ClientRequestStatus] crs 
		ON crs.Id = crh.IdClientRequestStatus
		AND crs.Name = 'Контроль данных'
	INNER JOIN stg.[_fedor].[core_TaskAndClientRequest] tcr 
		ON cr.Id = tcr.IdClientRequest
		AND tcr.isDeleted = 0
	INNER JOIN stg.[_fedor].[core_Task] t 
		ON tcr.IdTask = t.id
		AND t.isdeleted = 0
	INNER JOIN stg.[_fedor].[core_TaskHistory] th 
		ON t.id = th.Idtask
		AND th.IsDeleted = 0
	INNER JOIN stg.[_fedor].[core_TaskAssignUser] tau 
		ON tau.IdTask = t.Id
		AND tau.IsDeleted = 0
	WHERE crh.CreatedOn > '20200902' -- дата старта ФЕДОР в проде
	AND crh.IsDeleted = 0
	AND cr.CreatedOn > '20200902';

DROP TABLE IF EXISTS #pers_data
	SELECT * INTO #pers_data
	FROM 
		(
		SELECT 
		Number
		,Last_name
		,First_name
		,Patronymic
		,cast(Birth_date AS DATE) AS birth_date
		,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC) as rn
		FROM stg._loginom.Originationlog
		WHERE stage IN ('Call 1', 'Call 2')
		AND Last_name IS NOT NULL
		) t
	WHERE rn = 1
;
--------------------------------поиск bigInstallmentMarket RDWH-39
drop table if exists #biginstm;
select
number
,productTypeCode
,row_number() over (partition by number order by (select null)) as rn
into #biginstm
from stg._loginom.application app
where stage = 'Call 1'
and productTypeCode = 'bigInstallmentMarket'
;
--------------------------------call1 RDWH-39
drop table if exists #call1;
select
ol.number
,ol.productTypeCode as ol_productTypeCode
,biginstm.productTypeCode as biginstm_productTypeCode
,coalesce(biginstm.productTypeCode, ol.productTypeCode) as c1_product
,row_number() over (partition by ol.number order by ol.call_date desc) as rn
into #call1
from stg._loginom.Originationlog ol
left join #biginstm biginstm
	on ol.number = biginstm.number
	and biginstm.rn = 1
where ol.stage = 'Call 1'
and ol.call_date >= '2024-01-01'
and ol.number is not null
and ol.userName = 'service'
and ol.number not in ('19061300000088', '20101300041806', '21011900071506', '21011900071507')
;
--------------------------------SB_Cash_25 для bigInstallment RDWH-39
drop table if exists #ags25;
select 
number
,SB_Cash_25
,row_number() over (partition by number order by call_date desc) as rn
into #ags25
from stg._loginom.EqxScore5SBCash25Aggregates ag
where exists (select number from #call1 where number = ag.number)
and SB_Cash_25 is not null
;
--------------------------------rbp только для бигов RDWH-39
drop table if exists #biginst_rbp;
select 
call1.number
,case 
	when call1.biginstm_productTypeCode = 'bigInstallmentMarket' and call1.ol_productTypeCode <> 'bigInstallmentMarket' then 'DOWNSELL'
	when call1.c1_product in ('bigInstallmentMarket', 'bigInstallment') and ags25.SB_Cash_25 >= 620 then 'RBP 1'
	when call1.c1_product in ('bigInstallmentMarket', 'bigInstallment') and ags25.SB_Cash_25 >= 567 and SB_Cash_25 < 620 then 'RBP 2'
	when call1.c1_product in ('bigInstallmentMarket', 'bigInstallment') and ags25.SB_Cash_25 >= 530 and SB_Cash_25 < 567 then 'RBP 3'
	when call1.c1_product in ('bigInstallmentMarket', 'bigInstallment') and ags25.SB_Cash_25 >= 0 and SB_Cash_25 < 530 then 'RBP 4'
	when call1.c1_product in ('bigInstallmentMarket', 'bigInstallment') and ags25.SB_Cash_25 is null then 'RBP 4'
	else null
	end big_rbp
into #biginst_rbp
from #call1 call1
left join #ags25 ags25
	on call1.number = ags25.number
	and ags25.rn = 1
where call1.rn = 1
;
-----------------------------------------------------RBP_GR
DROP TABLE IF EXISTS #rbp_seg
	SELECT * INTO #rbp_seg
	FROM (
SELECT 
c.number
,CASE WHEN c1_date > '20230127 12:18' THEN c.apr_segment ELSE B.APR_SEGMENT END C1_APR_segment
,c.c1_APR
,case 
	--RDWH-43
	when c.productTypeCode = 'autoCredit' and coalesce(olc2.EqxScore, c.EqxScore) >= 670 then 'RBP 1'
	when c.productTypeCode = 'autoCredit' and coalesce(olc2.EqxScore, c.EqxScore) >= 631 
		and coalesce(olc2.EqxScore, c.EqxScore) < 670 then 'RBP 2'
	when c.productTypeCode = 'autoCredit' and coalesce(olc2.EqxScore, c.EqxScore) >= 590 
		and coalesce(olc2.EqxScore, c.EqxScore) < 631 then 'RBP 3'
	when c.productTypeCode = 'autoCredit' and (coalesce(olc2.EqxScore, c.EqxScore) < 590 
		or coalesce(olc2.EqxScore, c.EqxScore) is null) then 'RBP 4'

	--RDWH-39
	when call1.biginstm_productTypeCode = 'bigInstallmentMarket' and call1.ol_productTypeCode <> 'bigInstallmentMarket' then 'DOWNSELL'
	when call1.c1_product in ('bigInstallmentMarket', 'bigInstallment') and ags25.SB_Cash_25 >= 620 then 'RBP 1'
	when call1.c1_product in ('bigInstallmentMarket', 'bigInstallment') and ags25.SB_Cash_25 >= 567 and SB_Cash_25 < 620 then 'RBP 2'
	when call1.c1_product in ('bigInstallmentMarket', 'bigInstallment') and ags25.SB_Cash_25 >= 530 and SB_Cash_25 < 567 then 'RBP 3'
	when call1.c1_product in ('bigInstallmentMarket', 'bigInstallment') and ags25.SB_Cash_25 >= 0 and SB_Cash_25 < 530 then 'RBP 4'
	when call1.c1_product in ('bigInstallmentMarket', 'bigInstallment') and ags25.SB_Cash_25 is null then 'RBP 4'

	--RDWH-22
    when (olc2.client_type_2 ='docred' or olc2.client_type_2 = 'parallel') or (olc2.client_type_2 is null and c.client_type_1 = 'active') then 'АКТИВНЫЕ'
    when (c.client_type_1 = 'repeated' and olc2.client_type_2 is null) or olc2.client_type_2 = 'repeated' then 'ПОВТОРНЫЕ'
    when coalesce(olc2.probation, c.probation) = 1 then 'RBP PROBATION' --сегмент RBP испытательный срок
    when (c.REFIN_FL = 1 or olc2.REFIN_FL = 1) then 'RBP REFIN' ----сегмент RBP рефинансирование
	when coalesce(olc2.APR_SEGMENT, c.APR_SEGMENT) in ('1','2','3','4', '1001','1002','1003', '1071', '1051') then 'RBP 1'
	when coalesce(olc2.APR_SEGMENT, c.APR_SEGMENT) in ('10','20','21','22','23','24', '1101', '1171', '1151') then 'RBP 2'
	when c.C1_date >= '20211111 00:03'
		and ((c.APR_SEGMENT in ('60','61','62','63','101','102','103','104','50','51','52','53','54', '1201', '1202', '1271', '1251') 
		and olc2.APR_SEGMENT is null)
		or olc2.APR_SEGMENT in ('60','61','62','63','101','102','103','104','50','51','52','53','54', '1201', '1202', '1271', '1251')) 
		then 'RBP 3'
	when coalesce(olc2.APR_SEGMENT, c.APR_SEGMENT) in ('1301','1371','1351') then 'RBP 4'
    else 'RBP 4'
    end RBP_GR 

		,CASE 
			WHEN c.C1_date < '20201006 23:15' THEN NULL --28/03/2023 Власова Н.
			WHEN C.C1_strategy_version = 'INST_V1' THEN 'NotRBP_INST'
			WHEN C.PROBATION = 1 THEN 'NotRBP_PROBATION'--26/03/2024 - Прокопенко П., алгоритм отличается для продаж				
			WHEN c.no_PROBATION = 1 AND c.C1_date >= '20221214 12:00' THEN 'RBP 4'
			WHEN isnull(olc2.refin_fl, c.refin_fl) = 1 THEN 'NotRBP_REFIN'
			WHEN C.C1_strategy_version = 'New_V3'
				AND CASE WHEN c1_date > '20230127 12:18' THEN c.apr_segment ELSE B.APR_SEGMENT END IN ('1', '2', '3', '4', '1001', '1002', '1003')
				THEN 'RBP 1'
			WHEN C.C1_strategy_version = 'New_V3'
				AND CASE WHEN c1_date > '20230127 12:18' THEN c.apr_segment ELSE B.APR_SEGMENT END IN ('10', '20', '21', '22', '23', '24', '1101')
				THEN 'RBP 2'
			WHEN C.C1_strategy_version = 'New_V3'
				AND C.c1_date >= '20211111 00:03'
				AND CASE  WHEN c1_date > '20230127 12:18' THEN c.apr_segment ELSE B.APR_SEGMENT END IN ('60', '61', '62', '63', '101', '102', '103', '104', '50', '51', '52', '53', '54', '1201', '1202')
				THEN 'RBP 3'
			WHEN C.C1_strategy_version = 'New_V3' THEN 'RBP 4'
			ELSE 'NotRBP_Repeated'
			END RBP_GR_FOR_SALES
		,ROW_NUMBER() OVER (PARTITION BY c.number ORDER BY c.c1_date DESC,b.DWHInsertedDate DESC) as rn
		FROM #t_originationlog_call_1 c
		LEFT JOIN #originationlog_call_2 olc2 
			ON olc2.Number = c.number 
			and olc2.rn=1
		LEFT JOIN stg._loginom.score b 
			ON cast(b.number AS VARCHAR) = c.number
			AND b.stage = 'Call 1'
		left join #call1 call1
			on c.number = call1.number
			and call1.rn = 1
		left join #ags25 ags25
			on call1.number = ags25.number
			and ags25.rn = 1
		where c.rn=1
		) t
	WHERE rn = 1;

DROP TABLE IF EXISTS #cha_cha_seg
	SELECT 
	NUMBER
	,CASE 
		WHEN RBP_GR = 'RBP 1' AND C1_APR IN ('35', '40', '54', '50') THEN 'challenger' --RBP 1 назначена ставка, соответствующая сегменту
		WHEN RBP_GR = 'RBP 1'
			AND (
				C1_APR IS NULL
				OR C1_APR NOT IN ('35', '40', '54', '50')
				)
			THEN 'champion' --RBP 1 назначена ставка, несоответствующая сегменту (или не назначена)
		WHEN RBP_GR = 'RBP 2' AND C1_APR IN ('56', '70', '65') THEN 'challenger' --RBP 2 назначена ставка, соответствующая сегменту
		WHEN RBP_GR = 'RBP 2'
			AND (
				C1_APR IS NULL
				OR C1_APR NOT IN ('56', '70', '65')
				)
			THEN 'champion' --RBP 2 назначена ставка, несоответствующая сегменту (или не назначена)
		WHEN RBP_GR = 'RBP 3' AND C1_APR IN ('66', '70', '80', '65') THEN 'challenger' --RBP 3 назначена ставка, соответствующая сегменту
		WHEN RBP_GR = 'RBP 3'
			AND (
				C1_APR IS NULL
				OR C1_APR NOT IN ('66', '70', '80', '65')
				)
			THEN 'champion' --RBP 3 назначена ставка, несоответствующая сегменту (или не назначена)
		WHEN RBP_GR = 'RBP 4' AND C1_APR IS NOT NULL THEN 'challenger' --RBP 4 назначена ставка
		WHEN RBP_GR = 'RBP 4' AND C1_APR IS NULL THEN 'champion' --RBP 4 не назначена ставка
		ELSE NULL
		END CHA_CHA_SEGMENT --Настя - поправила логику
	INTO #cha_cha_seg
	FROM #rbp_seg
;

DROP TABLE IF EXISTS #cnt_accs
	SELECT * INTO #cnt_accs
	FROM (
		SELECT 
		number
		,CNT_ACT_ACCS_NBKI
		,CNT_ACT_ACCS_EQUI
		,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC) as rn
		FROM stg._loginom.OriginationLog
		WHERE stage IN ('Call 1', 'Call 2')
		AND (
			CNT_ACT_ACCS_NBKI IS NOT NULL
			OR CNT_ACT_ACCS_EQUI IS NOT NULL
			)
		) t
	WHERE t.rn = 1;

DROP TABLE IF EXISTS #cnt_dq_accs;
	SELECT * INTO #cnt_dq_accs
	FROM (
		SELECT 
		number
		,CNT_DQ_ACCS
		,SUM_DQ_PMTS
		,year_ts
		,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC) as rn
		FROM stg._loginom.OriginationLog
		WHERE stage IN ('Call 1', 'Call 2')
		AND CNT_DQ_ACCS IS NOT NULL
		) t
	WHERE rn = 1;

DROP TABLE IF EXISTS #micro_ever;
	SELECT *
	INTO #micro_ever
	FROM (
		SELECT 
		number
		,micro_ever
		,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC	,stage DESC) as rn
		FROM stg._loginom.score
		WHERE stage IN ('Call 1', 'Call 2')
		AND micro_ever IS NOT NULL
		) t
	WHERE t.rn = 1;

DROP TABLE IF EXISTS #micro_last_3_year;
	SELECT * INTO #micro_last_3_year
	FROM (
		SELECT 
		number
		,stage
		,micro_last3Y
		,ROW_NUMBER() OVER (PARTITION BY number ORDER BY call_date DESC	,stage DESC) as rn
		FROM stg._loginom.score
		WHERE stage IN ('Call 1', 'Call 2')
		AND micro_last3Y IS NOT NULL
		) t
	WHERE t.rn = 1;

DROP TABLE IF EXISTS #rbp_cha_cha_exception;
	SELECT * INTO #rbp_cha_cha_exception
	FROM (
		SELECT 
		DISTINCT w.number
		,RBP_GR = 'RBP 1'
		,CASE WHEN w.[group] = 50 THEN 'challenger' ELSE 'champion' END CHA_CHA_SEG
		,ROW_NUMBER() OVER (PARTITION BY w.number ORDER BY w.stage_date DESC) as rn
		FROM stg._loginom.WorkFlow w
		INNER JOIN stg._loginom.score b 
			ON b.stage = 'Call 1'
			AND b.Number = w.number
			AND b.APR_segment IN ('1', '2', '3')
		WHERE w.stage = 'Call 1'
		AND w.stage_date >= '20200716  23:00:00'
		AND w.stage_date <= '20201006  23:15:00'
		AND w.strategy_version = 'New_V3'
		) t
	WHERE rn = 1;

DROP TABLE IF EXISTS #fl_override;
	SELECT DISTINCT number
	INTO #fl_override
	FROM [stg].[_loginom].[Originationlog]
	WHERE is_installment = 1
		AND (
			number <> '19061300000088'
			AND number <> '19061300000089'
			AND number <> '20101300041806'
			AND number <> '21011900071506'
			AND number <> '21011900071507'
			)
		AND (
			(
				stage = 'Call 1'
				AND leadsource_exception_override_flg = 1
				)
			OR (
				stage = 'Call 2'
				AND leadsource_exception_override_flg = 1
				)
			--релиз PDL от 30/11/2023
			OR (
				stage = 'Call 5'
				AND leadsource_exception_override_flg = 1
				)
			);
--------------------------------
DROP TABLE IF EXISTS #applications;
	SELECT a.number
		,a.Last_name
		,a.First_name
		,a.Patronymic
		,a.birth_date
		,a.c1_date
		,a.c2_date
		,a.probation
		,a.refin_fl
		,isnull(a.IsInstallment, 0) AS IsInstallment
		,a.c1_apr
		,a.c2_apr
		,a.C1_APR_segment
		,CASE 
			WHEN a.client_type_2 = 'docred' OR a.client_type_2 = 'parallel' THEN '2.ACTIVE'
			WHEN a.client_type_2 = 'repeated' THEN '3.REPEATED'
			WHEN a.client_type_1 = 'repeated' THEN '3.REPEATED'
			WHEN a.client_type_1 = 'active' THEN '2.ACTIVE'
			ELSE '1.NEW'
			END client_type
		,CASE 
			WHEN a.client_type_2 = 'docred' THEN 'Докредитование'
			WHEN a.client_type_2 = 'parallel' THEN 'Параллельный'
			WHEN a.client_type_2 = 'repeated' OR a.client_type_1 = 'repeated' THEN 'Повторный'
			WHEN a.client_type_1 = 'active' THEN 'Докредитование'
			ELSE 'Первичный'
			END client_type_for_sales
		,CASE WHEN active_acc_cnt IS NULL THEN NULL ELSE a.micro_ever END micro_ever
		,CASE WHEN active_acc_cnt IS NULL THEN NULL ELSE a.micro_last3Y END micro_last3Y
		,a.active_acc_cnt
		,CASE WHEN active_acc_cnt IS NULL THEN NULL ELSE a.cnt_dq_accs END acc_delinq_cnt
		,CASE WHEN active_acc_cnt IS NULL THEN NULL ELSE a.sum_dq_pmts END dlq_summ
		,a.RBP_GR
		,a.RBP_GR_FOR_SALES
		,a.CHA_CHA_SEGMENT
		,a.age
		,a.region_fact
		,a.gender
		,a.c1_decision
		,a.okbscore
		,a.okbscore_date
		,a.c1_okbscore
		,a.c2_okbscore
		,a.nbchPV2score
		,a.c1_nbchPV2score
		,a.c2_nbchPV2score
		,a.strategy_version
		,a.fl_override
		,getdate() AS dt_dml
		,a.product
	INTO #applications
	FROM (
		SELECT 
			olc1.number
			,upper(pd.First_name) AS First_name
			,upper(pd.Last_name) AS Last_name
			,upper(pd.Patronymic) AS Patronymic
			,pd.birth_date
			,coalesce(olc2.probation, olc1.probation, 0) AS probation
			,coalesce(olc2.refin_fl, olc1.refin_fl, 0) AS refin_fl
			,isnull(olc2.IsInstallment, olc1.IsInstallment) AS IsInstallment
			,olc1.c1_date
			,olc1.c1_apr
			,olc2.apr AS c2_apr
			,olc2.C2_date
			,rbp.C1_APR_segment
			,olc1.client_type_1
			,olc2.client_type_2
			,CASE 
				WHEN (
						ca.CNT_ACT_ACCS_NBKI >= ca.CNT_ACT_ACCS_EQUI
						AND ca.CNT_ACT_ACCS_NBKI IS NOT NULL
						AND ca.CNT_ACT_ACCS_EQUI IS NOT NULL
						)
					THEN ca.CNT_ACT_ACCS_NBKI
				WHEN (
						ca.CNT_ACT_ACCS_EQUI >= ca.CNT_ACT_ACCS_NBKI
						AND ca.CNT_ACT_ACCS_NBKI IS NOT NULL
						AND ca.CNT_ACT_ACCS_EQUI IS NOT NULL
						)
					THEN ca.CNT_ACT_ACCS_EQUI
				ELSE COALESCE(ca.CNT_ACT_ACCS_NBKI, ca.CNT_ACT_ACCS_EQUI)
				END active_acc_cnt
			,cda.CNT_DQ_ACCS AS cnt_dq_accs
			,cda.SUM_DQ_PMTS AS sum_dq_pmts
			,me.micro_ever
			,ml3.micro_last3Y
			,isnull(cast(echa.RBP_GR AS VARCHAR(50)), rbp.RBP_GR) as RBP_GR --echa.RBP_GR там только для трех месяцев считалась в 2020, biginst_rbp.big_rbp RDWH-39
			,rbp.RBP_GR_FOR_SALES
			,isnull(cast(echa.CHA_CHA_SEG AS VARCHAR(50)), cha.CHA_CHA_SEGMENT) AS CHA_CHA_SEGMENT
			,olc1.age AS age
			,[Регионпроживания] AS region_fact
			,[ПолКлиента] AS gender
			,olc1.C1_strategy_version AS strategy_version
			,olc1.c1_decision
			,scr.okbscore
			,scr.okbscore_date
			,scr.c1_okbscore
			,scr.c2_okbscore
			,scr.nbchPV2score
			,scr.c1_nbchPV2score
			,scr.c2_nbchPV2score
			,CASE WHEN fo.number IS NOT NULL THEN 1 ELSE 0 END fl_override
			,CASE 
				WHEN olc1.PROBATION = 1 THEN 'Испытательный срок' 
				WHEN olc1.refin_fl = 1 OR olc2.refin_fl = 1 THEN 'Рефин'
				WHEN olc1.C1_strategy_version = 'INST_V1' THEN 'Беззалог'
				ELSE 'ПТС_остальные'
				END product
		FROM #t_originationlog_call_1 olc1
		LEFT JOIN #originationlog_call_2 olc2 ON olc2.number = olc1.number and olc2.rn=1
		LEFT JOIN #pers_data pd ON pd.Number = olc1.Number
		LEFT JOIN #cnt_accs ca ON ca.Number = olc1.Number
			AND ca.rn = 1
		LEFT JOIN #cnt_dq_accs cda ON cda.Number = olc1.Number
			AND cda.rn = 1
		LEFT JOIN #micro_ever me ON me.number = olc1.Number
			AND me.rn = 1
		LEFT JOIN #micro_last_3_year ml3 ON ml3.Number = olc1.Number
			AND ml3.rn = 1
		LEFT JOIN #rbp_seg rbp ON rbp.Number = olc1.Number
			AND rbp.rn = 1
		LEFT JOIN #cha_cha_seg cha ON cha.Number = olc1.Number
		LEFT JOIN #rbp_cha_cha_exception echa ON echa.Number = olc1.Number
			AND echa.rn = 1
		LEFT JOIN reports.dbo.dm_Factor_Analysis fa ON fa.[Номер] = olc1.Number
		LEFT JOIN #c12_score scr ON scr.Number = olc1.number
		LEFT JOIN #checker_flag chf ON chf.number = olc1.number
		LEFT JOIN #fl_override fo ON fo.number = olc1.number
		where olc1.rn=1
		) a;

		BEGIN TRANSACTION

		DELETE FROM risk.applications;

		INSERT INTO risk.applications
		SELECT DISTINCT *
		FROM #applications;

		COMMIT TRANSACTION;

		EXEC risk.set_debug_info @sp_name
			,'FINISH';
	END TRY

	BEGIN CATCH
		SET @msg = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		SET @subject = CONCAT (
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
