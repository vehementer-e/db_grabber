
--exec [dwh2].[risk].[etl_repbi_pdl_repeated_vint]
CREATE PROCEDURE [risk].[etl_repbi_pdl_repeated_vint]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		--1. соберем кредиты PDL за необходимый период
		DROP TABLE

		IF EXISTS #credit;
			SELECT *
			INTO #credit
			FROM risk.credits WITH (NOLOCK)
			WHERE credit_type = 'PDL';

		--2. по кредитам, отобранным на предыдущем шаге, выгрузим просрочку
		DROP TABLE

		IF EXISTS #overdue;
			SELECT o.*
			INTO #overdue
			FROM [dwh2].[dbo].[dm_OverdueIndicators] o
			INNER JOIN #credit c ON c.external_id = o.number;

		--3. подтянем признак промопериода из OrLog
		DROP TABLE

		IF EXISTS #log_promo;
			SELECT o.number
				,o.PromoPeriodRepayment
				,row_number() OVER (
					PARTITION BY o.number ORDER BY o.call_date DESC
					) AS rn_promo
			INTO #log_promo
			FROM stg._loginom.Originationlog o
			INNER JOIN #credit c ON c.external_id = o.number;

		--4. соберем промежуточный датасет с данными по просрочке и промопериоду.
		DROP TABLE

		IF EXISTS #data_set;
			SELECT cr.external_id
				,cr.client_type
				,cr.credit_type
				,cast(cr.amount AS FLOAT) AS CR_amount
				,cast(1 AS INT) AS flg_count
				,cr.PDLTerm
				,lp.PromoPeriodRepayment
				,cr.pdn
				,cr.generation
				,cr.startdate
				,cr.factenddate
				,cr.max_dpd
				,cast(od.CurrentPrincipalDebt AS FLOAT) AS CurrentPrincipalDebt
				,od.CurrentMOB_initial
				,od.CurrentMOB_accrual
				,od.fpd0
				,od.fpd4
				,od.fpd7
				,od.fpd10
				,od.fpd15
				,od.fpd30
				,od.spd0
				,od.tpd0
				,od.spd0_not_fpd0
				,od._30_4_MFO
				,od._30_4_CMR
				,od._90_6_MFO
				,od._90_6_CMR
				,od._90_12_MFO
				,od._90_12_CMR
				,od.MOB_overdue30_MFO_date
				,od.MOB_overdue30_MFO
				,cast(od.Pdebt_overdue30_MFO AS FLOAT) AS Pdebt_overdue30_MFO
				,od.MOB_overdue60_MFO_date
				,od.MOB_overdue60_MFO
				,cast(od.Pdebt_overdue60_MFO AS FLOAT) AS Pdebt_overdue60_MFO
				,od.MOB_overdue90_MFO_date
				,od.MOB_overdue90_MFO
				,cast(od.Pdebt_overdue90_MFO AS FLOAT) AS Pdebt_overdue90_MFO
				,od.MOB_overdue30_CMR_date
				,od.MOB_overdue30_CMR
				,cast(od.Pdebt_overdue30_CMR AS FLOAT) AS Pdebt_overdue30_CMR
				,od.MOB_overdue60_CMR_date
				,od.MOB_overdue60_CMR
				,cast(od.Pdebt_overdue60_CMR AS FLOAT) AS Pdebt_overdue60_CMR
				,od.MOB_overdue90_CMR_date
				,od.MOB_overdue90_CMR
				,cast(od.Pdebt_overdue90_CMR AS FLOAT) AS Pdebt_overdue90_CMR
				,od.CurrentOverdue_MFO
				,od.MaxOverdue_MFO
				,od.CurrentOverdue_CMR
				,od.MaxOverdue_CMR
				,od.HardFraud
				,od.ConfirmedFraud
				,od.UnconfirmedFraud
				,od.create_at
				,od.CurrentMOB
				,od._15_4_MFO
				,od._15_4_CMR
				,od.fpd60
				,od.Count_overdue
			INTO #data_set
			FROM #credit AS cr
			LEFT JOIN #overdue od ON cr.external_id = od.number
			LEFT JOIN #log_promo lp ON cr.external_id = lp.Number AND lp.rn_promo = 1;

		--5. выделим кредиты с пролонгацией
		DROP TABLE

		IF EXISTS #prolongation;
			SELECT *
				,row_number() OVER (
					PARTITION BY number ORDER BY period_start ASC
					) AS rn
			INTO #prolongation
			FROM [dbo].[dm_restructurings]
			WHERE reason_credit_vacation = 'Пролонгация PDL';

		--6. выгрузим признак запроса пролонгации (отличается от пролонгации тем, что клиент может не погасить %% за предыдущий период и тогда он не попадает на пролонгцию)
		DROP TABLE

		IF EXISTS #statement_prolongation;
			SELECT д.Ссылка AS Loan_id
				,д.Код AS number
				,dateadd(year, - 2000, д.Дата) AS loan_dt
				,dateadd(year, - 2000, PDLПролонгации.Период) AS prolong_start_dt
				,dateadd(year, - 2000, парам_договора.ДатаОкончания) AS prolong_finish_dt
				,'Реструктуризация' AS type_operation
				,'Пролонгация PDL' AS reason_credit_vacation
			INTO #statement_prolongation
			FROM stg._1cCmr.Справочник_договоры д
			INNER JOIN stg.[_1cCMR].[РегистрНакопления_PDLПролонгации] PDLПролонгации ON PDLПролонгации.Договор = д.Ссылка
			LEFT JOIN stg._1cCMR.РегистрСведений_ПараметрыДоговора парам_договора ON парам_договора.Договор = PDLПролонгации.Договор AND парам_договора.Регистратор_Ссылка = PDLПролонгации.Регистратор_Ссылка 
				AND парам_договора.Регистратор_ТипСсылки = 0x0000005E 
				AND парам_договора.Период = PDLПролонгации.Период
			WHERE PDLПролонгации.ВидДвижения = 0;

		--7. раскрасим запросы пролонгации фактом отсутствия реальной пролонгации
		DROP TABLE

		IF EXISTS #flg_statement_prolongation;
			SELECT sp.number
				,flg_statement_without_prolong = 1
			INTO #flg_statement_prolongation
			FROM #statement_prolongation sp
			LEFT JOIN #prolongation pr ON sp.number = pr.number
			WHERE pr.number IS NULL AND sp.prolong_start_dt <= dateadd(dd, - 10, sysdatetime());

		--8. определим все пролонгации по договору, максимально допустимо 4 пролонгации по 1 мес.
		DROP TABLE

		IF EXISTS #data_set_prolong;
			SELECT ds.*
				,pr_1.period_start AS period_start_1
				,pr_1.period_end AS period_end_1
				,pr_2.period_start AS period_start_2
				,pr_2.period_end AS period_end_2
				,pr_3.period_start AS period_start_3
				,pr_3.period_end AS period_end_3
				,pr_4.period_start AS period_start_4
				,pr_4.period_end AS period_end_4
			INTO #data_set_prolong
			FROM #data_set AS ds
			LEFT JOIN #prolongation pr_1 ON ds.external_id = pr_1.number AND pr_1.rn = 1
			LEFT JOIN #prolongation pr_2 ON ds.external_id = pr_2.number AND pr_2.rn = 2
			LEFT JOIN #prolongation pr_3 ON ds.external_id = pr_3.number AND pr_3.rn = 3
			LEFT JOIN #prolongation pr_4 ON ds.external_id = pr_4.number AND pr_4.rn = 4;

		--9. выделим кредиты с отсутствием исторической просрочки на дату отчета
		DROP TABLE

		IF EXISTS #without_overdue;
			SELECT cr.external_id
				,CASE WHEN max(bal.dpd_begin_day) = 0 THEN 1 ELSE 0 END AS without_overdue
			INTO #without_overdue
			FROM #credit cr
			INNER JOIN dbo.dm_CMRStatBalance bal ON cr.external_id = bal.external_id
			GROUP BY cr.external_id;

		--10. обогатим договоры данными из заявок
		DROP TABLE

		IF EXISTS #app_data;
			SELECT a.*
				,row_number() OVER (
					PARTITION BY a.number ORDER BY a.Stage_date DESC
					) AS rn_for_drop
			INTO #app_data
			FROM Stg._loginom.application a WITH (NOLOCK)
			INNER JOIN #credit c ON c.external_id = a.number AND a.Stage = 'Call 1';

		--11. Выделим признак автоапрува (после CALL2 идет этап CALL5)
		DROP TABLE

		IF EXISTS #Auto_Approve;
			SELECT DISTINCT number
				,CASE WHEN Decision = 'Accept' AND Next_step = 'Call 5' /*and client_type_2 = 'repeated'*/ THEN 1 ELSE 0 END AS flg_autoapp
				,ROW_NUMBER() OVER (
					PARTITION BY number ORDER BY call_date DESC
					) rn
			INTO #Auto_Approve
			FROM stg._loginom.Originationlog a WITH (NOLOCK)
			INNER JOIN #credit c ON c.external_id = a.number
			WHERE a.stage = 'Call 2';

		--12. соберем итоговый датасет с агрегированными данными 
		--часть данных/признаков используется для аналитики и анализа причин изменения показателей
		TRUNCATE TABLE risk.repbi_pdl_repeated_vint;
		--DROP TABLE risk.repbi_pdl_repeated_vint
		INSERT INTO risk.repbi_pdl_repeated_vint
		SELECT DISTINCT dsp.*
			,aa.flg_autoapp
			,CASE WHEN t_o.without_overdue = 1 AND dsp.factenddate IS NOT NULL AND dsp.period_start_1 IS NULL THEN 1 ELSE 0 END AS without_overdue
			,CASE WHEN dsp.factenddate IS NOT NULL THEN 1 ELSE 0 END AS flg_closed
			,CASE WHEN period_start_1 IS NOT NULL THEN 1 ELSE 0 END AS prolongation_1
			,CASE WHEN period_start_2 IS NOT NULL THEN 1 ELSE 0 END AS prolongation_2
			,CASE WHEN period_start_3 IS NOT NULL THEN 1 ELSE 0 END AS prolongation_3
			,CASE WHEN period_start_4 IS NOT NULL THEN 1 ELSE 0 END AS prolongation_4
			,CASE WHEN (period_start_1 IS NOT NULL AND period_start_2 IS NULL) AND (dsp.fpd0 + dsp.fpd4 + dsp.fpd7 + dsp.fpd10 + dsp.fpd30) = 0 THEN 1 WHEN (period_start_1 IS NOT NULL AND period_start_2 IS NOT NULL AND period_start_3 IS NULL) AND (dsp.fpd0 + dsp.fpd4 + dsp.fpd7 + dsp.fpd10 + dsp.fpd30) = 0 THEN 1 WHEN (period_start_1 IS NOT NULL AND period_start_2 IS NOT NULL AND period_start_3 IS NOT NULL AND period_start_4 IS NULL) AND (dsp.fpd0 + dsp.fpd4 + dsp.fpd7 + dsp.fpd10 + dsp.fpd30) = 0 THEN 1 WHEN (period_start_1 IS NOT NULL AND period_start_2 IS NOT NULL AND period_start_3 IS NOT NULL AND period_start_4 IS NOT NULL) AND (dsp.fpd0 + dsp.fpd4 + dsp.fpd7 + dsp.fpd10 + dsp.fpd30) = 0 THEN 1 ELSE 0 END AS prolong_without_overdue
			,case
					when dateadd(dd, PDLTerm, dsp.startdate) <= cast(SYSDATETIME() as date)
						then 1
					when FactEndDate is not null 
						then 1
					else 0
				end as flg_calc
			,CASE WHEN PromoPeriodRepayment > 0 THEN 1 ELSE 0 END AS flg_promo
			,ad.productTypeCode
			,ad.clientLoanTermLength
			,ad.clientLoanDaysLength
			,CASE WHEN ad.clientLoanDaysLength <= 7 THEN '<= 7' WHEN ad.clientLoanDaysLength > 7 AND ad.clientLoanDaysLength <= 14 THEN '(7; 14]' WHEN ad.clientLoanDaysLength > 14 AND ad.clientLoanDaysLength <= 21 THEN '(14; 21]' WHEN ad.clientLoanDaysLength > 21 AND ad.clientLoanDaysLength <= 30 THEN '(21; 30]' ELSE 'INST' END AS group_lenght_day
			,ad.Request_amount
			,ad.Income_amount
			,ad.Years
			,CASE WHEN ad.Request_amount <= 10000 THEN '(0; 10000]' WHEN ad.Request_amount > 10000 AND ad.Request_amount <= 20000 THEN '(10000; 20000]' WHEN ad.Request_amount > 20000 AND ad.Request_amount <= 30000 THEN '(20000; 30000]' WHEN ad.Request_amount > 30000 AND ad.Request_amount <= 50000 THEN '(30000; 50000]' WHEN ad.Request_amount > 50000 AND ad.Request_amount <= 100000 THEN '(50000; 100000]' WHEN ad.Request_amount > 100000 THEN '(100000; inf]' ELSE 'error' END AS group_request_amount
			,dsp.fpd0 * CR_amount AS sum_fpd0
			,dsp.fpd4 * CR_amount AS sum_fpd4
			,dsp.fpd7 * CR_amount AS sum_fpd7
			,dsp.fpd10 * CR_amount AS sum_fpd10
			,dsp.fpd15 * CR_amount AS sum_fpd15
			,dsp.fpd30 * CR_amount AS sum_fpd30
			,isnull(fsp.flg_statement_without_prolong,0) as flg_statement_without_prolong
			,cast(concat(FORMAT(dsp.generation, 'MMM'), char(39), FORMAT(dsp.generation, 'yy')) AS VARCHAR) AS generation_char
			,cast(FORMAT(dsp.generation, 'yyyy') AS INT) AS generation_year
			,case when dsp.factenddate IS NOT NULL and t_o.without_overdue = 1 AND dsp.factenddate IS NOT NULL AND dsp.period_start_1 IS NULL and flg_statement_without_prolong=1 then 1 else 0 end as flag_closed_wo_overdue_and_prolongation
			,CASE WHEN (period_start_1 IS NOT NULL AND period_start_2 IS NULL) AND (fpd0 + fpd4 + fpd7 + fpd10 + fpd30) > 0 THEN 1 
						WHEN (period_start_1 IS NOT NULL AND period_start_2 IS NOT NULL AND period_start_3 IS NULL) AND (fpd0 + fpd4 + fpd7 + fpd10 + fpd30) > 0 THEN 1 
						WHEN (period_start_1 IS NOT NULL AND period_start_2 IS NOT NULL AND period_start_3 IS NOT NULL AND period_start_4 IS NULL) AND (fpd0 + fpd4 + fpd7 + fpd10 + fpd30) > 0 THEN 1 
						WHEN (period_start_1 IS NOT NULL AND period_start_2 IS NOT NULL AND period_start_3 IS NOT NULL AND period_start_4 IS NOT NULL) AND (fpd0 + fpd4 + fpd7 + fpd10 + fpd30) > 0 THEN 1 ELSE 0 END as flag_prolongation_with_overdue
			,getdate() as dt_dml
			--INTO risk.repbi_pdl_repeated_vint
		FROM #data_set_prolong dsp
		LEFT JOIN #Auto_Approve aa ON dsp.external_id = aa.Number AND aa.rn = 1
		LEFT JOIN #without_overdue t_o ON dsp.external_id = t_o.external_id
		LEFT JOIN #app_data AS ad ON dsp.external_id = ad.Number AND ad.rn_for_drop = 1
		LEFT JOIN #flg_statement_prolongation fsp ON dsp.external_id = fsp.number
			WHERE DSP.generation>='2023-12-01';

	    DELETE FROM risk.repbi_pdl_repeated_vint where flg_calc<>1;

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
