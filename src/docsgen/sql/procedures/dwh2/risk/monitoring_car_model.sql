
--exec [risk].[monitoring_car_model]

CREATE PROCEDURE [risk].[monitoring_car_model]
AS
BEGIN
	DECLARE @srcname VARCHAR(100) = 'MONITORING DET_CAR_MODEL_MAPPING';
	DECLARE @vinfo VARCHAR(1000);
	DECLARE @cnt INT;

	BEGIN TRY
		EXEC risk.set_debug_info @src = @srcname
			,@info = 'START';

		--сборка выдач за последний месяц
		DROP TABLE

		IF EXISTS #stg_cred;
			WITH base
			AS (
				SELECT a.Код AS external_id
					,dateadd(yy, - 2000, cast(c.Период AS DATETIME)) AS status_dt
					,d.Наименование AS status_name
					,ROW_NUMBER() OVER (
						PARTITION BY a.Код ORDER BY c.Период DESC
						) AS rown
				FROM stg._1cCMR.Справочник_Договоры a
				LEFT JOIN stg._1cCMR.РегистрСведений_СтатусыДоговоров c ON a.Ссылка = c.Договор
				LEFT JOIN stg._1cCMR.Справочник_СтатусыДоговоров d ON c.Статус = d.Ссылка
				WHERE dateadd(yy, - 2000, cast(a.Дата AS DATE)) >= dateadd(dd, - 30, cast(getdate() AS DATE))
					AND dateadd(yy, - 2000, cast(a.Дата AS DATE)) < dateadd(dd, 0, cast(getdate() AS DATE)) --cast(getdate() as date)
					AND a.ПометкаУдаления = 0
					AND a.Тестовый = 0
				)
			SELECT a.external_id
				,a.status_dt
				,a.status_name
			INTO #stg_cred
			FROM base a
			WHERE 1 = 1
				AND a.rown = 1
				AND a.status_name NOT IN ('Аннулирован', 'Зарегистрирован');

		EXEC risk.set_debug_info @src = @srcname
			,@info = '#stg_cred';

		--залог
		DROP TABLE

		IF EXISTS #cred_pledge;
			SELECT DISTINCT a.external_id
				,b.vin AS VIN
			INTO #cred_pledge
			FROM #stg_cred a
			INNER JOIN risk.strategy_datamart b ON a.external_id = b.external_id;

		EXEC risk.set_debug_info @src = @srcname
			,@info = '#cred_pledge';

		--------------FEDOR------------------------------------------------------------------------------
		DROP TABLE

		IF EXISTS #stg_fedor;
			SELECT a.VIN
				,b.CreatedOn AS app_dt
				,b.Number AS app_id
				,br.[Name] AS brand
				,mdl.[Name] AS model
				,cast(1 AS BIT) AS flag_significant
			INTO #stg_fedor
			FROM (
				SELECT DISTINCT VIN
				FROM #cred_pledge
				) a
			INNER JOIN stg._fedor.core_ClientRequest b ON a.VIN = b.Vin collate Cyrillic_General_CI_AS
			INNER JOIN stg._fedor.core_ClientAssetTs c ON b.IdAsset = c.Id
			LEFT JOIN stg._fedor.dictionary_TsBrand br --марка
				ON b.IdTsBrand = br.Id
			LEFT JOIN stg._fedor.dictionary_TsModel mdl --модель
				ON b.IdTsModel = mdl.Id
			WHERE cast(b.CreatedOn AS DATE) < cast(getdate() AS DATE);

		UPDATE #stg_fedor
		SET flag_significant = 0
		WHERE brand IS NULL
			AND model IS NULL;

		DELETE
		FROM #stg_fedor
		WHERE flag_significant = 0;

		EXEC risk.set_debug_info @src = @srcname
			,@info = '#stg_fedor';

		-------------- МФО ------------------------------------------------------------------------------
		DROP TABLE

		IF EXISTS #stg_MFO;
			SELECT a.VIN
				,a.Номер AS app_id
				,dateadd(yy, - 2000, cast(a.Дата AS DATE)) AS app_date
				,a.МаркаАвто AS brand
				,a.МодельАвто AS model
				,cast(1 AS BIT) AS flag_significant
			INTO #stg_MFO
			FROM stg._1cMFO.Документ_ГП_Заявка a
			INNER JOIN (
				SELECT DISTINCT vin
				FROM #cred_pledge
				) b ON a.VIN = b.VIN
			WHERE dateadd(yy, - 2000, cast(a.Дата AS DATE)) < cast(getdate() AS DATE);

		UPDATE #stg_MFO
		SET flag_significant = 0
		WHERE brand IS NULL
			AND model IS NULL;

		DELETE
		FROM #stg_MFO
		WHERE flag_significant = 0;

		EXEC risk.set_debug_info @src = @srcname
			,@info = '#stg_mfo';

		---объединение всех источников
		DROP TABLE

		IF EXISTS #stg_total;
			SELECT a.VIN
				,a.app_dt AS dt1
				,a.app_dt AS dt2
				,'FEDOR' AS src
				,a.brand collate Cyrillic_General_CI_AS AS brand
				,a.model collate Cyrillic_General_CI_AS AS model
			INTO #stg_total
			FROM #stg_fedor a
			
			UNION ALL
			
			SELECT a.VIN
				,a.app_date AS dt1
				,a.app_date AS dt2
				,'MFO' AS src
				,a.brand
				,a.model
			FROM #stg_MFO a;

		EXEC risk.set_debug_info @src = @srcname
			,@info = '#stg_total';

		-- Марка + модель
		DROP TABLE

		IF EXISTS #final_brand_model;
			WITH base2
			AS (
				SELECT a.VIN
					,a.brand
					,a.model
					,ROW_NUMBER() OVER (
						PARTITION BY a.vin ORDER BY CASE 
								WHEN CONCAT (
										a.brand
										,a.model
										) NOT LIKE '%[а-яА-Я]%'
									THEN 1
								ELSE 0
								END DESC
							,a.dt1 DESC
						) AS rown
				FROM #stg_total a
				WHERE a.brand IS NOT NULL
					AND a.model IS NOT NULL
				)
			SELECT a.VIN
				,a.brand
				,a.model
			INTO #final_brand_model
			FROM base2 a
			WHERE a.rown = 1;

		EXEC risk.set_debug_info @src = @srcname
			,@info = '#final_brand_model';

		DROP TABLE

		IF EXISTS #new_brandmodel;
			SELECT DISTINCT a.brand
				,a.model
			INTO #new_brandmodel
			FROM #final_brand_model a
			LEFT JOIN risk.det_car_model_mapping b ON a.brand = b.portf_brand
				AND a.model = b.portf_model
			WHERE b.portf_brand IS NULL;

		SELECT @cnt = count(*)
		FROM #new_brandmodel;

		SELECT @vinfo = CASE 
				WHEN @cnt = 0
					THEN 'No new brand-model'
				ELSE CONCAT (
						'New brand-model cnt = '
						,@cnt
						)
				END;

		EXEC risk.set_debug_info @src = @srcname
			,@info = @vinfo;

		IF @cnt > 0
		BEGIN
			EXEC risk.set_debug_info @src = @srcname
				,@info = 'MERGE Into DET';

			BEGIN TRANSACTION;

			MERGE INTO risk.det_car_model_mapping dst
			USING #new_brandmodel src
				ON (
						src.brand = dst.portf_brand
						AND src.model = dst.portf_model
						)
			WHEN NOT MATCHED
				THEN
					INSERT (
						portf_brand
						,portf_model
						)
					VALUES (
						src.brand
						,src.model
						);

			COMMIT TRANSACTION;

			--Оповещение по Email
			DECLARE @subject1 NVARCHAR(255) = 'Появились новые записи в справочнике DET_CAR_MODEL_MAPPING'
			DECLARE @body NVARCHAR(1024) = 'Появились новые записи в справочнике DET_CAR_MODEL_MAPPING - ' + cast(@cnt AS NVARCHAR(255))

			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
				,@recipients = 'a.kuznecov@techmoney.ru; d.cyplakov@carmoney.ru'
				,@body = @body
				,@body_format = 'HTML'
				,@subject = 'Появились новые записи в справочнике DET_CAR_MODEL_MAPPING'
		END;

		EXEC risk.set_debug_info @src = @srcname
			,@info = 'FINISH';
	END TRY

	BEGIN CATCH
		DECLARE @msg2 NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@srcname
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		DECLARE @subject2 NVARCHAR(255) = CONCAT (
				'Ошибка выполнение процедуры '
				,@srcname
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'a.kuznecov@techmoney.ru; d.cyplakov@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg2
			,@body_format = 'TEXT'
			,@subject = @subject2;

		throw 51000
			,@msg2
			,1
	END CATCH
END;
