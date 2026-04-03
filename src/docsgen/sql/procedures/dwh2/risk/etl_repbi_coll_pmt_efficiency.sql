
--exec [risk].[etl_repbi_coll_pmt_efficiency]

CREATE PROCEDURE [risk].[etl_repbi_coll_pmt_efficiency]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY

	DROP TABLE

	IF EXISTS #stg_repbi_coll_pmt_eff;
		--year_ago
		SELECT p.код AS external_id
			,p.ДатаПлатежа AS pmt_dt
			,p.СуммаПлатежа AS pmt_amount
			,CASE WHEN d2.d IS NOT NULL THEN 1 ELSE 0 END AS dpd_1_flag
			,dateadd(yy, - 1, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE)) AS per
		INTO #stg_repbi_coll_pmt_eff
		FROM dm.CMRExpectedRepayments p
		LEFT JOIN reports.dbo.dm_CMRStatBalance_2 d1
			ON p.Код = d1.external_id AND datediff(day, p.ДатаПлатежа, d1.d) = - 1
		LEFT JOIN reports.dbo.dm_CMRStatBalance_2 d2
			ON p.Код = d2.external_id AND d2.dpd = 1 AND datediff(day, p.ДатаПлатежа, d2.d) = 1
		WHERE p.ДатаПлатежа BETWEEN dateadd(yy, - 1, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE))
				AND dateadd(dd, - 1, dateadd(yy, - 1, cast(dateadd(m, datediff(m, - 1, getdate()), 0) AS DATE))) AND d1.dpd = 0;

	--curr_month
	INSERT INTO #stg_repbi_coll_pmt_eff
	SELECT p.код AS external_id
		,p.ДатаПлатежа AS pmt_dt
		,p.СуммаПлатежа AS pmt_amount
		,CASE WHEN d2.d IS NOT NULL THEN 1 ELSE 0 END AS dpd_1_flag
		,cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE) AS per
	FROM dm.CMRExpectedRepayments p
	LEFT JOIN reports.dbo.dm_CMRStatBalance_2 d1
		ON p.Код = d1.external_id AND datediff(day, p.ДатаПлатежа, d1.d) = - 1
	LEFT JOIN reports.dbo.dm_CMRStatBalance_2 d2
		ON p.Код = d2.external_id AND d2.dpd = 1 AND datediff(day, p.ДатаПлатежа, d2.d) = 1
	WHERE p.ДатаПлатежа BETWEEN cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE)
			AND cast(getdate() - 1 AS DATE) AND d1.dpd = 0;

	--month_ago
	INSERT INTO #stg_repbi_coll_pmt_eff
	SELECT p.код AS external_id
		,p.ДатаПлатежа AS pmt_dt
		,p.СуммаПлатежа AS pmt_amount
		,CASE WHEN d2.d IS NOT NULL THEN 1 ELSE 0 END AS dpd_1_flag
		,dateadd(mm, - 1, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE)) AS period
	FROM dm.CMRExpectedRepayments p
	LEFT JOIN reports.dbo.dm_CMRStatBalance_2 d1
		ON p.Код = d1.external_id AND datediff(day, p.ДатаПлатежа, d1.d) = - 1
	LEFT JOIN reports.dbo.dm_CMRStatBalance_2 d2
		ON p.Код = d2.external_id AND d2.dpd = 1 AND datediff(day, p.ДатаПлатежа, d2.d) = 1
	WHERE p.ДатаПлатежа BETWEEN dateadd(mm, - 1, cast(dateadd(m, datediff(m, 0, getdate()), 0) AS DATE))
			AND dateadd(dd, - 1, dateadd(mm, - 1, cast(dateadd(m, datediff(m, - 1, getdate()), 0) AS DATE))) AND d1.dpd = 0;

	DROP TABLE

	IF EXISTS #repbi_coll_pmt_efficiency;
		SELECT a.per
			,day(a.pmt_dt) AS day_num
			,sum(iif(a.dpd_1_flag = 0, 1, 0)) / cast(COUNT(*) AS FLOAT) AS val
		INTO #repbi_coll_pmt_efficiency
		FROM #stg_repbi_coll_pmt_eff a
		GROUP BY a.per
			,day(a.pmt_dt)
		ORDER BY 1
			,2;

	DELETE FROM risk.repbi_coll_pmt_efficiency;

	WITH src_1_week
	AS (
		SELECT '1 week' as week_num, per, avg(a.val) AS val
		FROM #repbi_coll_pmt_efficiency a
		WHERE day_num BETWEEN 1
				AND 7
				group by a.per
		)
		,src_2_week
	AS (
		SELECT '2 week' as week_num, per, avg(a.val) AS val
		FROM #repbi_coll_pmt_efficiency a
		WHERE day_num BETWEEN 8
				AND 14
				group by a.per
		)
		,src_3_week
	AS (
		SELECT '3 week' as week_num, per, avg(a.val) AS val
		FROM #repbi_coll_pmt_efficiency a
		WHERE day_num BETWEEN 15
				AND 21
				group by a.per
		)
		,src_4_week
	AS (
		SELECT '4 week' as week_num, per, avg(a.val) AS val
		FROM #repbi_coll_pmt_efficiency a
		WHERE day_num BETWEEN 22
				AND 28
				group by a.per
		)
	INSERT INTO risk.repbi_coll_pmt_efficiency
	SELECT CONCAT (
			datepart(yyyy, a.per)
			,CASE WHEN datepart(mm, a.per) < 10 THEN cast(CONCAT (
								'0'
								,datepart(mm, a.per)
								) AS VARCHAR) ELSE cast(datepart(mm, a.per) AS VARCHAR) END
			) AS rep_month
		,cast(FORMAT(a.per, 'MMM yyyy') AS VARCHAR) AS per
		,a.day_num
		,coalesce(s1.val, s2.val, s3.val, s4.val) AS val
		,'Среднее за неделю' as metric
	FROM #repbi_coll_pmt_efficiency a
	LEFT JOIN src_1_week s1
		ON a.day_num = 7 and s1.per=a.per
	LEFT JOIN src_2_week s2
		ON a.day_num = 14 and s2.per=a.per
	LEFT JOIN src_3_week s3
		ON a.day_num = 21 and s3.per=a.per
	LEFT JOIN src_4_week s4
		ON a.day_num = 28 and s4.per=a.per
		where a.day_num in (7,14,21,28);


	WITH src_month
	AS (
		SELECT a.per, avg(a.val) AS val
		FROM #repbi_coll_pmt_efficiency a
		group by a.per
		)
	INSERT INTO risk.repbi_coll_pmt_efficiency
	SELECT CONCAT (
			datepart(yyyy, a.per)
			,CASE WHEN datepart(mm, a.per) < 10 THEN cast(CONCAT (
								'0'
								,datepart(mm, a.per)
								) AS VARCHAR) ELSE cast(datepart(mm, a.per) AS VARCHAR) END
			) AS rep_month
		,cast(FORMAT(a.per, 'MMM yyyy') AS VARCHAR) AS per
		,a.day_num
		,s1.val
		,'Среднее за текущий месяц' as metric
	FROM #repbi_coll_pmt_efficiency a
	LEFT JOIN src_month s1
		ON s1.per=a.per;

	INSERT INTO risk.repbi_coll_pmt_efficiency
	SELECT CONCAT (
			datepart(yyyy, a.per)
			,CASE WHEN datepart(mm, a.per) < 10 THEN cast(CONCAT (
								'0'
								,datepart(mm, a.per)
								) AS VARCHAR) ELSE cast(datepart(mm, a.per) AS VARCHAR) END
			) AS rep_month
		,cast(FORMAT(a.per, 'MMM yyyy') AS VARCHAR) AS per
		,a.day_num
		,a.val
		,'Подневная статистика' as metric
	FROM #repbi_coll_pmt_efficiency a;

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
