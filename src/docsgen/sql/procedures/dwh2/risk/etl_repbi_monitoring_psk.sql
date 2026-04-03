
--exec [dwh2].[risk].[etl_repbi_monitoring_psk]
CREATE PROCEDURE [risk].[etl_repbi_monitoring_psk]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		DROP TABLE

		IF EXISTS #results;
			WITH loginom_apr
			AS (
				SELECT a.number
					,a.APR AS [Ставка Loginom]
					,a.apr_max AS [Ставка Loginom без страховки]
					,ROW_NUMBER() OVER (
						PARTITION BY a.number ORDER BY a.call_date DESC
						) rn
				FROM stg._loginom.Originationlog a
				WHERE a.Stage = 'Call 2'
				)
				,src
			AS (
				SELECT c.startdate
					,c.external_id
					,p.fio
					,p.birth_date
					,c.rbp_gr
					,c.client_type
					,c.credit_type_init
					,cast(c.InitialRate AS FLOAT) AS InitialRateCMR
					,l.[Ставка Loginom]
					,l.[Ставка Loginom без страховки]
					,FA.ПризнакСтраховка
				FROM risk.credits c
				INNER JOIN risk.person p ON p.person_id = c.person_id
				LEFT JOIN loginom_apr l ON l.rn = 1
					AND l.Number = c.external_id
				LEFT JOIN [Reports].[dbo].[dm_Factor_Analysis] FA ON FA.Номер = c.external_id
				WHERE (
						c.client_type = 'Первичный'
						OR c.credit_type = 'PTS_REFIN'
						)
					AND c.credit_type <> 'INST'
					AND c.startdate = DATEADD(dd, - 1, cast(getdate() AS DATE))
				)
			SELECT a.*
				,CASE 
					WHEN a.client_type = 'Первичный'
						AND a.rbp_gr = 'RBP 4'
						AND round(a.InitialRateCMR, 1) <> a.InitialRateCMR
						THEN 'OK'
					WHEN a.client_type = 'Первичный'
						AND a.rbp_gr IN (
							'RBP 1'
							,'RBP 2'
							,'RBP 3'
							,'RBP 4'
							)
						AND a.ПризнакСтраховка = 1
						AND a.InitialRateCMR = a.[Ставка Loginom]
						THEN 'OK'
					WHEN a.client_type = 'Первичный'
						AND a.rbp_gr IN (
							'RBP 1'
							,'RBP 2'
							,'RBP 3'
							,'RBP 4'
							)
						AND a.ПризнакСтраховка = 1
						AND a.InitialRateCMR <> a.[Ставка Loginom]
						THEN 'не OK'
					WHEN a.client_type = 'Первичный'
						AND a.rbp_gr IN (
							'RBP 1'
							,'RBP 2'
							,'RBP 3'
							,'RBP 4'
							)
						AND a.ПризнакСтраховка = 0
						AND a.InitialRateCMR = a.[Ставка Loginom без страховки]
						THEN 'OK'
					WHEN a.client_type = 'Первичный'
						AND a.rbp_gr IN (
							'RBP 1'
							,'RBP 2'
							,'RBP 3'
							,'RBP 4'
							)
						AND a.ПризнакСтраховка = 0
						AND a.InitialRateCMR <> a.[Ставка Loginom без страховки]
						THEN 'не OK'
					WHEN a.client_type = 'Первичный'
						AND a.rbp_gr = 'NotRBP_PROBATION'
						AND a.InitialRateCMR = a.[Ставка Loginom]
						THEN 'OK'
					WHEN a.client_type = 'Первичный'
						AND a.rbp_gr = 'NotRBP_PROBATION'
						AND a.InitialRateCMR <> a.[Ставка Loginom]
						THEN 'не OK'
					WHEN a.credit_type_init = 'PTS_REFIN'
						AND round(a.InitialRateCMR, 1) <> a.InitialRateCMR
						THEN 'OK'
					WHEN a.credit_type_init = 'PTS_REFIN'
						AND a.ПризнакСтраховка = 1
						AND a.InitialRateCMR = a.[Ставка Loginom]
						THEN 'OK'
					WHEN a.credit_type_init = 'PTS_REFIN'
						AND a.ПризнакСтраховка = 1
						AND a.InitialRateCMR <> a.[Ставка Loginom]
						THEN 'не OK'
					WHEN a.credit_type_init = 'PTS_REFIN'
						AND a.ПризнакСтраховка = 1
						AND a.InitialRateCMR = a.[Ставка Loginom без страховки]
						THEN 'OK'
					WHEN a.credit_type_init = 'PTS_REFIN'
						AND a.ПризнакСтраховка = 0
						AND a.InitialRateCMR <> a.[Ставка Loginom без страховки]
						THEN 'не OK'
					
					END AS flag
				,CASE 
					WHEN a.client_type = 'Первичный'
						AND a.rbp_gr IN (
							'RBP 1'
							,'RBP 2'
							,'RBP 3'
							,'RBP 4'
							)
						AND a.ПризнакСтраховка = 1
						AND a.InitialRateCMR <> a.[Ставка Loginom]
						THEN a.[Ставка Loginom]
					WHEN a.client_type = 'Первичный'
						AND a.rbp_gr IN (
							'RBP 1'
							,'RBP 2'
							,'RBP 3'
							,'RBP 4'
							)
						AND a.ПризнакСтраховка = 0
						AND a.InitialRateCMR <> a.[Ставка Loginom без страховки]
						THEN a.[Ставка Loginom без страховки]
					WHEN a.client_type = 'Первичный'
						AND a.rbp_gr = 'NotRBP_PROBATION'
						AND a.InitialRateCMR <> a.[Ставка Loginom]
						THEN a.[Ставка Loginom]
					WHEN a.credit_type_init = 'PTS_REFIN'
						AND a.ПризнакСтраховка = 1
						AND a.InitialRateCMR <> a.[Ставка Loginom]
						THEN a.[Ставка Loginom]
					WHEN a.credit_type_init = 'PTS_REFIN'
						AND a.ПризнакСтраховка = 0
						AND a.InitialRateCMR <> a.[Ставка Loginom без страховки]
						THEN a.[Ставка Loginom без страховки]
						ELSE a.InitialRateCMR
					END AS correct_rate
			INTO #results
			FROM src a;

			update #results
			set flag='OK' where credit_type_init='PDL' and correct_rate=InitialRateCMR;

			DELETE FROM #results WHERE flag <> 'OK';

		DECLARE @cnt INT
			,@tableHTML NVARCHAR(MAX);


		SET @tableHTML = N'<H2>  Мониторинг ставок ПТС </H2>' + N'<table border="1" cellspacing="0" cellpadding="0">' + N'<tr><th>Дата выдачи</th>' + N'<th>Номер договора</th>' + N'<th>ФИО заемщика</th>' + '<th>Дата рожедния</th>' + '<th>RBP</th>' + '<th>Тип клиента</th>' + '<th>Тип кредита</th>' + '<th>Ставка CMR</th>' +  '<th>Корректная ставка</th>' + '<th>Ставка Loginom</th>' + '<th>Ставка Loginom без страховки</th>' + '<th>Наличие страховки</th>' + '<th>Флаг</th>' + CAST((
					SELECT DISTINCT td = a.startdate
						,' '
						,td = a.external_id
						,' '
						,td = fio
						,' '
						,td = a.birth_date
						,' '
						,td = a.rbp_gr
						,' '
						,td = client_type
						,' '
						,td = credit_type_init
						,' '
						,td = cast(InitialRateCMR as varchar(100))
						,' '
						,td = cast(correct_rate as varchar(100))
						,' '
						,td = cast([Ставка Loginom] as varchar(100))
						,' '
						,td = cast([Ставка Loginom без страховки] as varchar(100))
						,' '
						,td = ПризнакСтраховка
						,' '
						,td = flag

					FROM #results a
					FOR XML PATH('tr')
						,TYPE
					) AS NVARCHAR(MAX)) + N'</table>';

		SELECT @cnt = count(*)
		FROM #results
		WHERE upper(flag) <> 'OK';

		IF @cnt > 0
			EXEC msdb.dbo.sp_send_dbmail @recipients = 'Анастасия Ставничая <a.stavnichaya@techmoney.ru>; Александр Кузнецов <a.kuznecov@techmoney.ru>; Наталия Жиделева <n.zhideleva@techmoney.ru>; Полина Прокопенко <p.prokopenko@techmoney.ru>'
				 --msdb.dbo.sp_send_dbmail @recipients = 'Александр Кузнецов <a.kuznecov@techmoney.ru>'
				,@profile_name = 'Default'
				,@subject = 'Мониторинг ставок ПТС'
				,@body = @tableHTML
				,@body_format = 'HTML';

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
