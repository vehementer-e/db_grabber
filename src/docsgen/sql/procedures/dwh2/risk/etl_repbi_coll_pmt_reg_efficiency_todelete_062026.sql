
--exec [risk].[etl_repbi_coll_pmt_reg_efficiency]
CREATE PROCEDURE [risk].[etl_repbi_coll_pmt_reg_efficiency]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY

	DROP TABLE

	IF EXISTS #repbi_coll_pmt_reg_efficiency;
		SELECT a.external_id
			,a.d
			,day(a.d) AS day_num
			,case when a.bucket_p_coll='(2)_1_30' then '(2)_1_30' else '90+' end AS dpd_bucket_p
			,CASE 
				WHEN cast(isnull(principal_cnl, 0) AS FLOAT) + cast(isnull(percents_cnl, 0) AS FLOAT) + cast(isnull(fines_cnl, 0) AS FLOAT) + cast(isnull(otherpayments_cnl, 0) AS FLOAT) + cast(isnull(overpayments_cnl, 0) AS FLOAT) - cast(isnull(overpayments_acc, 0) AS FLOAT) < 0
					THEN 0
				ELSE cast(isnull(principal_cnl, 0) AS FLOAT) + cast(isnull(percents_cnl, 0) AS FLOAT) + cast(isnull(fines_cnl, 0) AS FLOAT) + cast(isnull(otherpayments_cnl, 0) AS FLOAT) + cast(isnull(overpayments_cnl, 0) AS FLOAT) - cast(isnull(overpayments_acc, 0) AS FLOAT)
				END AS pay_total
			,a.prev_od AS last_principal_rest
			,CASE 
				WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('белгородская')
					THEN 'белгородская'
				WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('курская')
					THEN 'курская'
				WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('ростовская')
					THEN 'ростовская'
				WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('воронежская')
					THEN 'воронежская'
				WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('брянская')
					THEN 'брянская'
				WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('москва г', 'московская')
					THEN 'Москва'
				WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('санкт-петербург г', 'ленинградская')
					THEN 'Спб'
				ELSE 'остальные'
				END AS region_group
			,CASE 
				WHEN ag.agent_name IS NULL
					THEN 0
				ELSE 1
				END AS ag_flag
			,FORMAT(cast(dateadd(m, datediff(m, 0, cast(getdate() AS DATE)), 0) AS DATE), 'MM/yyyy') AS period
			,cast('3.cur_month' AS VARCHAR(100)) AS period_metric
		INTO #repbi_coll_pmt_reg_efficiency
		FROM dbo.dm_CMRStatBalance a
		LEFT JOIN stg._1cMFO.Документ_ГП_Заявка z
			ON a.external_id = z.[Номер]
		LEFT JOIN dwh_new.dbo.agent_credits ag
			ON a.external_id = ag.external_id AND a.d BETWEEN ag.st_date
					AND isnull(ag.fact_end_date, dateadd(dd, 1, cast(getdate() AS DATE)))
		WHERE a.d BETWEEN cast(dateadd(m, datediff(m, 0, cast(getdate() AS DATE)), 0) AS DATE)
				AND dateadd(dd, - 1, cast(getdate() AS DATE)) AND a.bucket_p_coll IN ('(2)_1_30', '(5)_91_360', '(6)_361+');

	INSERT INTO #repbi_coll_pmt_reg_efficiency
	SELECT a.external_id
		,a.d
		,day(a.d) AS day_num
		,case when a.bucket_p_coll='(2)_1_30' then '(2)_1_30' else '90+' end AS dpd_bucket_p
		,CASE 
			WHEN cast(isnull(principal_cnl, 0) AS FLOAT) + cast(isnull(percents_cnl, 0) AS FLOAT) + cast(isnull(fines_cnl, 0) AS FLOAT) + cast(isnull(otherpayments_cnl, 0) AS FLOAT) + cast(isnull(overpayments_cnl, 0) AS FLOAT) - cast(isnull(overpayments_acc, 0) AS FLOAT) < 0
				THEN 0
			ELSE cast(isnull(principal_cnl, 0) AS FLOAT) + cast(isnull(percents_cnl, 0) AS FLOAT) + cast(isnull(fines_cnl, 0) AS FLOAT) + cast(isnull(otherpayments_cnl, 0) AS FLOAT) + cast(isnull(overpayments_cnl, 0) AS FLOAT) - cast(isnull(overpayments_acc, 0) AS FLOAT)
			END AS pay_total
		,a.prev_od AS last_principal_rest
		,CASE 
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('белгородская')
				THEN 'белгородская'
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('курская')
				THEN 'курская'
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('ростовская')
				THEN 'ростовская'
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('воронежская')
				THEN 'воронежская'
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('брянская')
				THEN 'брянская'
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('москва г', 'московская')
				THEN 'Москва'
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('санкт-петербург г', 'ленинградская')
				THEN 'Спб'
			ELSE 'остальные'
			END AS region_group
		,CASE 
			WHEN ag.agent_name IS NULL
				THEN 0
			ELSE 1
			END AS ag_flag
		,FORMAT(dateadd(mm, - 1, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE)), 'MM/yyyy') AS period
		,'2.prev_month' AS period_metric
	FROM dbo.dm_CMRStatBalance a
	LEFT JOIN stg._1cMFO.Документ_ГП_Заявка z
		ON a.external_id = z.[Номер]
	LEFT JOIN dwh_new.dbo.agent_credits ag
		ON a.external_id = ag.external_id AND a.d BETWEEN ag.st_date
				AND isnull(ag.fact_end_date, dateadd(dd, 1, cast(getdate() AS DATE)))
	WHERE a.d BETWEEN dateadd(mm, - 1, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE))
			AND dateadd(dd, - 1, cast(cast(dateadd(m, datediff(m, 0, cast(getdate() AS DATE)), 0) AS DATE) AS DATE)) AND a.bucket_p_coll IN ('(2)_1_30', '(5)_91_360', '(6)_361+');

	INSERT INTO #repbi_coll_pmt_reg_efficiency
	SELECT a.external_id
		,a.d
		,day(a.d) AS day_num
		,case when a.bucket_p_coll='(2)_1_30' then '(2)_1_30' else '90+' end AS dpd_bucket_p
		,CASE 
			WHEN cast(isnull(principal_cnl, 0) AS FLOAT) + cast(isnull(percents_cnl, 0) AS FLOAT) + cast(isnull(fines_cnl, 0) AS FLOAT) + cast(isnull(otherpayments_cnl, 0) AS FLOAT) + cast(isnull(overpayments_cnl, 0) AS FLOAT) - cast(isnull(overpayments_acc, 0) AS FLOAT) < 0
				THEN 0
			ELSE cast(isnull(principal_cnl, 0) AS FLOAT) + cast(isnull(percents_cnl, 0) AS FLOAT) + cast(isnull(fines_cnl, 0) AS FLOAT) + cast(isnull(otherpayments_cnl, 0) AS FLOAT) + cast(isnull(overpayments_cnl, 0) AS FLOAT) - cast(isnull(overpayments_acc, 0) AS FLOAT)
			END AS pay_total
		,a.prev_od AS last_principal_rest
		,CASE 
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('белгородская')
				THEN 'белгородская'
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('курская')
				THEN 'курская'
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('ростовская')
				THEN 'ростовская'
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('воронежская')
				THEN 'воронежская'
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('брянская')
				THEN 'брянская'
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('москва г', 'московская')
				THEN 'Москва'
			WHEN trim(replace(replace(replace(replace(replace(lower(z.[Регион]), 'обл', ''), 'республика - чувашия', ''), 'автономный округ', ''), 'край', ''), 'респ', '')) IN ('санкт-петербург г', 'ленинградская')
				THEN 'Спб'
			ELSE 'остальные'
			END AS region_group
		,CASE 
			WHEN ag.agent_name IS NULL
				THEN 0
			ELSE 1
			END AS ag_flag
		,FORMAT(dateadd(yy, - 1, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE)), 'MM/yyyy') AS period
		,'1.prev_year' AS period_metric
	FROM dbo.dm_CMRStatBalance a
	LEFT JOIN stg._1cMFO.Документ_ГП_Заявка z
		ON a.external_id = z.[Номер]
	LEFT JOIN dwh_new.dbo.agent_credits ag
		ON a.external_id = ag.external_id AND a.d BETWEEN ag.st_date
				AND isnull(ag.fact_end_date, dateadd(dd, 1, cast(getdate() AS DATE)))
	WHERE a.d BETWEEN dateadd(yy, - 1, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE))
			AND dateadd(dd, - 1, dateadd(yy, - 1, cast(dateadd(m, datediff(m, - 1, getdate()), 0) AS DATE))) AND a.bucket_p_coll IN ('(2)_1_30', '(5)_91_360', '(6)_361+');


	DELETE FROM #repbi_coll_pmt_reg_efficiency 
		WHERE dpd_bucket_p='(2)_1_30' and ag_flag=1;

	TRUNCATE TABLE risk.repbi_coll_pmt_reg_efficiency;

	WITH src
	AS (
		SELECT a.day_num
			,a.period
			,a.period_metric
			,a.dpd_bucket_p
			,a.ag_flag
			,region_group
			,round(sum(a.pay_total) / sum(a.last_principal_rest), 3) AS EFF
			,count(*) AS cnt
		FROM #repbi_coll_pmt_reg_efficiency a
		GROUP BY a.period
			,a.period_metric
			,a.dpd_bucket_p
			,a.ag_flag
			,region_group
			,a.day_num
		)
	INSERT INTO risk.repbi_coll_pmt_reg_efficiency
	SELECT a.*
		,sum(a.eff) OVER (
			PARTITION BY a.period
			,a.dpd_bucket_p
			,a.ag_flag
			,a.region_group ORDER BY a.day_num
			) AS eff_cumm 
	FROM src a;

	WITH src
	AS (
		SELECT a.day_num
			,a.period
			,a.period_metric
			,a.dpd_bucket_p
			,a.ag_flag
			,'все_регионы' region_group
			,round(sum(a.pay_total) / sum(a.last_principal_rest), 3) AS EFF
			,count(*) AS cnt
		FROM #repbi_coll_pmt_reg_efficiency a
		GROUP BY a.period
			,a.period_metric
			,a.dpd_bucket_p
			,a.ag_flag
			,a.day_num
		)
	INSERT INTO risk.repbi_coll_pmt_reg_efficiency
	SELECT a.*
		,sum(a.eff) OVER (
			PARTITION BY a.period
			,a.dpd_bucket_p
			,a.ag_flag
			,a.region_group ORDER BY a.day_num
			) AS eff_cumm
	FROM src a;




	--Совокупная эффективность
	WITH src
	AS (
		SELECT a.day_num
			,a.period
			,a.period_metric
			,a.dpd_bucket_p
			,3 as ag_flag
			,region_group
			,round(sum(a.pay_total) / sum(a.last_principal_rest), 3) AS EFF
			,count(*) AS cnt
		FROM #repbi_coll_pmt_reg_efficiency a
		WHERE a.dpd_bucket_p<>'(2)_1_30'
		GROUP BY a.period
			,a.period_metric
			,a.dpd_bucket_p
			,region_group
			,a.day_num
		)
	INSERT INTO risk.repbi_coll_pmt_reg_efficiency
	SELECT a.*
		,sum(a.eff) OVER (
			PARTITION BY a.period
			,a.dpd_bucket_p
			,a.ag_flag
			,a.region_group ORDER BY a.day_num
			) AS eff_cumm --into risk.repbi_coll_pmt_reg_efficiency  
	FROM src a;

	WITH src
	AS (
		SELECT a.day_num
			,a.period
			,a.period_metric
			,a.dpd_bucket_p
			,3 as ag_flag
			,'все_регионы' region_group
			,round(sum(a.pay_total) / sum(a.last_principal_rest), 3) AS EFF
			,count(*) AS cnt
		FROM #repbi_coll_pmt_reg_efficiency a
		WHERE a.dpd_bucket_p<>'(2)_1_30'
		GROUP BY a.period
			,a.period_metric
			,a.dpd_bucket_p
			,a.day_num
		)
	INSERT INTO risk.repbi_coll_pmt_reg_efficiency
	SELECT a.*
		,sum(a.eff) OVER (
			PARTITION BY a.period
			,a.dpd_bucket_p
			,a.ag_flag
			,a.region_group ORDER BY a.day_num
			) AS eff_cumm
	FROM src a;




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

		EXEC msdb.dbo.sp_send_dbmail @recipients = 'a.kuznecov@techmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject
		;throw 51000, @msg, 1
	END CATCH
END;
