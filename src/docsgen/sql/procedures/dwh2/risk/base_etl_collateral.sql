
--exec [dwh2].[risk].[base_etl_collateral];
CREATE PROCEDURE [risk].[base_etl_collateral]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)

	BEGIN TRY
		DROP TABLE

		IF EXISTS #staging_collateral;
			--Федор
			SELECT b.CreatedOn AS coll_dt
				,cast(b.Vin AS VARCHAR(200)) collate Cyrillic_General_CI_AS AS VIN
				,br.[Name] collate Cyrillic_General_CI_AS AS brand
				,mdl.[Name] collate Cyrillic_General_CI_AS AS model
				,CASE 
					WHEN b.Mileage <= 10
						THEN NULL
					ELSE cast(b.Mileage AS FLOAT)
					END AS Mileage
				,clr.[Name] collate Cyrillic_General_CI_AS AS color
				,CASE 
					WHEN tr.[Name] = 'Автомат'
						THEN 'AT'
					WHEN tr.[Name] = 'Робот'
						THEN 'AMT'
					WHEN tr.[Name] = 'Вариатор'
						THEN 'CVT'
					WHEN tr.[Name] = 'Механическая'
						THEN 'MT'
					ELSE NULL
					END AS transmission
				,cast(NULL AS FLOAT) AS engine_volume
				,b.TSyear AS TSyear
				,bdt.[name] collate Cyrillic_General_CI_AS AS body_type
				,cast(NULL AS FLOAT) AS power_HP
				,b.TsMarketPrice AS last_marketprice
				,b.CarEstimationPrice AS last_estimatedprice
				,tc.name AS tscategory
				,cast(NULL AS BIT) AS is_overturned_ts
				,cast(NULL AS BIT) AS is_modified_ts
				,cast('FEDOR' AS VARCHAR(100)) AS coll_src
			INTO #staging_collateral
			FROM stg._fedor.core_ClientRequest b
			INNER JOIN stg._fedor.core_ClientAssetTs c ON b.IdAsset = c.Id
			LEFT JOIN stg._fedor.dictionary_TsBrand br --марка
				ON b.IdTsBrand = br.Id
			LEFT JOIN stg._fedor.dictionary_TsModel mdl --модель
				ON b.IdTsModel = mdl.Id
			LEFT JOIN stg._fedor.dictionary_TsColor clr --цвет (по справочнику АвтоРу)
				ON c.IdTsColor = clr.Id
			LEFT JOIN stg._fedor.dictionary_Transmission tr --коробка
				ON c.IdTransmission = tr.Id
			LEFT JOIN stg._fedor.dictionary_BodyType bdt ON c.IdBodyType = bdt.id
			LEFT JOIN stg._fedor.dictionary_TsCategory tc ON tc.Id = c.IdTsCategory
			WHERE b.Vin <> '';

		--МФО
		INSERT INTO #staging_collateral
		SELECT dateadd(yy, - 2000, cast(a.Дата AS DATE)) AS coll_dt
			,a.VIN
			,a.МаркаАвто AS brand
			,a.МодельАвто AS model
			,CASE 
				WHEN a.Пробег < 10
					THEN NULL
				ELSE cast(a.Пробег AS FLOAT)
				END AS mileage
			,clr.Наименование AS color
			,CASE 
				WHEN kpp.Наименование IN ('АКПП', 'АКПП')
					THEN 'AT'
				WHEN kpp.Наименование IN ('Вариатор')
					THEN 'CVT'
				WHEN kpp.Наименование IN ('Робот')
					THEN 'AMT'
				WHEN kpp.Наименование IN ('МКПП', 'Механическая')
					THEN 'MT'
				END AS transmission
			,CASE 
				WHEN a.Объем <= 0
					THEN NULL
				ELSE cast(a.Объем AS FLOAT)
				END AS engine_volume
			,CASE 
				WHEN isnull(a.ГодАвто, 0) = 0
					AND a.Год BETWEEN 1950
						AND year(getdate())
					THEN a.Год
				WHEN a.ГодАвто BETWEEN 1950
						AND year(getdate())
					THEN cast(a.ГодАвто AS FLOAT)
				END AS TSyear
			,iif(bdt.Наименование = '', NULL, bdt.Наименование) AS body_type
			,cast(NULL AS FLOAT) AS power_HP
			,a.РыночнаяСтоимостьАвтоНаМоментОценки AS last_marketprice
			,cast(NULL AS FLOAT) AS last_estimatedprice
			,CASE 
				WHEN ВидТС_НаПечать = - 2047813255
					THEN 'B'
				WHEN ВидТС_НаПечать = - 816241412
					THEN 'C'
				WHEN ВидТС_НаПечать = - 615300972
					THEN 'D'
				END AS tscategory
			,cast(NULL AS BIT) AS is_overturned_ts
			,cast(NULL AS BIT) AS is_modified_ts
			,'MFO' AS coll_src
		FROM stg._1cMFO.Документ_ГП_Заявка a
		LEFT JOIN stg._1cMFO.Справочник_ГП_ЦветТС clr ON a.Цвет = clr.Ссылка
		LEFT JOIN stg._1cMfo.Справочник_ГП_ВидыКоробокПередач kpp ON a.КПП = kpp.ссылка
		LEFT JOIN stg._1cMfo.Справочник_ГП_ТипыКузова bdt ON a.ТипКузова = bdt.ссылка
		WHERE a.VIN <> '';

		--LOGINOM
		INSERT INTO #staging_collateral
		SELECT coalesce(a.gibdd_request_date, cl.call_date, ol.call_date) AS coll_dt
			,isnull(a.vin, ol.vin) AS vin
			,isnull(a.brand, ol.brand) AS brand
			,isnull(a.brand, ol.model) AS model
			,cast(NULL AS FLOAT) AS mileage
			,iif(a.history_color = '', NULL, a.history_color) AS color
			,cast(NULL AS VARCHAR(100)) AS transmission
			,cast(replace(iif(a.history_engineVolume = '', NULL, a.history_engineVolume), ',', '.') AS FLOAT) AS engine_volume
			,cast(replace(iif(a.history_year = '', NULL, a.history_year), ',', '.') AS FLOAT) AS TSyear
			,iif(a.history_type = '', NULL, a.history_type) AS body_type
			,cast(replace(iif(a.history_powerHp = '', NULL, a.history_powerHp), ',', '.') AS FLOAT) AS power_HP
			,cast(NULL AS FLOAT) AS last_marketprice
			,cast(NULL AS FLOAT) AS last_estimatedprice
			,cast(NULL AS VARCHAR(100)) AS tscategory
			,CASE 
				WHEN (
						a.accidents = 1
						AND lower(a.accidents_accidentType) LIKE '%опрокидывание%'
						)
					OR gp.number IS NOT NULL
					THEN 1
				ELSE 0
				END AS is_overturned_ts
			,CASE 
				WHEN cl.number IS NOT NULL
					THEN 1
				ELSE 0
				END AS is_modified_ts --Переоборудование авто
			,'LOGINOM' AS coll_src
		FROM stg._loginom.Originationlog ol
		LEFT JOIN stg._loginom.gibdd_response a ON ol.Number = a.external_id
		LEFT JOIN stg._loginom.Origination_gibdd_parse gp ON gp.number = ol.Number
			AND gp.accidents = 1
			AND lower(gp.accidents_accidentType) LIKE '%опрокидывание%'
		LEFT JOIN stg._loginom.callcheckverif_log cl ON cl.number = ol.Number
		    /*!! 07/08/2023 - временно*/
			AND isnull(cl.Result_1_11, cl.ch_result_11) = '100.0111.001'
		WHERE isnull(ol.vin, a.vin) <> ''
			AND ol.stage IN ('Call 1', 'Call 2');

		CREATE INDEX IX_STG_COLL_VIN ON #staging_collateral (VIN);

		DROP TABLE

		IF EXISTS #staging_collateral_src;
			SELECT DISTINCT cast(coalesce(crq.vin Collate Cyrillic_General_CI_AS, mz.vin) AS VARCHAR(1000)) AS VIN
			INTO #staging_collateral_src
			FROM stg._1ccmr.Справочник_Договоры a
			LEFT JOIN stg._1cMFO.Документ_ГП_Заявка mz ON mz.Номер = a.Код
			LEFT JOIN Stg._fedor.core_ClientRequest crq ON a.Код = crq.number Collate Cyrillic_General_CI_AS
			WHERE coalesce(crq.vin Collate Cyrillic_General_CI_AS, mz.vin) <> '';

		CREATE INDEX IX_STG_COLL_SRC_VIN ON #staging_collateral_src (VIN);

		DROP TABLE

		IF EXISTS #cdate;
			SELECT a.VIN
				,cast(max(a.coll_dt) AS DATE) AS src_dt
			INTO #cdate
			FROM #staging_collateral a
			GROUP BY a.vin;

		DROP TABLE

		IF EXISTS #final_brand_model;
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
						,a.coll_dt DESC
					) AS rn
			INTO #final_brand_model
			FROM #staging_collateral a
			WHERE a.brand IS NOT NULL
				AND a.model IS NOT NULL;

		DROP TABLE

		IF EXISTS #final_year;
			SELECT a.VIN
				,a.TsYear
				,ROW_NUMBER() OVER (
					PARTITION BY a.vin ORDER BY a.coll_dt DESC
					) AS rn
			INTO #final_year
			FROM #staging_collateral a
			WHERE a.TsYear IS NOT NULL;

		DROP TABLE

		IF EXISTS #stg_color;
			SELECT a.VIN
				,a.color
				,ROW_NUMBER() OVER (
					PARTITION BY a.vin ORDER BY a.coll_dt DESC
					) AS rn
			INTO #stg_color
			FROM #staging_collateral a
			WHERE a.color IS NOT NULL

		DROP TABLE

		IF EXISTS #final_color;
			SELECT b.VIN
				,b.color AS color_asis
				,c.car_color_tobe AS color
				,c.hex_code
			INTO #final_color
			FROM #stg_color b
			LEFT JOIN RISK.DICT_CAR_COLOR_MAPPING c ON isnull(b.color, 'xxx') = isnull(c.original_color, 'xxx')
			WHERE b.rn = 1;

		DROP TABLE

		IF EXISTS #transmission;
			SELECT a.VIN
				,a.transmission
				,ROW_NUMBER() OVER (
					PARTITION BY a.vin ORDER BY a.coll_dt DESC
					) AS rn
			INTO #transmission
			FROM #staging_collateral a
			WHERE a.transmission IS NOT NULL;

		DROP TABLE

		IF EXISTS #final_engine_volume;
			SELECT a.VIN
				,round(a.engine_volume / 1000.0, 1) AS engine_volume
				,ROW_NUMBER() OVER (
					PARTITION BY a.vin ORDER BY coll_dt DESC
					) AS rn
			INTO #final_engine_volume
			FROM #staging_collateral a
			WHERE a.engine_volume IS NOT NULL

		DROP TABLE

		IF EXISTS #final_power;
			SELECT a.VIN
				,a.power_HP
				,ROW_NUMBER() OVER (
					PARTITION BY a.vin ORDER BY coll_dt DESC
					) AS rn
			INTO #final_power
			FROM #staging_collateral a
			WHERE a.power_HP IS NOT NULL;

		DROP TABLE

		IF EXISTS #stg_calc_mileage
			SELECT a.VIN
				,a.Mileage
				,b.TSyear
				,a.coll_dt
				,ROW_NUMBER() OVER (
					PARTITION BY a.vin ORDER BY coll_dt DESC
					) AS rn
			INTO #stg_calc_mileage
			FROM #staging_collateral a
			LEFT JOIN #final_year b ON a.VIN = b.VIN
				AND b.rn = 1
			WHERE a.Mileage IS NOT NULL;

		DROP TABLE

		IF EXISTS #calc_mileage
			SELECT a.VIN
				,a.TsYear
				,round(case when cast(year(a.coll_dt) - a.TsYear + 1 AS FLOAT)=0 then a.Mileage else a.Mileage + DATEDIFF(dd, a.coll_dt, getdate()) * (a.Mileage / cast(year(a.coll_dt) - a.TsYear + 1 AS FLOAT)) / 365.0 end, 0)AS mileage
			INTO #calc_mileage
			FROM #stg_calc_mileage a
			WHERE a.rn = 1;

		DROP TABLE

		IF EXISTS #final_body_type;
			SELECT a.VIN
				,a.body_type
				,ROW_NUMBER() OVER (
					PARTITION BY a.vin ORDER BY a.coll_dt DESC
					) AS rn
			INTO #final_body_type
			FROM #staging_collateral a
			WHERE a.body_type IS NOT NULL;

		DROP TABLE

		IF EXISTS #stg_ownership_periods;
			SELECT DISTINCT a.vin
				,a.gibdd_request_date
				,a.history_ownershipPeriods_from
				,a.history_ownershipPeriods_to
			INTO #stg_ownership_periods
			FROM stg._loginom.gibdd_response a
			WHERE a.vin IS NOT NULL
				AND a.history_ownershipPeriods_from IS NOT NULL;

		DROP TABLE

		IF EXISTS #ownership_periods;
			SELECT a.vin
				,count(*) AS owners_count
			INTO #ownership_periods
			FROM #stg_ownership_periods a
			INNER JOIN (
				SELECT a.vin
					,max(a.gibdd_request_date) AS mx_dt
				FROM #stg_ownership_periods a
				GROUP BY a.vin
				) b ON a.vin = b.vin
				AND a.gibdd_request_date = b.mx_dt
			GROUP BY a.vin;

		DROP TABLE

		IF EXISTS #final_uw_est_price;
			SELECT a.VIN
				,a.last_estimatedprice
				,ROW_NUMBER() OVER (
					PARTITION BY a.vin ORDER BY a.coll_dt DESC
					) AS rn
			INTO #final_uw_est_price
			FROM #staging_collateral a
			WHERE a.last_estimatedprice > 0;

		DROP TABLE

		IF EXISTS #final_last_marketprice
			SELECT a.VIN
				,a.last_marketprice
				,ROW_NUMBER() OVER (
					PARTITION BY a.vin ORDER BY a.coll_dt DESC
					) AS rn
			INTO #final_last_marketprice
			FROM #staging_collateral a
			WHERE a.last_marketprice > 0;

		DROP TABLE

		IF EXISTS #tscat;
			SELECT a.VIN
				,a.tscategory
				,ROW_NUMBER() OVER (
					PARTITION BY a.vin ORDER BY a.coll_dt DESC
					) AS rn
			INTO #tscat
			FROM #staging_collateral a
			WHERE a.tscategory IS NOT NULL;

		DROP TABLE

		IF EXISTS #is_overt
			SELECT a.VIN
				,a.is_overturned_ts
				,ROW_NUMBER() OVER (
					PARTITION BY a.vin ORDER BY a.coll_dt DESC
					) AS rn
			INTO #is_overt
			FROM #staging_collateral a
			WHERE a.is_overturned_ts > 0

		DROP TABLE

		IF EXISTS #is_mod
			SELECT a.VIN
				,a.is_modified_ts
				,ROW_NUMBER() OVER (
					PARTITION BY a.vin ORDER BY a.coll_dt DESC
					) AS rn
			INTO #is_mod
			FROM #staging_collateral a
			WHERE a.is_modified_ts > 0;

		DELETE FROM risk.collateral;

		INSERT INTO risk.collateral
		SELECT DISTINCT cast(a.VIN AS VARCHAR(500)) AS vin
			,first_value(rc.person_id) OVER (
				PARTITION BY rc.VIN ORDER BY rc.startdate DESC
				) AS person_id
			,cd.src_dt
			,bm.brand AS ts_brand
			,bm.model AS ts_model
			,mlg.mileage AS ts_mileage
			,clr.color AS ts_color
			,isnull(clr.hex_code, 'FAFBFB') AS ts_hex_color --для пустых или неопределенных - белый
			,t.transmission AS ts_transmission
			,y.tsyear AS ts_year
			,vl.engine_volume AS ts_engine_volume
			,pw.power_hp AS ts_power_hp
			,bdt.body_type AS ts_body_type
			,op.owners_count AS ts_owners_count
			,fue.last_estimatedprice AS ts_last_estimatedprice
			,fum.last_marketprice AS ts_last_marketprice
			,isnull(tc.tscategory, 'nan') AS ts_category
			,isnull(i.is_overturned_ts, 0) AS is_overturned_ts
			,isnull(im.is_modified_ts, 0) AS is_modified_ts
			,max(iif(rc.factenddate <= GETDATE(), 0, 1)) OVER (PARTITION BY a.VIN) AS is_active
			,getdate() AS dt_dml
		FROM #staging_collateral_src a
		INNER JOIN risk.credits rc ON rc.VIN = a.VIN
		LEFT JOIN #CDATE cd ON cd.VIN = a.VIN
		LEFT JOIN #final_brand_model bm ON a.VIN = bm.VIN
			AND bm.rn = 1
		LEFT JOIN #calc_mileage mlg ON a.VIN = mlg.VIN
		LEFT JOIN #final_color clr ON a.VIN = clr.VIN
		LEFT JOIN #transmission t ON a.VIN = t.VIN
			AND t.rn = 1
		LEFT JOIN #final_year y ON a.VIN = y.VIN
			AND y.rn = 1
		LEFT JOIN #final_engine_volume vl ON a.VIN = vl.VIN
			AND vl.rn = 1
		LEFT JOIN #final_power pw ON a.VIN = pw.VIN
			AND pw.rn = 1
		LEFT JOIN #final_body_type bdt ON a.VIN = bdt.VIN
			AND bdt.rn = 1
		LEFT JOIN #ownership_periods op ON op.vin = a.VIN
		LEFT JOIN #final_uw_est_price fue ON fue.vin = a.VIN
			AND fue.rn = 1
		LEFT JOIN #final_last_marketprice fum ON fum.vin = a.VIN
			AND fum.rn = 1
		LEFT JOIN #tscat tc ON tc.vin = a.VIN
			AND tc.rn = 1
		LEFT JOIN #is_overt i ON i.VIN = a.VIN
			AND i.rn = 1
		LEFT JOIN #is_mod im ON im.VIN = a.VIN
			AND im.rn = 1;

		--ALTER TABLE risk.collateral ADD CONSTRAINT UC_collateral UNIQUE (VIN);
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
