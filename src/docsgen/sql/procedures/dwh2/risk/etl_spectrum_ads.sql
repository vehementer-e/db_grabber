
--EXEC [DWH2].[risk].[etl_spectrum_ads]
CREATE PROCEDURE [risk].[etl_spectrum_ads]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		EXEC risk.set_debug_info @sp_name
			,'[spectrum_ads_price] START';

		DROP TABLE

		IF EXISTS #base;
			SELECT DISTINCT number
			INTO #base
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND number IS NOT NULL AND number <> '19061300000088';

		CREATE INDEX number_idx ON #base (number);

		DROP TABLE

		IF EXISTS #vin;
			SELECT DISTINCT number
				,[values] AS VIN
			INTO #vin
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'vehicle_id'
				AND number IS NOT NULL
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #progress_ok;
			SELECT DISTINCT number
				,[values] AS progress_ok
			INTO #progress_ok
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_ok'
				AND number IS NOT NULL
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #progress_wait;
			SELECT DISTINCT number
				,[values] AS progress_wait
			INTO #progress_wait
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_wait'
				AND number IS NOT NULL
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #progress_error;
			SELECT DISTINCT number
				,[values] AS progress_error
			INTO #progress_error
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'progress_error'
				AND number IS NOT NULL
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #sources_0_id;
			SELECT DISTINCT number
				,[values] AS sources_0_id
			INTO #sources_0_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:0'
				AND NAMES = '_id'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #sources_0_id_state;
			SELECT DISTINCT number
				,[values] AS sources_0_id_state
			INTO #sources_0_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:0'
				AND NAMES = 'state'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #sources_1_id;
			SELECT DISTINCT number
				,[values] AS sources_1_id
			INTO #sources_1_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:1'
				AND NAMES = '_id'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #sources_1_id_state;
			SELECT DISTINCT number
				,[values] AS sources_1_id_state
			INTO #sources_1_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:1'
				AND NAMES = 'state'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #sources_2_id;
			SELECT DISTINCT number
				,[values] AS sources_2_id
			INTO #sources_2_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:2'
				AND NAMES = '_id'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #sources_2_id_state;
			SELECT DISTINCT number
				,[values] AS sources_2_id_state
			INTO #sources_2_id_state
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:state:sources:2'
				AND NAMES = 'state'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #requested_at;
			SELECT DISTINCT number
				,[values] AS requested_at
			INTO #requested_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'requested_at'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #max_price;
			SELECT DISTINCT number
				,[values] AS max_price
			INTO #max_price
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:amount'
				AND NAMES = 'max'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #min_price;
			SELECT DISTINCT number
				,[values] AS min_price
			INTO #min_price
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:amount'
				AND NAMES = 'min'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #optimal_price;
			SELECT DISTINCT number
				,[values] AS optimal_price
			INTO #optimal_price
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:amount'
				AND NAMES = 'optimal'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #currency_type;
			SELECT DISTINCT number
				,[values] AS currency_type
			INTO #currency_type
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:currency'
				AND NAMES = 'type'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #mileage;
			SELECT DISTINCT number
				,[values] AS mileage
			INTO #mileage
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0'
				AND NAMES = 'mileage'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #functions_name;
			SELECT DISTINCT number
				,[values] AS functions_name
			INTO #functions_name
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0'
				AND NAMES = 'name'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #description;
			SELECT DISTINCT number
				,[values] AS description
			INTO #description
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0'
				AND NAMES = 'description'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #functions_parts_type_0;
			SELECT DISTINCT number
				,[values] AS functions_parts_type_0
			INTO #functions_parts_type_0
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:0'
				AND NAMES = 'type'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #description_type_0;
			SELECT DISTINCT number
				,[values] AS description_type_0
			INTO #description_type_0
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:0'
				AND NAMES = 'description'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #bounds_left_type_0;
			SELECT DISTINCT number
				,[values] AS bounds_left_type_0
			INTO #bounds_left_type_0
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:0:bounds'
				AND NAMES = 'left'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #bounds_right_type_0;
			SELECT DISTINCT number
				,[values] AS bounds_right_type_0
			INTO #bounds_right_type_0
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:0:bounds'
				AND NAMES = 'right'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #functions_parts_type_1;
			SELECT DISTINCT number
				,[values] AS functions_parts_type_1
			INTO #functions_parts_type_1
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:1'
				AND NAMES = 'type'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #description_type_1;
			SELECT DISTINCT number
				,[values] AS description_type_1
			INTO #description_type_1
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:1'
				AND NAMES = 'description'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #coefficients_1_type_1;
			SELECT DISTINCT number
				,[values] AS coefficients_1_type_1
			INTO #coefficients_1_type_1
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:1:coefficients'
				AND NAMES = '1'
				AND idReportBlock = 'report_ads_price@carmoney';

				DROP TABLE

		IF EXISTS #coefficients_0_type_1;
			SELECT DISTINCT number
				,[values] AS coefficients_0_type_1
			INTO #coefficients_0_type_1
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:1:coefficients'
				AND NAMES = '0'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #bounds_left_type_1;
			SELECT DISTINCT number
				,[values] AS bounds_left_type_1
			INTO #bounds_left_type_1
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:1:bounds'
				AND NAMES = 'left'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #bounds_right_type_1;
			SELECT DISTINCT number
				,[values] AS bounds_right_type_1
			INTO #bounds_right_type_1
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:1:bounds'
				AND NAMES = 'right'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #functions_parts_type_2;
			SELECT DISTINCT number
				,[values] AS functions_parts_type_2
			INTO #functions_parts_type_2
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:2'
				AND NAMES = 'type'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #description_type_2;
			SELECT DISTINCT number
				,[values] AS description_type_2
			INTO #description_type_2
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:2'
				AND NAMES = 'description'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #coefficients_0_type_2;
			SELECT DISTINCT number
				,[values] AS coefficients_0_type_2
			INTO #coefficients_0_type_2
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:2:coefficients'
				AND NAMES = '0'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #coefficients_1_type_2;
			SELECT DISTINCT number
				,[values] AS coefficients_1_type_2
			INTO #coefficients_1_type_2
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:2:coefficients'
				AND NAMES = '1'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #bounds_left_type_2;
			SELECT DISTINCT number
				,[values] AS bounds_left_type_2
			INTO #bounds_left_type_2
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:2:bounds'
				AND NAMES = 'left'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #bounds_right_type_2;
			SELECT DISTINCT number
				,[values] AS bounds_right_type_2
			INTO #bounds_right_type_2
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:2:bounds'
				AND NAMES = 'right'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #date_update;
			SELECT DISTINCT number
				,[values] AS date_update
			INTO #date_update
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:date'
				AND NAMES = 'update'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #start_time;
			SELECT DISTINCT number
				,[values] AS start_time
			INTO #start_time
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:last_generation_stat'
				AND NAMES = 'start_time'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #complete_time;
			SELECT DISTINCT number
				,[values] AS complete_time
			INTO #complete_time
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:last_generation_stat'
				AND NAMES = 'complete_time'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #created_at;
			SELECT DISTINCT number
				,[values] AS created_at
			INTO #created_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'created_at'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #updated_at;
			SELECT DISTINCT number
				,[values] AS updated_at
			INTO #updated_at
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0'
				AND NAMES = 'updated_at'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #coefficients_0_type_0;
			SELECT DISTINCT number
				,[values] AS coefficients_0_type_0
			INTO #coefficients_0_type_0
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:0:coefficients'
				AND NAMES = '0'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #coefficients_1_type_0;
			SELECT DISTINCT number
				,[values] AS coefficients_1_type_0
			INTO #coefficients_1_type_0
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE number IS NOT NULL
				AND parent = 'root:data:0:content:market_prices:ads:items:0:metadata:functions:0:parts:0:coefficients'
				AND NAMES = '1'
				AND idReportBlock = 'report_ads_price@carmoney';

		BEGIN TRANSACTION

		TRUNCATE TABLE risk.spectrum_ads_price;

		INSERT INTO risk.spectrum_ads_price
		SELECT b.number
			,cast(a1.vin AS VARCHAR(200)) AS VIN
			,cast(a2.progress_ok AS INT) AS progress_ok
			,cast(a3.progress_wait AS INT) AS progress_wait
			,cast(a4.progress_error AS INT) AS progress_error
			,a5.sources_0_id
			,a6.sources_0_id_state
			,a7.sources_1_id
			,a8.sources_1_id_state
			,a9.sources_2_id
			,a10.sources_2_id_state
			,cast(a11.requested_at AS DATETIME) AS requested_at
			,a12.max_price AS max_price
			,a13.min_price AS min_price
			,a14.optimal_price AS optimal_price
			,a15.currency_type AS currency_type
			,a16.mileage AS mileage
			,a17.functions_name
			,a18.description
			,a19.functions_parts_type_0
			,a20.description_type_0
			,a201.coefficients_0_type_0
			,a311.coefficients_1_type_0
			,a22.bounds_left_type_0
			,a23.bounds_right_type_0
			,a24.functions_parts_type_1
			,a30.description_type_1
			,a202.coefficients_0_type_1
			,a31.coefficients_1_type_1
			,a32.bounds_left_type_1
			,a33.bounds_right_type_1
			,a34.functions_parts_type_2
			,a35.description_type_2
			,a36.coefficients_0_type_2
			,a37.coefficients_1_type_2
			,a38.bounds_left_type_2
			,a39.bounds_right_type_2
			,cast(a40.date_update AS DATETIME) AS date_update
			,cast(a41.start_time AS DATETIME) AS start_time
			,cast(a42.complete_time AS DATETIME) AS complete_time
			,cast(a43.created_at AS DATETIME) AS created_at
			,cast(a44.updated_at AS DATETIME) AS updated_at
		FROM #base b
		LEFT JOIN #vin a1 ON b.number = a1.number
		LEFT JOIN #progress_ok a2 ON b.number = a2.number
		LEFT JOIN #progress_wait a3 ON b.number = a3.number
		LEFT JOIN #progress_error a4 ON b.number = a4.number
		LEFT JOIN #sources_0_id a5 ON b.number = a5.number
		LEFT JOIN #sources_0_id_state a6 ON b.number = a6.number
		LEFT JOIN #sources_1_id a7 ON b.number = a7.number
		LEFT JOIN #sources_1_id_state a8 ON b.number = a8.number
		LEFT JOIN #sources_2_id a9 ON b.number = a9.number
		LEFT JOIN #sources_2_id_state a10 ON b.number = a10.number
		LEFT JOIN #requested_at a11 ON b.number = a11.number
		LEFT JOIN #max_price a12 ON b.number = a12.number
		LEFT JOIN #min_price a13 ON b.number = a13.number
		LEFT JOIN #optimal_price a14 ON b.number = a14.number
		LEFT JOIN #currency_type a15 ON b.number = a15.number
		LEFT JOIN #mileage a16 ON b.number = a16.number
		LEFT JOIN #functions_name a17 ON b.number = a17.number
		LEFT JOIN #description a18 ON b.number = a18.number
		LEFT JOIN #functions_parts_type_0 a19 ON b.number = a19.number
		LEFT JOIN #description_type_0 a20 ON b.number = a20.number
		LEFT JOIN #coefficients_0_type_0 a201 ON b.number = a201.number
		LEFT JOIN #coefficients_0_type_1 a202 ON b.number = a202.number
		LEFT JOIN #bounds_left_type_0 a22 ON b.number = a22.number
		LEFT JOIN #bounds_right_type_0 a23 ON b.number = a23.number
		LEFT JOIN #functions_parts_type_1 a24 ON b.number = a24.number
		LEFT JOIN #description_type_1 a30 ON b.number = a30.number
		LEFT JOIN #coefficients_1_type_0 a311 ON b.number = a311.number
		LEFT JOIN #coefficients_1_type_1 a31 ON b.number = a31.number
		LEFT JOIN #bounds_left_type_1 a32 ON b.number = a32.number
		LEFT JOIN #bounds_right_type_1 a33 ON b.number = a33.number
		LEFT JOIN #functions_parts_type_2 a34 ON b.number = a34.number
		LEFT JOIN #description_type_2 a35 ON b.number = a35.number
		LEFT JOIN #coefficients_0_type_2 a36 ON b.number = a36.number
		LEFT JOIN #coefficients_1_type_2 a37 ON b.number = a37.number
		LEFT JOIN #bounds_left_type_2 a38 ON b.number = a38.number
		LEFT JOIN #bounds_right_type_2 a39 ON b.number = a39.number
		LEFT JOIN #date_update a40 ON b.number = a40.number
		LEFT JOIN #start_time a41 ON b.number = a41.number
		LEFT JOIN #complete_time a42 ON b.number = a42.number
		LEFT JOIN #created_at a43 ON b.number = a43.number
		LEFT JOIN #updated_at a44 ON b.number = a44.number;

		COMMIT TRANSACTION;

		EXEC risk.set_debug_info @sp_name
			,'[spectrum_related_ads_price] START';

		DROP TABLE

		IF EXISTS #base1;
			SELECT DISTINCT number
			INTO #base1
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina')
				AND number IS NOT NULL
				AND number IS NOT NULL AND number <> '19061300000088';

		CREATE UNIQUE INDEX base1_idx ON #base1 (number);

		DROP TABLE

		IF EXISTS #vin1;
			SELECT DISTINCT number
				,[values] AS VIN
			INTO #vin1
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE a.NAMES = 'vehicle_id'
				AND number IS NOT NULL
				AND idReportBlock = 'report_ads_price@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		CREATE INDEX vin1_idx ON #vin1 (number);

		DROP TABLE

		IF EXISTS #date_publish;
			SELECT DISTINCT number
				,[values] AS date_publish
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #date_publish
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:date'
				AND NAMES = 'publish'
				AND idReportBlock = 'report_ads_price@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #country;
			SELECT DISTINCT number
				,[values] AS country
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #country
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:geo'
				AND NAMES = 'country'
				AND idReportBlock = 'report_ads_price@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #region;
			SELECT DISTINCT number
				,[values] AS region
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #region
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:geo'
				AND NAMES = 'region'
				AND idReportBlock = 'report_ads_price@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #city;
			SELECT DISTINCT number
				,[values] AS city
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #city
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:geo'
				AND NAMES = 'city'
				AND idReportBlock = 'report_ads_price@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #street;
			SELECT DISTINCT number
				,[values] AS street
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #street
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:geo'
				AND NAMES = 'street'
				AND idReportBlock = 'report_ads_price@carmoney'
				AND userName NOT IN ('P.Chesnokova', 'DStarikov', 'shoshina');

		DROP TABLE

		IF EXISTS #house;
			SELECT DISTINCT number
				,[values] AS house
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #house
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:geo'
				AND NAMES = 'house'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #uri;
			SELECT DISTINCT number
				,[values] AS uri
				,cast(SUBSTRING(parent, 59, 10) AS INT) AS ads
			INTO #uri
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%'
				AND NAMES = 'uri'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #price_amount;
			SELECT DISTINCT number
				,[values] AS price_amount
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #price_amount
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:price'
				AND NAMES = 'amount'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #price_currency;
			SELECT DISTINCT number
				,[values] AS price_currency
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #price_currency
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:price'
				AND NAMES = 'currency'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #brand_name;
			SELECT DISTINCT number
				,[values] AS brand_name
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #brand_name
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:brand'
				AND NAMES = 'name'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #model_name;
			SELECT DISTINCT number
				,[values] AS model_name
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #model_name
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:model'
				AND NAMES = 'name'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #year;
			SELECT DISTINCT number
				,[values] AS [year]
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #year
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle'
				AND NAMES = 'year'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #mileage1;
			SELECT DISTINCT number
				,[values] AS mileage
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #mileage1
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle'
				AND NAMES = 'mileage'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #condition;
			SELECT DISTINCT number
				,[values] AS condition
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #condition
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle'
				AND NAMES = 'condition'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #owners_count;
			SELECT DISTINCT number
				,[values] AS owners_count
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #owners_count
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:owners'
				AND NAMES = 'count'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #wheel_position;
			SELECT DISTINCT number
				,[values] AS wheel_position
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #wheel_position
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:wheel'
				AND NAMES = 'position'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #position_id;
			SELECT DISTINCT number
				,[values] AS position_id
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #position_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:wheel'
				AND NAMES = 'position_id'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #transmission_type;
			SELECT DISTINCT number
				,[values] AS transmission_type
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #transmission_type
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:transmission'
				AND NAMES = 'type'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #transmission_type_id;
			SELECT DISTINCT number
				,[values] AS transmission_type_id
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #transmission_type_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:transmission'
				AND NAMES = 'type_id'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #drive_type;
			SELECT DISTINCT number
				,[values] AS drive_type
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #drive_type
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:drive'
				AND NAMES = 'type'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #drive_type_id;
			SELECT DISTINCT number
				,[values] AS drive_type_id
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #drive_type_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:drive'
				AND NAMES = 'type_id'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #engine_power_hp;
			SELECT DISTINCT number
				,[values] AS engine_power_hp
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #engine_power_hp
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:engine:power'
				AND NAMES = 'hp'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #engine_volume;
			SELECT DISTINCT number
				,[values] AS engine_volume
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #engine_volume
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:engine'
				AND NAMES = 'volume'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #fuel_type;
			SELECT DISTINCT number
				,[values] AS fuel_type
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #fuel_type
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:engine:fuel'
				AND NAMES = 'type'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #fuel_type_id;
			SELECT DISTINCT number
				,[values] AS fuel_type_id
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #fuel_type_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:engine:fuel'
				AND NAMES = 'type_id'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #body_type;
			SELECT DISTINCT number
				,[values] AS body_type
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #body_type
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:body'
				AND NAMES = 'type'
				AND idReportBlock = 'report_ads_price@carmoney';

		DROP TABLE

		IF EXISTS #body_type_id;
			SELECT DISTINCT number
				,[values] AS body_type_id
				,cast(substring(SUBSTRING(parent, 59, 10), 1, CHARINDEX(':', SUBSTRING(parent, 59, 10)) - 1) AS INT) AS ads
			INTO #body_type_id
			FROM stg._loginom.Origination_spectrum_parse a
			WHERE parent LIKE 'root:data:0:content:market_prices:ads:items:0:related_ads:%:vehicle:body'
				AND NAMES = 'type_id'
				AND idReportBlock = 'report_ads_price@carmoney';

		CREATE CLUSTERED INDEX date_publish_idx ON #date_publish (
			number
			,ads
			);

		CREATE CLUSTERED INDEX country_idx ON #country (
			number
			,ads
			);

		CREATE CLUSTERED INDEX region_idx ON #region (
			number
			,ads
			);

		CREATE CLUSTERED INDEX city_idx ON #city (
			number
			,ads
			);

		CREATE CLUSTERED INDEX street_idx ON #street (
			number
			,ads
			);

		CREATE CLUSTERED INDEX house_idx ON #house (
			number
			,ads
			);

		CREATE INDEX uri_idx ON #uri (
			number
			,ads
			);

		CREATE CLUSTERED INDEX price_amount_idx ON #price_amount (
			number
			,ads
			);

		CREATE INDEX price_currency_idx ON #price_currency (
			number
			,ads
			);

		CREATE CLUSTERED INDEX brand_name_idx ON #brand_name (
			number
			,ads
			);

		CREATE CLUSTERED INDEX model_name_idx ON #model_name (
			number
			,ads
			);

		CREATE CLUSTERED INDEX year_idx ON #year (
			number
			,ads
			);

		CREATE CLUSTERED INDEX mileage_idx ON #mileage1 (
			number
			,ads
			);

		CREATE CLUSTERED INDEX condition_idx ON #condition (
			number
			,ads
			);

		CREATE CLUSTERED INDEX owners_count_idx ON #owners_count (
			number
			,ads
			);

		CREATE CLUSTERED INDEX wheel_position_idx ON #wheel_position (
			number
			,ads
			);

		CREATE CLUSTERED INDEX position_id_idx ON #position_id (
			number
			,ads
			);

		CREATE CLUSTERED INDEX transmission_type_idx ON #transmission_type (
			number
			,ads
			);

		CREATE CLUSTERED INDEX transmission_type_id_idx ON #transmission_type_id (
			number
			,ads
			);

		CREATE CLUSTERED INDEX drive_type_idx ON #drive_type (
			number
			,ads
			);

		CREATE CLUSTERED INDEX drive_type_id_idx ON #drive_type_id (
			number
			,ads
			);

		CREATE CLUSTERED INDEX engine_power_hp_idx ON #engine_power_hp (
			number
			,ads
			);

		CREATE CLUSTERED INDEX engine_volume_idx ON #engine_volume (
			number
			,ads
			);

		CREATE CLUSTERED INDEX fuel_type_idx ON #fuel_type (
			number
			,ads
			);

		CREATE CLUSTERED INDEX fuel_type_id_idx ON #fuel_type_id (
			number
			,ads
			);

		CREATE CLUSTERED INDEX body_type_idx ON #body_type (
			number
			,ads
			);

		CREATE CLUSTERED INDEX body_type_id_idx ON #body_type_id (
			number
			,ads
			);

		BEGIN TRANSACTION

		TRUNCATE TABLE risk.spectrum_related_ads_price;

		INSERT INTO risk.spectrum_related_ads_price
		SELECT a2.number
			,a2.vin
			,a3.ads
			,cast(a3.date_publish AS DATETIME) AS date_publish
			--,a4.country
			--,a5.region
			,a6.city
			,a7.street
			--,a8.house
			,a9.uri
			,a10.price_amount
			,a11.price_currency
			,a12.brand_name
			,a13.model_name
			,a14.year
			,a15.mileage
			,a16.condition
			,a17.owners_count
			,a18.wheel_position
			,a19.position_id
			,a20.transmission_type
			,a21.transmission_type_id
			,a22.drive_type
			,a23.drive_type_id
			,a24.engine_power_hp
			,a25.engine_volume
			,a26.fuel_type
			,a27.fuel_type_id
			,a28.body_type
			,a29.body_type_id
		FROM #vin1 a2
		INNER JOIN #date_publish a3 ON a3.number = a2.number
		LEFT JOIN #country a4 ON a4.number = a3.number
			AND a4.ads = a3.ads
		LEFT JOIN #region a5 ON a5.number = a3.number
			AND a5.ads = a3.ads
		LEFT JOIN #city a6 ON a6.number = a3.number
			AND a6.ads = a3.ads
		LEFT JOIN #street a7 ON a7.number = a3.number
			AND a7.ads = a3.ads
		LEFT JOIN #house a8 ON a8.number = a3.number
			AND a8.ads = a3.ads
		LEFT JOIN #uri a9 ON a9.number = a3.number
			AND a9.ads = a3.ads
		LEFT JOIN #price_amount a10 ON a10.number = a3.number
			AND a10.ads = a3.ads
		LEFT JOIN #price_currency a11 ON a11.number = a3.number
			AND a11.ads = a3.ads
		LEFT JOIN #brand_name a12 ON a12.number = a3.number
			AND a12.ads = a3.ads
		LEFT JOIN #model_name a13 ON a13.number = a3.number
			AND a13.ads = a3.ads
		LEFT JOIN #year a14 ON a14.number = a3.number
			AND a14.ads = a3.ads
		LEFT JOIN #mileage1 a15 ON a15.number = a3.number
			AND a15.ads = a3.ads
		LEFT JOIN #condition a16 ON a16.number = a3.number
			AND a16.ads = a3.ads
		LEFT JOIN #owners_count a17 ON a17.number = a3.number
			AND a17.ads = a3.ads
		LEFT JOIN #wheel_position a18 ON a18.number = a3.number
			AND a18.ads = a3.ads
		LEFT JOIN #position_id a19 ON a19.number = a3.number
			AND a19.ads = a3.ads
		LEFT JOIN #transmission_type a20 ON a20.number = a3.number
			AND a20.ads = a3.ads
		LEFT JOIN #transmission_type_id a21 ON a21.number = a3.number
			AND a21.ads = a3.ads
		LEFT JOIN #drive_type a22 ON a22.number = a3.number
			AND a22.ads = a3.ads
		LEFT JOIN #drive_type_id a23 ON a23.number = a3.number
			AND a23.ads = a3.ads
		LEFT JOIN #engine_power_hp a24 ON a24.number = a3.number
			AND a24.ads = a3.ads
		LEFT JOIN #engine_volume a25 ON a25.number = a3.number
			AND a25.ads = a3.ads
		LEFT JOIN #fuel_type a26 ON a26.number = a3.number
			AND a26.ads = a3.ads
		LEFT JOIN #fuel_type_id a27 ON a27.number = a3.number
			AND a27.ads = a3.ads
		LEFT JOIN #body_type a28 ON a28.number = a3.number
			AND a28.ads = a3.ads
		LEFT JOIN #body_type_id a29 ON a29.number = a3.number
			AND a29.ads = a3.ads;

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
END;
