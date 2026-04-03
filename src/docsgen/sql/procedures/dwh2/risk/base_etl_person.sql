
--exec [risk].[base_etl_person]
CREATE PROCEDURE [risk].[base_etl_person]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)

	BEGIN TRY
		DROP TABLE

		IF EXISTS #address_mfo;
			SELECT b.Номер AS external_id
				,cast(b.АдресРегистрации AS NVARCHAR(4000)) AS adres_reg
				,b.Регион AS registration_region
				,cast(b.АдресПроживания AS NVARCHAR(4000)) AS adres_fact
				,b.РегионФактическогоПроживания AS fact_region
			INTO #address_mfo
			FROM stg._1cMFO.Документ_ГП_Заявка b;

		CREATE INDEX IX_RISK_ADDR_MFO ON #address_mfo (external_id);

		--Регион регистрации МФО
		DROP TABLE

		IF EXISTS #region_reg_mfo;
			WITH splited_reg_address
			AS (
				SELECT a.external_id
					,ssa.addr_component
					,ssa.num_component
				FROM #address_mfo a
				INNER JOIN risk.credits r ON r.external_id = a.external_id
				CROSS APPLY (
					SELECT trim(' ' FROM value) AS addr_component
						,ROW_NUMBER() OVER (
							PARTITION BY a.external_id ORDER BY a.external_id
							) AS num_component
					FROM STRING_SPLIT(a.adres_reg, ',')
					) ssa
				WHERE isnull(a.adres_reg, '') <> ''
				)
				,parsed_reg_region
			AS (
				SELECT a.external_id
					,max(b.region) AS region
				FROM splited_reg_address a
				INNER JOIN risk.dict_region_pattern b ON a.addr_component LIKE b.pattern
					AND a.num_component = 3
				GROUP BY a.external_id
				)
				,reg_region
			AS (
				SELECT a.external_id
					,max(b.region) AS region
				FROM #address_mfo a
				INNER JOIN risk.dict_region_pattern b ON a.registration_region LIKE b.pattern
				GROUP BY a.external_id
				)
			SELECT DISTINCT a.external_id
				,isnull(r.region, pr.region) AS region_registration_mfo
			INTO #region_reg_mfo
			FROM #address_mfo a
			LEFT JOIN parsed_reg_region pr ON pr.external_id = a.external_id
			LEFT JOIN reg_region r ON r.external_id = a.external_id
			WHERE isnull(r.region, pr.region) IS NOT NULL;

		--Регион факт МФО
		DROP TABLE

		IF EXISTS #region_fact_mfo;
			WITH splited_reg_address
			AS (
				SELECT a.external_id
					,ssa.addr_component
					,ssa.num_component
				FROM #address_mfo a
				CROSS APPLY (
					SELECT trim(' ' FROM value) AS addr_component
						,ROW_NUMBER() OVER (
							PARTITION BY a.external_id ORDER BY a.external_id
							) AS num_component
					FROM STRING_SPLIT(a.adres_fact, ',')
					) ssa
				WHERE isnull(a.adres_fact, '') <> ''
				)
				,parsed_reg_region
			AS (
				SELECT a.external_id
					,max(b.region) AS region
				FROM splited_reg_address a
				INNER JOIN risk.dict_region_pattern b ON a.addr_component LIKE b.pattern
					AND a.num_component = 3
				GROUP BY a.external_id
				)
				,reg_region
			AS (
				SELECT a.external_id
					,max(b.region) AS region
				FROM #address_mfo a
				INNER JOIN risk.dict_region_pattern b ON a.fact_region LIKE b.pattern
				GROUP BY a.external_id
				)
			SELECT DISTINCT a.external_id
				,isnull(r.region, pr.region) AS region_fact_mfo
			INTO #region_fact_mfo
			FROM #address_mfo a
			LEFT JOIN parsed_reg_region pr ON pr.external_id = a.external_id
			LEFT JOIN reg_region r ON r.external_id = a.external_id
			WHERE isnull(r.region, pr.region) IS NOT NULL;

		DROP TABLE

		IF EXISTS #fedor;
			SELECT DISTINCT cr.Number Collate Cyrillic_General_CI_AS AS external_id
				,FIRST_VALUE(COALESCE (
					nullif(cr.ClientPassportSerial,'')
					,cr_ci.[PassportSerial]
					)) OVER (
					PARTITION BY IdClient ORDER BY CreatedRequestDate DESC
					) Collate Cyrillic_General_CI_AS AS ClientPassportSerial
				,FIRST_VALUE(COALESCE (
					nullif(cr.ClientPassportNumber, '')
					,cr_ci.[PassportNumber]
					))OVER (PARTITION BY IdClient ORDER BY CreatedRequestDate DESC
					) Collate Cyrillic_General_CI_AS AS ClientPassportNumber
				,cast(FIRST_VALUE(COALESCE (
					nullif(cr.ClientPassportIssuedDate, '')
					,cr_ci.PassportIssuedDate))OVER (
						PARTITION BY IdClient ORDER BY CreatedRequestDate DESC
						) AS DATE) AS ClientPassportIssuedDate
				,FIRST_VALUE(clientPhoneMobile) OVER (
					PARTITION BY IdClient ORDER BY CreatedRequestDate DESC
					) Collate Cyrillic_General_CI_AS AS mobile_phone
				,FIRST_VALUE(drr.name) OVER (
					PARTITION BY IdClient ORDER BY CreatedRequestDate DESC
					) Collate Cyrillic_General_CI_AS AS region_registration
				,FIRST_VALUE(drf.name) OVER (
					PARTITION BY IdClient ORDER BY CreatedRequestDate DESC
					) Collate Cyrillic_General_CI_AS AS region_fact
				,FIRST_VALUE(COALESCE (
					nullif(cr.ClientAddressRegistration, '')
					,cr_ci.AddressRegistration)) OVER (
					PARTITION BY IdClient ORDER BY CreatedRequestDate DESC
					) Collate Cyrillic_General_CI_AS AS address_registration
				,FIRST_VALUE(COALESCE (
					nullif(cr.ClientAddressStay, '')
					,cr_ci.AddressResidential)) OVER (
					PARTITION BY IdClient ORDER BY CreatedRequestDate DESC
					) Collate Cyrillic_General_CI_AS AS address_fact
				,FIRST_VALUE(COALESCE(cr.IdGender,cr_ci.GenderId)) OVER (
					PARTITION BY IdClient ORDER BY CreatedRequestDate DESC
					) AS gender
			INTO #fedor
			FROM Stg._fedor.core_ClientRequest cr
			left join Stg._fedor.core_ClientRequestClientInfo cr_ci
				on cr_ci.id =cr.Id
			LEFT JOIN stg._fedor.dictionary_region drr ON drr.id = cr.IdClientAddressRegion
			LEFT JOIN stg._fedor.dictionary_region drf ON drf.id = cr.IdClientAddressRegionFact
			WHERE cr.IsNewProcess = 1
				AND cr.CreatedRequestDate > = '2020-09-01'

		DROP TABLE

		IF EXISTS #result;
			WITH cred_cmr_status
			AS (
				SELECT b.Код AS external_id
					,dateadd(yy, - 2000, a.Период) AS dt_status
					,c.Наименование AS STATUS
					,ROW_NUMBER() OVER (
						PARTITION BY b.Код ORDER BY a.Период DESC
						) AS rn
				FROM stg._1cCMR.РегистрСведений_СтатусыДоговоров a
				INNER JOIN stg._1cCMR.Справочник_Договоры b ON a.Договор = b.Ссылка
				INNER JOIN stg._1cCMR.Справочник_СтатусыДоговоров c ON a.Статус = c.Ссылка
				WHERE b.ПометкаУдаления = 0x00
				)
				,src
			AS (
				SELECT a.person_id AS person_id
					,rtrim(ltrim(cl.Фамилия)) AS last_name
					,rtrim(ltrim(cl.Имя)) AS first_name
					,rtrim(ltrim(cl.Отчество)) AS patronymic
					,CONCAT (
						rtrim(ltrim(cl.Фамилия))
						,' '
						,rtrim(ltrim(cl.Имя))
						,' '
						,rtrim(ltrim(cl.Отчество))
						,' '
						,isnull(dateadd(yy, - 2000, cast(cl.ДатаРождения AS DATE)), '19000101')
						) AS person_id2
					,CONCAT (
						rtrim(ltrim(cl.Фамилия))
						,' '
						,rtrim(ltrim(cl.Имя))
						,' '
						,rtrim(ltrim(cl.Отчество))
						) AS fio
					,isnull(dateadd(yy, - 2000, cast(cl.ДатаРождения AS DATE)), '19000101') AS birth_date
					,CONCAT (
						CASE 
							WHEN replace(cl.ПаспортСерия, ' ', '') IS NOT NULL
								AND replace(cl.ПаспортСерия, ' ', '') <> ''
								THEN replace(cl.ПаспортСерия, ' ', '')
							WHEN replace(sd.ПаспортСерия, ' ', '') IS NOT NULL
								AND replace(sd.ПаспортСерия, ' ', '') <> ''
								THEN replace(sd.ПаспортСерия, ' ', '')
							WHEN replace(fd.ClientPassportSerial, ' ', '') IS NOT NULL
								AND replace(fd.ClientPassportSerial, ' ', '') <> ''
								THEN replace(fd.ClientPassportSerial, ' ', '')
							ELSE replace(mfo.СерияПаспорта, ' ', '')
							END
						,' '
						,CASE 
							WHEN replace(cl.ПаспортНомер, ' ', '') IS NOT NULL
								AND replace(cl.ПаспортНомер, ' ', '') <> ''
								THEN replace(cl.ПаспортНомер, ' ', '')
							WHEN replace(sd.ПаспортНомер, ' ', '') IS NOT NULL
								AND replace(sd.ПаспортНомер, ' ', '') <> ''
								THEN replace(sd.ПаспортНомер, ' ', '')
							WHEN replace(fd.ClientPassportNumber, ' ', '') IS NOT NULL
								AND replace(fd.ClientPassportNumber, ' ', '') <> ''
								THEN replace(fd.ClientPassportNumber, ' ', '')
							ELSE replace(mfo.НомерПаспорта, ' ', '')
							END
						) AS passport_number
					,cast(coalesce(nullif((fd.ClientPassportIssuedDate), ''), nullif(iif(year(mfo.ДатаВыдачиПаспорта) > 3000, dateadd(year, - 2000, mfo.ДатаВыдачиПаспорта), NULL), ''), NULL) AS DATE) AS passport_date
					,CASE 
						WHEN replace(cl.ПаспортСерия, ' ', '') IS NOT NULL
							AND replace(cl.ПаспортСерия, ' ', '') <> ''
							THEN replace(cl.ПаспортСерия, ' ', '')
						WHEN replace(sd.ПаспортСерия, ' ', '') IS NOT NULL
							AND replace(sd.ПаспортСерия, ' ', '') <> ''
							THEN replace(sd.ПаспортСерия, ' ', '')
						WHEN replace(fd.ClientPassportSerial, ' ', '') IS NOT NULL
							AND replace(fd.ClientPassportSerial, ' ', '') <> ''
							THEN replace(fd.ClientPassportSerial, ' ', '')
						ELSE replace(mfo.СерияПаспорта, ' ', '')
						END AS doc_ser
					,CASE 
						WHEN replace(cl.ПаспортНомер, ' ', '') IS NOT NULL
							AND replace(cl.ПаспортНомер, ' ', '') <> ''
							THEN replace(cl.ПаспортНомер, ' ', '')
						WHEN replace(sd.ПаспортНомер, ' ', '') IS NOT NULL
							AND replace(sd.ПаспортНомер, ' ', '') <> ''
							THEN replace(sd.ПаспортНомер, ' ', '')
						WHEN replace(fd.ClientPassportNumber, ' ', '') IS NOT NULL
							AND replace(fd.ClientPassportNumber, ' ', '') <> ''
							THEN replace(fd.ClientPassportNumber, ' ', '')
						ELSE replace(mfo.НомерПаспорта, ' ', '')
						END AS doc_num
					,a.app_dt
					,coalesce(ls.FICO3_score, rf.FICO3_score) AS FICO3_score
					,coalesce(fd.mobile_phone, mfo_d.ТелефонМобильный) AS mobile_phone
					,coalesce(fd.region_registration, rr.region_registration_mfo) AS region_registration
					,coalesce(fd.region_fact, rfc.region_fact_mfo) AS region_fact
					,coalesce(fd.address_registration, cast(mfo.АдресРегистрации AS NVARCHAR(4000))) AS address_registration
					,coalesce(fd.address_fact, cast(mfo.АдресПроживания AS NVARCHAR(4000))) AS address_fact
					,CASE 
						WHEN fd.gender IS NOT NULL
							THEN cast(fd.gender AS VARCHAR(10))
						WHEN right(rtrim(cl.Отчество), 3) IN (
								'ВИЧ'
								,'ГЛЫ'
								,'ЬИЧ'
								)
							THEN '1'
						WHEN right(rtrim(cl.Отчество), 3) IN (
								'ВНА'
								,'ЫЗЫ'
								,'ЧНА'
								)
							THEN '2'
						ELSE 'Other'
						END AS calc_gender
					,sum(iif(a.factenddate <= GETDATE(), 0, 1)) OVER (PARTITION BY a.person_id) AS is_active
				FROM risk.credits a
				INNER JOIN stg._1cCMR.Справочник_Клиенты cl ON a.person_id = cl.Ссылка
				LEFT JOIN #fedor fd ON fd.external_id = a.external_id
				LEFT JOIN stg._1cMFO.Документ_ГП_Заявка mfo ON mfo.Номер = a.external_id
				LEFT JOIN stg._1cMFO.Документ_ГП_Договор mfo_d ON mfo_d.Номер = a.external_id
				LEFT JOIN stg._1cCMR.Справочник_Договоры sd ON sd.Код = a.external_id
				LEFT JOIN stg._loginom.score ls ON cast(ls.Number AS NVARCHAR(50)) = cast(a.external_id AS NVARCHAR(50))
				LEFT JOIN RISK.REG_RETROFICO rf ON rf.external_id = a.external_id
				LEFT JOIN #region_reg_mfo rr ON rr.external_id = a.external_id
				LEFT JOIN #region_fact_mfo rfc ON rfc.external_id = a.external_id
				)
			SELECT DISTINCT a.person_id
				,FIRST_VALUE(a.last_name) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS last_name
				,FIRST_VALUE(a.first_name) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS first_name
				,FIRST_VALUE(a.patronymic) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS patronymic
				,FIRST_VALUE(a.person_id2) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS person_id2
				,FIRST_VALUE(a.fio) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS FIO
				,a.birth_date
				,CASE 
					WHEN MONTH(a.birth_date) > MONTH(getdate())
						THEN DATEDIFF(YYYY, a.birth_date, getdate()) - 1
					WHEN MONTH(a.birth_date) < MONTH(getdate())
						THEN DATEDIFF(YYYY, a.birth_date, getdate())
					WHEN MONTH(a.birth_date) = MONTH(getdate())
						THEN CASE 
								WHEN DAY(a.birth_date) > DAY(getdate())
									THEN DATEDIFF(YYYY, a.birth_date, getdate()) - 1
								ELSE DATEDIFF(YYYY, a.birth_date, getdate())
								END
					END AS age
				,FIRST_VALUE(a.passport_number) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS passport_number
				,FIRST_VALUE(a.passport_date) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS passport_date
				,FIRST_VALUE(a.doc_ser) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS doc_ser
				,FIRST_VALUE(a.doc_num) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS doc_num
				,FIRST_VALUE(a.app_dt) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS app_dt
				,FIRST_VALUE(a.FICO3_score) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS FICO3_score
				,FIRST_VALUE(a.mobile_phone) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS mobile_phone
				,FIRST_VALUE(a.region_registration) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS region_registration
				,FIRST_VALUE(a.region_fact) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS region_fact
				,FIRST_VALUE(a.address_registration) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS address_registration
				,FIRST_VALUE(a.address_fact) OVER (
					PARTITION BY a.person_id ORDER BY a.app_dt DESC
					) AS address_fact
				,a.is_active
				,getdate() AS dt_dml
			INTO #result
			FROM src a;

		IF object_id('risk.person') IS NOT NULL
			TRUNCATE TABLE risk.person;

		INSERT INTO risk.person
		SELECT person_id
			,FIRST_VALUE(last_name) OVER (
				PARTITION BY passport_number ORDER BY app_dt DESC
				) AS last_name
			,FIRST_VALUE(first_name) OVER (
				PARTITION BY passport_number ORDER BY app_dt DESC
				) AS first_name
			,FIRST_VALUE(patronymic) OVER (
				PARTITION BY passport_number ORDER BY app_dt DESC
				) AS patronymic
			,FIRST_VALUE(person_id2) OVER (
				PARTITION BY passport_number ORDER BY app_dt DESC
				) AS person_id2
			,FIRST_VALUE(FIO) OVER (
				PARTITION BY passport_number ORDER BY app_dt DESC
				) AS FIO
			,FIRST_VALUE(birth_date) OVER (
				PARTITION BY passport_number ORDER BY app_dt DESC
				) AS birth_date
			,age
			,passport_number
			,passport_date
			,doc_ser
			,doc_num
			,app_dt
			,FICO3_score
			,mobile_phone
			,region_registration
			,region_fact
			,address_registration
			,address_fact
			,is_active
			,dt_dml
		FROM #result;

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
