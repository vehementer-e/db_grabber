
--exec [risk].[etl_VerificationReaction];
--Витрины для облегчения процесса верификации клиента
--Обновление раз в час
--Данные передаются в логином
--Источники данных:
--stg.[_loginom].[Originationlog]
--stg.[_loginom].[callcheckverif_log]
--stg.[_fedor].[core_ClientRequest]
--stg.[_fedor].[core_ClientAndContactPerson] 
--stg.[_fedor].[core_PersonInfoPhysical] 
--stg.[_fedor].[core_PersonContactInfo] 
--11.05.2023 - добавили условие на 90 дней для флагов// Полина Прокопенко
--22.07.2025 - изменение логики расчета флага SocMedia_fl
--09.02.2026 - изменение выборки #source - RDWH-42

CREATE PROCEDURE [risk].[etl_VerificationReaction]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)

	BEGIN TRY
		BEGIN TRANSACTION;

		DROP TABLE IF EXISTS #source;
			--залоговые продукты
			SELECT DISTINCT s.number
			INTO #source
			FROM stg.[_loginom].[Originationlog] s
			WHERE s.decision = 'Accept' 
			AND s.stage = 'Call 4' 
			--AND isnull(s.Is_installment, 0) = 0
			AND s.productTypeCode in ('pts', 'ptsLite', 'autoCredit') --RDWH-42
			
			UNION
			
			--беззалог
			SELECT DISTINCT s.number
			FROM stg.[_loginom].[Originationlog] s
			WHERE s.decision = 'Accept' 
			--AND s.stage = 'Call 3' 
			--AND isnull(s.Is_installment, 0) = 1;
			AND s.stage  = 'Call 1.5' --RDWH-42
			AND s.productTypeCode in ('bigInstallment', 'bigInstallmentMarket', 'installment', 'pdl');--RDWH-42

		DROP TABLE IF EXISTS #originationlog_call2;
			SELECT a.Number
				,a.Last_name
				,a.First_name
				,a.Patronymic
				,cast(a.Birth_date AS DATE) AS Birth_date
				,a.Passport_series
				,a.Passport_number
				,a.Mobile_number AS MobileNumber
				,a.call_date
				,a.VIN
				,ROW_NUMBER() OVER (PARTITION BY a.number ORDER BY a.call_date DESC) rn
			INTO #originationlog_call2
			FROM stg.[_loginom].[Originationlog] a
			WHERE a.stage = 'Call 2';

		DROP TABLE IF EXISTS #uw_checks;
			SELECT vl.number
				--22.07.2025 изменение логики расчета флага SocMedia_fl
				/*,CASE 
					WHEN vl.Result_2_25 = '100.0225.001' 
					AND vl.Result_2_26 IN ('100.0226.001', '100.0226.002') 
					AND vl.Result_2_27 = '100.0227.002' 
					AND datediff(dd, vl.call_date, getdate()) <= 90 
					THEN 1 
					WHEN isnull(vl.Result_1_203, vl.Result_2_103) = '100.0803.001' 
					AND isnull(vl.Result_1_204, vl.Result_2_104) IN ('100.0804.001', '100.0804.002') 
					AND isnull(vl.Result_1_205, vl.Result_2_105) = '100.0805.002' 
					AND datediff(dd, vl.call_date, getdate()) <= 90 
					THEN 1 ELSE 0 END AS SocMedia_fl
*/
				,CASE 
					WHEN ((vl.Result_2_25 = '100.0225.001' 
					AND vl.Result_2_26 IN ('100.0226.001', '100.0226.002') 
					AND vl.Result_2_27 = '100.0227.002') 
					OR (vl.Result_2_40 = '100.0240.001'))
					AND datediff(dd, vl.call_date, getdate()) <= 90 
					THEN 1 
					WHEN ((isnull(vl.Result_1_203, vl.Result_2_103) = '100.0803.001' 
					AND isnull(vl.Result_1_204, vl.Result_2_104) IN ('100.0804.001', '100.0804.002') 
					AND isnull(vl.Result_1_205, vl.Result_2_105) = '100.0805.002')
					OR vl.Result_1_219 = '100.0819.001')
					AND datediff(dd, vl.call_date, getdate()) <= 90 
					THEN 1
					ELSE 0 END SocMedia_fl

				,CASE 
					WHEN (vl.Result_2_29 = '100.0229.001' 
					OR isnull(vl.Result_1_207, vl.Result_2_107) = '100.0807.001') 
					AND datediff(dd, vl.call_date, getdate()) <= 90 
					THEN 1 
					ELSE 0 END ContactPhone_fl

				,CASE 
					WHEN (vl.Result_2_11 = '100.0211.001' 
					OR isnull(vl.Result_1_213, vl.Result_2_113) = '100.0813.001') 
					AND datediff(dd, vl.call_date, getdate()) <= 90 
					THEN 1 
					ELSE 0 END ContactPhoneCall_fl

				,CASE 
					WHEN (vl.Result_2_28 = '100.0228.001' 
					OR isnull(vl.Result_1_206, vl.Result_2_106) = '100.0806.001') 
					AND datediff(dd, vl.call_date, getdate()) <= 90 
					THEN 1 
					ELSE 0 END MobileNumber_fl

				,CASE 
					WHEN (isnull(vl.Result_1_214, vl.Result_2_114) = '100.0814.001' 
					OR vl.Result_2_8 = '100.0208.001') 
					AND datediff(dd, vl.call_date, getdate()) <= 90 
					THEN 1 
					ELSE 0 END MobileNumberCall_fl

				,CASE 
					WHEN vl.Result_2_7 = '100.0207.001' THEN 'B' 
					WHEN vl.Result_2_7 IN ('100.0207.002', '100.0207.003') THEN 'C' 
					WHEN vl.Result_2_7 = '100.0207.004' THEN 'D' 
					END Name_Category_TS

				,ROW_NUMBER() OVER (PARTITION BY vl.number ORDER BY vl.call_date DESC) rn
			INTO #uw_checks
			FROM [stg].[_loginom].[callcheckverif_log] vl
			WHERE vl.Stage in ('Call 1.5', 'Call 3');

		DROP TABLE IF EXISTS #contact_phone;
			SELECT 
				cr.[Number]
				,pci.CreatedOn
				,pci.[Value] AS ContactPhone
				,pci.idstatus
				,fg.idtype
				,fg.idkind
			INTO #contact_phone
			FROM stg.[_fedor].[core_ClientRequest] cr
			INNER JOIN stg.[_fedor].[core_ClientAndContactPerson] cacp 
				ON cr.idclient = cacp.IdClient
			INNER JOIN stg.[_fedor].[core_PersonContactInfo] pci 
				ON pci.IdPerson = cacp.IdContactPerson AND pci.IdStatus = 1
			INNER JOIN [Stg].[_fedor].[core_ContactPerson] fg 
				ON pci.[IdPerson] = fg.Id 
				AND ISNULL(fg.IdType, 0) <> 10 
				AND ISNULL(fg.IdKind, 0) <> 1;

		DROP TABLE IF EXISTS #contact_phone_src;
			SELECT number
				,count(*) AS cnt
			INTO #contact_phone_src
			FROM #contact_phone
			GROUP BY number;

		DELETE
		FROM risk.VerificationReaction;

		INSERT INTO risk.VerificationReaction
		SELECT 
			s.Number
			,a.Last_name
			,a.First_name
			,a.Patronymic
			,a.Birth_date
			,a.Passport_series
			,a.Passport_number
			,u.SocMedia_fl
			,a.call_date
			,cf.ContactPhone
			,u.ContactPhone_fl
			,u.ContactPhoneCall_fl
			,a.MobileNumber
			,u.MobileNumber_fl
			,u.MobileNumberCall_fl
			,a.VIN
			,u.Name_Category_TS
			,0 AS last_app_flag
			,getdate() AS dt_dml
		FROM #source s
		LEFT JOIN #originationlog_call2 a 
			ON a.number = s.Number 
			AND a.rn = 1
		LEFT JOIN #uw_checks u 
			ON u.Number = s.Number 
			AND u.rn = 1
		LEFT JOIN #contact_phone_src cs 
			ON cs.Number = cast(s.Number as nvarchar(255))
			AND cs.cnt = 1
		LEFT JOIN #contact_phone cf 
			ON cf.Number = cs.Number;

		WITH cte_to_update
		AS (
			SELECT *
				,ROW_NUMBER() OVER (PARTITION BY VIN ORDER BY call_date DESC) rn_last_app_flag_vin
			FROM risk.VerificationReaction
			WHERE vin <> ''
			)
		UPDATE t
		SET last_app_flag = CASE WHEN rn_last_app_flag_vin = 1 THEN 1 ELSE 0 END
		FROM cte_to_update t;

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

		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'risk_tech@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;
