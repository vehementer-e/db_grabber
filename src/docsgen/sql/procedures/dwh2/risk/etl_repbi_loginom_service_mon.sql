
--exec [risk].[etl_repbi_loginom_service_mon];

CREATE PROCEDURE [risk].[etl_repbi_loginom_service_mon]
AS


BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY

	DROP TABLE

	IF EXISTS #repbi_loginom_service_mon_err;
		CREATE TABLE #repbi_loginom_service_mon_err (
			[dt] [date] NULL
			,[source] [nvarchar](50) NULL
			,[process] [nvarchar](50) NULL
			,[stage] [nvarchar](50) NULL
			,[number] [bigint] NULL
			,[JSON] [varchar](50) NULL
			) ON [PRIMARY];

    INSERT INTO #repbi_loginom_service_mon_err
		SELECT cast(a.request_date AS DATE) AS dt
			,a.source
			,a.process
			,a.stage
			,a.person_id AS number
			,substring(a.JSON, 1, 50) AS JSON
		FROM stg._loginom.Original_response a
		WHERE cast(a.request_date AS DATE) >= cast(getdate() - 21 AS DATE) AND a.process <> 'Call0';


	CREATE INDEX repbi_loginom_service_mon_err_idx ON #repbi_loginom_service_mon_err (
		number
		,stage
		,source
		)

	TRUNCATE TABLE risk.repbi_loginom_service_mon;

	INSERT INTO risk.repbi_loginom_service_mon
	SELECT DISTINCT a.dt
		,a.number
		,upper(a.source)
		,a.process
		,a.stage
		--,b.strategy_version
		,null as strategy_version
		,c.errorcode AS errorcode
		,CASE WHEN c.errorcode > 0 
				OR substring(a.json, 1, 5) = 'ERROR' 
				OR substring(a.json, 1, 37) = 'COULD NOT GET A UNITED CREDIT HISTORY' 
				OR substring(a.json, 11, 30) = 'Day limit of requests exceeded' 
				OR substring(a.json, 1, 19) = 'Ошибка HTTP-клиента'
					THEN 1 ELSE 0 END AS error_flg
		,CASE WHEN c.errorcode <> 0 THEN substring(c.ErrorDesc, 1, 19) 
			  WHEN a.json IS NULL or substring([JSON], 1, 5) = '' THEN 'Нет ответа' 
			  WHEN substring(a.json, 1, 5) = 'ERROR' THEN 'Service error' 
			  WHEN substring(a.json, 1, 37) = 'COULD NOT GET A UNITED CREDIT HISTORY' THEN 'Could not get OKI' 
			  WHEN substring(a.json, 11, 30) = 'Day limit of requests exceeded' THEN 'Limit exceeded' 
			  WHEN  substring(a.json, 1, 19) = 'Ошибка HTTP-клиента' then 'Ошибка HTTP-клиента'
			    ELSE 'Success' END AS error_code
	FROM #repbi_loginom_service_mon_err a
	--LEFT JOIN stg._loginom.Originationlog b
	--	ON a.number = b.number AND a.stage = b.stage
	LEFT JOIN stg._loginom.source_error c 
		ON a.number = c.number AND a.stage = c.stage AND a.source = c.sourcename
	WHERE 1=0

	UNION
	
	SELECT DISTINCT cast(DATETIME AS DATE) AS dt
		,cc.number
		,upper(cc.sourcename) AS source
		,'Origination' AS process
		,cc.stage
		--,b.strategy_version
		,null as strategy_version
		,cc.errorcode
		,1 AS error_flg
		,CASE WHEN cc.errorcode IN (6, 7) THEN substring(cc.ErrorDesc, 1, 19) ELSE 'NA' END AS error_code
	FROM stg._loginom.source_error cc
	--LEFT JOIN stg._loginom.Originationlog b
	--	ON cc.number = b.number AND cc.stage = b.stage
	WHERE cc.errorCode <> 0 AND cast(DATETIME AS DATE) >= cast(getdate() - 21 AS DATE) AND cast(DATETIME AS DATE) <= cast(getdate() - 1 AS DATE)
	AND 1=0;

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
			,@recipients = 'risk-technology@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject
		;throw 51000, @msg, 1
	END CATCH
END;
