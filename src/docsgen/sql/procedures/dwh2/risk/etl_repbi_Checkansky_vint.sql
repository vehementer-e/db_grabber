
--exec [risk].[etl_repbi_Checkansky_vint];
CREATE PROCEDURE [risk].[etl_repbi_Checkansky_vint]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		DROP TABLE

		IF EXISTS #src
			SELECT d AS r_date
				,st.r_year
				,st.r_month
				,st.r_day
				,CASE 
					WHEN day(d) = day(eomonth(d))
						THEN 1
					ELSE 0
					END AS r_max
				,st.external_id
				,cast(contractStartdate AS DATE) AS contractStartdate
				,cast([сумма] AS FLOAT) AS credit_amount
				,CASE 
					WHEN creditmonths < 0
						THEN 0
					ELSE creditmonths
					END AS miw
				,CASE 
					WHEN year(contractStartdate) = 2016
						THEN '(1)_2016'
					WHEN year(contractStartdate) = 2017
						THEN '(2)_2017'
					WHEN year(contractStartdate) = 2018 AND month(contractStartdate) <= 6
						THEN '(3)_2018_I'
					WHEN year(contractStartdate) = 2018 AND month(contractStartdate) <= 12
						THEN '(4)_2018_II'
					WHEN year(contractStartdate) = 2019 AND month(contractStartdate) <= 6
						THEN '(5)_2019_I'
					WHEN year(contractStartdate) = 2019 AND month(contractStartdate) <= 12
						THEN '(6)_2019_II'
					ELSE '(7)_2020'
					END AS vintage_all
				,CONCAT (
					year(contractStartdate)
					,' '
					,month(contractStartdate)
					) AS vintage
				,CASE 
					WHEN ContractEndDate IS NOT NULL AND ContractEndDate <= d
						THEN 1
					ELSE 0
					END AS closed
				,isnull(dpd_coll, 0) AS overdue_days
				,isnull(dpd_p_coll, 0) AS overdue_days_p
				,cast(isnull([остаток од], 0) AS FLOAT) AS principal_rest
				,cast(isnull(principal_cnl, 0) AS FLOAT) + cast(isnull(percents_cnl, 0) AS FLOAT) + cast(isnull(fines_cnl, 0) AS FLOAT) + cast(isnull(otherpayments_cnl, 0) AS FLOAT) + cast(isnull(overpayments_cnl, 0) AS FLOAT) - cast(isnull(overpayments_acc, 0) AS FLOAT) AS pay_total
			INTO #src
			FROM dbo.dm_CMRStatBalance st
			WHERE day(st.d) = day(eomonth(st.d));

		DELETE
		FROM #src
		WHERE r_date > dateadd(dd, - 1, cast(getdate() AS DATE));

		UPDATE #src
		SET principal_rest = 0
		WHERE principal_rest < 0.01 OR closed = 1;
		begin tran
		IF object_id('risk.repbi_Checkansky_vint') IS NOT NULL
			TRUNCATE TABLE risk.repbi_Checkansky_vint;

		INSERT INTO risk.repbi_Checkansky_vint
		SELECT a.miw
			,a.vintage_all
			,a.vintage
			,CASE 
				WHEN sum(a.npl_90) = 0
					THEN 0.0001
				ELSE sum(a.npl_90)
				END AS npl_90
			,sum(a.credit_amount) AS credit_amount
			,sum(pay_total) AS WO_CUMULATIVE
		FROM (
			SELECT external_id
				,miw
				,vintage_all
				,vintage
				,CASE 
					WHEN overdue_days >= 91
						THEN principal_rest
					ELSE 0
					END AS npl_90
				,credit_amount
				,pay_total
			FROM #src a
			WHERE a.miw >= 4 AND a.r_max = 1
			) a
		GROUP BY a.miw
			,a.vintage_all
			,a.vintage
		ORDER BY a.miw
			,a.vintage_all
			,a.vintage;
		commit tran
		
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
