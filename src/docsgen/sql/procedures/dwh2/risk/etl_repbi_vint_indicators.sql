
CREATE PROCEDURE [risk].[etl_repbi_vint_indicators]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY

	DROP TABLE IF EXISTS #vintages
		SELECT oi.number
			,oi.StartDate
			,oi.amount
			,oi.fpd0
			,oi.fpd4
			,oi.fpd7
			,oi.fpd30
			,oi.spd0
			,oi.tpd0
			,oi.spd0_not_fpd0
			,oi._30_4_CMR
			,oi._30_4_MFO
			,oi.DeferredInMOB
			,oi._90_6_CMR
			,oi._90_6_MFO
			,oi._90_12_CMR
			,oi._90_12_MFO
			,c.generation AS vintage
			,ank.probation
			,CASE WHEN (ank.client_type_2 = 'docred' OR ank.client_type_2 = 'parallel') THEN '3.ACTIVE' WHEN (ank.client_type_2 = 'repeated') THEN '2.REPEATED' WHEN (ank.client_type_1 = 'repeated') THEN '2.REPEATED' WHEN (ank.client_type_1 = 'active') THEN '3.ACTIVE' ELSE '1.NEW' END AS CLIENT_TYPE
			,CASE WHEN ank.Branch_id = '3645' THEN 1 ELSE 0 END AS REFIN_FL
			,inst.Is_installment
		INTO #vintages
		FROM reports.dbo.dm_OverdueIndicators oi
		INNER JOIN risk.credits c
			ON c.external_id = oi.Number
		LEFT JOIN (
			SELECT DISTINCT number
				,call_date AS stage_date
				,probation
				,Branch_id
				,client_type_1
				,client_type_2
				,gender
				,--Женский, Мужской
				ROW_NUMBER() OVER (
					PARTITION BY number ORDER BY call_date DESC
					) rn
			FROM stg._loginom.OriginationLog
			WHERE call_date >= '20190701' AND (stage = 'Call 1' OR stage = 'Call 2')
			) ank
			ON oi.number = ank.Number AND ank.rn = 1
		LEFT JOIN (
			SELECT DISTINCT number
				,CASE WHEN Is_installment = 1 THEN 1 ELSE 0 END AS Is_installment
				,ROW_NUMBER() OVER (
					PARTITION BY number ORDER BY stage_date DESC
					) rn
			FROM stg._loginom.application
			WHERE stage in ('Call 1', 'Call 2')
			) inst
			ON oi.number = inst.Number AND inst.rn = 1
		WHERE oi.StartDate >= '20190801' AND oi.StartDate < getdate() AND oi.amount > 0;

	delete risk.repbi_vint_indicators_hist
	where repdate=cast(getdate() as date);

	insert into risk.repbi_vint_indicators_hist
	select cast(getdate() as date) as repdate, a.* from #vintages a;

	IF object_id('risk.repbi_vint_indicators') IS NOT NULL
		TRUNCATE TABLE risk.repbi_vint_indicators;

	--1. All_PTS
	WITH src
	AS (
		SELECT vintage
			,cast('1. All_PTS' AS VARCHAR(100)) AS grp
			,count(DISTINCT number) AS cnt
			,cast(sum(amount) AS FLOAT) AS amnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(fpd0) AS FLOAT) / cast(count(fpd0) AS FLOAT) END AS fpd0_cnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd0_amnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(fpd4) AS FLOAT) / cast(count(fpd4) AS FLOAT) END AS fpd4_cnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd4 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd4 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd4_amnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(fpd7) AS FLOAT) / cast(count(fpd7) AS FLOAT) END AS fpd7_cnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd7 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd7 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd7_amnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(fpd30) AS FLOAT) / cast(count(fpd30) AS FLOAT) END AS fpd30_cnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd30 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd30 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd30_amnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(spd0) AS FLOAT) / cast(count(spd0) AS FLOAT) END AS spd0_cnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_amnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(tpd0) AS FLOAT) / cast(count(tpd0) AS FLOAT) END AS tpd0_cnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN tpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN tpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS tpd0_amnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(spd0_not_fpd0) AS FLOAT) / cast(count(spd0_not_fpd0) AS FLOAT) END AS spd0_not_fpd0_cnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0_not_fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0_not_fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_not_fpd0_amnt
			/*,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(_30_4_MFO) AS FLOAT) / cast(count(_30_4_MFO) AS FLOAT) END AS cnt_30@4
			,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(_90_6_MFO) AS FLOAT) / cast(count(_90_6_MFO) AS FLOAT) END AS cnt_90@6
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(_90_12_MFO) AS FLOAT) / cast(count(_90_12_MFO) AS FLOAT) END AS cnt_90@12
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
		*/
----------CMR 14/10/25
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(_30_4_CMR) AS FLOAT) / cast(count(_30_4_CMR) AS FLOAT) END AS cnt_30@4
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(_90_6_CMR) AS FLOAT) / cast(count(_90_6_CMR) AS FLOAT) END AS cnt_90@6
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(_90_12_CMR) AS FLOAT) / cast(count(_90_12_CMR) AS FLOAT) END AS cnt_90@12
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
----------
		FROM #vintages
		WHERE Is_installment = 0
		GROUP BY vintage
		)
	INSERT INTO risk.repbi_vint_indicators
	SELECT row_number() OVER (PARTITION BY a.grp ORDER BY vintage) AS rn
		,round(avg(amnt / cnt) OVER (PARTITION BY grp ,vintage), 0) AS avg_amnt
		,a.*
		,getdate() AS dt_dml
	FROM src a
	ORDER BY 1;

	--2. NEW_TOTAL
	WITH src
	AS (
		SELECT vintage
			,cast('2. NEW TOTAL' AS VARCHAR(100)) AS grp
			,count(DISTINCT number) AS cnt
			,cast(sum(amount) AS FLOAT) AS amnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(fpd0) AS FLOAT) / cast(count(fpd0) AS FLOAT) END AS fpd0_cnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd0_amnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(fpd4) AS FLOAT) / cast(count(fpd4) AS FLOAT) END AS fpd4_cnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd4 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd4 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd4_amnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(fpd7) AS FLOAT) / cast(count(fpd7) AS FLOAT) END AS fpd7_cnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd7 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd7 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd7_amnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(fpd30) AS FLOAT) / cast(count(fpd30) AS FLOAT) END AS fpd30_cnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd30 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd30 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd30_amnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(spd0) AS FLOAT) / cast(count(spd0) AS FLOAT) END AS spd0_cnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_amnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(tpd0) AS FLOAT) / cast(count(tpd0) AS FLOAT) END AS tpd0_cnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN tpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN tpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS tpd0_amnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(spd0_not_fpd0) AS FLOAT) / cast(count(spd0_not_fpd0) AS FLOAT) END AS spd0_not_fpd0_cnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0_not_fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0_not_fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_not_fpd0_amnt
			/*,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(_30_4_MFO) AS FLOAT) / cast(count(_30_4_MFO) AS FLOAT) END AS cnt_30@4
			,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(_90_6_MFO) AS FLOAT) / cast(count(_90_6_MFO) AS FLOAT) END AS cnt_90@6
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(_90_12_MFO) AS FLOAT) / cast(count(_90_12_MFO) AS FLOAT) END AS cnt_90@12
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
		*/
----------CMR 14/10/25
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(_30_4_CMR) AS FLOAT) / cast(count(_30_4_CMR) AS FLOAT) END AS cnt_30@4
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(_90_6_CMR) AS FLOAT) / cast(count(_90_6_CMR) AS FLOAT) END AS cnt_90@6
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(_90_12_CMR) AS FLOAT) / cast(count(_90_12_CMR) AS FLOAT) END AS cnt_90@12
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
----------
		FROM #vintages
		WHERE Is_installment = 0 AND client_type = '1.NEW'
		GROUP BY vintage
		)
	INSERT INTO risk.repbi_vint_indicators
	SELECT row_number() OVER (PARTITION BY a.grp ORDER BY vintage) AS rn
		,round(avg(amnt / cnt) OVER (PARTITION BY grp ,vintage), 0) AS avg_amnt
		,a.*
		,getdate() AS dt_dml
	FROM src a
	ORDER BY 1;

	--3. New without refin and probation
	WITH src
	AS (
		SELECT vintage
			,cast('3. NEW WO REF/PROBATION' AS VARCHAR(100)) AS grp
			,count(DISTINCT number) AS cnt
			,cast(sum(amount) AS FLOAT) AS amnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(fpd0) AS FLOAT) / cast(count(fpd0) AS FLOAT) END AS fpd0_cnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd0_amnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(fpd4) AS FLOAT) / cast(count(fpd4) AS FLOAT) END AS fpd4_cnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd4 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd4 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd4_amnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(fpd7) AS FLOAT) / cast(count(fpd7) AS FLOAT) END AS fpd7_cnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd7 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd7 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd7_amnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(fpd30) AS FLOAT) / cast(count(fpd30) AS FLOAT) END AS fpd30_cnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd30 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd30 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd30_amnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(spd0) AS FLOAT) / cast(count(spd0) AS FLOAT) END AS spd0_cnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_amnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(tpd0) AS FLOAT) / cast(count(tpd0) AS FLOAT) END AS tpd0_cnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN tpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN tpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS tpd0_amnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(spd0_not_fpd0) AS FLOAT) / cast(count(spd0_not_fpd0) AS FLOAT) END AS spd0_not_fpd0_cnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0_not_fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0_not_fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_not_fpd0_amnt
			/*,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(_30_4_MFO) AS FLOAT) / cast(count(_30_4_MFO) AS FLOAT) END AS cnt_30@4
			,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(_90_6_MFO) AS FLOAT) / cast(count(_90_6_MFO) AS FLOAT) END AS cnt_90@6
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(_90_12_MFO) AS FLOAT) / cast(count(_90_12_MFO) AS FLOAT) END AS cnt_90@12
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
		*/
----------CMR 14/10/25
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(_30_4_CMR) AS FLOAT) / cast(count(_30_4_CMR) AS FLOAT) END AS cnt_30@4
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(_90_6_CMR) AS FLOAT) / cast(count(_90_6_CMR) AS FLOAT) END AS cnt_90@6
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(_90_12_CMR) AS FLOAT) / cast(count(_90_12_CMR) AS FLOAT) END AS cnt_90@12
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
----------
		FROM #vintages
		WHERE Is_installment = 0 AND client_type = '1.NEW' AND (probation IS NULL OR probation = 0) AND refin_fl = 0
		GROUP BY vintage
		)
	INSERT INTO risk.repbi_vint_indicators
	SELECT row_number() OVER (PARTITION BY a.grp ORDER BY vintage) AS rn
		,round(avg(amnt / cnt) OVER (PARTITION BY grp ,vintage), 0) AS avg_amnt
		,a.*
		,getdate() AS dt_dml
	FROM src a
	ORDER BY 1;

	--4. POVT_ALL
	WITH src
	AS (
		SELECT vintage
			,cast('4. POVT_ALL' AS VARCHAR(100)) AS grp
			,count(DISTINCT number) AS cnt
			,cast(sum(amount) AS FLOAT) AS amnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(fpd0) AS FLOAT) / cast(count(fpd0) AS FLOAT) END AS fpd0_cnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd0_amnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(fpd4) AS FLOAT) / cast(count(fpd4) AS FLOAT) END AS fpd4_cnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd4 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd4 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd4_amnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(fpd7) AS FLOAT) / cast(count(fpd7) AS FLOAT) END AS fpd7_cnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd7 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd7 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd7_amnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(fpd30) AS FLOAT) / cast(count(fpd30) AS FLOAT) END AS fpd30_cnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd30 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd30 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd30_amnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(spd0) AS FLOAT) / cast(count(spd0) AS FLOAT) END AS spd0_cnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_amnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(tpd0) AS FLOAT) / cast(count(tpd0) AS FLOAT) END AS tpd0_cnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN tpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN tpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS tpd0_amnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(spd0_not_fpd0) AS FLOAT) / cast(count(spd0_not_fpd0) AS FLOAT) END AS spd0_not_fpd0_cnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0_not_fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0_not_fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_not_fpd0_amnt
			/*,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(_30_4_MFO) AS FLOAT) / cast(count(_30_4_MFO) AS FLOAT) END AS cnt_30@4
			,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(_90_6_MFO) AS FLOAT) / cast(count(_90_6_MFO) AS FLOAT) END AS cnt_90@6
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(_90_12_MFO) AS FLOAT) / cast(count(_90_12_MFO) AS FLOAT) END AS cnt_90@12
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
		*/
----------CMR 14/10/25
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(_30_4_CMR) AS FLOAT) / cast(count(_30_4_CMR) AS FLOAT) END AS cnt_30@4
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(_90_6_CMR) AS FLOAT) / cast(count(_90_6_CMR) AS FLOAT) END AS cnt_90@6
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(_90_12_CMR) AS FLOAT) / cast(count(_90_12_CMR) AS FLOAT) END AS cnt_90@12
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
----------
		FROM #vintages
		WHERE Is_installment = 0 AND client_type IN (
				'2.REPEATED'
				,'3.ACTIVE'
				) AND refin_fl = 0
		GROUP BY vintage
		)
	INSERT INTO risk.repbi_vint_indicators
	SELECT row_number() OVER (PARTITION BY a.grp ORDER BY vintage) AS rn
		,round(avg(amnt / cnt) OVER (PARTITION BY grp ,vintage), 0) AS avg_amnt
		,a.*
		,getdate() AS dt_dml
	FROM src a
	ORDER BY 1;

	--5. ПОВТОРНЫЕ (ACTIVE)
	WITH src
	AS (
		SELECT vintage
			,cast('5. Active povt' AS VARCHAR(100)) AS grp
			,count(DISTINCT number) AS cnt
			,cast(sum(amount) AS FLOAT) AS amnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(fpd0) AS FLOAT) / cast(count(fpd0) AS FLOAT) END AS fpd0_cnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd0_amnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(fpd4) AS FLOAT) / cast(count(fpd4) AS FLOAT) END AS fpd4_cnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd4 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd4 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd4_amnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(fpd7) AS FLOAT) / cast(count(fpd7) AS FLOAT) END AS fpd7_cnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd7 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd7 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd7_amnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(fpd30) AS FLOAT) / cast(count(fpd30) AS FLOAT) END AS fpd30_cnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd30 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd30 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd30_amnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(spd0) AS FLOAT) / cast(count(spd0) AS FLOAT) END AS spd0_cnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_amnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(tpd0) AS FLOAT) / cast(count(tpd0) AS FLOAT) END AS tpd0_cnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN tpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN tpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS tpd0_amnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(spd0_not_fpd0) AS FLOAT) / cast(count(spd0_not_fpd0) AS FLOAT) END AS spd0_not_fpd0_cnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0_not_fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0_not_fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_not_fpd0_amnt
			/*,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(_30_4_MFO) AS FLOAT) / cast(count(_30_4_MFO) AS FLOAT) END AS cnt_30@4
			,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(_90_6_MFO) AS FLOAT) / cast(count(_90_6_MFO) AS FLOAT) END AS cnt_90@6
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(_90_12_MFO) AS FLOAT) / cast(count(_90_12_MFO) AS FLOAT) END AS cnt_90@12
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
		*/
----------CMR 14/10/25
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(_30_4_CMR) AS FLOAT) / cast(count(_30_4_CMR) AS FLOAT) END AS cnt_30@4
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(_90_6_CMR) AS FLOAT) / cast(count(_90_6_CMR) AS FLOAT) END AS cnt_90@6
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(_90_12_CMR) AS FLOAT) / cast(count(_90_12_CMR) AS FLOAT) END AS cnt_90@12
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
----------
		FROM #vintages
		WHERE Is_installment = 0 AND client_type IN ('3.ACTIVE') AND refin_fl = 0
		GROUP BY vintage
		)
	INSERT INTO risk.repbi_vint_indicators
	SELECT row_number() OVER (PARTITION BY a.grp ORDER BY vintage) AS rn
		,round(avg(amnt / cnt) OVER (PARTITION BY grp ,vintage), 0) AS avg_amnt
		,a.*
		,getdate() AS dt_dml
	FROM src a
	ORDER BY 1;

	--6. ПОВТОРНЫЕ (REPEATED)
	WITH src
	AS (
		SELECT vintage
			,cast('6. POVT REPEATED' AS VARCHAR(100)) AS grp
			,count(DISTINCT number) AS cnt
			,cast(sum(amount) AS FLOAT) AS amnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(fpd0) AS FLOAT) / cast(count(fpd0) AS FLOAT) END AS fpd0_cnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd0_amnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(fpd4) AS FLOAT) / cast(count(fpd4) AS FLOAT) END AS fpd4_cnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd4 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd4 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd4_amnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(fpd7) AS FLOAT) / cast(count(fpd7) AS FLOAT) END AS fpd7_cnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd7 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd7 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd7_amnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(fpd30) AS FLOAT) / cast(count(fpd30) AS FLOAT) END AS fpd30_cnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd30 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd30 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd30_amnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(spd0) AS FLOAT) / cast(count(spd0) AS FLOAT) END AS spd0_cnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_amnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(tpd0) AS FLOAT) / cast(count(tpd0) AS FLOAT) END AS tpd0_cnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN tpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN tpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS tpd0_amnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(spd0_not_fpd0) AS FLOAT) / cast(count(spd0_not_fpd0) AS FLOAT) END AS spd0_not_fpd0_cnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0_not_fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0_not_fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_not_fpd0_amnt
			/*,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(_30_4_MFO) AS FLOAT) / cast(count(_30_4_MFO) AS FLOAT) END AS cnt_30@4
			,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(_90_6_MFO) AS FLOAT) / cast(count(_90_6_MFO) AS FLOAT) END AS cnt_90@6
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(_90_12_MFO) AS FLOAT) / cast(count(_90_12_MFO) AS FLOAT) END AS cnt_90@12
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
		*/
----------CMR 14/10/25
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(_30_4_CMR) AS FLOAT) / cast(count(_30_4_CMR) AS FLOAT) END AS cnt_30@4
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(_90_6_CMR) AS FLOAT) / cast(count(_90_6_CMR) AS FLOAT) END AS cnt_90@6
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(_90_12_CMR) AS FLOAT) / cast(count(_90_12_CMR) AS FLOAT) END AS cnt_90@12
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
----------
		FROM #vintages
		WHERE Is_installment = 0 AND client_type IN ('2.REPEATED') AND refin_fl = 0
		GROUP BY vintage
		)
	INSERT INTO risk.repbi_vint_indicators
	SELECT row_number() OVER (PARTITION BY a.grp ORDER BY vintage) AS rn
		,round(avg(amnt / cnt) OVER (PARTITION BY grp ,vintage), 0) AS avg_amnt
		,a.*
		,getdate() AS dt_dml
	FROM src a
	ORDER BY 1;

	--7. РЕФИНАНС
	WITH src
	AS (
		SELECT vintage
			,cast('7. REFIN' AS VARCHAR(1000)) AS grp
			,count(DISTINCT number) AS cnt
			,cast(sum(amount) AS FLOAT) AS amnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(fpd0) AS FLOAT) / cast(count(fpd0) AS FLOAT) END AS fpd0_cnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd0_amnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(fpd4) AS FLOAT) / cast(count(fpd4) AS FLOAT) END AS fpd4_cnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd4 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd4 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd4_amnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(fpd7) AS FLOAT) / cast(count(fpd7) AS FLOAT) END AS fpd7_cnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd7 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd7 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd7_amnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(fpd30) AS FLOAT) / cast(count(fpd30) AS FLOAT) END AS fpd30_cnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd30 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd30 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd30_amnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(spd0) AS FLOAT) / cast(count(spd0) AS FLOAT) END AS spd0_cnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_amnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(tpd0) AS FLOAT) / cast(count(tpd0) AS FLOAT) END AS tpd0_cnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN tpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN tpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS tpd0_amnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(spd0_not_fpd0) AS FLOAT) / cast(count(spd0_not_fpd0) AS FLOAT) END AS spd0_not_fpd0_cnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0_not_fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0_not_fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_not_fpd0_amnt
			/*,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(_30_4_MFO) AS FLOAT) / cast(count(_30_4_MFO) AS FLOAT) END AS cnt_30@4
			,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(_90_6_MFO) AS FLOAT) / cast(count(_90_6_MFO) AS FLOAT) END AS cnt_90@6
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(_90_12_MFO) AS FLOAT) / cast(count(_90_12_MFO) AS FLOAT) END AS cnt_90@12
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
		*/
----------CMR 14/10/25
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(_30_4_CMR) AS FLOAT) / cast(count(_30_4_CMR) AS FLOAT) END AS cnt_30@4
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(_90_6_CMR) AS FLOAT) / cast(count(_90_6_CMR) AS FLOAT) END AS cnt_90@6
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(_90_12_CMR) AS FLOAT) / cast(count(_90_12_CMR) AS FLOAT) END AS cnt_90@12
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
----------
		FROM #vintages
		WHERE Is_installment = 0 AND refin_fl = 1
		GROUP BY vintage
		)
	INSERT INTO risk.repbi_vint_indicators
	SELECT row_number() OVER (PARTITION BY a.grp ORDER BY vintage) AS rn
		,round(avg(amnt / cnt) OVER (PARTITION BY grp ,vintage), 0) AS avg_amnt
		,a.*
		,getdate() AS dt_dml
	FROM src a
	ORDER BY 1;

	--8. ИСПЫТАТЕЛЬНЫЙ СРОК НОВЫЕ
	WITH src
	AS (
		SELECT vintage
			,cast('8. Probation New' AS VARCHAR(1000)) AS grp
			,count(DISTINCT number) AS cnt
			,cast(sum(amount) AS FLOAT) AS amnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(fpd0) AS FLOAT) / cast(count(fpd0) AS FLOAT) END AS fpd0_cnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd0_amnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(fpd4) AS FLOAT) / cast(count(fpd4) AS FLOAT) END AS fpd4_cnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd4 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd4 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd4_amnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(fpd7) AS FLOAT) / cast(count(fpd7) AS FLOAT) END AS fpd7_cnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd7 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd7 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd7_amnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(fpd30) AS FLOAT) / cast(count(fpd30) AS FLOAT) END AS fpd30_cnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd30 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd30 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd30_amnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(spd0) AS FLOAT) / cast(count(spd0) AS FLOAT) END AS spd0_cnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_amnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(tpd0) AS FLOAT) / cast(count(tpd0) AS FLOAT) END AS tpd0_cnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN tpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN tpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS tpd0_amnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(spd0_not_fpd0) AS FLOAT) / cast(count(spd0_not_fpd0) AS FLOAT) END AS spd0_not_fpd0_cnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0_not_fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0_not_fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_not_fpd0_amnt
			/*,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(_30_4_MFO) AS FLOAT) / cast(count(_30_4_MFO) AS FLOAT) END AS cnt_30@4
			,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(_90_6_MFO) AS FLOAT) / cast(count(_90_6_MFO) AS FLOAT) END AS cnt_90@6
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(_90_12_MFO) AS FLOAT) / cast(count(_90_12_MFO) AS FLOAT) END AS cnt_90@12
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
		*/
----------CMR 14/10/25
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(_30_4_CMR) AS FLOAT) / cast(count(_30_4_CMR) AS FLOAT) END AS cnt_30@4
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(_90_6_CMR) AS FLOAT) / cast(count(_90_6_CMR) AS FLOAT) END AS cnt_90@6
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(_90_12_CMR) AS FLOAT) / cast(count(_90_12_CMR) AS FLOAT) END AS cnt_90@12
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
----------
		FROM #vintages
		WHERE Is_installment = 0 AND client_type = '1.NEW' AND probation = 1
		GROUP BY vintage
		)
	INSERT INTO risk.repbi_vint_indicators
	SELECT row_number() OVER (PARTITION BY a.grp ORDER BY vintage) AS rn
		,round(avg(amnt / cnt) OVER (PARTITION BY grp ,vintage), 0) AS avg_amnt
		,a.*
		,getdate() AS dt_dml
	FROM src a
	ORDER BY 1;

	--9. ИНСТОЛМЕНТ
	WITH src
	AS (
		SELECT vintage
			,cast('9. INSTALLMENT' AS VARCHAR(1000)) AS grp
			,count(DISTINCT number) AS cnt
			,cast(sum(amount) AS FLOAT) AS amnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(fpd0) AS FLOAT) / cast(count(fpd0) AS FLOAT) END AS fpd0_cnt
			,CASE WHEN count(fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd0_amnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(fpd4) AS FLOAT) / cast(count(fpd4) AS FLOAT) END AS fpd4_cnt
			,CASE WHEN count(fpd4) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd4 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd4 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd4_amnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(fpd7) AS FLOAT) / cast(count(fpd7) AS FLOAT) END AS fpd7_cnt
			,CASE WHEN count(fpd7) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd7 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd7 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd7_amnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(fpd30) AS FLOAT) / cast(count(fpd30) AS FLOAT) END AS fpd30_cnt
			,CASE WHEN count(fpd30) = 0 THEN NULL ELSE cast(sum(CASE WHEN fpd30 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN fpd30 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS fpd30_amnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(spd0) AS FLOAT) / cast(count(spd0) AS FLOAT) END AS spd0_cnt
			,CASE WHEN count(spd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_amnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(tpd0) AS FLOAT) / cast(count(tpd0) AS FLOAT) END AS tpd0_cnt
			,CASE WHEN count(tpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN tpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN tpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS tpd0_amnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(spd0_not_fpd0) AS FLOAT) / cast(count(spd0_not_fpd0) AS FLOAT) END AS spd0_not_fpd0_cnt
			,CASE WHEN count(spd0_not_fpd0) = 0 THEN NULL ELSE cast(sum(CASE WHEN spd0_not_fpd0 = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN spd0_not_fpd0 IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS spd0_not_fpd0_amnt
			/*,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(_30_4_MFO) AS FLOAT) / cast(count(_30_4_MFO) AS FLOAT) END AS cnt_30@4
			,CASE WHEN count(_30_4_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(_90_6_MFO) AS FLOAT) / cast(count(_90_6_MFO) AS FLOAT) END AS cnt_90@6
			,CASE WHEN count(_90_6_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(_90_12_MFO) AS FLOAT) / cast(count(_90_12_MFO) AS FLOAT) END AS cnt_90@12
			,CASE WHEN count(_90_12_MFO) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_MFO = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_MFO IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
		*/
----------CMR 14/10/25
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(_30_4_CMR) AS FLOAT) / cast(count(_30_4_CMR) AS FLOAT) END AS cnt_30@4
,CASE WHEN count(_30_4_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _30_4_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _30_4_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_30@4
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(_90_6_CMR) AS FLOAT) / cast(count(_90_6_CMR) AS FLOAT) END AS cnt_90@6
,CASE WHEN count(_90_6_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_6_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_6_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@6
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(_90_12_CMR) AS FLOAT) / cast(count(_90_12_CMR) AS FLOAT) END AS cnt_90@12
,CASE WHEN count(_90_12_CMR) = 0 THEN NULL ELSE cast(sum(CASE WHEN _90_12_CMR = 1 THEN amount ELSE 0 END) AS FLOAT) / cast(sum(CASE WHEN _90_12_CMR IS NOT NULL THEN amount ELSE 0 END) AS FLOAT) END AS amnt_90@12
----------
		FROM #vintages
		WHERE Is_installment = 1
		GROUP BY vintage
		)
	INSERT INTO risk.repbi_vint_indicators
	SELECT row_number() OVER (PARTITION BY a.grp ORDER BY vintage) AS rn
		,round(avg(amnt / cnt) OVER (PARTITION BY grp ,vintage), 0) AS avg_amnt
		,a.*
		,getdate() AS dt_dml
	FROM src a
	ORDER BY 1;

	EXEC risk.set_debug_info @sp_name, 'FINISH';

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
			,@subject = @subject
		;throw 51000, @msg, 1
	END CATCH
END;
