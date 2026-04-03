
--EXEC [dwh2].[risk].[etl_spectrum_taxi]
CREATE PROCEDURE [risk].[etl_spectrum_taxi]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		EXEC risk.set_debug_info @sp_name
			,'[spectrum_used_in_taxi] START';

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
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #progress_ok;
			SELECT DISTINCT number
				,[values] AS progress_ok
			INTO #progress_ok
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_ok'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #progress_wait;
			SELECT DISTINCT number
				,[values] AS progress_wait
			INTO #progress_wait
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_wait'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #progress_error;
			SELECT DISTINCT number
				,[values] AS progress_error
			INTO #progress_error
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_error'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #sources_0_id;
			SELECT DISTINCT number
				,[values] AS sources_0_id
			INTO #sources_0_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:0'
				AND NAMES = '_id'
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #sources_0_id_state;
			SELECT DISTINCT number
				,[values] AS sources_0_id_state
			INTO #sources_0_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:0'
				AND NAMES = 'state'
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #sources_1_id;
			SELECT DISTINCT number
				,[values] AS sources_1_id
			INTO #sources_1_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:1'
				AND NAMES = '_id'
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #sources_1_id_state;
			SELECT DISTINCT number
				,[values] AS sources_1_id_state
			INTO #sources_1_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:1'
				AND NAMES = 'state'
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #sources_2_id;
			SELECT DISTINCT number
				,[values] AS sources_2_id
			INTO #sources_2_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:2'
				AND NAMES = '_id'
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #sources_2_id_state;
			SELECT DISTINCT number
				,[values] AS sources_2_id_state
			INTO #sources_2_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:2'
				AND NAMES = 'state'
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #requested_at;
			SELECT DISTINCT number
				,[values] AS requested_at
			INTO #requested_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'requested_at'
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #used_in_taxi;
			SELECT DISTINCT number
				,[values] AS used_in_taxi
			INTO #used_in_taxi
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:taxi'
				AND NAMES = 'used_in_taxi'
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #history_count;
			SELECT DISTINCT number
				,[values] AS history_count
			INTO #history_count
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:taxi:history'
				AND NAMES = 'count'
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #start_time
			SELECT DISTINCT number
				,[values] AS start_time
			INTO #start_time
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:last_generation_stat'
				AND NAMES = 'start_time'
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #complete_time
			SELECT DISTINCT number
				,[values] AS complete_time
			INTO #complete_time
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:last_generation_stat'
				AND NAMES = 'complete_time'
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #created_at;
			SELECT DISTINCT number
				,[values] AS created_at
			INTO #created_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'created_at'
				AND idReportBlock = 'report_taxi@carmoney';

		DROP TABLE

		IF EXISTS #updated_at;
			SELECT DISTINCT number
				,[values] AS updated_at
			INTO #updated_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'updated_at'
				AND idReportBlock = 'report_taxi@carmoney';

		BEGIN TRANSACTION

		TRUNCATE TABLE [dwh2].[risk].[spectrum_used_in_taxi];

		INSERT INTO [dwh2].[risk].[spectrum_used_in_taxi]
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
			,cast(a12.requested_at AS DATETIME) AS requested_at
			,a13.used_in_taxi
			,a14.history_count
			,cast(a15.start_time AS DATETIME) AS start_time
			,cast(a16.complete_time AS DATETIME) AS complete_time
			,cast(a17.created_at AS DATETIME) AS created_at
			,cast(a18.updated_at AS DATETIME) AS updated_at
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
		LEFT JOIN #requested_at a12 ON a1.number = a12.number
		LEFT JOIN #used_in_taxi a13 ON a1.number = a13.number
		LEFT JOIN #history_count a14 ON a1.number = a14.number
		LEFT JOIN #start_time a15 ON a1.number = a15.number
		LEFT JOIN #complete_time a16 ON a1.number = a16.number
		LEFT JOIN #created_at a17 ON a1.number = a17.number
		LEFT JOIN #updated_at a18 ON a1.number = a18.number;

		COMMIT TRANSACTION;

		EXEC risk.set_debug_info @sp_name
			,'[spectrum_content_taxi] START';

		DROP TABLE

		IF EXISTS #base_content_taxi;
			SELECT DISTINCT number
			INTO #base_content_taxi
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND number IS NOT NULL
				AND number IS NOT NULL AND number <> '19061300000088';

		CREATE UNIQUE INDEX base_content_taxi_idx ON #base_content_taxi (number);

		DROP TABLE

		IF EXISTS #vin_content_taxi;
			SELECT DISTINCT number
				,[values] AS VIN
			INTO #vin_content_taxi
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'vehicle_id'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #date_start;
			SELECT DISTINCT number
				,[values] AS date_start
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #date_start
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'start'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:date';

		DROP TABLE

		IF EXISTS #date_end;
			SELECT DISTINCT number
				,[values] AS date_end
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #date_end
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'end'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:date';

		DROP TABLE

		IF EXISTS #date_actual;
			SELECT DISTINCT number
				,[values] AS date_actual
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #date_actual
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'actual'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:date';

		DROP TABLE

		IF EXISTS #date_cancel;
			SELECT DISTINCT number
				,[values] AS date_cancel
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #date_cancel
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'cancel'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:date';

		DROP TABLE

		IF EXISTS #license_number;
			SELECT DISTINCT number
				,[values] AS license_number
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #license_number
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'number'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:license';

		DROP TABLE

		IF EXISTS #license_status;
			SELECT DISTINCT number
				,[values] AS license_status
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #license_status
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'status'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:license';

		DROP TABLE

		IF EXISTS #company_name;
			SELECT DISTINCT number
				,[values] AS company_name
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #company_name
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'name'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:company';

		DROP TABLE

		IF EXISTS #ogrn;
			SELECT DISTINCT number
				,[values] AS ogrn
				,SUBSTRING(parent, 40, 10) AS taxi_history
			INTO #ogrn
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'ogrn'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%';

		DROP TABLE

		IF EXISTS #tin;
			SELECT DISTINCT number
				,[values] AS tin
				,SUBSTRING(parent, 40, 10) AS taxi_history
			INTO #tin
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'tin'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%';

		DROP TABLE

		IF EXISTS #number_plate_is_yellow;
			SELECT DISTINCT number
				,[values] AS number_plate_is_yellow
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #number_plate_is_yellow
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'is_yellow'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:number_plate';

		DROP TABLE

		IF EXISTS #brand_name;
			SELECT DISTINCT number
				,[values] AS brand_name
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #brand_name
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'name'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:vehicle:brand';

		DROP TABLE

		IF EXISTS #color;
			SELECT DISTINCT number
				,[values] AS color
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #color
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'color'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:vehicle';

		DROP TABLE

		IF EXISTS #reg_num;
			SELECT DISTINCT number
				,[values] AS reg_num
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #reg_num
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'reg_num'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:vehicle';

		DROP TABLE

		IF EXISTS #year;
			SELECT DISTINCT number
				,[values] AS [year]
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #year
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'year'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:vehicle';

		DROP TABLE

		IF EXISTS #region;
			SELECT DISTINCT number
				,[values] AS [region]
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #region
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'code'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:region';

		DROP TABLE

		IF EXISTS #city;
			SELECT DISTINCT number
				,[values] AS city
				,cast(substring(SUBSTRING(parent, 40, 10), 1, CHARINDEX(':', SUBSTRING(parent, 40, 10)) - 1) AS INT) AS taxi_history
			INTO #city
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'name'
				AND number IS NOT NULL
				AND idReportBlock = 'report_taxi@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:taxi:history:items:%:city';

		CREATE CLUSTERED INDEX date_start_idx ON #date_start (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX date_end_idx ON #date_end (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX date_actual_idx ON #date_actual (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX date_cancel_idx ON #date_cancel (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX license_number_idx ON #license_number (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX license_status_idx ON #license_status (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX company_name_idx ON #company_name (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX ogrn_idx ON #ogrn (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX tin_idx ON #tin (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX number_plate_is_yellow_idx ON #number_plate_is_yellow (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX brand_name_idx ON #brand_name (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX color_idx ON #color (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX reg_num_idx ON #reg_num (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX year_idx ON #year (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX region_idx ON #region (
			number
			,taxi_history
			);

		CREATE CLUSTERED INDEX city_idx ON #city (
			number
			,taxi_history
			);

		BEGIN TRANSACTION

		TRUNCATE TABLE [dwh2].[risk].[spectrum_content_taxi];

		INSERT INTO [dwh2].[risk].[spectrum_content_taxi]
		SELECT a1.number
			,a2.vin
			,cast(a3.date_start AS DATE) AS date_start
			,a3.taxi_history
			,cast(a4.date_end AS DATE) AS date_end
			,cast(a5.date_actual AS DATE) AS date_actual
			,a6.date_cancel
			,a7.license_number
			,a8.license_status
			,a9.company_name
			,a10.ogrn
			,a11.tin
			,a12.number_plate_is_yellow
			,a13.brand_name
			,a14.color
			,a15.reg_num
			,a16.year
			,a17.region
			,a18.city
		FROM #base_content_taxi a1
		INNER JOIN #vin_content_taxi a2 ON a2.number = a1.number
		LEFT JOIN #date_start a3 ON a3.number = a1.number
		LEFT JOIN #date_end a4 ON a4.number = a1.number
			AND a4.taxi_history = a3.taxi_history
		LEFT JOIN #date_actual a5 ON a5.number = a1.number
			AND a5.taxi_history = a3.taxi_history
		LEFT JOIN #date_cancel a6 ON a6.number = a1.number
			AND a6.taxi_history = a3.taxi_history
		LEFT JOIN #license_number a7 ON a7.number = a1.number
			AND a7.taxi_history = a3.taxi_history
		LEFT JOIN #license_status a8 ON a8.number = a1.number
			AND a8.taxi_history = a3.taxi_history
		LEFT JOIN #company_name a9 ON a9.number = a1.number
			AND a9.taxi_history = a3.taxi_history
		LEFT JOIN #ogrn a10 ON a10.number = a1.number
			AND a10.taxi_history = a3.taxi_history
		LEFT JOIN #tin a11 ON a11.number = a1.number
			AND a11.taxi_history = a3.taxi_history
		LEFT JOIN #number_plate_is_yellow a12 ON a12.number = a1.number
			AND a12.taxi_history = a3.taxi_history
		LEFT JOIN #brand_name a13 ON a13.number = a1.number
			AND a13.taxi_history = a3.taxi_history
		LEFT JOIN #color a14 ON a14.number = a1.number
			AND a14.taxi_history = a3.taxi_history
		LEFT JOIN #reg_num a15 ON a15.number = a1.number
			AND a15.taxi_history = a3.taxi_history
		LEFT JOIN #year a16 ON a16.number = a1.number
			AND a16.taxi_history = a3.taxi_history
		LEFT JOIN #region a17 ON a17.number = a1.number
			AND a17.taxi_history = a3.taxi_history
		LEFT JOIN #city a18 ON a18.number = a1.number
			AND a18.taxi_history = a3.taxi_history;

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
