
--EXEC [risk].[etl_spectrum_report_documents]
CREATE PROCEDURE [risk].[etl_spectrum_report_documents]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		EXEC risk.set_debug_info @sp_name
			,'[spectrum_documents] START';

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
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #progress_ok;
			SELECT DISTINCT number
				,[values] AS progress_ok
			INTO #progress_ok
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_ok'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #progress_wait;
			SELECT DISTINCT number
				,[values] AS progress_wait
			INTO #progress_wait
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_wait'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #progress_error;
			SELECT DISTINCT number
				,[values] AS progress_error
			INTO #progress_error
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_error'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #sources_0_id;
			SELECT DISTINCT number
				,[values] AS sources_0_id
			INTO #sources_0_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:0'
				AND NAMES = '_id'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #sources_0_id_state;
			SELECT DISTINCT number
				,[values] AS sources_0_id_state
			INTO #sources_0_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:0'
				AND NAMES = 'state'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #pts;
			SELECT DISTINCT number
				,[values] AS pts
			INTO #pts
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:identifiers:vehicle'
				AND NAMES = 'pts'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #masked_pts;
			SELECT DISTINCT number
				,[values] AS masked_pts
			INTO #masked_pts
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:identifiers_masked:vehicle'
				AND NAMES = 'pts'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #engine_number;
			SELECT DISTINCT number
				,[values] AS engine_number
			INTO #engine_number
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:tech_data:engine'
				AND NAMES = 'number'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #engine_model;
			SELECT DISTINCT number
				,[values] AS engine_model
			INTO #engine_model
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:tech_data:engine:model'
				AND NAMES = 'name'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #tech_date_update;
			SELECT DISTINCT number
				,[values] AS tech_date_update
			INTO #tech_date_update
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:tech_data:date'
				AND NAMES = 'update'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #pts_date;
			SELECT DISTINCT number
				,[values] AS pts_date
			INTO #pts_date
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:additional_info:vehicle:passport:date'
				AND NAMES = 'receive'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #has_dublicate;
			SELECT DISTINCT number
				,[values] AS has_dublicate
			INTO #has_dublicate
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:additional_info:vehicle:passport'
				AND NAMES = 'has_dublicate'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #passport_number;
			SELECT DISTINCT number
				,[values] AS passport_number
			INTO #passport_number
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:additional_info:vehicle:passport'
				AND NAMES = 'number'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #sts_date;
			SELECT DISTINCT number
				,[values] AS sts_date
			INTO #sts_date
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:additional_info:vehicle:sts:date'
				AND NAMES = 'receive'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #was_modificated;
			SELECT DISTINCT number
				,[values] AS was_modificated
			INTO #was_modificated
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:additional_info:vehicle:modifications'
				AND NAMES = 'was_modificated'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #exported;
			SELECT DISTINCT number
				,[values] AS exported
			INTO #exported
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:additional_info:vehicle'
				AND NAMES = 'exported'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #was_utilized;
			SELECT DISTINCT number
				,[values] AS was_utilized
			INTO #was_utilized
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:utilizations'
				AND NAMES = 'was_utilized'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #utilizations_count;
			SELECT DISTINCT number
				,[values] AS utilizations_count
			INTO #utilizations_count
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:utilizations'
				AND NAMES = 'count'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #utilization_date_update;
			SELECT DISTINCT number
				,[values] AS utilization_date_update
			INTO #utilization_date_update
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:utilizations:date'
				AND NAMES = 'update'
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #start_time
			SELECT DISTINCT number
				,[values] AS start_time
			INTO #start_time
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:last_generation_stat'
				AND NAMES = 'start_time'
				AND idReportBlock = 'report_documents@carmoney';

		DROP TABLE

		IF EXISTS #complete_time
			SELECT DISTINCT number
				,[values] AS complete_time
			INTO #complete_time
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:last_generation_stat'
				AND NAMES = 'complete_time'
				AND idReportBlock = 'report_documents@carmoney';

		DROP TABLE

		IF EXISTS #created_at;
			SELECT DISTINCT number
				,[values] AS created_at
			INTO #created_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'created_at'
				AND idReportBlock = 'report_documents@carmoney';

		DROP TABLE

		IF EXISTS #updated_at;
			SELECT DISTINCT number
				,[values] AS updated_at
			INTO #updated_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'updated_at'
				AND idReportBlock = 'report_documents@carmoney';

		BEGIN TRANSACTION;

		TRUNCATE TABLE risk.spectrum_documents;

		INSERT INTO risk.spectrum_documents
		SELECT a1.number
			,a2.vin
			,a3.progress_ok
			,a4.progress_wait
			,a5.progress_error
			,a6.sources_0_id
			,a7.sources_0_id_state
			,a8.pts
			,a9.masked_pts
			,a10.engine_number
			,a11.engine_model
			,a12.tech_date_update
			,cast(a13.pts_date AS DATE) AS pts_date
			,a14.has_dublicate
			,a15.passport_number
			,a16.sts_date
			,a17.was_modificated
			,a18.exported
			,a19.was_utilized
			,a20.utilizations_count
			,a21.utilization_date_update
			,cast(a22.start_time AS DATETIME) AS start_time
			,cast(a23.complete_time AS DATETIME) AS complete_time
			,cast(a24.created_at AS DATETIME) AS created_at
			,cast(a25.updated_at AS DATETIME) AS updated_at
		FROM #base a1
		LEFT JOIN #vin a2 ON a2.number = a1.number
		LEFT JOIN #progress_ok a3 ON a3.number = a1.number
		LEFT JOIN #progress_wait a4 ON a4.number = a1.number
		LEFT JOIN #progress_error a5 ON a5.number = a1.number
		LEFT JOIN #sources_0_id a6 ON a6.number = a1.number
		LEFT JOIN #sources_0_id_state a7 ON a7.number = a1.number
		LEFT JOIN #pts a8 ON a8.number = a1.number
		LEFT JOIN #masked_pts a9 ON a9.number = a1.number
		LEFT JOIN #engine_number a10 ON a10.number = a1.number
		LEFT JOIN #engine_model a11 ON a11.number = a1.number
		LEFT JOIN #tech_date_update a12 ON a12.number = a1.number
		LEFT JOIN #pts_date a13 ON a13.number = a1.number
		LEFT JOIN #has_dublicate a14 ON a14.number = a1.number
		LEFT JOIN #passport_number a15 ON a15.number = a1.number
		LEFT JOIN #sts_date a16 ON a16.number = a1.number
		LEFT JOIN #was_modificated a17 ON a17.number = a1.number
		LEFT JOIN #exported a18 ON a18.number = a1.number
		LEFT JOIN #was_utilized a19 ON a19.number = a1.number
		LEFT JOIN #utilizations_count a20 ON a20.number = a1.number
		LEFT JOIN #utilization_date_update a21 ON a21.number = a1.number
		LEFT JOIN #start_time a22 ON a22.number = a1.number
		LEFT JOIN #complete_time a23 ON a23.number = a1.number
		LEFT JOIN #created_at a24 ON a24.number = a1.number
		LEFT JOIN #updated_at a25 ON a25.number = a1.number

		COMMIT TRANSACTION;

		EXEC risk.set_debug_info @sp_name
			,'[spectrum_registration_actions] START';

		DROP TABLE

		IF EXISTS #base_registration_actions;
			SELECT DISTINCT number
			INTO #base_registration_actions
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND number IS NOT NULL
				AND number IS NOT NULL AND number <> '19061300000088';

		CREATE UNIQUE INDEX base_registration_actions_idx ON #base_registration_actions (number);

		DROP TABLE

		IF EXISTS #vin_registration_actions;
			SELECT DISTINCT number
				,[values] AS VIN
			INTO #vin_registration_actions
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'vehicle_id'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		CREATE CLUSTERED INDEX vin_registration_actions_idx ON #vin_registration_actions (number);

		DROP TABLE

		IF EXISTS #reg_actions_count;
			SELECT DISTINCT number
				,[values] AS reg_actions_count
			INTO #reg_actions_count
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'count'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent = 'root:data:0:content:registration_actions'

		DROP TABLE

		IF EXISTS #reg_action;
			SELECT DISTINCT number
				,cast(substring(SUBSTRING(parent, 48, 10), 1, CHARINDEX(':', SUBSTRING(parent, 48, 10)) - 1) AS INT) AS reg_action
			INTO #reg_action
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'start'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%';

		DROP TABLE

		IF EXISTS #date_start;
			SELECT DISTINCT number
				,[values] AS date_start
				,cast(substring(SUBSTRING(parent, 48, 10), 1, CHARINDEX(':', SUBSTRING(parent, 48, 10)) - 1) AS INT) AS Reg_action
			INTO #date_start
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'start'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%:date';

		DROP TABLE

		IF EXISTS #date_end;
			SELECT DISTINCT number
				,[values] AS date_end
				,cast(substring(SUBSTRING(parent, 48, 10), 1, CHARINDEX(':', SUBSTRING(parent, 48, 10)) - 1) AS INT) AS reg_action
			INTO #date_end
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'end'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%:date';

		DROP TABLE

		IF EXISTS #identifiers_pts;
			SELECT DISTINCT number
				,[values] AS identifiers_pts
				,cast(substring(SUBSTRING(parent, 48, 10), 1, CHARINDEX(':', SUBSTRING(parent, 48, 10)) - 1) AS INT) AS reg_action
			INTO #identifiers_pts
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'pts'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%:identifiers';

		DROP TABLE

		IF EXISTS #owner_type;
			SELECT DISTINCT number
				,[values] AS owner_type
				,cast(substring(SUBSTRING(parent, 48, 10), 1, CHARINDEX(':', SUBSTRING(parent, 48, 10)) - 1) AS INT) AS reg_action
			INTO #owner_type
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'type'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%:owner';

		DROP TABLE

		IF EXISTS #owner_org_name;
			SELECT DISTINCT number
				,[values] AS owner_org_name
				,cast(substring(SUBSTRING(parent, 48, 10), 1, CHARINDEX(':', SUBSTRING(parent, 48, 10)) - 1) AS INT) AS reg_action
			INTO #owner_org_name
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'name'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%:owner:org';

		DROP TABLE

		IF EXISTS #owner_org_ogrn;
			SELECT DISTINCT number
				,[values] AS owner_org_ogrn
				,cast(substring(SUBSTRING(parent, 48, 10), 1, CHARINDEX(':', SUBSTRING(parent, 48, 10)) - 1) AS INT) AS reg_action
			INTO #owner_org_ogrn
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'ogrn'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%:owner:org';

		DROP TABLE

		IF EXISTS #owner_org_tin;
			SELECT DISTINCT number
				,[values] AS owner_org_tin
				,cast(substring(SUBSTRING(parent, 48, 10), 1, CHARINDEX(':', SUBSTRING(parent, 48, 10)) - 1) AS INT) AS reg_action
			INTO #owner_org_tin
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'ogrn'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%:owner:org';

		DROP TABLE

		IF EXISTS #code;
			SELECT DISTINCT number
				,[values] AS code
				,SUBSTRING(parent, 48, 10) AS reg_action
			INTO #code
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'code'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%';

		DROP TABLE

		IF EXISTS #type;
			SELECT DISTINCT number
				,[values] AS [type]
				,SUBSTRING(parent, 48, 10) AS reg_action
			INTO #type
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'type'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%'
				AND parent NOT LIKE 'root:data:0:content:registration_actions:items:%:%';

		DROP TABLE

		IF EXISTS #region;
			SELECT DISTINCT number
				,[values] AS region
				,cast(substring(SUBSTRING(parent, 48, 10), 1, CHARINDEX(':', SUBSTRING(parent, 48, 10)) - 1) AS INT) AS reg_action
			INTO #region
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'region'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%:geo';

		DROP TABLE

		IF EXISTS #city;
			SELECT DISTINCT number
				,[values] AS city
				,cast(substring(SUBSTRING(parent, 48, 10), 1, CHARINDEX(':', SUBSTRING(parent, 48, 10)) - 1) AS INT) AS reg_action
			INTO #city
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'city'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%:geo';

		DROP TABLE

		IF EXISTS #street;
			SELECT DISTINCT number
				,[values] AS street
				,cast(substring(SUBSTRING(parent, 48, 10), 1, CHARINDEX(':', SUBSTRING(parent, 48, 10)) - 1) AS INT) AS reg_action
			INTO #street
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'street'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%:geo';

		DROP TABLE

		IF EXISTS #house;
			SELECT DISTINCT number
				,[values] AS house
				,cast(substring(SUBSTRING(parent, 48, 10), 1, CHARINDEX(':', SUBSTRING(parent, 48, 10)) - 1) AS INT) AS reg_action
			INTO #house
			FROM stg._loginom.Origination_spectrum_parse
			WHERE NAMES = 'house'
				AND number IS NOT NULL
				AND idReportBlock = 'report_documents@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND parent LIKE 'root:data:0:content:registration_actions:items:%:geo';

		CREATE UNIQUE INDEX reg_action_uidx ON #reg_action (
			number
			,reg_action
			);

		CREATE CLUSTERED INDEX date_start_idx ON #date_start (
			number
			,reg_action
			);

		CREATE CLUSTERED INDEX date_end_idx ON #date_end (
			number
			,reg_action
			);

		CREATE CLUSTERED INDEX identifiers_pts_idx ON #identifiers_pts (
			number
			,reg_action
			);

		CREATE CLUSTERED INDEX owner_type_idx ON #owner_type (
			number
			,reg_action
			);

		CREATE CLUSTERED INDEX owner_org_name_idx ON #owner_org_name (
			number
			,reg_action
			);

		CREATE CLUSTERED INDEX owner_org_ogrn_idx ON #owner_org_ogrn (
			number
			,reg_action
			);

		CREATE CLUSTERED INDEX owner_org_tin_idx ON #owner_org_tin (
			number
			,reg_action
			);

		CREATE CLUSTERED INDEX code_idx ON #code (
			number
			,reg_action
			);

		CREATE CLUSTERED INDEX type_idx ON #type (
			number
			,reg_action
			);

		CREATE CLUSTERED INDEX region_idx ON #region (
			number
			,reg_action
			);

		CREATE CLUSTERED INDEX city_idx ON #city (
			number
			,reg_action
			);

		CREATE CLUSTERED INDEX street_idx ON #street (
			number
			,reg_action
			);

		CREATE CLUSTERED INDEX house_idx ON #house (
			number
			,reg_action
			);

		BEGIN TRANSACTION

		TRUNCATE TABLE risk.spectrum_registration_actions;

		INSERT INTO risk.spectrum_registration_actions
		SELECT a1.number
			,a2.VIN
			,a3.reg_actions_count
			,a4.reg_action
			,cast(a5.date_start AS DATE) AS date_start
			,cast(a6.date_end AS DATE) AS date_end
			,a7.identifiers_pts
			,a8.owner_type
			,a9.owner_org_name
			,a10.owner_org_ogrn
			,a11.owner_org_tin
			,a12.code
			,a13.type
			,a14.region
			,a15.city
			,a16.street
			,a17.house
		FROM #base_registration_actions a1
		LEFT JOIN #vin_registration_actions a2 ON a1.number = a2.number
		LEFT JOIN #reg_actions_count a3 ON a1.number = a3.number
		LEFT JOIN #reg_action a4 ON a1.number = a4.number
		LEFT JOIN #date_start a5 ON a5.number = a4.number
			AND a5.Reg_action = a4.reg_action
		LEFT JOIN #date_end a6 ON a6.number = a4.number
			AND a6.Reg_action = a4.reg_action
		LEFT JOIN #identifiers_pts a7 ON a7.number = a4.number
			AND a7.Reg_action = a4.reg_action
		LEFT JOIN #owner_type a8 ON a8.number = a4.number
			AND a8.Reg_action = a4.reg_action
		LEFT JOIN #owner_org_name a9 ON a9.number = a4.number
			AND a9.Reg_action = a4.reg_action
		LEFT JOIN #owner_org_ogrn a10 ON a10.number = a4.number
			AND a10.Reg_action = a4.reg_action
		LEFT JOIN #owner_org_tin a11 ON a11.number = a4.number
			AND a11.Reg_action = a4.reg_action
		LEFT JOIN #code a12 ON a12.number = a4.number
			AND a12.Reg_action = a4.reg_action
		LEFT JOIN #type a13 ON a13.number = a4.number
			AND a13.Reg_action = a4.reg_action
		LEFT JOIN #region a14 ON a14.number = a4.number
			AND a14.Reg_action = a4.reg_action
		LEFT JOIN #city a15 ON a15.number = a4.number
			AND a15.Reg_action = a4.reg_action
		LEFT JOIN #street a16 ON a16.number = a4.number
			AND a16.Reg_action = a4.reg_action
		LEFT JOIN #house a17 ON a17.number = a4.number
			AND a17.Reg_action = a4.reg_action;

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
