
--exec [risk].[etl_zaprosto_dataset]
CREATE PROCEDURE [risk].[etl_zaprosto_dataset]
AS
BEGIN
	DROP TABLE

	IF EXISTS ##stg_Запросто_postgre;
		--USE stg;
		--Выргрузку из Postgre делать "В формате БД"
		DECLARE @ReturnCode INT
			,@ReturnMessage VARCHAR(8000)

	EXEC stg.dbo.ExecLoadExcel @PathName = '\\10.196.41.14\DWHFiles\Risk\Запросто\'
		,@FileName = 'Запросто финал 2710.xlsx'
		,@SheetName = 'Лист1'
		,@isMoveFile = 'false'
		,@TableName = '##stg_Запросто_postgre'
		,@ReturnCode = @ReturnCode OUTPUT
		,@ReturnMessage = @ReturnMessage OUTPUT

	SELECT 'ReturnCode' = @ReturnCode
		,'ReturnMessage' = @ReturnMessage;

	ALTER TABLE ##stg_Запросто_postgre

	DROP COLUMN

	IF EXISTS created;
		--,f24
		--,f25
		--,f26
		--,f27
		--,f28;
		EXEC stg.dbo.ExecLoadExcel @PathName = '\\10.196.41.14\DWHFiles\Risk\Запросто\'
			,@FileName = 'Запросто дилеры 2107.xlsx'
			,@SheetName = 'Лист1'
			,@isMoveFile = 'false'
			,@TableName = '##stg_Запросто_dealers'
			,@ReturnCode = @ReturnCode OUTPUT
			,@ReturnMessage = @ReturnMessage OUTPUT

	SELECT 'ReturnCode' = @ReturnCode
		,'ReturnMessage' = @ReturnMessage;

	ALTER TABLE ##stg_Запросто_dealers

	DROP COLUMN created;

	EXEC stg.dbo.ExecLoadExcel @PathName = '\\10.196.41.14\DWHFiles\Risk\Запросто\'
		,@FileName = 'ЗапростоLastDateTimeActivity 2807.xlsx'
		,@SheetName = 'Лист1'
		,@isMoveFile = 'false'
		,@TableName = '##stg_Запросто_LastDateTimeActivity'
		,@ReturnCode = @ReturnCode OUTPUT
		,@ReturnMessage = @ReturnMessage OUTPUT

	SELECT 'ReturnCode' = @ReturnCode
		,'ReturnMessage' = @ReturnMessage;

	ALTER TABLE ##stg_Запросто_LastDateTimeActivity

	DROP COLUMN created;

	UPDATE ##stg_Запросто_postgre
	SET report_date = REPLACE(report_date, '''', '')
		,birthdate = REPLACE(birthdate, '''', '')
		,plan_close_date = REPLACE(plan_close_date, '''', '')
		,[Уникальный номер заявки] = REPLACE([Уникальный номер заявки], ' ', '')
		,issue_date = REPLACE(issue_date, '''', '')
		,[Остаток ОД] = REPLACE([Остаток ОД], '&', '')
		,[Плановые платежи нак итогом] = REPLACE([Плановые платежи нак итогом], '&', '')
		,[Фактические платежи нак итогом] = REPLACE([Фактические платежи нак итогом], '&', '')
		,amount = REPLACE(amount, '&', '')
		,[Стоимость телефона] = REPLACE([Стоимость телефона], '&', '')
		,[Первоначальный взнос] = REPLACE([Первоначальный взнос], '&', '')

	-----------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------
	--use dwh2;
	DROP TABLE

	IF EXISTS [risk].[Запросто_postgre];
		CREATE TABLE [risk].[Запросто_postgre] (
			[report_date] [date] NULL
			,[contract_name] [float] NULL
			,[client_name] [nvarchar](255) NULL
			,[birthdate] [date] NULL
			,[address_reg] [nvarchar](255) NULL
			,[address_fact] [nvarchar](255) NULL
			,[phone_number] [float] NULL
			,[client_gender] [nvarchar](255) NULL
			,[passport] [nvarchar](255) NULL
			,[code] [nvarchar](255) NULL
			,[issue_date] [date] NULL
			,[plan_close_date] [date] NULL
			,[amount] [float] NULL
			,[dpd_in] [float] NULL
			,[dpd_out] [float] NULL
			,[Остаток ОД] [float] NULL
			,[Плановые платежи нак итогом] [float] NULL
			,[Фактические платежи нак итогом] [float] NULL
			,[Номер планового текущего платежа] [float] NULL
			,[Уникальный номер заявки] [nvarchar](255) NULL
			,[model] [nvarchar](255) NULL
			,[imei] [float] NULL
			,[collateral_properties] [nvarchar](255) NULL
			,[cur_dob] [int] NULL
			,[fpd] [int] NULL
			,[spd] [int] NULL
			,[tpd] [int] NULL
			,[45+ на 60 день] [int] NULL
			,[45+ на 90 день] [int] NULL
			,[7+ на 30] [int] NULL
			,[30+ на 60 день] [int] NULL
			,[45+ ever] [int] NULL
			,[brand] [nvarchar](255) NULL
			,[max_dob] [int] NULL
			,[max_dpd_in] [int] NULL
			,[max_dpd_out] [int] NULL
			,[action] [nvarchar](255) NULL
			,[Стоимость телефона] [float] NULL
			,[Первоначальный взнос] [float] NULL
			);

	INSERT INTO [risk].[Запросто_postgre] (
		[report_date]
		,[contract_name]
		,[client_name]
		,[birthdate]
		,[address_reg]
		,[address_fact]
		,[phone_number]
		,[client_gender]
		,[passport]
		,[code]
		,[issue_date]
		,[plan_close_date]
		,[amount]
		,[dpd_in]
		,[dpd_out]
		,[Остаток ОД]
		,[Плановые платежи нак итогом]
		,[Фактические платежи нак итогом]
		,[Номер планового текущего платежа]
		,[Уникальный номер заявки]
		,[model]
		,[imei]
		,[collateral_properties]
		,[Стоимость телефона]
		,[Первоначальный взнос]
		)
	SELECT [report_date]
		,[contract_name]
		,[client_name]
		,[birthdate]
		,[address_reg]
		,[address_fact]
		,[phone_number]
		,[client_gender]
		,[passport]
		,[code]
		,[issue_date]
		,[plan_close_date]
		,[amount]
		,[dpd_in]
		,[dpd_out]
		,[Остаток ОД]
		,[Плановые платежи нак итогом]
		,[Фактические платежи нак итогом]
		,[Номер планового текущего платежа]
		,[Уникальный номер заявки]
		,[model]
		,[imei]
		,[collateral_properties]
		,[Стоимость телефона]
		,[Первоначальный взнос]
	FROM ##stg_Запросто_postgre a;

	DROP TABLE

	IF EXISTS [risk].[Запросто_dealers];
		CREATE TABLE [risk].[Запросто_dealers] (
			[contract_name] [float] NULL
			,[dealer_legal_name] [nvarchar](255) NULL
			,[dealer_name] [nvarchar](255) NULL
			,[dealer_inn] [float] NULL
			,[dealer_address_reg] [nvarchar](255) NULL
			,[dealer_address_fact] [nvarchar](255) NULL
			)

	INSERT INTO [risk].[Запросто_dealers]
	SELECT *
	FROM ##stg_Запросто_dealers;

	TRUNCATE TABLE [risk].[Запросто_LastDateTimeActivity];

	INSERT INTO [risk].[Запросто_LastDateTimeActivity]
	SELECT imei
		,cast(CASE 
				WHEN LastDateTimeActivity = '[NULL]'
					THEN NULL
				ELSE LastDateTimeActivity
				END AS DATETIME) AS LastDateTimeActivity
	FROM ##stg_Запросто_LastDateTimeActivity a;

	WITH cte_to_update
	AS (
		SELECT a.*
			,max(datediff(dd, a.issue_date, a.report_date) + 1) OVER (PARTITION BY a.contract_name) AS mmax_dob
		FROM [risk].[Запросто_postgre] a
		)
	UPDATE t
	SET t.max_dob = mmax_dob
	FROM cte_to_update t;

	WITH cte_to_update
	AS (
		SELECT a.*
			,datediff(dd, a.issue_date, a.report_date) + 1 AS ccur_dob
		FROM [risk].[Запросто_postgre] a
		)
	UPDATE t
	SET t.cur_dob = ccur_dob
	FROM cte_to_update t;

	WITH cte_to_update
	AS (
		SELECT a.*
			,max(dpd_in) OVER (PARTITION BY a.contract_name) AS mmax_dpd_in
			,max(dpd_out) OVER (PARTITION BY a.contract_name) AS mmax_dpd_out
		FROM [risk].[Запросто_postgre] a
		)
	UPDATE t
	SET t.max_dpd_in = mmax_dpd_in
		,t.max_dpd_out = mmax_dpd_out
	FROM cte_to_update t;

	UPDATE [risk].[Запросто_postgre]
	SET fpd = 0
		,spd = 0
		,tpd = 0;

	WITH cte_to_update
	AS (
		SELECT a.*
			,max(CASE 
					WHEN a.[Номер планового текущего платежа] = 1
						THEN a.[Фактические платежи нак итогом]
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS max_pmt_fpd
			,max(CASE 
					WHEN a.[Номер планового текущего платежа] = 1
						THEN a.[Плановые платежи нак итогом]
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS plant_pmt1
		FROM [risk].[Запросто_postgre] a
		)
	UPDATE t
	SET t.fpd = 1
	FROM cte_to_update t
	WHERE max_pmt_fpd < plant_pmt1 * 0.9;

	WITH cte_to_update
	AS (
		SELECT a.*
			,max(CASE 
					WHEN a.[Номер планового текущего платежа] = 2
						THEN a.[Фактические платежи нак итогом]
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS max_pmt_spd
			,max(CASE 
					WHEN a.[Номер планового текущего платежа] = 1
						THEN a.[Плановые платежи нак итогом]
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS plant_pmt1
		FROM [risk].[Запросто_postgre] a
		)
	UPDATE t
	SET t.spd = 1
	FROM cte_to_update t
	WHERE fpd = 1
		AND cast(max_pmt_spd AS FLOAT) < cast(plant_pmt1 AS FLOAT);

	WITH cte_to_update
	AS (
		SELECT a.*
			,max(CASE 
					WHEN a.[Номер планового текущего платежа] = 1
						THEN a.[Фактические платежи нак итогом]
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS max_pmt_fpd
			,max(CASE 
					WHEN a.[Номер планового текущего платежа] = 2
						THEN a.[Фактические платежи нак итогом]
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS max_pmt_spd
			,min(CASE 
					WHEN a.[Номер планового текущего платежа] = 3
						THEN a.[Фактические платежи нак итогом]
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS max_pmt_tpd
			,max(CASE 
					WHEN a.[Номер планового текущего платежа] = 1
						THEN a.[Плановые платежи нак итогом]
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS plant_pmt1
			,max(CASE 
					WHEN a.[Номер планового текущего платежа] = 2
						THEN a.[Плановые платежи нак итогом]
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS plant_pmt2
			,max(CASE 
					WHEN a.[Номер планового текущего платежа] = 3
						THEN a.[Плановые платежи нак итогом]
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS plant_pmt3
		FROM [risk].[Запросто_postgre] a
		)
	UPDATE t
	SET t.tpd = 1
	FROM cte_to_update t
	WHERE fpd = 1
		AND spd = 1
		AND cast(max_pmt_tpd AS FLOAT) < cast(plant_pmt3 AS FLOAT) * 0.9
		AND cast(max_pmt_tpd AS FLOAT) < cast(plant_pmt1 AS FLOAT);

	WITH cte_to_update
	AS (
		SELECT a.*
			,max(CASE 
					WHEN a.[Номер планового текущего платежа] = 1
						THEN a.report_date
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS max_repdate
			,min(CASE 
					WHEN a.[Номер планового текущего платежа] = 1
						THEN a.report_date
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS min_repdate
			,min(CASE 
					WHEN a.[Номер планового текущего платежа] = 2
						THEN a.report_date
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS min_repdate2
		FROM [risk].[Запросто_postgre] a
		)
	UPDATE t
	SET t.fpd = NULL
		,spd = NULL
		,tpd = NULL
	FROM cte_to_update t
	WHERE DATEDIFF(dd, min_repdate, MAX_REPDATE) < 6
		AND min_repdate2 IS NULL;

	WITH cte_to_update
	AS (
		SELECT a.*
			,max(CASE 
					WHEN a.[Номер планового текущего платежа] = 2
						THEN a.report_date
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS max_repdate
			,min(CASE 
					WHEN a.[Номер планового текущего платежа] = 2
						THEN a.report_date
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS min_repdate
		FROM [risk].[Запросто_postgre] a
		)
	UPDATE t
	SET spd = NULL
		,tpd = NULL
	FROM cte_to_update t
	WHERE DATEDIFF(dd, min_repdate, MAX_REPDATE) < 6;

	WITH cte_to_update
	AS (
		SELECT a.*
			,max(CASE 
					WHEN a.[Номер планового текущего платежа] = 3
						THEN a.report_date
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS max_repdate
			,min(CASE 
					WHEN a.[Номер планового текущего платежа] = 3
						THEN a.report_date
					ELSE NULL
					END) OVER (PARTITION BY a.contract_name) AS min_repdate
		FROM [risk].[Запросто_postgre] a
		)
	UPDATE t
	SET tpd = NULL
	FROM cte_to_update t
	WHERE DATEDIFF(dd, min_repdate, MAX_REPDATE) < 6;

	UPDATE [risk].[Запросто_postgre]
	SET [45+ ever] = 0;

	UPDATE [risk].[Запросто_postgre]
	SET [45+ ever] = 1
	WHERE dpd_in > 45;

	UPDATE [risk].[Запросто_postgre]
	SET [7+ на 30] = NULL
		,[30+ на 60 день] = NULL
		,[45+ на 60 день] = NULL
		,[45+ на 90 день] = NULL;

	WITH cte_to_update
	AS (
		SELECT a.*
		FROM [risk].[Запросто_postgre] a
		WHERE a.max_dob >= 30
			AND a.cur_dob <= 30
			AND a.dpd_in > 7
		)
	UPDATE t
	SET t.[7+ на 30] = 1
	FROM cte_to_update t;

	WITH cte_to_update
	AS (
		SELECT a.*
		FROM [risk].[Запросто_postgre] a
		WHERE a.max_dob >= 60
			AND a.cur_dob <= 60
			AND a.dpd_in > 30
		)
	UPDATE t
	SET t.[30+ на 60 день] = 1
	FROM cte_to_update t;

	WITH cte_to_update
	AS (
		SELECT a.*
		FROM [risk].[Запросто_postgre] a
		WHERE a.max_dob >= 60
			AND a.cur_dob <= 60
			AND a.dpd_in > 45
		)
	UPDATE t
	SET t.[45+ на 60 день] = 1
	FROM cte_to_update t;

	WITH cte_to_update
	AS (
		SELECT a.*
		FROM [risk].[Запросто_postgre] a
		WHERE a.max_dob >= 90
			AND a.cur_dob <= 90
			AND a.dpd_in > 45
		)
	UPDATE t
	SET t.[45+ на 90 день] = 1
	FROM cte_to_update t;

	WITH cte_to_update
	AS (
		SELECT a.*
			,max([7+ на 30]) OVER (PARTITION BY a.contract_name) AS max_metric
		FROM [risk].[Запросто_postgre] a
		)
	UPDATE t
	SET t.[7+ на 30] = max_metric
	FROM cte_to_update t;

	WITH cte_to_update
	AS (
		SELECT a.*
			,max([30+ на 60 день]) OVER (PARTITION BY a.contract_name) AS max_metric
		FROM [dwh2].[risk].[Запросто_postgre] a
		)
	UPDATE t
	SET t.[30+ на 60 день] = max_metric
	FROM cte_to_update t;

	WITH cte_to_update
	AS (
		SELECT a.*
			,max([45+ на 60 день]) OVER (PARTITION BY a.contract_name) AS max_metric
		FROM [risk].[Запросто_postgre] a
		)
	UPDATE t
	SET t.[45+ на 60 день] = max_metric
	FROM cte_to_update t;

	WITH cte_to_update
	AS (
		SELECT a.*
			,max([45+ на 90 день]) OVER (PARTITION BY a.contract_name) AS max_metric
		FROM [risk].[Запросто_postgre] a
		)
	UPDATE t
	SET t.[45+ на 90 день] = max_metric
	FROM cte_to_update t;

	WITH cte_to_update
	AS (
		SELECT a.*
			,max([45+ ever]) OVER (PARTITION BY a.contract_name) AS max_metric
		FROM [risk].[Запросто_postgre] a
		)
	UPDATE t
	SET t.[45+ ever] = max_metric
	FROM cte_to_update t;

	UPDATE [risk].[Запросто_postgre]
	SET [7+ на 30] = 0
	WHERE max_dob >= 30
		AND [7+ на 30] IS NULL;

	UPDATE [risk].[Запросто_postgre]
	SET [30+ на 60 день] = 0
	WHERE max_dob >= 60
		AND [30+ на 60 день] IS NULL;

	UPDATE [risk].[Запросто_postgre]
	SET [45+ на 60 день] = 0
	WHERE max_dob >= 60
		AND [45+ на 60 день] IS NULL;

	UPDATE [risk].[Запросто_postgre]
	SET [45+ на 90 день] = 0
	WHERE max_dob >= 90
		AND [45+ на 90 день] IS NULL;

	--brand
	UPDATE risk.Запросто_postgre
	SET brand = 'samsung'
	WHERE lower(collateral_properties) LIKE '%samsung%'
		AND brand IS NULL;

	UPDATE risk.Запросто_postgre
	SET brand = 'xiaomi'
	WHERE lower(collateral_properties) LIKE '%xiaomi%'
		AND brand IS NULL;

	--brand
	UPDATE risk.Запросто_postgre
	SET brand = 'samsung'
	WHERE lower(collateral_properties) LIKE '%samsung%'
		AND brand IS NULL;

	UPDATE risk.Запросто_postgre
	SET brand = 'xiaomi'
	WHERE lower(collateral_properties) LIKE '%xiaomi%'
		AND brand IS NULL;

	WITH cte_to_update
	AS (
		SELECT a.*
			,CASE 
				WHEN lower(za.event_name) LIKE '%картинка%'
					THEN 'Wallpaper'
				WHEN lower(za.event_name) LIKE '%блокировка%'
					THEN 'Block'
				ELSE NULL
				END AS maction
		FROM [risk].[Запросто_postgre] a
		LEFT JOIN risk.Запросто_actions za ON za.IMEI = a.imei
			AND cast(za.action_time AS DATE) = a.report_date
			AND lower(za.[status_name]) = 'configured'
			AND (
				lower(za.event_name) LIKE '%картинка%'
				OR lower(za.event_name) LIKE '%блокировка%'
				)
			AND lower(za.event_name) LIKE '%applied%'
		)
	UPDATE t
	SET t.[action] = t.maction
	FROM cte_to_update t;
END;
