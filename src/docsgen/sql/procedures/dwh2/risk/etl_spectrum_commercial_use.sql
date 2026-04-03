
--EXEC [dwh2].[risk].[etl_spectrum_commercial_use]
CREATE PROCEDURE [risk].[etl_spectrum_commercial_use]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		EXEC risk.set_debug_info @sp_name
			,'[spectrum_commercial_use] START';

		DROP TABLE

		IF EXISTS #base;
			SELECT DISTINCT number
			INTO #base
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND number IS NOT NULL
				AND number IS NOT NULL AND number <> '19061300000088';

		DROP TABLE

		IF EXISTS #vin;
			SELECT DISTINCT number
				,[values] AS VIN
			INTO #vin
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'vehicle_id'
				AND number IS NOT NULL
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #progress_ok;
			SELECT DISTINCT number
				,[values] AS progress_ok
			INTO #progress_ok
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_ok'
				AND number IS NOT NULL
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #progress_wait;
			SELECT DISTINCT number
				,[values] AS progress_wait
			INTO #progress_wait
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_wait'
				AND number IS NOT NULL
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #progress_error;
			SELECT DISTINCT number
				,[values] AS progress_error
			INTO #progress_error
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_error'
				AND number IS NOT NULL
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #sources_0_id;
			SELECT DISTINCT number
				,[values] AS sources_0_id
			INTO #sources_0_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:0'
				AND NAMES = '_id'
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #sources_0_id_state;
			SELECT DISTINCT number
				,[values] AS sources_0_id_state
			INTO #sources_0_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:0'
				AND NAMES = 'state'
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #sources_1_id;
			SELECT DISTINCT number
				,[values] AS sources_1_id
			INTO #sources_1_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:1'
				AND NAMES = '_id'
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #sources_1_id_state;
			SELECT DISTINCT number
				,[values] AS sources_1_id_state
			INTO #sources_1_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:1'
				AND NAMES = 'state'
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #requested_at;
			SELECT DISTINCT number
				,[values] AS requested_at
			INTO #requested_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'requested_at'
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #count;
			SELECT DISTINCT number
				,[values] AS count
			INTO #count
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:commercial_use'
				AND NAMES = 'count'
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #date_update;
			SELECT DISTINCT number
				,[values] AS date_update
			INTO #date_update
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:commercial_use:date'
				AND NAMES = 'update'
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #start_time
			SELECT DISTINCT number
				,[values] AS start_time
			INTO #start_time
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:last_generation_stat'
				AND NAMES = 'start_time'
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #complete_time
			SELECT DISTINCT number
				,[values] AS complete_time
			INTO #complete_time
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:last_generation_stat'
				AND NAMES = 'complete_time'
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #created_at;
			SELECT DISTINCT number
				,[values] AS created_at
			INTO #created_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'created_at'
				AND idReportBlock = 'report_commercial_use@carmoney';

		DROP TABLE

		IF EXISTS #updated_at;
			SELECT DISTINCT number
				,[values] AS updated_at
			INTO #updated_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'updated_at'
				AND idReportBlock = 'report_commercial_use@carmoney';

		BEGIN TRANSACTION;

		TRUNCATE TABLE risk.spectrum_commercial_use;

		INSERT INTO risk.spectrum_commercial_use
		SELECT a1.number
			,a2.vin
			,a3.progress_ok
			,a4.progress_wait
			,a5.progress_error
			,a6.sources_0_id
			,a7.sources_0_id_state
			,a8.sources_1_id
			,a9.sources_1_id_state
			,cast(a10.requested_at AS DATETIME) AS requested_at
			,a11.count
			,cast(a12.date_update AS DATETIME) AS date_update
			,cast(a13.start_time AS DATETIME) AS start_time
			,cast(a14.complete_time AS DATETIME) AS complete_time
			,cast(a15.created_at AS DATETIME) AS created_at
			,cast(a16.updated_at AS DATETIME) AS updated_at
		FROM #base a1
		LEFT JOIN #vin a2 ON a1.number = a2.number
		LEFT JOIN #progress_ok a3 ON a1.number = a3.number
		LEFT JOIN #progress_wait a4 ON a1.number = a4.number
		LEFT JOIN #progress_error a5 ON a1.number = a5.number
		LEFT JOIN #sources_0_id a6 ON a1.number = a6.number
		LEFT JOIN #sources_0_id_state a7 ON a1.number = a7.number
		LEFT JOIN #sources_1_id a8 ON a1.number = a8.number
		LEFT JOIN #sources_1_id_state a9 ON a1.number = a9.number
		LEFT JOIN #requested_at a10 ON a1.number = a10.number
		LEFT JOIN #count a11 ON a1.number = a11.number
		LEFT JOIN #date_update a12 ON a1.number = a12.number
		LEFT JOIN #start_time a13 ON a1.number = a13.number
		LEFT JOIN #complete_time a14 ON a1.number = a14.number
		LEFT JOIN #created_at a15 ON a1.number = a15.number
		LEFT JOIN #updated_at a16 ON a1.number = a16.number;

		COMMIT TRANSACTION;

		EXEC risk.set_debug_info @sp_name
			,'[spectrum_content_commercial_use] START';

		DROP TABLE

		IF EXISTS #base_content_commercial_use;
			SELECT DISTINCT number
			INTO #base_content_commercial_use
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND number IS NOT NULL
				AND number IS NOT NULL AND number <> '19061300000088';

		CREATE UNIQUE INDEX base_content_commercial_use_idx ON #base_content_commercial_use (number);

		DROP TABLE

		IF EXISTS #vin_content_commercial_use;
			SELECT DISTINCT number
				,[values] AS VIN
			INTO #vin_content_commercial_use
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'vehicle_id'
				AND number IS NOT NULL
				AND idReportBlock = 'report_commercial_use@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #service_name;
			SELECT DISTINCT number
				,[values] AS [service_name]
				,cast(substring(SUBSTRING(parent, 42, 10), 1, CHARINDEX(':', SUBSTRING(parent, 42, 10)) - 1) AS INT) AS comm_use_history
			INTO #service_name
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'name'
				AND number IS NOT NULL
				AND idReportBlock = 'report_commercial_use@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:commercial_use:items:%:service';

		DROP TABLE

		IF EXISTS #service_url;
			SELECT DISTINCT number
				,[values] AS [service_url]
				,cast(substring(SUBSTRING(parent, 42, 10), 1, CHARINDEX(':', SUBSTRING(parent, 42, 10)) - 1) AS INT) AS comm_use_history
			INTO #service_url
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'url'
				AND number IS NOT NULL
				AND idReportBlock = 'report_commercial_use@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:commercial_use:items:%:service';

		DROP TABLE

		IF EXISTS #company_name;
			SELECT DISTINCT number
				,[values] AS company_name
				,cast(substring(SUBSTRING(parent, 42, 10), 1, CHARINDEX(':', SUBSTRING(parent, 42, 10)) - 1) AS INT) AS comm_use_history
			INTO #company_name
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'name'
				AND number IS NOT NULL
				AND idReportBlock = 'report_commercial_use@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:commercial_use:items:%:company';

		DROP TABLE

		IF EXISTS #company_tin;
			SELECT DISTINCT number
				,[values] AS company_tin
				,cast(substring(SUBSTRING(parent, 42, 10), 1, CHARINDEX(':', SUBSTRING(parent, 42, 10)) - 1) AS INT) AS comm_use_history
			INTO #company_tin
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'tin'
				AND number IS NOT NULL
				AND idReportBlock = 'report_commercial_use@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:commercial_use:items:%:company';

		DROP TABLE

		IF EXISTS #company_type;
			SELECT DISTINCT number
				,[values] AS company_type
				,cast(substring(SUBSTRING(parent, 42, 10), 1, CHARINDEX(':', SUBSTRING(parent, 42, 10)) - 1) AS INT) AS comm_use_history
			INTO #company_type
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'type'
				AND number IS NOT NULL
				AND idReportBlock = 'report_commercial_use@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:commercial_use:items:%:company';

		BEGIN TRANSACTION;

		TRUNCATE TABLE risk.spectrum_content_commercial_use;

		INSERT INTO risk.spectrum_content_commercial_use
		SELECT a1.number
			,a2.vin
			,a3.comm_use_history
			,a3.company_name
			,a4.company_tin
			,a5.company_type
			,a6.service_name
			,a7.service_url
		FROM #base_content_commercial_use a1
		INNER JOIN #vin_content_commercial_use a2 ON a2.number = a1.number
		LEFT JOIN #company_name a3 ON a2.number = a3.number
		LEFT JOIN #company_tin a4 ON a4.number = a3.number
			AND a4.comm_use_history = a3.comm_use_history
		LEFT JOIN #company_type a5 ON a5.number = a3.number
			AND a5.comm_use_history = a3.comm_use_history
		LEFT JOIN #service_name a6 ON a6.number = a3.number
			AND a6.comm_use_history = a3.comm_use_history
		LEFT JOIN #service_url a7 ON a7.number = a3.number
			AND a7.comm_use_history = a3.comm_use_history;

		COMMIT TRANSACTION;

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
			,@recipients = 'a.kuznecov@techmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END
