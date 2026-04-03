
--exec [risk].[etl_repbi_monitoring_pdn2]
CREATE PROCEDURE [risk].[etl_repbi_monitoring_pdn2]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)          

	BEGIN TRY
		--Мониторинг ПДН--
		DECLARE @str_date_pts DATE = '2022-04-01'
		DECLARE @str_date_inst DATE = '2023-04-01'

		DROP TABLE

		IF EXISTS #base --собираем данные по займам, выданным вчера
			SELECT --с null или нулем в одном из полей
				a.external_id
				,isnull(b.income_amount, - 1) AS income_amount --заменяем null на -1, чтобы корректно работал unpivot
				,isnull(b.pdn, - 1) AS pdn
				,isnull(b.rosstat_income, - 1) AS rosstat_income
				,isnull(b.bki_exp_amount, - 1) AS bki_exp_amount
				,isnull(b.bki_income, - 1) AS bki_income
				,cast(isnull(credit_exp, - 1) AS FLOAT) AS credit_exp
			INTO #base
			FROM risk.credits a
			LEFT JOIN risk.pdn_calculation_2gen b ON a.external_id = b.number
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')

			WHERE a.startdate = dateadd(day, - 1, cast(getdate() AS DATE))
				AND a.amount >= 10000
				and l.number is null;

		DROP TABLE

		IF EXISTS #result;
			SELECT *
				,iif([null значений] > 0, 'Есть null в столбце', 'ok') AS message --Сообщение о ошибке
			INTO #result
			FROM (
				SELECT dateadd(day, - 1, cast(getdate() AS DATE)) AS DATE -- Дата
					,a.gr_name -- Название поля
					,count(b.gr) AS [null значений] -- Кол-во нулевых значений
				FROM #base
				unpivot(gr FOR gr_name IN (pdn, rosstat_income, bki_exp_amount, bki_income, income_amount, credit_exp)) AS a -- Тут все значения
				LEFT JOIN #base
				unpivot(gr FOR gr_name IN (pdn, rosstat_income, bki_exp_amount, bki_income, income_amount, credit_exp)) AS b -- Тут только null
					ON a.gr_name = b.gr_name
					AND a.gr = b.gr
					AND b.gr = - 1
					AND b.external_id = a.external_id
				GROUP BY a.gr_name
				) a;

		DECLARE @cnt INT
			,@tableHTML NVARCHAR(MAX);

		SET @tableHTML = N'<H2>  Мониторинг ПДН  </H2>' + N'<table border="1" cellspacing="0" cellpadding="0">' + N'<tr><th>Отчетная дата</th>' + N'<th>Группа</th>' + N'<th>Нулевых значений</th>' + '<th>Сообщение</th>' + CAST((
					SELECT DISTINCT td = format(a.DATE, 'dd.MM.yyyy')
						,' '
						,td = a.gr_name
						,' '
						,td = a.[null значений]
						,' '
						,td = a.message
					FROM #result a
					FOR XML PATH('tr')
						,TYPE
					) AS NVARCHAR(MAX)) + N'</table>';

		SELECT @cnt = count(*)
		FROM #result
		WHERE upper(message) = 'ЕСТЬ NULL В СТОЛБЦЕ';

		IF @cnt > 0
			EXEC msdb.dbo.sp_send_dbmail @recipients = 'risk_tech@carmoney.ru'
				,@profile_name = 'Default'
				,@subject = 'Мониторинг ПДН'
				,@body = @tableHTML
				,@body_format = 'HTML';

		-- Мониторинг PSI (ПТС) --
		DROP TABLE

		IF EXISTS #base2 -- распределение договоров по группам		
			SELECT -- старт - первый понедельник апреля
				a.external_id
				,a.startdate
				,CASE 
					WHEN b.pdn >= 0
						AND b.pdn < 0.45
						THEN 0
					WHEN b.pdn >= 0.45
						AND b.pdn < 0.70
						THEN 45
					WHEN b.pdn >= 0.70
						AND b.pdn < 1
						THEN 70
					WHEN b.pdn >= 1
						AND b.pdn < 1.6
						THEN 100
					WHEN b.pdn >= 1.6
						AND b.pdn < 3.3
						THEN 160
					WHEN b.pdn >= 3.3
						THEN 330
					END AS pdn_gr
				,CASE 
					WHEN b.rosstat_income >= 56000
						THEN 56000
					WHEN b.rosstat_income >= 37000
						THEN 37000
					WHEN b.rosstat_income >= 31000
						THEN 31000
					WHEN b.rosstat_income >= 1
						THEN 1
					END AS rosstat_income_gr
				,CASE 
					WHEN isnull(b.bki_exp_amount, 0) = 0
						THEN 0
					WHEN b.bki_exp_amount >= 140000
						THEN 140000
					WHEN b.bki_exp_amount >= 65000
						THEN 65000
					WHEN b.bki_exp_amount >= 25000
						THEN 25000
					WHEN b.bki_exp_amount >= 0.01
						THEN 1
					END AS bki_exp_amount_gr
				,CASE 
					WHEN isnull(b.bki_income, 0) = 0
						THEN 0
					WHEN b.bki_income >= 140000
						THEN 140000
					WHEN b.bki_income >= 65000
						THEN 65000
					WHEN b.bki_income >= 25000
						THEN 25000
					WHEN b.bki_income >= 0.01
						THEN 1
					END AS bki_income_gr
				,CASE 
					WHEN isnull(b.income_amount, 0) = 0
						THEN 0
					WHEN b.income_amount >= 150000
						THEN 150000
					WHEN b.income_amount >= 100000
						THEN 100000
					WHEN b.income_amount >= 73000
						THEN 73000
					WHEN b.income_amount >= 55000
						THEN 55000
					WHEN b.income_amount >= 1
						THEN 1
					END AS income_amount_gr
				,CASE 
					WHEN credit_exp >= 40000
						THEN 40000
					WHEN credit_exp >= 20000
						THEN 20000
					WHEN credit_exp >= 10000
						THEN 10000
					WHEN credit_exp >= 0
						THEN 0
					END AS credit_exp_gr
				,credit_exp
			INTO #base2
			FROM risk.credits a
			--LEFT JOIN stg._loginom.pdn_calculation_2gen_stg b ON a.external_id = b.number
			LEFT JOIN risk.pdn_calculation_2gen b ON a.external_id = b.number
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')

			WHERE a.startdate >= @str_date_pts
				AND a.credit_type = 'PTS' --только птс
				AND a.amount >= 10000 -- только займы >=10k
				AND isnull(b.income_amount, 0) > 0 -- убираем ошибки
				and l.number is null

		DECLARE @cur_date AS DATE = -- дата вчера
			dateadd(day, - 1, cast(GETDATE() AS DATE))
		DECLARE @znampast2 AS FLOAT = --кол-во договоров за период с апреля до -2мес
			(
				SELECT count(b.external_id)
				FROM #base2 b
				WHERE b.startdate BETWEEN @str_date_pts
						AND dateadd(month, - 2, @cur_date)
				)
		DECLARE @znamcur2 AS FLOAT = -- кол-во договоров за прошлые 7 дней
			(
				SELECT count(b.external_id)
				FROM #base2 b
				WHERE b.startdate BETWEEN dateadd(day, - 6, @cur_date)
						AND @cur_date
				)
		DECLARE @min_date_rosstat AS DATE = --дата обновления справочника росстата
			(
				SELECT iif(max(a.datetimefrom) < dateadd(month, - 1, @cur_date), max(datetimefrom), dateadd(month, - 1, @cur_date))
				FROM Stg._loginom.Origination_dict_rosstatIncome a --Stg._loginom.dict_rosstat a --26/01/2024
			)

		--DECLARE @min_date_rosstat AS DATE = --дата обновления справочника росстата
		--	(
		--		SELECT iif(max(repdate) < dateadd(month, - 1, @cur_date), max(repdate), dateadd(month, - 1, @cur_date))
		--		FROM risk.REG_ROSSTAT_INCOME 
		--		where @cur_date between dt_valid_from and dt_valid_to
		--	)

		DECLARE @znampast_rosstat AS FLOAT = --кол-во договоров за пр. период для росстата
			(
				SELECT count(b.external_id)
				FROM #base2 b
				WHERE b.startdate BETWEEN @min_date_rosstat
						AND dateadd(day, - 7, @cur_date)
				)

		DROP TABLE

		IF EXISTS #result2;
			SELECT CONCAT (
					dateadd(day, - 6, @cur_date)
					,' - '
					,@cur_date
					) AS DATE
				,ab.gr_name
				,round(sum(psi), 3) AS psi
				,iif(sum(psi) >= 0.1, 'PSI >= 10%', 'ok') AS message
			INTO #result2
			FROM (
				SELECT a.gr_name
					,a.gr
					,log(a.psi / b.psi) * (a.psi - b.psi) AS psi -- рассчет psi
				FROM (
					SELECT gr_name
						,gr
						,count(external_id) / -- распределение по группам в прошлом, с которым будем сравнивать текущее распределение
						iif(gr_name = 'rosstat_income_gr', @znampast_rosstat, @znampast2) AS psi --отдельно для росстат
					FROM #base2
					unpivot(gr FOR gr_name IN (pdn_gr, rosstat_income_gr, bki_exp_amount_gr, bki_income_gr, income_amount_gr, credit_exp_gr)) AS unpiv
					WHERE (
							startdate BETWEEN @str_date_pts
								AND dateadd(month, - 2, @cur_date)
							AND gr_name <> 'rosstat_income_gr'
							)
						OR (
							startdate BETWEEN @min_date_rosstat
								AND dateadd(day, - 7, @cur_date)
							AND gr_name = 'rosstat_income_gr'
							)
					GROUP BY gr_name
						,gr
					) a
				JOIN (
					SELECT gr_name
						,gr
						,count(external_id) / @znamcur2 AS psi -- текущее распределение за прошедшую неделю
					FROM #base2
					unpivot(gr FOR gr_name IN (pdn_gr, rosstat_income_gr, bki_exp_amount_gr, bki_income_gr, income_amount_gr, credit_exp_gr)) AS unpiv
					WHERE startdate BETWEEN dateadd(day, - 6, @cur_date)
							AND @cur_date
					GROUP BY gr_name
						,gr
					) b ON a.gr_name = b.gr_name
					AND a.gr = b.gr
				) ab
			GROUP BY ab.gr_name;

		DECLARE @cnt2 INT
			,@tableHTML2 NVARCHAR(MAX);

		SET @tableHTML2 = N'<H2>  Мониторинг PSI (ПТС) </H2>' + N'<table border="1" cellspacing="0" cellpadding="0">' + N'<tr><th>Отчетная дата</th>' + N'<th>Группа</th>' + N'<th>PSI</th>' + '<th>Сообщение</th>' + CAST((
					SELECT DISTINCT td = a.DATE
						,' '
						,td = a.gr_name
						,' '
						,td = cast(a.[psi] AS VARCHAR(100))
						,' '
						,td = a.message
					FROM #result2 a
					FOR XML PATH('tr')
						,TYPE
					) AS NVARCHAR(MAX)) + N'</table>';

		SELECT @cnt2 = count(*)
		FROM #result2
		WHERE upper(message) = 'PSI >= 10%';

		IF @cnt2 > 0
			EXEC msdb.dbo.sp_send_dbmail @recipients = 'risk_tech@carmoney.ru'
				--msdb.dbo.sp_send_dbmail @recipients = 'Александр Кузнецов <a.kuznecov@techmoney.ru>'
				,@profile_name = 'Default'
				,@subject = 'Мониторинг ПДН (PSI)'
				,@body = @tableHTML2
				,@body_format = 'HTML';

		-- Мониторинг PSI (installment) --
		DROP TABLE

		IF EXISTS #base3
			SELECT a.external_id
				,a.amount
				,a.startdate
				,CASE -- распределение договоров по группам	
					WHEN b.pdn >= 0
						AND b.pdn < 0.45
						THEN 0
					WHEN b.pdn >= 0.45
						AND b.pdn < 0.70
						THEN 45
					WHEN b.pdn >= 0.70
						AND b.pdn < 1
						THEN 70
					WHEN b.pdn >= 1
						AND b.pdn < 1.6
						THEN 100
					WHEN b.pdn >= 1.6
						AND b.pdn < 3.3
						THEN 160
					WHEN b.pdn >= 3.3
						THEN 330
					END AS pdn_gr
				,CASE 
					WHEN b.rosstat_income >= 55000
						THEN 55000
					WHEN b.rosstat_income >= 36000
						THEN 36000
					WHEN b.rosstat_income >= 30000
						THEN 30000
					WHEN b.rosstat_income >= 1
						THEN 1
					END AS rosstat_income_gr
				,CASE 
					WHEN isnull(b.bki_exp_amount, 0) = 0
						THEN 0
					WHEN b.bki_exp_amount >= 140000
						THEN 140000
					WHEN b.bki_exp_amount >= 65000
						THEN 65000
					WHEN b.bki_exp_amount >= 25000
						THEN 25000
					WHEN b.bki_exp_amount >= 0.01
						THEN 1
					END AS bki_exp_amount_gr
				,CASE 
					WHEN isnull(b.bki_income, 0) = 0
						THEN 0
					WHEN b.bki_income >= 50000
						THEN 50000
					WHEN b.bki_income >= 23000
						THEN 23000
					WHEN b.bki_income >= 6000
						THEN 6000
					WHEN b.bki_income >= 0.01
						THEN 1
					END AS bki_income_gr
				,CASE 
					WHEN isnull(b.income_amount, 0) = 0
						THEN 0
					WHEN b.income_amount >= 80000
						THEN 90000
					WHEN b.income_amount >= 52000
						THEN 52000
					WHEN b.income_amount >= 40000
						THEN 40000
					WHEN b.income_amount >= 1
						THEN 1
					END AS income_amount_gr
				,CASE 
					WHEN credit_exp >= 8000
						THEN 8000
					WHEN credit_exp >= 4800
						THEN 4800
					WHEN credit_exp >= 4470
						THEN 4470
					WHEN credit_exp > 0
						THEN 0
					END AS credit_exp_gr
			INTO #base3
			FROM risk.credits a
			LEFT JOIN risk.pdn_calculation_2gen b ON a.external_id = b.number
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')

			WHERE a.credit_type = 'INST'
				AND isnull(b.income_amount, 0) <> 0 --только инстоллменты, заявочный доход = 0 считается ошибкой
				and l.number is null
		DECLARE @znampast3 AS FLOAT = --кол-во договоров за 2023
			(
				SELECT count(b.external_id)
				FROM #base3 b
				WHERE b.startdate > @str_date_inst
				)
		DECLARE @znamcur3 AS FLOAT = -- кол-во договоров за прошлые 7 дней
			(
				SELECT count(b.external_id)
				FROM #base3 b
				WHERE b.startdate BETWEEN dateadd(day, - 6, @cur_date)
						AND @cur_date
				)

		DROP TABLE

		IF EXISTS #result3;
			SELECT CONCAT (
					dateadd(day, - 6, @cur_date)
					,' - '
					,@cur_date
					) AS DATE
				,ab.gr_name
				,round(sum(psi), 3) AS psi
				,iif(sum(psi) >= 0.1, 'PSI >= 10%', 'ok') AS message
			INTO #result3
			FROM (
				SELECT a.gr_name
					,a.gr
					,log(a.psi / b.psi) * (a.psi - b.psi) AS psi -- рассчет psi
				FROM (
					SELECT gr_name
						,gr
						,count(external_id) / @znampast3 AS psi -- распределение по группам в прошлом, с которым будем сравнивать текущее распределение
					FROM #base3
					unpivot(gr FOR gr_name IN (pdn_gr, rosstat_income_gr, bki_exp_amount_gr, bki_income_gr, income_amount_gr, credit_exp_gr)) AS unpiv
					WHERE startdate >= @str_date_inst
					GROUP BY gr_name
						,gr
					) a
				JOIN (
					SELECT gr_name
						,gr
						,count(external_id) / @znamcur3 AS psi -- текущее распределение за прошедшую неделю
					FROM #base3
					unpivot(gr FOR gr_name IN (pdn_gr, rosstat_income_gr, bki_exp_amount_gr, bki_income_gr, income_amount_gr, credit_exp_gr)) AS unpiv
					WHERE startdate BETWEEN dateadd(day, - 6, @cur_date)
							AND @cur_date
					GROUP BY gr_name
						,gr
					) b ON a.gr_name = b.gr_name
					AND a.gr = b.gr
				) ab
			GROUP BY ab.gr_name;

		DECLARE @cnt3 INT
			,@tableHTML3 NVARCHAR(MAX);

		SET @tableHTML3 = N'<H2>  Мониторинг PSI (Installment) </H2>' + N'<table border="1" cellspacing="0" cellpadding="0">' + N'<tr><th>Отчетная дата</th>' + N'<th>Группа</th>' + N'<th>PSI</th>' + '<th>Сообщение</th>' + CAST((
					SELECT DISTINCT td = a.DATE
						,' '
						,td = a.gr_name
						,' '
						,td = cast(a.[psi] AS VARCHAR(100))
						,' '
						,td = a.message
					FROM #result3 a
					FOR XML PATH('tr')
						,TYPE
					) AS NVARCHAR(MAX)) + N'</table>';

		SELECT @cnt3 = count(*)
		FROM #result3
		WHERE upper(message) = 'PSI >= 10%';

		IF @cnt3 > 0
			EXEC msdb.dbo.sp_send_dbmail @recipients = 'risk_tech@carmoney.ru'
				,@profile_name = 'Default'
				,@subject = 'Мониторинг ПДН (PSI)'
				,@body = @tableHTML3
				,@body_format = 'HTML';

		-- Мониторинг PSI (installment 10k) --
		DROP TABLE

		IF EXISTS #base4
			SELECT a.external_id
				,a.startdate
				,CASE -- распределение договоров по группам	
					WHEN b.pdn IS NULL
						THEN 'null'
					WHEN b.pdn >= 0
						AND b.pdn < 0.50
						THEN '0'
					WHEN b.pdn >= 0.50
						AND b.pdn < 0.80
						THEN '50'
					WHEN b.pdn >= 0.80
						AND b.pdn < 1
						THEN '80'
					WHEN b.pdn >= 1
						THEN '1'
					END AS pdn_gr
			INTO #base4
			FROM risk.credits a
			LEFT JOIN risk.pdn_calculation_2gen b ON a.external_id = b.number
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')

			WHERE a.credit_type = 'INST'
				AND isnull(b.income_amount, 1) <> 0 --только инстоллменты, заявочный доход = 0 считается ошибкой
				and l.number is null
		DECLARE @znampast4 AS FLOAT = --кол-во договоров за 2023
			(
				SELECT count(b.external_id)
				FROM #base4 b
				WHERE b.startdate > @str_date_inst
				)
		DECLARE @znamcur4 AS FLOAT = -- кол-во договоров за прошлые 7 дней
			(
				SELECT count(b.external_id)
				FROM #base4 b
				WHERE b.startdate BETWEEN dateadd(day, - 6, @cur_date)
						AND @cur_date
				)

		DROP TABLE

		IF EXISTS #result4;
			SELECT CONCAT (
					dateadd(day, - 6, @cur_date)
					,' - '
					,@cur_date
					) AS DATE
				,ab.gr_name
				,round(sum(psi), 3) AS psi
				,iif(sum(psi) >= 0.1, 'PSI >= 10%', 'ok') AS message
			INTO #result4
			FROM (
				SELECT a.gr_name
					,a.gr
					,log(a.psi / b.psi) * (a.psi - b.psi) AS psi -- рассчет psi
				FROM (
					SELECT gr_name
						,gr
						,count(external_id) / @znampast4 AS psi -- распределение по группам в прошлом, с которым будем сравнивать текущее распределение
					FROM #base4
					unpivot(gr FOR gr_name IN (pdn_gr)) AS unpiv
					WHERE startdate >= @str_date_inst
					GROUP BY gr_name
						,gr
					) a
				JOIN (
					SELECT gr_name
						,gr
						,count(external_id) / @znamcur4 AS psi -- текущее распределение за прошедшую неделю
					FROM #base4
					unpivot(gr FOR gr_name IN (pdn_gr)) AS unpiv
					WHERE startdate BETWEEN dateadd(day, - 6, @cur_date)
							AND @cur_date
					GROUP BY gr_name
						,gr
					) b ON a.gr_name = b.gr_name
					AND a.gr = b.gr
				) ab
			GROUP BY ab.gr_name

		DECLARE @cnt4 INT
			,@tableHTML4 NVARCHAR(MAX);

		SET @tableHTML4 = N'<H2>  Мониторинг PSI (Installment) </H2>' + N'<table border="1" cellspacing="0" cellpadding="0">' + N'<tr><th>Отчетная дата</th>' + N'<th>Группа</th>' + N'<th>PSI</th>' + '<th>Сообщение</th>' + CAST((
					SELECT DISTINCT td = a.DATE
						,' '
						,td = a.gr_name
						,' '
						,td = cast(a.[psi] AS VARCHAR(100))
						,' '
						,td = a.message
					FROM #result4 a
					FOR XML PATH('tr')
						,TYPE
					) AS NVARCHAR(MAX)) + N'</table>';

		SELECT @cnt4 = count(*)
		FROM #result4
		WHERE upper(message) = 'PSI >= 10%';

		IF @cnt4 > 0
			EXEC msdb.dbo.sp_send_dbmail @recipients = 'risk_tech@carmoney.ru'
				,@profile_name = 'Default'
				,@subject = 'Мониторинг ПДН (PSI)'
				,@body = @tableHTML4
				,@body_format = 'HTML';

		
		
		---------------------------
		-------------МПЛ-----------
		------Беззалог Тотал-------
		---------------------------



		--признак самоходной машины из Fedor
		DROP TABLE IF EXISTS #IsSelfPropelledTs;
			SELECT DISTINCT number
				,IsSelfPropelledTs
			INTO #IsSelfPropelledTs
			FROM stg._fedor.core_ClientRequest b
			INNER JOIN [Stg].[_fedor].[core_ClientAssetTs] c ON b.IdAsset = c.Id
				AND c.IsSelfPropelledTs = 1;

	drop table if exists #selfemployed;
	select distinct number
	into #selfemployed
	from stg._loginom.Application
	where 1=1
	and selectedOffer = 'selfEmployed';

	insert into #selfemployed (number)
    select number
    from RiskDWH.risk.selfemployed;
--обновлено 12.02.2026
delete from #selfemployed
where number in (
-------3К25------ 
 '25081403592445' --дефект (должен был выдаться как самозанятый, но выдался как обычный ПТС, поэтому в МПЛ включаем)
,'25083003643752'
,'25083103647692'
,'25082803635900'
,'25082803636968'
,'25082903638673'
,'25090103653993'
,'25090403662405'
,'25090803673533'
,'25072603541639'
,'25080403564110'
-------окт25-------
);



		DROP TABLE IF EXISTS #stg_mpl_day;
			SELECT a.startdate
				,sum(CASE 
						WHEN a.pdn > 0.8
							THEN a.amount
						ELSE 0
						END) amount_more80
				,sum(CASE 
						WHEN a.pdn > 0.5
							AND a.pdn <= 0.8
							THEN a.amount
						ELSE 0
						END) amount_more50
				,sum(a.amount) amount
				,sum(CASE 
						WHEN a.pdn > 0.8
							THEN a.amount
						ELSE 0
						END) / cast(sum(a.amount) AS FLOAT) share_more80
				,sum(CASE 
						WHEN a.pdn > 0.5
							AND a.pdn <= 0.8
							THEN a.amount
						ELSE 0
						END) / cast(sum(a.amount) AS FLOAT) share_more50
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 5
						THEN format(a.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
					END AS daily
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS weekly
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS monthly
				,CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS quater_cumm
				,getdate() AS dt_dml
			INTO #stg_mpl_day
			FROM risk.credits a
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			left join #selfemployed em on a.external_id = em.Number
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')

			WHERE (
					a.IsInstallment = 1
					OR ts.Number IS NOT NULL
					or a.credit_type = 'bigInstallment'
					)
				AND a.startdate < cast(getdate() AS DATE)
				and em.Number is null
				and l.number is null
			GROUP BY a.startdate
			ORDER BY 1 DESC;

/*SELECT TOP 10 * 
INTO risk.repbi_monitoring_pdn_mpl_2 
FROM dwh2.risk.repbi_monitoring_pdn_mpl;*/
		TRUNCATE TABLE risk.repbi_monitoring_pdn_mpl_2;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_2
		SELECT a.startdate
			,a.daily AS period
			,a.amount_more50
			,a.amount_more80
			,a.amount
			,cast(a.share_more50 AS FLOAT) AS share_more50
			,cast(a.share_more80 AS FLOAT) AS share_more80
			,getdate() AS dt_dml
			,'current' AS metric
		FROM #stg_mpl_day a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_2
		SELECT min(a.startdate) AS startdate
			,weekly
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'current' AS metric
		FROM #stg_mpl_day a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_2
		SELECT min(a.startdate) AS startdate
			,monthly
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'current' AS metric
		FROM #stg_mpl_day a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_2
		SELECT min(DATEADD(dd, - 100, a.startdate)) AS startdate
			,quater_cumm
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'current' AS metric
		FROM #stg_mpl_day a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

		DROP TABLE

		IF EXISTS #stg_mpl_day_additional;
			SELECT a.startdate
				,sum(CASE 
						WHEN np.pdn > 0.8
							THEN a.amount
						ELSE 0
						END) amount_more80
				,sum(CASE 
						WHEN np.pdn > 0.5
							AND np.pdn <= 0.8
							THEN a.amount
						ELSE 0
						END) amount_more50
				,sum(a.amount) amount
				,sum(CASE 
						WHEN np.pdn > 0.8
							THEN a.amount
						ELSE 0
						END) / cast(sum(a.amount) AS FLOAT) share_more80
				,sum(CASE 
						WHEN np.pdn > 0.5
							AND np.pdn <= 0.8
							THEN a.amount
						ELSE 0
						END) / cast(sum(a.amount) AS FLOAT) share_more50
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 5
						THEN format(a.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
					END AS daily
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS weekly
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS monthly
				,CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS quater_cumm
				,getdate() AS dt_dml
			INTO #stg_mpl_day_additional
			FROM risk.credits a
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			left join #selfemployed em on a.external_id = em.Number
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')

			WHERE (
					a.IsInstallment = 1
					OR ts.Number IS NOT NULL
					)
				AND a.startdate < cast(getdate() AS DATE)
				and em.Number is null
				and l.number is null
			GROUP BY a.startdate
			ORDER BY 1 DESC;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_2
		SELECT a.startdate
			,a.daily AS period
			,a.amount_more50
			,a.amount_more80
			,a.amount
			,cast(a.share_more50 AS FLOAT) AS share_more50
			,cast(a.share_more80 AS FLOAT) AS share_more80
			,getdate() AS dt_dml
			,'additional' AS metric
		FROM #stg_mpl_day_additional a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_2
		SELECT min(a.startdate) AS startdate
			,weekly
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'additional' AS metric
		FROM #stg_mpl_day_additional a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_2
		SELECT min(a.startdate) AS startdate
			,monthly
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'additional' AS metric
		FROM #stg_mpl_day_additional a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_2
		SELECT min(DATEADD(dd, - 100, a.startdate)) AS startdate
			,quater_cumm
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'additional' AS metric
		FROM #stg_mpl_day_additional a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;


		-------------
		-----МПЛ-----
		-----ПТС-----
		-------------

		DROP TABLE

		IF EXISTS #stg_mpl_day_pts;
			SELECT a.startdate
				,sum(CASE 
						WHEN a.pdn > 0.8
							THEN a.amount
						ELSE 0
						END) amount_more80
				,sum(CASE 
						WHEN a.pdn > 0.5
							AND a.pdn <= 0.8
							THEN a.amount
						ELSE 0
						END) amount_more50
				,sum(a.amount) amount
				,sum(CASE 
						WHEN a.pdn > 0.8
							THEN a.amount
						ELSE 0
						END) / cast(sum(a.amount) AS FLOAT) share_more80
				,sum(CASE 
						WHEN a.pdn > 0.5
							AND a.pdn <= 0.8
							THEN a.amount
						ELSE 0
						END) / cast(sum(a.amount) AS FLOAT) share_more50
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 5
						THEN format(a.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
					END AS daily
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS weekly
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS monthly
				,CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS quater_cumm
				,getdate() AS dt_dml
			INTO #stg_mpl_day_pts
			FROM risk.credits a
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			left join #selfemployed em on a.external_id = em.Number 
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE 1=1
					and a.IsInstallment = 0 --меняем на 0
					and credit_type like '%PTS%' --смотрим только птс
					and ts.Number IS NULL --признак не самоходки
					AND a.startdate < cast(getdate() AS DATE)
					and em.Number is null
					and l.number is null
			GROUP BY a.startdate
			ORDER BY 1 DESC;
/*SELECT TOP 10 * 
INTO risk.repbi_monitoring_pdn_mpl_pts_2 
FROM dwh2.risk.repbi_monitoring_pdn_mpl_pts;*/
		TRUNCATE TABLE risk.repbi_monitoring_pdn_mpl_pts_2;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_2
		SELECT a.startdate
			,a.daily AS period
			,a.amount_more50
			,a.amount_more80
			,a.amount
			,cast(a.share_more50 AS FLOAT) AS share_more50
			,cast(a.share_more80 AS FLOAT) AS share_more80
			,getdate() AS dt_dml
			,'current' AS metric
		FROM #stg_mpl_day_pts a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_2
		SELECT min(a.startdate) AS startdate
			,weekly
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'current' AS metric
		FROM #stg_mpl_day_pts a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_2
		SELECT min(a.startdate) AS startdate
			,monthly
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'current' AS metric
		FROM #stg_mpl_day_pts a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_2
		SELECT min(DATEADD(dd, - 100, a.startdate)) AS startdate
			,quater_cumm
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'current' AS metric
		FROM #stg_mpl_day_pts a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

		DROP TABLE

		IF EXISTS #stg_mpl_day_pts_additional;
			SELECT a.startdate
				,sum(CASE 
						WHEN np.pdn > 0.8
							THEN a.amount
						ELSE 0
						END) amount_more80
				,sum(CASE 
						WHEN np.pdn > 0.5
							AND np.pdn <= 0.8
							THEN a.amount
						ELSE 0
						END) amount_more50
				,sum(a.amount) amount
				,sum(CASE 
						WHEN np.pdn > 0.8
							THEN a.amount
						ELSE 0
						END) / cast(sum(a.amount) AS FLOAT) share_more80
				,sum(CASE 
						WHEN np.pdn > 0.5
							AND np.pdn <= 0.8
							THEN a.amount
						ELSE 0
						END) / cast(sum(a.amount) AS FLOAT) share_more50
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 5
						THEN format(a.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
					END AS daily
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS weekly
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS monthly
				,CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS quater_cumm
				,getdate() AS dt_dml
			INTO #stg_mpl_day_pts_additional
			FROM risk.credits a
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			left join #selfemployed em on a.external_id = em.Number 
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE 1=1
					and a.IsInstallment = 0 --меняем на 0
					and credit_type like '%PTS%' --смотрим только птс
					and ts.Number IS NULL --признак не самоходки
				AND a.startdate < cast(getdate() AS DATE)
				and em.Number is null
				and l.number is null
			GROUP BY a.startdate
			ORDER BY 1 DESC;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_2
		SELECT a.startdate
			,a.daily AS period
			,a.amount_more50
			,a.amount_more80
			,a.amount
			,cast(a.share_more50 AS FLOAT) AS share_more50
			,cast(a.share_more80 AS FLOAT) AS share_more80
			,getdate() AS dt_dml
			,'additional' AS metric
		FROM #stg_mpl_day_pts_additional a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_2
		SELECT min(a.startdate) AS startdate
			,weekly
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'additional' AS metric
		FROM #stg_mpl_day_pts_additional a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_2
		SELECT min(a.startdate) AS startdate
			,monthly
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'additional' AS metric
		FROM #stg_mpl_day_pts_additional a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_2
		SELECT min(DATEADD(dd, - 100, a.startdate)) AS startdate
			,quater_cumm
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'additional' AS metric
		FROM #stg_mpl_day_pts_additional a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;


		---------------
		------МПЛ------
		--Автокредиты--
		---------------

		DROP TABLE

		IF EXISTS #stg_mpl_day_autocred;
			SELECT a.startdate
				,sum(CASE 
						WHEN a.pdn > 0.8
							THEN a.amount
						ELSE 0
						END) amount_more80
				,sum(CASE 
						WHEN a.pdn > 0.5
							AND a.pdn <= 0.8
							THEN a.amount
						ELSE 0
						END) amount_more50
				,sum(a.amount) amount
				,sum(CASE 
						WHEN a.pdn > 0.8
							THEN a.amount
						ELSE 0
						END) / cast(sum(a.amount) AS FLOAT) share_more80
				,sum(CASE 
						WHEN a.pdn > 0.5
							AND a.pdn <= 0.8
							THEN a.amount
						ELSE 0
						END) / cast(sum(a.amount) AS FLOAT) share_more50
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 5
						THEN format(a.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
					END AS daily
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS weekly
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS monthly
				,CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS quater_cumm
				,getdate() AS dt_dml
			INTO #stg_mpl_day_autocred
			FROM risk.credits a
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			left join #selfemployed em on a.external_id = em.Number 
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE 1=1
					and a.IsInstallment = 0 --меняем на 0
					and credit_type = 'AUTOCREDIT' --смотрим только автокредиты
					and ts.Number IS NULL --признак не самоходки
					AND a.startdate < cast(getdate() AS DATE)
					and em.Number is null
					and l.number is null
			GROUP BY a.startdate
			ORDER BY 1 DESC;
/*SELECT TOP 10 * 
INTO risk.repbi_monitoring_pdn_mpl_autocred_2 
FROM dwh2.risk.repbi_monitoring_pdn_mpl_autocred;*/
		TRUNCATE TABLE risk.repbi_monitoring_pdn_mpl_autocred_2;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_2
		SELECT a.startdate
			,a.daily AS period
			,a.amount_more50
			,a.amount_more80
			,a.amount
			,cast(a.share_more50 AS FLOAT) AS share_more50
			,cast(a.share_more80 AS FLOAT) AS share_more80
			,getdate() AS dt_dml
			,'current' AS metric
		FROM #stg_mpl_day_autocred a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_2
		SELECT min(a.startdate) AS startdate
			,weekly
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'current' AS metric
		FROM #stg_mpl_day_autocred a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_2
		SELECT min(a.startdate) AS startdate
			,monthly
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'current' AS metric
		FROM #stg_mpl_day_autocred a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_2
		SELECT min(DATEADD(dd, - 100, a.startdate)) AS startdate
			,quater_cumm
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'current' AS metric
		FROM #stg_mpl_day_autocred a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

		DROP TABLE

		IF EXISTS #stg_mpl_day_autocred_additional;
			SELECT a.startdate
				,sum(CASE 
						WHEN np.pdn > 0.8
							THEN a.amount
						ELSE 0
						END) amount_more80
				,sum(CASE 
						WHEN np.pdn > 0.5
							AND np.pdn <= 0.8
							THEN a.amount
						ELSE 0
						END) amount_more50
				,sum(a.amount) amount
				,sum(CASE 
						WHEN np.pdn > 0.8
							THEN a.amount
						ELSE 0
						END) / cast(sum(a.amount) AS FLOAT) share_more80
				,sum(CASE 
						WHEN np.pdn > 0.5
							AND np.pdn <= 0.8
							THEN a.amount
						ELSE 0
						END) / cast(sum(a.amount) AS FLOAT) share_more50
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 5
						THEN format(a.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
					END AS daily
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS weekly
				,CASE 
					WHEN datediff(d, a.startdate, cast(getdate() AS DATE)) BETWEEN 1
							AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS monthly
				,CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, a.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
					END AS quater_cumm
				,getdate() AS dt_dml
			INTO #stg_mpl_day_autocred_additional
			FROM risk.credits a
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			left join #selfemployed em on a.external_id = em.Number 
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE 1=1
					and a.IsInstallment = 0 --меняем на 0
					and credit_type = 'AUTOCREDIT' --смотрим только автокредиты
					and ts.Number IS NULL --признак не самоходки
				AND a.startdate < cast(getdate() AS DATE)
				and em.Number is null
				and l.number is null
			GROUP BY a.startdate
			ORDER BY 1 DESC;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_2
		SELECT a.startdate
			,a.daily AS period
			,a.amount_more50
			,a.amount_more80
			,a.amount
			,cast(a.share_more50 AS FLOAT) AS share_more50
			,cast(a.share_more80 AS FLOAT) AS share_more80
			,getdate() AS dt_dml
			,'additional' AS metric
		FROM #stg_mpl_day_autocred_additional a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_2
		SELECT min(a.startdate) AS startdate
			,weekly
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'additional' AS metric
		FROM #stg_mpl_day_autocred_additional a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_2
		SELECT min(a.startdate) AS startdate
			,monthly
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'additional' AS metric
		FROM #stg_mpl_day_autocred_additional a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_2
		SELECT min(DATEADD(dd, - 100, a.startdate)) AS startdate
			,quater_cumm
			,sum(a.amount_more50) AS amount_more50
			,sum(a.amount_more80) AS amount_more80
			,sum(a.amount) AS amount
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more50) / sum(a.amount)
				END AS share_more50
			,CASE 
				WHEN isnull(sum(a.amount), 0) = 0
					THEN 0
				ELSE sum(a.amount_more80) / sum(a.amount)
				END AS share_more80
			,getdate() AS dt_dml
			,'additional' AS metric
		FROM #stg_mpl_day_autocred_additional a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

-----------------------------------------------------------------------------------------------------------
--New 14.07.25
--CMR/УМФО
exec dwh2.risk.fill_logs_cmr_pdn_calculation;
--start

drop table if exists #cmr_pdn;
with 
umfo as (select КодДоговораЗайма, PDN from dwh2.sat.ДоговорЗайма_ПДН where Система = 'УМФО'),
cmr1 as (select КодДоговораЗайма, PDN from dwh2.sat.ДоговорЗайма_ПДН where Система = 'CMR' and year(Дата_по) = '2999'),
cmr2 as (select number, pdn_logs from dwh2.risk.logs_cmr_pdn_calculation)
select distinct a.external_id as КодДоговораЗайма, coalesce(cmr2.pdn_logs, cmr1.pdn, umfo.pdn) as pdn
into #cmr_pdn
from dwh2.risk.credits a
left join umfo on a.external_id = umfo.КодДоговораЗайма
left join cmr1 on a.external_id = cmr1.КодДоговораЗайма
left join cmr2 on a.external_id = cmr2.number
left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
where l.number is null
;
-- Создаем таблицу с датами за последние 30 дней для всех интервалов
DROP TABLE IF EXISTS #date_range;
SELECT DATEADD(day, -n, CAST(GETDATE() AS DATE)) as startdate
INTO #date_range
FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 as n
    FROM master.dbo.spt_values
    WHERE type = 'P'
    AND number < 365
) numbers;

		--------------------------
		------------МПЛ-----------
		------Беззалог Тотал------
		--------------------------

		DROP TABLE IF EXISTS #stg_mpl_day_cmr;
			SELECT 
				d.startdate,
				--  ISNULL для замены NULL на 0
				ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) amount_more80,
				ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) amount_more50,
				ISNULL(sum(a.amount), 0) amount,
				--  Защита от деления на ноль
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more80,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more50,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 5
						THEN format(d.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
				END AS daily,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS weekly,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS monthly,
				CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS quater_cumm,
				CASE 
					WHEN  datediff(m, d.startdate, cast(getdate() AS DATE)) BETWEEN 0 AND 2
					THEN CONCAT(
						concat('01/',MONTH(d.startdate),'/',year(d.startdate))
						,' - '
						,format(EOMONTH(d.startdate), 'dd/MM/yyyy'))
					ELSE 'NULL'
				END AS monthly_calendar,
				getdate() AS dt_dml
			INTO #stg_mpl_day_cmr
			FROM #date_range d
			-- LEFT JOIN для включения всех дат
			LEFT JOIN risk.credits a ON d.startdate = a.startdate 
				AND a.startdate < cast(getdate() AS DATE)
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			LEFT JOIN #cmr_pdn b ON a.external_id = b.КодДоговораЗайма
			LEFT JOIN #selfemployed em ON a.external_id = em.Number
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE (em.Number is null OR em.Number IS NULL) AND (
					a.IsInstallment = 1
					OR ts.Number IS NOT NULL
					OR a.credit_type  IN ( 'bigInstallment', 'bigInstallmentMarket')
				)
				and l.number is null
			GROUP BY d.startdate
			ORDER BY 1 DESC;
/*SELECT TOP 10 * 
INTO risk.repbi_monitoring_pdn_mpl_cmr_2 
FROM dwh2.risk.repbi_monitoring_pdn_mpl_cmr;*/
		TRUNCATE TABLE risk.repbi_monitoring_pdn_mpl_cmr_2;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_2
		SELECT 
			a.startdate,
			a.daily AS period,
			ISNULL(a.amount_more50, 0) AS amount_more50,
			ISNULL(a.amount_more80, 0) AS amount_more80,
			ISNULL(a.amount, 0) AS amount,
			ISNULL(cast(a.share_more50 AS FLOAT), 0) AS share_more50,
			ISNULL(cast(a.share_more80 AS FLOAT), 0) AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_2
		SELECT 
			min(a.startdate) AS startdate,
			weekly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_2
		SELECT 
			min(a.startdate) AS startdate,
			monthly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_2
		SELECT 
			min(DATEADD(dd, - 250, a.startdate)) AS startdate,
			quater_cumm,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

		
		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_2
		SELECT 
			min(DATEADD(dd, - 150, a.startdate)) AS startdate,
			monthly_calendar,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr a
		WHERE a.monthly_calendar <> 'NULL'
		GROUP BY monthly_calendar;

		-- Additional метрика с аналогичными исправлениями
		DROP TABLE IF EXISTS #stg_mpl_day_additional_cmr_2;
			SELECT 
				d.startdate,
				ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) amount_more80,
				ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) amount_more50,
				ISNULL(sum(a.amount), 0) amount,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more80,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more50,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 5
						THEN format(d.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
				END AS daily,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS weekly,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS monthly,
				CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS quater_cumm,
				getdate() AS dt_dml
			INTO #stg_mpl_day_additional_cmr
			FROM #date_range d
			LEFT JOIN risk.credits a ON d.startdate = a.startdate 
				
				AND a.startdate < cast(getdate() AS DATE)
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			LEFT JOIN #cmr_pdn b ON a.external_id = b.КодДоговораЗайма
			LEFT JOIN #selfemployed em ON a.external_id = em.Number 
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE (em.Number is null OR em.Number IS NULL) AND (
					a.IsInstallment = 1
					OR ts.Number IS NOT NULL
					OR a.credit_type  IN ( 'bigInstallment', 'bigInstallmentMarket')
				)
				and l.number is null
			GROUP BY d.startdate
			ORDER BY 1 DESC;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_2
		SELECT 
			a.startdate,
			a.daily AS period,
			ISNULL(a.amount_more50, 0) AS amount_more50,
			ISNULL(a.amount_more80, 0) AS amount_more80,
			ISNULL(a.amount, 0) AS amount,
			ISNULL(cast(a.share_more50 AS FLOAT), 0) AS share_more50,
			ISNULL(cast(a.share_more80 AS FLOAT), 0) AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_2
		SELECT 
			min(a.startdate) AS startdate,
			weekly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_2
		SELECT 
			min(a.startdate) AS startdate,
			monthly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_2
		SELECT 
			min(DATEADD(dd, - 100, a.startdate)) AS startdate,
			quater_cumm,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

		-----------------------------
		--------------МПЛ------------
		------Беззалог без Бига------
		-----------------------------

		DROP TABLE IF EXISTS #stg_mpl_day_cmr_nobig;
			SELECT 
				d.startdate,
				ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) amount_more80,
				ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) amount_more50,
				ISNULL(sum(a.amount), 0) amount,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more80,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more50,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 5
						THEN format(d.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
				END AS daily,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS weekly,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS monthly,
				CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS quater_cumm,
				CASE 
					WHEN  datediff(m, d.startdate, cast(getdate() AS DATE)) BETWEEN 0 AND 2
					THEN CONCAT(
						concat('01/',MONTH(d.startdate),'/',year(d.startdate))
						,' - '
						,format(EOMONTH(d.startdate), 'dd/MM/yyyy'))
					ELSE 'NULL'
				END AS monthly_calendar,
				getdate() AS dt_dml
			INTO #stg_mpl_day_cmr_nobig
			FROM #date_range d
			LEFT JOIN risk.credits a ON d.startdate = a.startdate 
				AND a.credit_type not in ('bigInstallment','biginstallmentmarket')
				AND a.startdate < cast(getdate() AS DATE)
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			LEFT JOIN #cmr_pdn b ON a.external_id = b.КодДоговораЗайма
			LEFT JOIN #selfemployed em ON a.external_id = em.Number
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE (em.Number is null OR em.Number IS NULL) AND (
					a.IsInstallment = 1
					OR ts.Number IS NOT NULL
				) and l.number is null
			GROUP BY d.startdate
			ORDER BY 1 DESC;
/*SELECT TOP 10 * 
INTO risk.repbi_monitoring_pdn_mpl_cmr_nobig_2 
FROM dwh2.risk.repbi_monitoring_pdn_mpl_cmr_nobig;*/
		TRUNCATE TABLE risk.repbi_monitoring_pdn_mpl_cmr_nobig_2;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_nobig_2
		SELECT 
			a.startdate,
			a.daily AS period,
			ISNULL(a.amount_more50, 0) AS amount_more50,
			ISNULL(a.amount_more80, 0) AS amount_more80,
			ISNULL(a.amount, 0) AS amount,
			ISNULL(cast(a.share_more50 AS FLOAT), 0) AS share_more50,
			ISNULL(cast(a.share_more80 AS FLOAT), 0) AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_nobig a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_nobig_2
		SELECT 
			min(a.startdate) AS startdate,
			weekly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_nobig a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_nobig_2
		SELECT 
			min(a.startdate) AS startdate,
			monthly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_nobig a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_nobig_2
		SELECT 
			min(DATEADD(dd, - 250, a.startdate)) AS startdate,
			quater_cumm,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_nobig a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

		
		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_nobig_2
		SELECT 
			min(DATEADD(dd, - 150, a.startdate)) AS startdate,
			monthly_calendar,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_nobig a
		WHERE a.monthly_calendar <> 'NULL'
		GROUP BY monthly_calendar;

		DROP TABLE IF EXISTS #stg_mpl_day_additional_cmr_nobig_2;
			SELECT 
				d.startdate,
				ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) amount_more80,
				ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) amount_more50,
				ISNULL(sum(a.amount), 0) amount,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more80,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more50,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 5
						THEN format(d.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
				END AS daily,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS weekly,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS monthly,
				CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS quater_cumm,
				getdate() AS dt_dml
			INTO #stg_mpl_day_additional_cmr_nobig
			FROM #date_range d
			LEFT JOIN risk.credits a ON d.startdate = a.startdate 
				AND a.credit_type not in ('bigInstallment','biginstallmentmarket')
				AND a.startdate < cast(getdate() AS DATE)
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			LEFT JOIN #cmr_pdn b ON a.external_id = b.КодДоговораЗайма
			LEFT JOIN #selfemployed em ON a.external_id = em.Number
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE (em.Number is null OR em.Number IS NULL) AND (
					a.IsInstallment = 1
					OR ts.Number IS NOT NULL
				) and l.number is null
			GROUP BY d.startdate
			ORDER BY 1 DESC;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_nobig_2
		SELECT 
			a.startdate,
			a.daily AS period,
			ISNULL(a.amount_more50, 0) AS amount_more50,
			ISNULL(a.amount_more80, 0) AS amount_more80,
			ISNULL(a.amount, 0) AS amount,
			ISNULL(cast(a.share_more50 AS FLOAT), 0) AS share_more50,
			ISNULL(cast(a.share_more80 AS FLOAT), 0) AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr_nobig a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_nobig_2
		SELECT 
			min(a.startdate) AS startdate,
			weekly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr_nobig a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_nobig_2
		SELECT 
			min(a.startdate) AS startdate,
			monthly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr_nobig a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_cmr_nobig_2
		SELECT 
			min(DATEADD(dd, - 100, a.startdate)) AS startdate,
			quater_cumm,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr_nobig a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

		-----------------------------
		--------------МПЛ------------
		-----------Только Биг--------
		-----------------------------

		DROP TABLE IF EXISTS #stg_mpl_day_cmr_bigonly;
			SELECT 
				d.startdate,
				ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) amount_more80,
				ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) amount_more50,
				ISNULL(sum(a.amount), 0) amount,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more80,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more50,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 5
						THEN format(d.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
				END AS daily,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS weekly,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS monthly,
				CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS quater_cumm,
				CASE 
					WHEN  datediff(m, d.startdate, cast(getdate() AS DATE)) BETWEEN 0 AND 2
					THEN CONCAT(
						concat('01/',MONTH(d.startdate),'/',year(d.startdate))
						,' - '
						,format(EOMONTH(d.startdate), 'dd/MM/yyyy'))
					ELSE 'NULL'
				END AS monthly_calendar,
				getdate() AS dt_dml
			INTO #stg_mpl_day_cmr_bigonly
			FROM #date_range d
			LEFT JOIN risk.credits a ON d.startdate = a.startdate 
				AND a.credit_type = 'bigInstallment'
				AND a.startdate < cast(getdate() AS DATE)
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			LEFT JOIN #cmr_pdn b ON a.external_id = b.КодДоговораЗайма
			LEFT JOIN #selfemployed em ON a.external_id = em.Number 
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE (em.Number is null OR em.Number IS NULL) and l.number is null
			GROUP BY d.startdate
			ORDER BY 1 DESC;

	/*		SELECT TOP 10 * 
INTO risk.repbi_monitoring_pdn_mpl_cmr_bigonly_2 
FROM dwh2.risk.repbi_monitoring_pdn_mpl_cmr_bigonly;*/
		TRUNCATE TABLE  risk.repbi_monitoring_pdn_mpl_cmr_bigonly_2;

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigonly_2
		SELECT 
			a.startdate,
			a.daily AS period,
			ISNULL(a.amount_more50, 0) AS amount_more50,
			ISNULL(a.amount_more80, 0) AS amount_more80,
			ISNULL(a.amount, 0) AS amount,
			ISNULL(cast(a.share_more50 AS FLOAT), 0) AS share_more50,
			ISNULL(cast(a.share_more80 AS FLOAT), 0) AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_bigonly a
		WHERE a.daily <> 'NULL';

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigonly_2
		SELECT 
			min(a.startdate) AS startdate,
			weekly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_bigonly a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigonly_2
		SELECT 
			min(a.startdate) AS startdate,
			monthly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_bigonly a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigonly_2
		SELECT 
			min(DATEADD(dd, - 250, a.startdate)) AS startdate,
			quater_cumm,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_bigonly a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

		
		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigonly_2
		SELECT 
			min(DATEADD(dd, - 150, a.startdate)) AS startdate,
			monthly_calendar,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_bigonly a
		WHERE a.monthly_calendar <> 'NULL'
		GROUP BY monthly_calendar;

		DROP TABLE IF EXISTS #stg_mpl_day_additional_cmr_bigonly;
			SELECT 
				d.startdate,
				ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) amount_more80,
				ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) amount_more50,
				ISNULL(sum(a.amount), 0) amount,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more80,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more50,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 5
						THEN format(d.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
				END AS daily,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS weekly,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS monthly,
				CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS quater_cumm,
				getdate() AS dt_dml
			INTO #stg_mpl_day_additional_cmr_bigonly
			FROM #date_range d
			LEFT JOIN risk.credits a ON d.startdate = a.startdate 
				AND a.credit_type = 'bigInstallment'
				AND a.startdate < cast(getdate() AS DATE)
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			LEFT JOIN #cmr_pdn b ON a.external_id = b.КодДоговораЗайма
			LEFT JOIN #selfemployed em ON a.external_id = em.Number 
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE (em.Number is null OR em.Number IS NULL) and l.number is null
			GROUP BY d.startdate
			ORDER BY 1 DESC;

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigonly_2
		SELECT 
			a.startdate,
			a.daily AS period,
			ISNULL(a.amount_more50, 0) AS amount_more50,
			ISNULL(a.amount_more80, 0) AS amount_more80,
			ISNULL(a.amount, 0) AS amount,
			ISNULL(cast(a.share_more50 AS FLOAT), 0) AS share_more50,
			ISNULL(cast(a.share_more80 AS FLOAT), 0) AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr_bigonly a
		WHERE a.daily <> 'NULL';

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigonly_2
		SELECT 
			min(a.startdate) AS startdate,
			weekly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr_bigonly a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigonly_2
		SELECT 
			min(a.startdate) AS startdate,
			monthly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr_bigonly a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigonly_2
		SELECT 
			min(DATEADD(dd, - 100, a.startdate)) AS startdate,
			quater_cumm,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr_bigonly a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

        --------------МПЛ------------
		-----------Только biginstallmentmarket--------
		-----------------------------

		DROP TABLE IF EXISTS #stg_mpl_day_cmr_bigmarket;
			SELECT 
				d.startdate,
				ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) amount_more80,
				ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) amount_more50,
				ISNULL(sum(a.amount), 0) amount,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more80,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more50,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 5
						THEN format(d.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
				END AS daily,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS weekly,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS monthly,
				CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS quater_cumm,
				CASE 
					WHEN  datediff(m, d.startdate, cast(getdate() AS DATE)) BETWEEN 0 AND 2
					THEN CONCAT(
						concat('01/',MONTH(d.startdate),'/',year(d.startdate))
						,' - '
						,format(EOMONTH(d.startdate), 'dd/MM/yyyy'))
					ELSE 'NULL'
				END AS monthly_calendar,
				getdate() AS dt_dml
			INTO #stg_mpl_day_cmr_bigmarket
			FROM #date_range d
			LEFT JOIN risk.credits a ON d.startdate = a.startdate 
				AND a.credit_type = 'biginstallmentmarket'
				AND a.startdate < cast(getdate() AS DATE)
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			LEFT JOIN #cmr_pdn b ON a.external_id = b.КодДоговораЗайма
			LEFT JOIN #selfemployed em ON a.external_id = em.Number
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE (em.Number is null OR em.Number IS NULL) and l.number is null
			GROUP BY d.startdate
			ORDER BY 1 DESC;
/*SELECT TOP 10 * 
INTO risk.repbi_monitoring_pdn_mpl_cmr_bigmarket_2 
FROM dwh2.risk.repbi_monitoring_pdn_mpl_cmr_bigmarket;*/
		TRUNCATE TABLE  risk.repbi_monitoring_pdn_mpl_cmr_bigmarket_2;

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigmarket_2
		SELECT 
			a.startdate,
			a.daily AS period,
			ISNULL(a.amount_more50, 0) AS amount_more50,
			ISNULL(a.amount_more80, 0) AS amount_more80,
			ISNULL(a.amount, 0) AS amount,
			ISNULL(cast(a.share_more50 AS FLOAT), 0) AS share_more50,
			ISNULL(cast(a.share_more80 AS FLOAT), 0) AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_bigmarket a
		WHERE a.daily <> 'NULL';

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigmarket_2
		SELECT 
			min(a.startdate) AS startdate,
			weekly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_bigmarket a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigmarket_2
		SELECT 
			min(a.startdate) AS startdate,
			monthly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_bigmarket a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigmarket_2
		SELECT 
			min(DATEADD(dd, - 250, a.startdate)) AS startdate,
			quater_cumm,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_bigmarket a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

		
		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigmarket_2
		SELECT 
			min(DATEADD(dd, - 150, a.startdate)) AS startdate,
			monthly_calendar,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_cmr_bigmarket a
		WHERE a.monthly_calendar <> 'NULL'
		GROUP BY monthly_calendar;

		DROP TABLE IF EXISTS #stg_mpl_day_additional_cmr_bigmarket;
			SELECT 
				d.startdate,
				ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) amount_more80,
				ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) amount_more50,
				ISNULL(sum(a.amount), 0) amount,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more80,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more50,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 5
						THEN format(d.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
				END AS daily,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS weekly,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS monthly,
				CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS quater_cumm,
				getdate() AS dt_dml
			INTO #stg_mpl_day_additional_cmr_bigmarket
			FROM #date_range d
			LEFT JOIN risk.credits a ON d.startdate = a.startdate 
				AND a.credit_type = 'biginstallmentmarket'
				AND a.startdate < cast(getdate() AS DATE)
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			LEFT JOIN #cmr_pdn b ON a.external_id = b.КодДоговораЗайма
			LEFT JOIN #selfemployed em ON a.external_id = em.Number 
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE (em.Number is null OR em.Number IS NULL) and l.number is null
			GROUP BY d.startdate
			ORDER BY 1 DESC;

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigmarket_2
		SELECT 
			a.startdate,
			a.daily AS period,
			ISNULL(a.amount_more50, 0) AS amount_more50,
			ISNULL(a.amount_more80, 0) AS amount_more80,
			ISNULL(a.amount, 0) AS amount,
			ISNULL(cast(a.share_more50 AS FLOAT), 0) AS share_more50,
			ISNULL(cast(a.share_more80 AS FLOAT), 0) AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr_bigmarket a
		WHERE a.daily <> 'NULL';

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigmarket_2
		SELECT 
			min(a.startdate) AS startdate,
			weekly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr_bigmarket a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigmarket_2
		SELECT 
			min(a.startdate) AS startdate,
			monthly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr_bigmarket a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO  risk.repbi_monitoring_pdn_mpl_cmr_bigmarket_2
		SELECT 
			min(DATEADD(dd, - 100, a.startdate)) AS startdate,
			quater_cumm,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_additional_cmr_bigmarket a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

		-------------
		-----МПЛ-----
		-----ПТС-----
		-------------

		DROP TABLE IF EXISTS #stg_mpl_day_pts_cmr;
			SELECT 
				d.startdate,
				ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) amount_more80,
				ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) amount_more50,
				ISNULL(sum(a.amount), 0) amount,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more80,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more50,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 5
						THEN format(d.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
				END AS daily,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS weekly,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS monthly,
				CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS quater_cumm,
				CASE 
					WHEN  datediff(m, d.startdate, cast(getdate() AS DATE)) BETWEEN 0 AND 2
					THEN CONCAT(
						concat('01/',MONTH(d.startdate),'/',year(d.startdate))
						,' - '
						,format(EOMONTH(d.startdate), 'dd/MM/yyyy'))
					ELSE 'NULL'
				END AS monthly_calendar,
				getdate() AS dt_dml
			INTO #stg_mpl_day_pts_cmr
			FROM #date_range d
			LEFT JOIN risk.credits a ON d.startdate = a.startdate 
				AND a.IsInstallment = 0
				AND credit_type like '%PTS%'
				AND a.startdate < cast(getdate() AS DATE)
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			LEFT JOIN #cmr_pdn b ON a.external_id = b.КодДоговораЗайма
			LEFT JOIN #selfemployed em ON a.external_id = em.Number 
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE (em.Number is null OR em.Number IS NULL) AND ts.Number IS NULL and l.number is null
			GROUP BY d.startdate
			ORDER BY 1 DESC;

/*SELECT TOP 10 * 
INTO risk.repbi_monitoring_pdn_mpl_pts_cmr_2 
FROM dwh2.risk.repbi_monitoring_pdn_mpl_pts_cmr;*/
		TRUNCATE TABLE risk.repbi_monitoring_pdn_mpl_pts_cmr_2;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_cmr_2
		SELECT 
			a.startdate,
			a.daily AS period,
			ISNULL(a.amount_more50, 0) AS amount_more50,
			ISNULL(a.amount_more80, 0) AS amount_more80,
			ISNULL(a.amount, 0) AS amount,
			ISNULL(cast(a.share_more50 AS FLOAT), 0) AS share_more50,
			ISNULL(cast(a.share_more80 AS FLOAT), 0) AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_pts_cmr a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_cmr_2
		SELECT 
			min(a.startdate) AS startdate,
			weekly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_pts_cmr a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_cmr_2
		SELECT 
			min(a.startdate) AS startdate,
			monthly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_pts_cmr a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_cmr_2
		SELECT 
			min(DATEADD(dd, - 250, a.startdate)) AS startdate,
			quater_cumm,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_pts_cmr a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_cmr_2
		SELECT 
			min(DATEADD(dd, - 150, a.startdate)) AS startdate,
			monthly_calendar,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_pts_cmr a
		WHERE a.monthly_calendar <> 'NULL'
		GROUP BY monthly_calendar;

		DROP TABLE IF EXISTS #stg_mpl_day_pts_additional_cmr;
			SELECT 
				d.startdate,
				ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) amount_more80,
				ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) amount_more50,
				ISNULL(sum(a.amount), 0) amount,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more80,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more50,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 5
						THEN format(d.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
				END AS daily,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS weekly,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS monthly,
				CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS quater_cumm,
				getdate() AS dt_dml
			INTO #stg_mpl_day_pts_additional_cmr
			FROM #date_range d
			LEFT JOIN risk.credits a ON d.startdate = a.startdate 
				AND a.IsInstallment = 0
				AND credit_type like '%PTS%'
				AND a.startdate < cast(getdate() AS DATE)
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			LEFT JOIN #cmr_pdn b ON a.external_id = b.КодДоговораЗайма
			LEFT JOIN #selfemployed em ON a.external_id = em.Number
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE (em.Number is null OR em.Number IS NULL) AND ts.Number IS NULL and l.number is null
			GROUP BY d.startdate
			ORDER BY 1 DESC;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_cmr_2
		SELECT 
			a.startdate,
			a.daily AS period,
			ISNULL(a.amount_more50, 0) AS amount_more50,
			ISNULL(a.amount_more80, 0) AS amount_more80,
			ISNULL(a.amount, 0) AS amount,
			ISNULL(cast(a.share_more50 AS FLOAT), 0) AS share_more50,
			ISNULL(cast(a.share_more80 AS FLOAT), 0) AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_pts_additional_cmr a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_cmr_2
		SELECT 
			min(a.startdate) AS startdate,
			weekly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_pts_additional_cmr a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_cmr_2
		SELECT 
			min(a.startdate) AS startdate,
			monthly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_pts_additional_cmr a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_pts_cmr_2
		SELECT 
			min(DATEADD(dd, - 100, a.startdate)) AS startdate,
			quater_cumm,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_pts_additional_cmr a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

		---------------
		------МПЛ------
		--Автокредиты--
		---------------

		DROP TABLE IF EXISTS #stg_mpl_day_autocred_cmr;
			SELECT 
				d.startdate,
				ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) amount_more80,
				ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) amount_more50,
				ISNULL(sum(a.amount), 0) amount,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more80,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more50,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 5
						THEN format(d.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
				END AS daily,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS weekly,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS monthly,
				CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS quater_cumm,
				CASE 
					WHEN  datediff(m, d.startdate, cast(getdate() AS DATE)) BETWEEN 0 AND 2
					THEN CONCAT(
						concat('01/',MONTH(d.startdate),'/',year(d.startdate))
						,' - '
						,format(EOMONTH(d.startdate), 'dd/MM/yyyy'))
					ELSE 'NULL'
				END AS monthly_calendar,
				getdate() AS dt_dml
			INTO #stg_mpl_day_autocred_cmr
			FROM #date_range d
			LEFT JOIN risk.credits a ON d.startdate = a.startdate 
				AND a.IsInstallment = 0
				AND credit_type = 'AUTOCREDIT'
				AND a.startdate < cast(getdate() AS DATE)
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			LEFT JOIN #cmr_pdn b ON a.external_id = b.КодДоговораЗайма
			LEFT JOIN #selfemployed em ON a.external_id = em.Number 
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE (em.Number is null OR em.Number IS NULL) AND ts.Number IS NULL
			and l.number is null
			GROUP BY d.startdate
			ORDER BY 1 DESC;

/*SELECT TOP 10 * 
INTO risk.repbi_monitoring_pdn_mpl_autocred_cmr_2 
FROM dwh2.risk.repbi_monitoring_pdn_mpl_autocred_cmr;*/
		TRUNCATE TABLE risk.repbi_monitoring_pdn_mpl_autocred_cmr_2;
		
		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_cmr_2
		SELECT 
			a.startdate,
			a.daily AS period,
			ISNULL(a.amount_more50, 0) AS amount_more50,
			ISNULL(a.amount_more80, 0) AS amount_more80,
			ISNULL(a.amount, 0) AS amount,
			ISNULL(cast(a.share_more50 AS FLOAT), 0) AS share_more50,
			ISNULL(cast(a.share_more80 AS FLOAT), 0) AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_autocred_cmr a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_cmr_2
		SELECT 
			min(a.startdate) AS startdate,
			weekly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_autocred_cmr a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_cmr_2
		SELECT 
			min(a.startdate) AS startdate,
			monthly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_autocred_cmr a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_cmr_2
		SELECT 
			min(DATEADD(dd, - 250, a.startdate)) AS startdate,
			quater_cumm,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_autocred_cmr a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_cmr_2
		SELECT 
			min(DATEADD(dd, - 150, a.startdate)) AS startdate,
			monthly_calendar,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'current' AS metric
		FROM #stg_mpl_day_autocred_cmr a
		WHERE a.monthly_calendar <> 'NULL'
		GROUP BY monthly_calendar;

		DROP TABLE IF EXISTS #stg_mpl_day_autocred_additional_cmr;
			SELECT 
				d.startdate,
				ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) amount_more80,
				ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) amount_more50,
				ISNULL(sum(a.amount), 0) amount,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more80,
				CASE 
					WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
					ELSE ISNULL(sum(CASE WHEN b.pdn > 0.5 AND b.pdn <= 0.8 THEN a.amount ELSE 0 END), 0) / CAST(ISNULL(sum(a.amount), 1) AS FLOAT)
				END share_more50,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 5
						THEN format(d.startdate, 'dd/MM/yyyy')
					ELSE 'NULL'
				END AS daily,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 7
						THEN CONCAT (
								format(dateadd(dd, - 7, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS weekly,
				CASE 
					WHEN datediff(d, d.startdate, cast(getdate() AS DATE)) BETWEEN 1 AND 30
						THEN CONCAT (
								format(dateadd(dd, - 30, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								,' - '
								,format(dateadd(dd, - 1, cast(getdate() AS DATE)), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS monthly,
				CASE 
					--первое число квартала
					WHEN cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE) = cast(getdate() AS DATE)
						AND cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate() - 1), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() - 1 AS DATE), 'dd/MM/yyyy')
								)
					WHEN cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE) >= cast(dateadd(qq, datediff(qq, 0, getdate()), 0) AS DATE)
						THEN CONCAT (
								format(cast(dateadd(qq, datediff(qq, 0, d.startdate), 0) AS DATE), 'dd/MM/yyyy')
								,' - '
								,format(cast(getdate() AS DATE), 'dd/MM/yyyy')
								)
					ELSE 'NULL'
				END AS quater_cumm,
				getdate() AS dt_dml
			INTO #stg_mpl_day_autocred_additional_cmr
			FROM #date_range d
			LEFT JOIN risk.credits a ON d.startdate = a.startdate 
				AND a.IsInstallment = 0
				AND credit_type = 'AUTOCREDIT'
				AND a.startdate < cast(getdate() AS DATE)
			LEFT JOIN risk.pdn_calculation_2gen np ON np.number = a.external_id
			LEFT JOIN #IsSelfPropelledTs ts ON a.external_id = ts.Number collate Cyrillic_General_CI_AS
			LEFT JOIN #cmr_pdn b ON a.external_id = b.КодДоговораЗайма
			LEFT JOIN #selfemployed em ON a.external_id = em.Number 
			left join stg._loginom.originationlog l on l.number = a.external_id and l.stage = 'call 2' and l.Region in ('94', '93', '90', '95')
			WHERE (em.Number is null OR em.Number IS NULL) AND ts.Number IS NULL and l.number is null
			GROUP BY d.startdate
			ORDER BY 1 DESC;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_cmr_2
		SELECT 
			a.startdate,
			a.daily AS period,
			ISNULL(a.amount_more50, 0) AS amount_more50,
			ISNULL(a.amount_more80, 0) AS amount_more80,
			ISNULL(a.amount, 0) AS amount,
			ISNULL(cast(a.share_more50 AS FLOAT), 0) AS share_more50,
			ISNULL(cast(a.share_more80 AS FLOAT), 0) AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_autocred_additional_cmr a
		WHERE a.daily <> 'NULL';

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_cmr_2
		SELECT 
			min(a.startdate) AS startdate,
			weekly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_autocred_additional_cmr a
		WHERE a.weekly <> 'NULL'
		GROUP BY weekly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_cmr_2
		SELECT 
			min(a.startdate) AS startdate,
			monthly,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_autocred_additional_cmr a
		WHERE a.monthly <> 'NULL'
		GROUP BY monthly;

		INSERT INTO risk.repbi_monitoring_pdn_mpl_autocred_cmr_2
		SELECT 
			min(DATEADD(dd, - 100, a.startdate)) AS startdate,
			quater_cumm,
			ISNULL(sum(a.amount_more50), 0) AS amount_more50,
			ISNULL(sum(a.amount_more80), 0) AS amount_more80,
			ISNULL(sum(a.amount), 0) AS amount,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more50), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more50,
			CASE 
				WHEN ISNULL(sum(a.amount), 0) = 0 THEN 0
				ELSE ISNULL(sum(a.amount_more80), 0) / ISNULL(sum(a.amount), 1)
			END AS share_more80,
			getdate() AS dt_dml,
			'additional' AS metric
		FROM #stg_mpl_day_autocred_additional_cmr a
		WHERE a.quater_cumm <> 'NULL'
		GROUP BY quater_cumm;

-----------------------------------------------------------------------------------------------------------



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


