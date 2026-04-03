
--exec [risk].[monitoring_car_brand];
CREATE PROCEDURE [risk].[monitoring_car_brand]
AS
BEGIN
	DECLARE @srcname VARCHAR(100) = 'MONITORING DET_CAR_BRAND_MAPPING';
	DECLARE @vinfo VARCHAR(1000);
	DECLARE @cnt INT;

	BEGIN TRY
		EXEC risk.set_debug_info @src = @srcname
			,@info = 'START';

		-- Обогащаем справочник Марок данными из всех источников
		-- 1) Логином, name_brand
		DROP TABLE

		IF EXISTS #BRANDS;
			SELECT DISTINCT a.name_brand AS brand
			INTO #BRANDS
			FROM stg._loginom.originationlog a
			WHERE a.name_brand IS NOT NULL;

		EXEC risk.set_debug_info @src = @srcname
			,@info = 'LOGINOM.NAME_BRAND';

		-- 2) Логином, brand
		MERGE INTO #BRANDS dst
		USING (
			SELECT DISTINCT a.Brand AS brand
			FROM stg._loginom.Originationlog a
			WHERE a.Brand IS NOT NULL
			) src
			ON (dst.brand = src.brand)
		WHEN NOT MATCHED
			THEN
				INSERT (brand)
				VALUES (src.brand);

		EXEC risk.set_debug_info @src = @srcname
			,@info = 'LOGINOM.BRAND';

		-- 3) Федор, справочник
		MERGE INTO #BRANDS dst
		USING (
			SELECT DISTINCT a.Name AS brand
			FROM stg._fedor.dictionary_TsBrand a
			) src
			ON (dst.brand = src.brand collate SQL_Latin1_General_CP1_CI_AS)
		WHEN NOT MATCHED
			THEN
				INSERT (brand)
				VALUES (src.brand);

		EXEC risk.set_debug_info @src = @srcname
			,@info = 'FEDOR.DICT';

		-- 4) МФО, МаркаАвто
		MERGE INTO #BRANDS dst
		USING (
			SELECT DISTINCT a.МаркаАвто AS brand
			FROM stg._1cMFO.Документ_ГП_Заявка a
			WHERE a.МаркаАвто IS NOT NULL
				AND a.Дата >= '4018-01-01'
			) src
			ON (dst.brand = src.brand collate SQL_Latin1_General_CP1_CI_AS)
		WHEN NOT MATCHED
			THEN
				INSERT (brand)
				VALUES (src.brand);

		EXEC risk.set_debug_info @src = @srcname
			,@info = 'MFO.МАРКААВТО';

		-- 5) МФО. Справочник
		MERGE INTO #BRANDS dst
		USING (
			SELECT DISTINCT a.Наименование AS brand
			FROM stg._1cMFO.Справочник_ГП_МаркаАвтомобиля a
			) src
			ON (dst.brand = src.brand collate SQL_Latin1_General_CP1_CI_AS)
		WHEN NOT MATCHED
			THEN
				INSERT (brand)
				VALUES (src.brand);

		EXEC risk.set_debug_info @src = @srcname
			,@info = 'MFO.DICT';

		SELECT @cnt = count(*)
		FROM (
			SELECT a.brand
				,CASE 
					WHEN a.brand NOT LIKE '%[^0-9-]%'
						THEN '__UNKNOWN' --марка состоит только из цифр и дефисов
					END AS mark_code
			FROM #BRANDS a
			WHERE NOT EXISTS (
					SELECT 1
					FROM risk.det_car_brand_mapping b
					WHERE a.brand = b.portf_brand
					)
			) a

		SELECT @vinfo = CASE 
				WHEN @cnt = 0
					THEN 'No new brand'
				ELSE CONCAT (
						'New brand cnt = '
						,@cnt
						)
				END;

		IF @cnt > 0
		BEGIN
			BEGIN TRANSACTION;

			-- Добавляем новые записи в справочник
			MERGE INTO risk.det_car_brand_mapping dst
			USING (
				SELECT a.brand
					,CASE 
						WHEN a.brand NOT LIKE '%[^0-9-]%'
							THEN '__UNKNOWN' --марка состоит только из цифр и дефисов
						END AS mark_code
				FROM #BRANDS a
				WHERE NOT EXISTS (
						SELECT 1
						FROM risk.det_car_brand_mapping b
						WHERE a.brand = b.portf_brand
						)
				) src
				ON (dst.portf_brand = src.brand)
			WHEN NOT MATCHED
				THEN
					INSERT (
						portf_brand
						,mark_code
						)
					VALUES (
						src.brand
						,src.mark_code
						);

			COMMIT TRANSACTION;

			EXEC risk.set_debug_info @src = @srcname
				,@info = 'MERGE INTO det_car_brand_mapping';

			--Оповещение по Email 
			DECLARE @body NVARCHAR(1024) = 'Появились новые записи в справочнике DET_CAR_BRAND_MAPPING - ' + cast(@cnt AS NVARCHAR(255))

			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
				,@recipients = 'a.kuznecov@techmoney.ru; d.cyplakov@carmoney.ru'
				,@body = @body
				,@body_format = 'HTML'
				,@subject = 'Появились новые записи в справочнике DET_CAR_BRAND_MAPPING'
		END

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
