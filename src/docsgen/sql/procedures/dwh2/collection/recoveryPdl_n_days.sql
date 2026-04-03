-- exec collection.recoveryPdl_n_days 7
CREATE   PROCEDURE collection.recoveryPdl_n_days
	@num_days INT
AS
BEGIN
	WITH CTE_OverdueInstances AS (
		SELECT
			external_id [номер договора],
			[d] AS overdue_date,
			[остаток од] AS debt_amount,
			LAG([dpd], 1, 0) OVER (PARTITION BY [external_id] ORDER BY [d]) AS prev_overdue_days,
			[dpd_begin_day][количество дней просрочки]
		FROM
		   dwh2.dbo.dm_cmrstatbalance 
		   where [Тип Продукта]='PDL'
	),
	CTE_kk as (


	SELECT 
		  [number]
		 ,[period_start]
		  --,dat =dateadd(dd,1, EOMONTH([period_start], -1))
  
		  ,[reason_credit_vacation]
     
	  FROM [dwh2].[dbo].[dm_restructurings]
	  where operation_type='Реструктуризация' and reason_credit_vacation ='Пролонгация PDL' 
	),



	CTE_InitialOverdue AS (
		SELECT
			[номер договора],
			overdue_date AS first_overdue_date,
			debt_amount AS initial_debt_amount
		FROM
			CTE_OverdueInstances od left join CTE_kk kk on od.[номер договора]=kk.[number] and kk.period_start between od.overdue_date and  DATEADD(day, 10, od.overdue_date)--kk.dat=dateadd(dd,1, EOMONTH([overdue_date], -1))
		WHERE
			prev_overdue_days = 0 AND [количество дней просрочки] > 0 and kk.[number] is null
	),
	CTE_ReceiptsDuringOverdue AS (
		SELECT 
			io.[номер договора],
			io.first_overdue_date,
			io.initial_debt_amount,
			yt.[d] AS receipt_date,
			yt.[сумма поступлений],
			yt.[dpd] AS days_overdue_on_receipt,
			LAG(yt.[dpd], 1, 0) OVER (PARTITION BY yt.[external_id] ORDER BY yt.[d]) AS prev_days_overdue
			,yt.[dpd_begin_day]
		FROM 
			CTE_InitialOverdue io
		JOIN 
			dwh2.dbo.dm_cmrstatbalance yt ON io.[номер договора] = yt.[external_id]
		WHERE 
			yt.[d] BETWEEN io.first_overdue_date AND DATEADD(day, @num_days, io.first_overdue_date) and yt.[Тип Продукта]='PDL'
	),
	CTE_FilteredReceipts AS (
		SELECT
			[номер договора],
			first_overdue_date,
			initial_debt_amount,
			receipt_date,
			[сумма поступлений],
			days_overdue_on_receipt
			,[dpd_begin_day]
		FROM
			CTE_ReceiptsDuringOverdue
		WHERE
		  [dpd_begin_day]>0 -- prev_days_overdue > 0
	),

	CTE_Grouped_od AS (
	  SELECT
		   -- [номер договора],
		   DATENAME(month, io.first_overdue_date) AS entry_month,
			DATEPART(year, io.first_overdue_date) AS entry_year,
      
			sum(initial_debt_amount) AS total_initial_debt
		FROM CTE_InitialOverdue io
		group by    DATENAME(month, io.first_overdue_date),
					DATEPART(year, io.first_overdue_date) 
	),

	CTE_Grouped_sum AS (
		SELECT
			DATENAME(month, io.first_overdue_date) AS entry_month,
			DATEPART(year, io.first_overdue_date) AS entry_year,
		   -- sum(io.initial_debt_amount) AS total_initial_debt,
			SUM(fr.[сумма поступлений]) AS total_receipts
		FROM
			CTE_InitialOverdue io
		LEFT JOIN 
			CTE_FilteredReceipts fr ON io.[номер договора] = fr.[номер договора] AND io.first_overdue_date = fr.first_overdue_date
		GROUP BY
			DATENAME(month, io.first_overdue_date),
			DATEPART(year, io.first_overdue_date)
		
	),

	CTE_Grouped AS (

	select 
	   od.entry_month,
	   od.entry_year,
	   total_initial_debt,
	   total_receipts
	from 
		CTE_Grouped_od  od
		left join  
		CTE_Grouped_sum sm on  od.entry_year = sm.entry_year and od.entry_month = sm.entry_month
	)

	SELECT
	 entry_year,
		entry_month,
	   dpd=@num_days,
		total_initial_debt,
		total_receipts,
		(CAST(total_receipts AS FLOAT) / total_initial_debt)*100 AS receipt_ratio
	FROM
		CTE_Grouped
	ORDER BY
		entry_year,
		entry_month;
END;
