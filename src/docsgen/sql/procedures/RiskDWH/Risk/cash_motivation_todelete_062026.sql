CREATE PROCEDURE [Risk].[cash_motivation]
AS
BEGIN
DECLARE @msg NVARCHAR(255),
@subject NVARCHAR(255)
BEGIN TRY
exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'Cash_motivation - START';
DROP TABLE IF EXISTS #cash_motivation_0_360

	SELECT DISTINCT t.*
		,CASE 
			WHEN t.claimant_fio IN ('Булганин Николай Викторович', 'Лебедев Александр Дмитриевич', 'Макаров Виталий Александрович', 'Самородов Василий Васильевич')
				THEN 'SOFT'
			WHEN t.claimant_fio IS NULL
				AND CRMClientStage IN ('Soft', 'Middle')
				AND m1.manager IN ('ЧЕЙШВИЛИ ЕЛЕНА ВЛАДИМИРОВНА', 'Алехина Виктория Анатольевна', 'Полянцева Анастасия Сергеевна', 'Чувилева Ирина Николаевна', 'Алехина Офелия Сосовна', 'Комардина Татьяна Михайловна', 'Зайцева Фаина Николаевна')
				THEN 'SOFT'
			WHEN m1.manager IN ('ЧЕЙШВИЛИ ЕЛЕНА ВЛАДИМИРОВНА')
				AND CRMClientStage = 'Legal'
				THEN 'SOFT'
			ELSE 'HARD'
			END AS stage
		,CASE 
			WHEN k.[номер договора] IS NOT NULL
				THEN 1
			ELSE 0
			END AS freeze_flag
		,CASE 
			WHEN x.external_id IS NOT NULL
				THEN 1
			ELSE 0
			END AS FSSP_flag
		,x.agent_name AS FSSP_agent_name
		,CASE 
			WHEN z.external_id IS NOT NULL
				THEN 1
			ELSE 0
			END AS IspHard_flag
		,z.stage2 AS IspHard_type
		,m1.manager
	INTO #cash_motivation_0_360

	FROM reports.[Risk].[dm_ReportCollectionPlanMFOCred] t (nolock)
	LEFT JOIN devDB.dbo.say_log_dogovora_kk k ON t.external_id = k.[номер договора]
		AND cast(k.[дата время состовления отчёта] AS DATE) = cast(getdate() AS DATE)
	LEFT JOIN (
		--x
		SELECT a.r_date
			,a.dpd_bucket_from
			,a.external_id
			,a.agent_name
			,a.pay_total
		FROM Reports.Risk.dm_ReportCollectionPlanFSSPPmt a (nolock)
		WHERE a.rep_dt = dateadd(dd, - 1, cast(getdate() AS DATE))
			AND a.seg = 'CM'
			AND a.product = 'PTS'
		) x ON t.external_id = x.external_id
		AND t.r_date = x.r_date
	LEFT JOIN (
		--z
		SELECT a.external_id
			,a.r_year
			,a.r_month
			,a.r_day
			,a.dpd_bucket_cmr
			,a.stage
			,a.agent_name
			,a.pay_total
			,a.stage2
			,a.fio
		FROM Reports.Risk.dm_ReportCollectionPlanIspHard a (nolock)
		WHERE a.rep_dt = dateadd(dd, - 1, cast(getdate() AS DATE))
			AND a.product = 'PTS' --and a.external_id='19081100000112'
		) z ON t.external_id = z.external_id
		AND z.r_day = DATEPART(day, t.r_date)
	LEFT JOIN (
		--m1
		SELECT m.*
		FROM (
			--m
			SELECT t.CommunicationDateTime
				,t.number
				,t.manager
				,ROW_NUMBER() OVER (
					PARTITION BY t.number ORDER BY t.CommunicationDate DESC
					) rn
			FROM stg.[_Collection].[mv_Communications] t (nolock)
			WHERE 1 = 1
				--and  t.Number='22042100350788'
				AND t.CommunicationDate >= cast('2022-10-01' AS DATE)
				AND t.manager <> 'Система'
			) m
		WHERE m.rn = 1
		) m1 ON t.external_id = m1.number
	WHERE t.dpd_bucket_from IN ('[09] 0-90 hard', '(5)_91_360', '(6)_361+')
		AND t.rep_dt = cast(getdate() - 1 AS DATE);

-------------------------------
DROP TABLE IF EXISTS #base_lost_claimant_id;
	SELECT ObjectId
		,coalesce(NewValue, 0) ClaimantId
		,dt_rt dt_st
	INTO #base_lost_claimant_id
	FROM (
		SELECT [ChangeDate]
			,cast([ChangeDate] AS DATE) dt_rt
			,[OldValue]
			,[NewValue]
			,[ObjectId]
			,ROW_NUMBER() OVER (
				PARTITION BY [ObjectId] ORDER BY [ChangeDate] DESC
				) rn
		FROM [Stg].[_Collection].[CustomerHistory] (nolock)
		WHERE 1 = 1
			AND field = 'Ответственный взыскатель'
		) aaa
	WHERE 1 = 1
		AND rn = 1;

DROP TABLE IF EXISTS #cash_motivation

	SELECT a.external_id
		,a.d
		,a.bucket_p_coll
		,isnull(cast(isnull(principal_cnl,    0) as float) +
				cast(isnull(percents_cnl,     0) as float) +
				cast(isnull(fines_cnl,        0) as float) +
				cast(isnull(otherpayments_cnl,0) as float) +
				cast(isnull(overpayments_cnl, 0) as float) - 
				cast(isnull(overpayments_acc, 0) as float), 0) as pay_total
		,CASE 
			WHEN fr.[номер договора] IS NULL
				THEN 0
			ELSE 1
			END AS freeze_flag
		,fr.fio_claimant
	INTO #cash_motivation

	FROM dwh2.dbo.dm_cmrstatbalance a (nolock)
	LEFT JOIN (
		--fr
		SELECT t.[номер договора]
			,t.[стадия договора]
			,t.[бакет просрочки]
			,CASE 
				WHEN b.external_id IS NULL
					THEN 0
				ELSE 1
				END AS ag_flag
			,b.agent_name
			,b.fact_end_date
			,t.principal_rest
			,e.LastName + ' ' + e.FirstName + ' ' + e.MiddleName fio_claimant
		FROM [devDB].[dbo].[say_log_dogovora_kk] t
		LEFT JOIN dwh_new.dbo.agent_credits b (nolock) ON t.[Номер договора] = b.external_id
			AND b.fact_end_date IS NULL
		JOIN stg._Collection.Deals d ON d.number = t.[номер договора]
		JOIN stg._collection.customers c ON c.id = d.idcustomer
		LEFT JOIN #base_lost_claimant_id blc ON blc.ObjectId = d.idcustomer
		LEFT JOIN stg._collection.Employee e ON blc.claimantid = e.id
		WHERE cast(t.[дата время состовления отчёта] AS DATE) = cast(getdate() AS DATE)
			AND t.[стадия договора] NOT IN ('Closed', 'Current', 'Predelinquency')
		) fr ON a.external_id = fr.[номер договора]
	WHERE a.d BETWEEN '2022-10-01'
			AND cast(getdate() AS DATE)
		AND (cast(isnull(principal_cnl,    0) as float) +
    		cast(isnull(percents_cnl,     0) as float) +
    		cast(isnull(fines_cnl,        0) as float) +
    		cast(isnull(otherpayments_cnl,0) as float) +
    		cast(isnull(overpayments_cnl, 0) as float) - 
			cast(isnull(overpayments_acc, 0) as float) > 0);

------------------------------
DROP TABLE IF EXISTS #cash_motivation2

	SELECT a.r_date
		,a.dpd_bucket_from
		,fr.fio_claimant AS fio_claimant_freeze
		,a.claimant_fio
		,CASE 
			WHEN fr.[номер договора] IS NULL
				THEN 0
			ELSE 1
			END AS freeze_flag
		,sum(a.pay_total) AS pay_total
	INTO #cash_motivation2

	FROM Reports.Risk.dm_ReportCollectionPlanMFOCred a (nolock)
	LEFT JOIN (
		--fr
		SELECT t.[номер договора]
			,t.[стадия договора]
			,t.[бакет просрочки]
			,CASE 
				WHEN b.external_id IS NULL
					THEN 0
				ELSE 1
				END AS ag_flag
			,b.agent_name
			,b.fact_end_date
			,t.principal_rest
			,e.LastName + ' ' + e.FirstName + ' ' + e.MiddleName fio_claimant
		FROM [devDB].[dbo].[say_log_dogovora_kk] t (nolock)
		LEFT JOIN dwh_new.dbo.agent_credits b ON t.[Номер договора] = b.external_id
			AND b.fact_end_date IS NULL
		JOIN stg._Collection.Deals d ON d.number = t.[номер договора]
		JOIN stg._collection.customers c ON c.id = d.idcustomer
		LEFT JOIN #base_lost_claimant_id blc ON blc.ObjectId = d.idcustomer
		LEFT JOIN stg._collection.Employee e ON blc.claimantid = e.id
		WHERE cast(t.[дата время состовления отчёта] AS DATE) = cast(getdate() AS DATE)
			AND t.[стадия договора] NOT IN ('Closed', 'Current', 'Predelinquency')
		) fr ON a.external_id = fr.[номер договора]
	WHERE a.rep_dt = cast(dateadd(dd, - 1, sysdatetime()) AS DATE)
		AND a.product = 'PTS'
		AND a.dpd_bucket_from IN ('[09] 0-90 hard', '(2)_1_30', '(3)_31_60', '(4)_61_90', '(5)_91_360')
	GROUP BY a.r_date
		,a.dpd_bucket_from
		,fr.fio_claimant
		,a.claimant_fio
		,CASE 
			WHEN fr.[номер договора] IS NULL
				THEN 0
			ELSE 1
			END;

/*if OBJECT_ID('riskdwh.[cm\o.postnov].cash_motivation_0_360') is null
begin
	select  top(0) * into riskdwh.[cm\o.postnov].cash_motivation_0_360
	from #cash_motivation_0_360
end;*/

if OBJECT_ID('riskdwh.[cm\o.postnov].cash_motivation') is null
begin
	select  top(0) * into riskdwh.[cm\o.postnov].cash_motivation
	from #cash_motivation
end;

if OBJECT_ID('riskdwh.[cm\o.postnov].cash_motivation2') is null
begin
	select  top(0) * into riskdwh.[cm\o.postnov].cash_motivation2
	from #cash_motivation2
end;

BEGIN TRANSACTION
		truncate table riskdwh.[cm\o.postnov].cash_motivation;
		INSERT INTO riskdwh.[cm\o.postnov].cash_motivation
		SELECT * FROM #cash_motivation;

		truncate table riskdwh.[cm\o.postnov].cash_motivation2;
		INSERT INTO riskdwh.[cm\o.postnov].cash_motivation2
		SELECT * FROM #cash_motivation2;

		--truncate table riskdwh.[cm\o.postnov].cash_motivation_0_360;
		INSERT INTO riskdwh.[cm\o.postnov].cash_motivation_0_360
		SELECT * FROM #cash_motivation_0_360;

COMMIT TRANSACTION;

drop table #cash_motivation;
drop table #cash_motivation2;
drop table #cash_motivation_0_360;
drop table #base_lost_claimant_id;

exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'Cash_motivation - FINISH';
END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
		exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'Cash_motivation - ERROR';
		SET @msg = 'Ошибка выполнение процедуры cash_motivation'

		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'ala.kurikalov@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;
		throw 51000
			,@msg
			,1
	END CATCH
END;
