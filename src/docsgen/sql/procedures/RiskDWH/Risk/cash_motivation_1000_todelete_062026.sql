CREATE PROCEDURE [Risk].[cash_motivation_1000]
as 
begin

declare @mydate date;
set @mydate = 
case when day(GETDATE()) = 1 then DATEFROMPARTS(YEAR(DATEADD(m, -1, GETDATE()) ), MONTH(DATEADD(m, -1, GETDATE()) ), 1) 
else DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) end;
DECLARE @msg NVARCHAR(255),
@subject NVARCHAR(255)

BEGIN TRY
exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'Cash_motivation_1000 - START';
-- список всех договоров ever на сегодня  
-- разбивка на producttype and productsegment
drop table if exists #alldocs;
with producttype as (
select distinct
    a.Код as external_id,
	case when upper(cmr_ПодтипыПродуктов.Наименование) like '%PDL%' THEN 'PDL'
	when upper(cmr_ПодтипыПродуктов.Наименование) like '%INSTALLMENT%' then 'INST'
	else 'PTS' end product,

	case when t.segment_code='trialperiod' then 'TrialPeriod'
	when t.probation=1 then 'PTS31'
	else 'n/a' end as productsegment

	from stg._1cCMR.Справочник_Договоры a
	LEFT JOIN Stg._1cCMR.Справочник_Заявка cmr_Заявка ON cmr_Заявка.Ссылка = a.Заявка
	LEFT JOIN stg._1cCMR.Справочник_ПодтипыПродуктов cmr_ПодтипыПродуктов ON cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка 
	Left Join dwh2.[dm].[Collection_StrategyDataMart] t (nolock) on a.Код=t.external_id
	where t.StrategyDate=cast(getdate() as date)
),
base as (
select 
t.strategydate,
t.fio,
t.CRMClientGUID,                          
t.external_id,
a.product as producttype,
a.productsegment as productsegment

from dwh2.[dm].[Collection_StrategyDataMart] t (nolock)
left join producttype a on a.external_id=t.external_id
where t.StrategyDate=cast(getdate() as date)

)
select * 
into #alldocs
from base a
;

---Безнадёжное взыскание подтвержден
--- с createdate до нвр.

drop table if exists #beznadega;

select 
t.customerid,
t.customerstateid,
cast(t.createdate as date) as createdate,
tt.number,
CASE WHEN t.customerstateid=22  THEN 'Безнадёжное взыскание подтверждено '	ELSE 'other' END AS beznadega,
ROW_NUMBER() over (partition by t.[CustomerId] order by t.createdate) rn

into #beznadega
from [Stg].[_Collection].[CustomerStatus] t
left join stg._collection.deals tt on t.customerid=tt.IdCustomer
where t.CustomerStateId=22
;
--- данные по договору из CMR и витрины \ ClaimanStage \ cash total and by day

DROP TABLE IF EXISTS #dm_CMRStatBalance;
	
	SELECT *
	INTO #dm_CMRStatBalance 
	FROM [dwh2].[dbo].[dm_CMRStatBalance] a (nolock)
	WHERE a.d >= @mydate;

CREATE INDEX #dm_CMRStatBalance ON #dm_CMRStatBalance (
	external_id
	,d
	);

DROP TABLE IF EXISTS #Collection_External_Stage_history;
	SELECT c.*
		,cast(call_date AS DATE) AS call_date_dt
	INTO #Collection_External_Stage_history
	FROM [Stg].[_loginom].[Collection_External_Stage_history] c (nolock)
	WHERE cast(c.call_date AS DATE) >= @mydate;

CREATE INDEX #Collection_External_Stage_history_idx ON #Collection_External_Stage_history (
	external_id
	,call_date_dt
	);


drop table if exists #cmr

select distinct b.StrategyDate,
eomonth(cast(a.d as date)) as reportmonth,
a.external_id,
b.fio,
a.CMRClientGUID,
a.d as r_date,
a.r_year,
a.r_month,
a.r_day,
isnull(a.dpd_coll,0) as dpd_end,
RiskDWH.dbo.get_bucket_end_motiv(a.dpd_coll) as bucket_end, --Функция для определения бакета 
/*case 
when isnull(a.dpd_coll,0) > 2000 then '9.[2000+]'
when isnull(a.dpd_coll,0) > 1500 then '8.[1501-2000]'
when isnull(a.dpd_coll,0) > 1000 then '7.[1001-1500]'
when isnull(a.dpd_coll,0) > 360 then '6.[361-1000]'
when isnull(a.dpd_coll,0) > 90 then '5.[91-360]'
when isnull(a.dpd_coll,0) > 60 then '4.[61-90]'
when isnull(a.dpd_coll,0)> 30 then '3.[31-60]'
when isnull(a.dpd_coll,0) > 0 then '2.[1-30]'
else '1.[0]' end as bucket_end,*/
isnull(a.dpd_p_coll,0) as dpd_start, -- на начало дня 
RiskDWH.dbo.get_bucket_end_motiv(a.dpd_p_coll) as bucket_start, --Функция для определения бакета 
/*case 
when isnull(a.dpd_p_coll,0) > 2000 then '9.[2000+]'
when isnull(a.dpd_p_coll,0) > 1500 then '8.[1501-2000]'
when isnull(a.dpd_p_coll,0) > 1000 then '7.[1001-1500]'
when isnull(a.dpd_p_coll,0) > 360 then '6.[361-1000]'
when isnull(a.dpd_p_coll,0) > 90 then '5.[91-360]'
when isnull(a.dpd_p_coll,0) > 60 then '4.[61-90]'
when isnull(a.dpd_p_coll,0)> 30 then '3.[31-60]'
when isnull(a.dpd_p_coll,0) > 0 then '2.[1-30]'
else '1.[0]' end as bucket_start,*/
isnull(c.External_Stage,e.External_Stage) as External_Stage, -- добавлена проверка если нет значений , то берется на пред день
isnull(c.ClaimantStage,e.ClaimantStage) as ClaimantStage, -- добавлена проверка если нет значений , то берется на пред день
b.producttype,
b.productsegment,
cast(isnull(a.сумма,0) as float) as amount,
cast(isnull(a.[остаток од],0) as float) as principal_rest,
cast(isnull(a.[остаток %],0) as float) as percents_rest,
cast(isnull(a.[остаток пени],0) as float) as others_rest,
cast(isnull(a.[остаток од],0) as float) + cast(isnull(a.[остаток %],0) as float) + cast(isnull(a.[остаток пени],0) as float) as gross_rest,
cast(isnull(a.overdue,0) as float) as overdue, 
cast(isnull(a.[сумма поступлений  нарастающим итогом],0) as float) as all_cash_in,
cast(isnull(a.principal_cnl,    0) as float) +
cast(isnull(a.percents_cnl,     0) as float) +
cast(isnull(a.fines_cnl,        0) as float) +
cast(isnull(a.otherpayments_cnl,0) as float) +
cast(isnull(a.overpayments_cnl, 0) as float) - cast(isnull(a.overpayments_acc, 0) as float) as pay_total,
isnull(d.isactive,0) as isactive,
isnull(d.agent_flag,0)as agent_flag,
isnull(d.bankrupt,0) as bankrupt,  --'Банкрот подтверждённый','Банкрот неподтверждённый')
isnull(d.BankruptConfirmed,0) as BankruptConfirmed,
isnull(d.BankruptUnconfirmed,0) as BankruptUnconfirmed,
isnull(d.BankruptCompleted,0) as bankruptcompleted, -- 'Банкротство завершено'
isnull(d.death_flag,0) as death_flag,
isnull(d.HardFraud,0) as HardFraud,
isnull(d.Active_PTP,0) as Active_PTP,
isnull(d.Litigation_fl,0) as Litigation_fl,
isnull(kk.operation_type,0) as KK_operation_type,
CASE WHEN t.external_id IS NULL	THEN 0 ELSE 1 END AS ag_flag,
t.agent_name as ag_agentname,
CASE WHEN k.[номер договора] IS NOT NULL THEN 1	ELSE 0 END AS freeze_flag,
CASE WHEN x.external_id IS NOT NULL	THEN 1 ELSE 0 END AS FSSP_flag,
CASE WHEN z.external_id IS NOT NULL	THEN 1 ELSE 0 END AS IspHard_flag,
z.stage as isp_stage, 
z.stage2 as isp_stage2,
z.agent_name as isp_agent_name,
cl.claimant_fio,
bv.beznadega

into #cmr
from #dm_CMRStatBalance a (nolock)
inner join #alldocs b on a.external_id=b.external_id
left join #Collection_External_Stage_history c (nolock) on a.external_id=c.external_id and cast(a.d as date)=cast(c.call_date as date)
left join dwh2.[dm].[Collection_StrategyDataMart] d (nolock) on a.external_id=d.external_id and cast(a.d as date)=cast(d.StrategyDate as date)
left join #Collection_External_Stage_history e (nolock) on a.external_id=e.external_id and cast(a.d as date)=cast(e.call_date+1 as date)
left join dwh2.dbo.dm_restructurings kk (nolock) on a.external_id=kk.number and a.d between kk.period_start and isnull(kk.period_end,'2999-01-01') and kk.operation_type in ('Кредитные каникулы','Заморозка 1.0')
left join #beznadega bv (nolock) on a.external_id=bv.number and a.d >  bv.createdate 
left join dwh_new.dbo.agent_credits t (nolock) ON a.external_id = t.external_id AND cast(a.d as date) between t.st_date and isnull(t.fact_end_date,'2999-01-01')
left join Reports.Risk.dm_ReportCollectionPlanFSSPPmt x (nolock) on  a.external_id = x.external_id AND cast(a.d as date) = cast(x.r_date as date)
left join Reports.Risk.dm_ReportCollectionPlanIspHard z (nolock) on  a.external_id = z.external_id AND cast(a.d as date) = cast (dateadd(dd, - 1, z.rep_dt) as date)
LEFT JOIN devDB.dbo.say_log_dogovora_kk k (nolock) ON a.external_id = k.[номер договора]	AND cast(k.[дата время состовления отчёта] AS DATE) = cast(a.d as date)
LEFT JOIN reports.[Risk].[dm_ReportCollectionPlanMFOCred] cl (nolock) on  a.external_id = cl.external_id AND cast(a.d as date) = cast(cl.r_date as date) 
;

if OBJECT_ID('RiskDWH.[CM\D.Timin].[call_motiv_01_2024]') is null
begin
	select  top(0) * into RiskDWH.[CM\D.Timin].[call_motiv_01_2024]
	from #cmr
end;

BEGIN TRANSACTION
		--truncate table RiskDWH.[CM\D.Timin].[call_motiv_01_2024];
		INSERT INTO RiskDWH.[CM\D.Timin].[call_motiv_01_2024]
		SELECT * FROM #cmr
		where pay_total >0;
COMMIT TRANSACTION;

drop table #cmr;
drop table #alldocs;
drop table #beznadega;
drop table #dm_CMRStatBalance;
drop table #Collection_External_Stage_history;

exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'Cash_motivation_1000 - FINISH';
END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
		exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'Cash_motivation_1000 - ERROR';
		SET @msg = 'Ошибка выполнение процедуры cash_motivation_1000'

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