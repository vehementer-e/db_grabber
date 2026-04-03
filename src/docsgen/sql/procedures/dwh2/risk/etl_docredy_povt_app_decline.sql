
--exec [risk].[etl_docredy_povt_app_decline];
CREATE PROCEDURE [risk].[etl_docredy_povt_app_decline]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)

	BEGIN TRY
		DROP TABLE

		IF EXISTS #declines_client;
			SELECT DISTINCT cast(a.Number AS NVARCHAR(100)) AS external_id
			INTO #declines_client
			FROM stg.[_loginom].decision_code a WITH (NOLOCK)
			WHERE 1 = 1
				AND (
					[Values] = '100.0060.015'
					AND cast([Datetime] AS DATE) >= dateadd(dd, - 6, cast(getdate() AS DATE))
					OR [Values] IN ('100.0406.007', '100.0406.008')
					AND cast([Datetime] AS DATE) >= dateadd(dd, - 29, cast(getdate() AS DATE))
					);

		INSERT INTO #declines_client
		SELECT cast(a.Number AS NVARCHAR(100)) AS external_id
		FROM stg.[_loginom].callcheckverif_log a WITH (NOLOCK)
		WHERE 1 = 1
			AND (
				(
					Result_2_4 = '100.0204.002'
					OR Result_2_6 IN ('100.0206.007', '100.0206.008')
					OR Result_2_8 IN ('100.0208.002', '100.0208.004', '100.0208.008')
					OR Result_2_10 IN ('100.0210.004', '100.0210.005', '100.0210.006')
					OR Result_2_11 = '100.0211.002'
					OR Result_2_13 = '100.0213.001'
					OR Result_3_2 IN ('100.0302.001', '100.0302.003')
					)
				AND cast(Call_date AS DATE) >= dateadd(dd, - 29, cast(getdate() AS DATE))
				OR (
					Result_1_1 = '100.0101.002'
					OR Result_2_8 = '100.0208.009'
					OR Result_2_11 = '100.0211.004'
					OR Result_2_13 = '100.0213.006'
					OR Result_3_1 = '100.0301.006'
					OR Result_3_2 IN ('100.0302.008', '100.0302.005', '100.0302.006')
					)
				)
			AND NOT EXISTS (
				SELECT 1
				FROM #declines_client b
				WHERE cast(a.number AS NVARCHAR(100)) = b.external_id
				);

		--Отказы по Авто
		DROP TABLE

		IF EXISTS #declines_car;
			SELECT DISTINCT cast(a.Number AS NVARCHAR(100)) AS external_id
			INTO #declines_car
			FROM stg.[_loginom].decision_code a WITH (NOLOCK)
			WHERE 1 = 1
				AND (
					[Values] IN ('100.0406.007', '100.0406.008')
					AND cast([Datetime] AS DATE) >= dateadd(dd, - 29, cast(getdate() AS DATE))
					);

		INSERT INTO #declines_car
		SELECT cast(a.Number AS NVARCHAR(100)) AS external_id
		FROM stg.[_loginom].callcheckverif_log a WITH (NOLOCK)
		WHERE 1 = 1
			AND (
				(
					Result_2_13 = '100.0213.008'
					OR Result_2_14 = '100.0214.006'
					)
				AND cast(Call_date AS DATE) >= dateadd(dd, - 6, cast(getdate() AS DATE))
				OR (
					Result_2_6 IN ('100.0206.007', '100.0206.008', '100.0206.002', '100.0206.004')
					OR Result_2_14 = '100.0214.004'
					OR Result_3_1 IN ('100.0301.004', '100.0301.006')
					)
				AND cast(Call_date AS DATE) >= dateadd(dd, - 29, cast(getdate() AS DATE))
				OR (
					Result_2_6 IN ('100.0206.005', '100.0206.006')
					OR Result_2_14 = '100.0214.001'
					OR Result_3_1 IN ('100.0301.002', '100.0301.003')
					)
				)
			AND NOT EXISTS (
				SELECT 1
				FROM #declines_car b
				WHERE cast(a.number AS NVARCHAR(100)) = b.external_id
				);

		--реестр заявок с ФИО, датой рождения, паспортом, VIN
		DROP TABLE

		IF EXISTS #app_info;
			SELECT cast(a.Number AS NVARCHAR(100)) AS external_id
				,a.Stage
				,a.Call_date
				,a.Last_name
				,a.First_name
				,a.Patronymic
				,cast(a.Birth_date AS DATE) AS birth_date
				,a.Passport_series
				,a.Passport_number
				,a.Vin
			INTO #app_info
			FROM Stg._loginom.Originationlog a WITH (NOLOCK);

		---отказы: ФИО+Дата рождения
		DROP TABLE

		IF EXISTS #fio_db_red_decline;
			WITH base
			AS (
				SELECT a.external_id
					,b.Call_date
					,CONCAT (
						trim(b.Last_name)
						,' '
						,trim(b.First_name)
						,' '
						,trim(b.Patronymic)
						) AS fio
					,b.birth_date
					,CONCAT (
						trim(b.Last_name)
						,' '
						,trim(b.First_name)
						,' '
						,trim(b.Patronymic)
						,' '
						,isnull(birth_date, '19000101')
						) AS fio_bd
					,ROW_NUMBER() OVER (
						PARTITION BY a.external_id ORDER BY b.call_date DESC
						) AS rown
				FROM #declines_client a
				INNER JOIN #app_info b ON a.external_id = b.external_id
				WHERE 1 = 1
					AND b.Birth_date IS NOT NULL
					AND b.Last_name IS NOT NULL
					AND b.First_name IS NOT NULL
				)
			SELECT cast(getdate() AS DATETIME) AS dt_dml
				,a.fio
				,a.birth_date
				,a.fio_bd
				,STRING_AGG(a.external_id, ', ') AS app_list
			INTO #fio_db_red_decline
			FROM base a
			WHERE a.rown = 1
			GROUP BY a.fio
				,a.birth_date
				,a.fio_bd;

		---отказы: Паспорта
		DROP TABLE

		IF EXISTS #passport_red_decline;
			WITH base
			AS (
				SELECT a.external_id
					,b.Call_date
					,b.Passport_series
					,b.Passport_number
					,ROW_NUMBER() OVER (
						PARTITION BY a.external_id ORDER BY b.call_date DESC
						) AS rown
				FROM #declines_client a
				INNER JOIN #app_info b ON a.external_id = b.external_id
				WHERE 1 = 1
					AND b.Passport_number IS NOT NULL
					AND b.Passport_series IS NOT NULL
				)
			SELECT cast(getdate() AS DATETIME) AS dt_dml
				,a.Passport_series
				,a.Passport_number
				,STRING_AGG(a.external_id, ', ') AS app_list
			INTO #passport_red_decline
			FROM base a
			WHERE a.rown = 1
			GROUP BY a.Passport_series
				,a.Passport_number;

		---отказы: VIN (авто)
		DROP TABLE

		IF EXISTS #vin_red_decline;
			WITH base
			AS (
				SELECT a.external_id
					,b.Call_date
					,b.Vin
					,ROW_NUMBER() OVER (
						PARTITION BY a.external_id ORDER BY b.call_date DESC
						) AS rown
				FROM #declines_car a
				INNER JOIN #app_info b ON a.external_id = b.external_id
				WHERE b.Vin IS NOT NULL
				)
			SELECT cast(getdate() AS DATETIME) AS dt_dml
				,a.Vin
				,STRING_AGG(a.external_id, ', ') AS app_list
			INTO #vin_red_decline
			FROM base a
			WHERE a.rown = 1
			GROUP BY a.Vin;

		--удаляем временные таблицы, которые далее не используются
		DROP TABLE #app_info;

		DROP TABLE #declines_car;

		DROP TABLE #declines_client;

		--Запись в таблицы 
		BEGIN TRANSACTION

		DELETE
		FROM risk.docr_povt_fio_db_red_decline
		WHERE cdate = cast(getdate() AS DATE);

		INSERT INTO risk.docr_povt_fio_db_red_decline (
			dt_dml
			,fio
			,birth_date
			,fio_bd
			,app_list
			,cdate
			)
		SELECT a.dt_dml
			,a.fio
			,a.birth_date
			,a.fio_bd
			,a.app_list
			,cast(getdate() AS DATE) AS cdate
		FROM #fio_db_red_decline a;

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;

		DELETE
		FROM risk.docr_povt_passport_red_decline
		WHERE cdate = cast(getdate() AS DATE);

		INSERT INTO risk.docr_povt_passport_red_decline (
			dt_dml
			,Passport_series
			,Passport_number
			,app_list
			,cdate
			)
		SELECT a.dt_dml
			,a.Passport_series
			,a.Passport_number
			,a.app_list
			,cast(getdate() AS DATE) AS cdate
		FROM #passport_red_decline a;

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;

		DELETE
		FROM risk.docr_povt_vin_red_decline
		WHERE cdate = cast(getdate() AS DATE);

		INSERT INTO risk.docr_povt_vin_red_decline (
			dt_dml
			,Vin
			,app_list
			,cdate
			)
		SELECT a.dt_dml
			,a.Vin
			,a.app_list
			,cast(getdate() AS DATE) AS cdate
		FROM #vin_red_decline a;

		COMMIT TRANSACTION;

		EXEC risk.set_debug_info @sp_name
			,'FINISH';
	END TRY

	BEGIN CATCH
		SET @msg = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		SET @subject = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		EXEC msdb.dbo.sp_send_dbmail @recipients = 'a.kuznecov@techmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;
