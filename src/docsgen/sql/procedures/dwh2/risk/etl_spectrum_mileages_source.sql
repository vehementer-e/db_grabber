
--EXEC [dwh2].[risk].[etl_spectrum_mileages_source]
CREATE PROCEDURE [risk].[etl_spectrum_mileages_source]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		EXEC risk.set_debug_info @sp_name
			,'[spectrum_mileages_source] START';

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
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #progress_ok;
			SELECT DISTINCT number
				,[values] AS progress_ok
			INTO #progress_ok
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_ok'
				AND number IS NOT NULL
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #progress_wait;
			SELECT DISTINCT number
				,[values] AS progress_wait
			INTO #progress_wait
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_wait'
				AND number IS NOT NULL
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #progress_error;
			SELECT DISTINCT number
				,[values] AS progress_error
			INTO #progress_error
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_error'
				AND number IS NOT NULL
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_0_id;
			SELECT DISTINCT number
				,[values] AS sources_0_id
			INTO #sources_0_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:0'
				AND NAMES = '_id'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_0_id_state;
			SELECT DISTINCT number
				,[values] AS sources_0_id_state
			INTO #sources_0_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:0'
				AND NAMES = 'state'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_1_id;
			SELECT DISTINCT number
				,[values] AS sources_1_id
			INTO #sources_1_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:1'
				AND NAMES = '_id'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_1_id_state;
			SELECT DISTINCT number
				,[values] AS sources_1_id_state
			INTO #sources_1_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:1'
				AND NAMES = 'state'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_2_id;
			SELECT DISTINCT number
				,[values] AS sources_2_id
			INTO #sources_2_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:2'
				AND NAMES = '_id'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_2_id_state;
			SELECT DISTINCT number
				,[values] AS sources_2_id_state
			INTO #sources_2_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:2'
				AND NAMES = 'state'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_3_id;
			SELECT DISTINCT number
				,[values] AS sources_3_id
			INTO #sources_3_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:3'
				AND NAMES = '_id'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_3_id_state;
			SELECT DISTINCT number
				,[values] AS sources_3_id_state
			INTO #sources_3_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:3'
				AND NAMES = 'state'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_4_id;
			SELECT DISTINCT number
				,[values] AS sources_4_id
			INTO #sources_4_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:4'
				AND NAMES = '_id'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_4_id_state;
			SELECT DISTINCT number
				,[values] AS sources_4_id_state
			INTO #sources_4_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:4'
				AND NAMES = 'state'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_5_id;
			SELECT DISTINCT number
				,[values] AS sources_5_id
			INTO #sources_5_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:5'
				AND NAMES = '_id'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_5_id_state;
			SELECT DISTINCT number
				,[values] AS sources_5_id_state
			INTO #sources_5_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:5'
				AND NAMES = 'state'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_6_id;
			SELECT DISTINCT number
				,[values] AS sources_6_id
			INTO #sources_6_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:6'
				AND NAMES = '_id'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_6_id_state;
			SELECT DISTINCT number
				,[values] AS sources_6_id_state
			INTO #sources_6_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:6'
				AND NAMES = 'state'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_7_id;
			SELECT DISTINCT number
				,[values] AS sources_7_id
			INTO #sources_7_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:7'
				AND NAMES = '_id'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_7_id_state;
			SELECT DISTINCT number
				,[values] AS sources_7_id_state
			INTO #sources_7_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:7'
				AND NAMES = 'state'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_8_id;
			SELECT DISTINCT number
				,[values] AS sources_8_id
			INTO #sources_8_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:8'
				AND NAMES = '_id'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_8_id_state;
			SELECT DISTINCT number
				,[values] AS sources_8_id_state
			INTO #sources_8_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:8'
				AND NAMES = 'state'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_9_id;
			SELECT DISTINCT number
				,[values] AS sources_9_id
			INTO #sources_9_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:9'
				AND NAMES = '_id'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #sources_9_id_state;
			SELECT DISTINCT number
				,[values] AS sources_9_id_state
			INTO #sources_9_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:9'
				AND NAMES = 'state'
				AND idReportBlock = 'report_mileages@carmoney';

		--
		DROP TABLE

		IF EXISTS #requested_at;
			SELECT DISTINCT number
				,[values] AS requested_at
			INTO #requested_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'requested_at'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #count;
			SELECT DISTINCT number
				,[values] AS count
			INTO #count
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:commercial_use'
				AND NAMES = 'count'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #start_time
			SELECT DISTINCT number
				,[values] AS start_time
			INTO #start_time
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:last_generation_stat'
				AND NAMES = 'start_time'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #complete_time
			SELECT DISTINCT number
				,[values] AS complete_time
			INTO #complete_time
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:last_generation_stat'
				AND NAMES = 'complete_time'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #created_at;
			SELECT DISTINCT number
				,[values] AS created_at
			INTO #created_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'created_at'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #updated_at;
			SELECT DISTINCT number
				,[values] AS updated_at
			INTO #updated_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'updated_at'
				AND idReportBlock = 'report_mileages@carmoney';

		DROP TABLE

		IF EXISTS #date_update;
			SELECT DISTINCT number
				,[values] AS date_update
			INTO #date_update
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:commercial_use:date'
				AND NAMES = 'update'
				AND idReportBlock = 'report_mileages@carmoney';

		BEGIN TRANSACTION;

		TRUNCATE TABLE risk.spectrum_mileages_source;

		INSERT INTO risk.spectrum_mileages_source
		SELECT a1.number
			,a2.vin
			,a3.progress_ok
			,a4.progress_wait
			,a5.progress_error
			,a6.sources_0_id
			,a7.sources_0_id_state
			,a8.sources_1_id
			,a9.sources_1_id_state
			,a10.sources_2_id
			,a11.sources_2_id_state
			,a12.sources_3_id
			,a13.sources_3_id_state
			,a14.sources_4_id
			,a15.sources_4_id_state
			,a16.sources_5_id
			,a17.sources_5_id_state
			,a18.sources_6_id
			,a19.sources_6_id_state
			,a20.sources_7_id
			,a21.sources_7_id_state
			,a22.sources_8_id
			,a23.sources_8_id_state
			,a24.sources_9_id
			,a25.sources_9_id_state
			,cast(a26.requested_at AS DATETIME) AS requested_at
			,a27.count
			,cast(a28.date_update AS DATETIME) AS date_update
			,cast(a29.start_time AS DATETIME) AS start_time
			,cast(a30.complete_time AS DATETIME) AS complete_time
			,cast(a31.created_at AS DATETIME) AS created_at
			,cast(a32.updated_at AS DATETIME) AS updated_at
		FROM #base a1
		LEFT JOIN #vin a2 ON a1.number = a2.number
		LEFT JOIN #progress_ok a3 ON a1.number = a3.number
		LEFT JOIN #progress_wait a4 ON a1.number = a4.number
		LEFT JOIN #progress_error a5 ON a1.number = a5.number
		LEFT JOIN #sources_0_id a6 ON a1.number = a6.number
		LEFT JOIN #sources_0_id_state a7 ON a1.number = a7.number
		LEFT JOIN #sources_1_id a8 ON a1.number = a8.number
		LEFT JOIN #sources_1_id_state a9 ON a1.number = a9.number
		LEFT JOIN #sources_2_id a10 ON a1.number = a10.number
		LEFT JOIN #sources_2_id_state a11 ON a1.number = a11.number
		LEFT JOIN #sources_3_id a12 ON a1.number = a12.number
		LEFT JOIN #sources_3_id_state a13 ON a1.number = a13.number
		LEFT JOIN #sources_4_id a14 ON a1.number = a14.number
		LEFT JOIN #sources_4_id_state a15 ON a1.number = a15.number
		LEFT JOIN #sources_5_id a16 ON a1.number = a16.number
		LEFT JOIN #sources_5_id_state a17 ON a1.number = a17.number
		LEFT JOIN #sources_6_id a18 ON a1.number = a18.number
		LEFT JOIN #sources_6_id_state a19 ON a1.number = a19.number
		LEFT JOIN #sources_7_id a20 ON a1.number = a20.number
		LEFT JOIN #sources_7_id_state a21 ON a1.number = a21.number
		LEFT JOIN #sources_8_id a22 ON a1.number = a22.number
		LEFT JOIN #sources_8_id_state a23 ON a1.number = a23.number
		LEFT JOIN #sources_9_id a24 ON a1.number = a24.number
		LEFT JOIN #sources_9_id_state a25 ON a1.number = a25.number
		LEFT JOIN #requested_at a26 ON a1.number = a26.number
		LEFT JOIN #count a27 ON a1.number = a27.number
		LEFT JOIN #date_update a28 ON a1.number = a28.number
		LEFT JOIN #start_time a29 ON a1.number = a29.number
		LEFT JOIN #complete_time a30 ON a1.number = a30.number
		LEFT JOIN #created_at a31 ON a1.number = a31.number
		LEFT JOIN #updated_at a32 ON a1.number = a32.number;

		COMMIT TRANSACTION;

		EXEC risk.set_debug_info @sp_name
			,'[spectrum_mileages] START';

		DROP TABLE

		IF EXISTS #base_mileages;
			SELECT DISTINCT number
			INTO #base_mileages
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND number IS NOT NULL
				AND number IS NOT NULL AND number <> '19061300000088';

		CREATE UNIQUE INDEX base_mileages_idx ON #base_mileages (number);

		DROP TABLE

		IF EXISTS #vin_mileages;
			SELECT DISTINCT number
				,[values] AS VIN
			INTO #vin_mileages
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'vehicle_id'
				AND number IS NOT NULL
				AND idReportBlock = 'report_mileages@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		CREATE INDEX vin_mileages_idx ON #vin_mileages (number);

		DROP TABLE

		IF EXISTS #row;
			SELECT DISTINCT number
				,cast(substring(SUBSTRING(parent, 36, 10), 1, CHARINDEX(':', SUBSTRING(parent, 36, 10)) - 1) AS INT) AS [row]
			INTO #row
			FROM stg._loginom.Origination_spectrum_parse
			WHERE number IS NOT NULL
				AND idReportBlock = 'report_mileages@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:mileages:items:%:%'

		DROP TABLE

		IF EXISTS #date_event;
			SELECT DISTINCT number
				,[values] AS date_event
				,cast(substring(SUBSTRING(parent, 36, 10), 1, CHARINDEX(':', SUBSTRING(parent, 36, 10)) - 1) AS INT) AS [row]
			INTO #date_event
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'event'
				AND number IS NOT NULL
				AND idReportBlock = 'report_mileages@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:mileages:items:%:date';

		DROP TABLE

		IF EXISTS #mileage;
			SELECT DISTINCT number
				,[values] AS mileage
				,cast(SUBSTRING(parent, 36, 10) AS INT) AS [row]
			INTO #mileage
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'mileage'
				AND number IS NOT NULL
				AND idReportBlock = 'report_mileages@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:mileages:items:%';

		DROP TABLE

		IF EXISTS #filled_by_source;
			SELECT DISTINCT number
				,[values] AS filled_by_source
				,cast(substring(SUBSTRING(parent, 36, 10), 1, CHARINDEX(':', SUBSTRING(parent, 36, 10)) - 1) AS INT) AS [row]
			INTO #filled_by_source
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'source'
				AND number IS NOT NULL
				AND idReportBlock = 'report_mileages@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:mileages:items:%:filled_by';

		DROP TABLE

		IF EXISTS #actuality_date;
			SELECT DISTINCT number
				,[values] AS actuality_date
				,cast(substring(SUBSTRING(parent, 36, 10), 1, CHARINDEX(':', SUBSTRING(parent, 36, 10)) - 1) AS INT) AS [row]
			INTO #actuality_date
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'date'
				AND number IS NOT NULL
				AND idReportBlock = 'report_mileages@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:mileages:items:0:actuality';

		CREATE CLUSTERED INDEX actuality_date_idx ON #row (
			number
			,row
			);

		CREATE CLUSTERED INDEX row_idx ON #date_event (
			number
			,row
			);

		CREATE CLUSTERED INDEX date_event_idx ON #mileage (
			number
			,row
			);

		CREATE CLUSTERED INDEX mileage_idx ON #filled_by_source (
			number
			,row
			);

		CREATE CLUSTERED INDEX filled_by_source_idx ON #actuality_date (
			number
			,row
			);

		BEGIN TRANSACTION

		TRUNCATE TABLE risk.spectrum_mileage

		INSERT INTO risk.spectrum_mileage
		SELECT a1.number
			,a2.vin
			,a3.row
			,a4.date_event
			,a5.mileage
			,a6.filled_by_source
			,a7.actuality_date
		FROM #base_mileages a1
		LEFT JOIN #vin_mileages a2 ON a1.number = a2.number
		INNER JOIN #row a3 ON a3.number = a1.number
		LEFT JOIN #date_event a4 ON a4.number = a1.number
			AND a4.row = a3.row
		LEFT JOIN #mileage a5 ON a5.number = a1.number
			AND a5.row = a3.row
		LEFT JOIN #filled_by_source a6 ON a6.number = a1.number
			AND a6.row = a3.row
		LEFT JOIN #actuality_date a7 ON a7.number = a1.number
			AND a7.row = a3.row

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
