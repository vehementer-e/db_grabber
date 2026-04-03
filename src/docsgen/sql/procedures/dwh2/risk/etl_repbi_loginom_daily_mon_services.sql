
--exec [risk].[etl_repbi_loginom_daily_mon_services];
CREATE PROCEDURE [risk].[etl_repbi_loginom_daily_mon_services]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		EXEC risk.set_debug_info @sp_name
			,'START';

		DROP TABLE

		IF EXISTS #src_loginom_monitoring;
			SELECT a.request_date
				,a.person_id
				,a.json
				,CASE 
					WHEN a.source LIKE '%bankrupts%'
						THEN 'Bankrupts'
					WHEN a.source LIKE '%checkFile%'
						THEN 'CheckFile'
					WHEN a.source LIKE '%equifax%'
						THEN 'Equifax'
					WHEN a.source LIKE '%ExchangeRates%'
						THEN 'ExchangeRates'
					WHEN a.source LIKE '%fincard%'
						THEN 'Fincard'
					WHEN a.source LIKE '%fms%'
						THEN 'FMS'
					WHEN a.source LIKE '%fnp%'
						THEN 'FNP'
					WHEN a.source LIKE '%fssp%'
						THEN 'FSSP'
					WHEN a.source LIKE '%gibdd%'
						THEN 'GIBDD'
					WHEN a.source LIKE '%okbscore%'
						THEN 'Okbscore'
					WHEN a.source LIKE '%qiwi%'
						THEN 'Qiwi'
					WHEN a.source LIKE '%rsa%'
						THEN 'RSA'
					WHEN a.source LIKE '%spectrum%'
						THEN 'Spectrum'
					WHEN a.source LIKE '%xneo%'
						THEN 'Xneo'
					ELSE a.source
					END AS source
				,a.ErrorID
				,a.validReport_flg
			INTO #src_loginom_monitoring
			FROM stg._loginom.Original_response a
			WHERE cast(a.request_date AS DATE) = dateadd(dd, - 1, cast(getdate() AS DATE))
				AND a.process <> 'Monitoring'
				AND source NOT IN ('fms', 'equifax', 'okbscore', 'nbch PV2 score', 'ExchangeRates', 'DBrain', 'photosByRequest', 'nbch')
			ORDER BY a.request_date;

		DROP TABLE

		IF EXISTS #src_loginom_monitoring_row_num;
			SELECT a.*
				,ROW_NUMBER() OVER (
					PARTITION BY a.source ORDER BY a.request_date DESC
					) AS rn_source
				,CASE 
					WHEN a.[JSON] IS NULL
						OR substring(a.[JSON], 1, 5) = ''
						OR a.ErrorID > 0
						OR a.validReport_flg = 0
						THEN 1
					ELSE 0
					END AS error_flag
			INTO #src_loginom_monitoring_row_num
			FROM #src_loginom_monitoring a
			WHERE source NOT IN ('fms', 'equifax', 'okbscore', 'nbch PV2 score', 'ExchangeRates', 'DBrain', 'photosByRequest', 'nbch');

		DROP TABLE

		IF EXISTS #trigger_src;
			SELECT cast(request_date AS DATE) AS request_date
				,source
				,count(*) AS cnt
				,sum(error_flag) AS summ_err_flag
				,sum(error_flag) / cast(count(*) AS FLOAT) AS prc
			INTO #trigger_src
			FROM #src_loginom_monitoring_row_num
			GROUP BY source
				,cast(request_date AS DATE)
			ORDER BY 1;

		DELETE
		FROM risk.repbi_loginom_daily_mon_services
		WHERE request_date = dateadd(dd, - 1, cast(getdate() AS DATE))
		OR request_date <= dateadd(dd, - 30, cast(getdate() AS DATE))

		INSERT INTO risk.repbi_loginom_daily_mon_services
		SELECT *
		FROM #trigger_src;

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
			,@recipients = 'risk-technology@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;
