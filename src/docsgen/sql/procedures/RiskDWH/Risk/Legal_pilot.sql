CREATE PROCEDURE [Risk].[Legal_pilot]
AS
BEGIN
DECLARE @msg NVARCHAR(255),
@subject NVARCHAR(255)
BEGIN TRY
exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'Legal_pilot - START';

drop table if exists #pilot_inst;
with src as (
SELECT DISTINCT d.number as external_id
,cast(d.Date as date) as startdate
,case when d.Date<'2022-11-01' then 'INST-OLD' else 'INST-NEW' end as Inst_Type
,cast(jp.SubmissionClaimDate AS DATE) AS [Дата отправки требования]
,cast(jc.CourtClaimSendingDate AS DATE) AS [Дата отправки иска в суд]
,cast(jc.JudgmentDate AS DATE) AS [Дата судебного решения]
--,cast(eo.ReceiptDate AS DATE) AS [Дата получения ИЛ]
,case when eo.Number is not null then coalesce(cast(eo.ReceiptDate AS DATE), cast(epe.ExcitationDate AS DATE)) else null 
	end [Дата получения ИЛ]
,cast(jc.ReceiptOfJudgmentDate AS DATE) AS [Дата получения решения суд]
,cast(jc.AdoptionProductionDate AS DATE) AS [Дата принятия к производству]
,cast(epe.ExcitationDate AS DATE) AS [Дата возбуждения ИП]
,ROW_NUMBER() over (partition by jp.DealId order by epe.ExcitationDate desc) rn
,jp.DealId
,d.installment
FROM stg._Collection.deals d
inner JOIN stg._Collection.JudicialProceeding jp ON d.id = jp.DealId
AND jp.isfake <> 1
LEFT JOIN Stg._Collection.JudicialClaims jc ON jp.id = jc.JudicialProceedingId
LEFT JOIN Stg._Collection.EnforcementOrders eo ON jc.id = eo.JudicialClaimId
LEFT JOIN Stg._Collection.EnforcementProceeding ep ON eo.id = ep.EnforcementOrderId
LEFT JOIN Stg._Collection.EnforcementProceedingExcitation epe ON epe.EnforcementProceedingId = ep.id
where 1=1
--d.installment=1
and jp.SubmissionClaimDate is not Null
)
select * into #pilot_inst 
from src 
where rn=1;

-- данные по платежам 
drop table if exists #CMR_inst;
select 
t.external_id as external_id1,
a.d, a.external_id,
a.prev_dpd_coll, 
cast(isnull([остаток од],   0) as float) as principal_rest,
cast(isnull([остаток од],   0) as float) +
cast(isnull([остаток %],    0) as float) as principal_percents_rest,
case 
when cast(isnull(principal_cnl,    0) as float) +
cast(isnull(percents_cnl,     0) as float) +
cast(isnull(fines_cnl,        0) as float) +
cast(isnull(otherpayments_cnl,0) as float) +
cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float)
< isnull([сумма поступлений], 0) then isnull([сумма поступлений], 0)
else cast(isnull(principal_cnl,    0) as float) +
cast(isnull(percents_cnl,     0) as float) +
cast(isnull(fines_cnl,        0) as float) +
cast(isnull(otherpayments_cnl,0) as float) +
cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) end
 as pay_total,
isnull([сумма поступлений], 0) as pay_total_calc,

case when  a.d between t.[Дата отправки требования] and cast (isnull(t.[Дата получения ИЛ],'9999-01-01') as date) 
then 
	case 
	when (cast(isnull(principal_cnl,    0) as float) +
cast(isnull(percents_cnl,     0) as float) +
cast(isnull(fines_cnl,        0) as float) +
cast(isnull(otherpayments_cnl,0) as float) +
cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float))
< isnull([сумма поступлений], 0) then isnull([сумма поступлений], 0)
else cast(isnull(principal_cnl,    0) as float) +
cast(isnull(percents_cnl,     0) as float) +
cast(isnull(fines_cnl,        0) as float) +
cast(isnull(otherpayments_cnl,0) as float) +
cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) end
else 0 end as cashbeforeIL,

case when  a.d >cast (isnull(t.[Дата получения ИЛ],'9999-01-01') as date) then 
	case 
	when (cast(isnull(principal_cnl,    0) as float) +
cast(isnull(percents_cnl,     0) as float) +
cast(isnull(fines_cnl,        0) as float) +
cast(isnull(otherpayments_cnl,0) as float) +
cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float))
< isnull([сумма поступлений], 0) then isnull([сумма поступлений], 0)
else cast(isnull(principal_cnl,    0) as float) +
cast(isnull(percents_cnl,     0) as float) +
cast(isnull(fines_cnl,        0) as float) +
cast(isnull(otherpayments_cnl,0) as float) +
cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) end
else 0 end as cashafterIL
,t.installment
into #CMR_inst
from #pilot_inst t
left join dwh2.dbo.dm_CMRStatBalance a on a.external_id=t.external_id
where a.d >= cast (isnull(t.[Дата отправки требования],'9999-01-01') as date)
;


--- общий итог \ 
drop table if exists #db1;
select distinct
a.external_id,
eomonth(a.startdate) as monthofissue,
a.startdate,
a.Inst_Type,

COALESCE(CONVERT(VARCHAR,a.[Дата отправки требования], 23), '') as [Дата отправки требования],
COALESCE(CONVERT(VARCHAR,a.[Дата отправки иска в суд], 23), '') as [Дата отправки иска в суд],
COALESCE(CONVERT(VARCHAR,a.[Дата судебного решения], 23), '') as [Дата судебного решения],
COALESCE(CONVERT(VARCHAR,a.[Дата получения ИЛ], 23), '') as [Дата получения ИЛ],
COALESCE(CONVERT(VARCHAR,a.[Дата получения решения суд], 23), '') as [Дата получения решения суд],
COALESCE(CONVERT(VARCHAR,a.[Дата принятия к производству], 23),'') as [Дата принятия к производству],
COALESCE(CONVERT(VARCHAR,a.[Дата возбуждения ИП], 23), '') as [Дата возбуждения ИП],

avg(c.principal_percents_rest) as principal_percents_rest,
sum(isnull(b.pay_total,0)) as pay_total,
sum(isnull(b.cashbeforeIL,0)) as cashbeforeIL,
sum(isnull(b.cashafterIL,0)) as cashafterIL,
COALESCE(m.collectionStage, '') as collectionStage,
COALESCE(m.bankrupt, '') as bankrupt
,a.installment
INTO #db1
from #pilot_inst a
left join #CMR_inst c on a.external_id=c.external_id and cast(c.d as date)= cast( a.[Дата отправки требования] as date)
left join #CMR_inst b on a.external_id=b.external_id 
left join dwh2.[dm].[Collection_StrategyDataMart] m on m.external_id=c.external_id 
and m.StrategyDate = cast(getdate() as date)
group by 
a.external_id,
a.startdate,
a.Inst_Type,
a.[Дата отправки требования],
a.[Дата отправки иска в суд],
a.[Дата судебного решения],
a.[Дата получения ИЛ],
a.[Дата получения решения суд],
a.[Дата принятия к производству],
a.[Дата принятия к производству],
a.[Дата возбуждения ИП],
m.collectionStage,
m.bankrupt
,a.installment
order by monthofissue asc


--- разбивка по платежам
drop table if exists #db2;
select distinct
a.external_id,
eomonth(a.startdate) as monthofissue,
eomonth(a.[Дата отправки иска в суд]) as court_send,
a.Inst_Type,
b.d,
b.pay_total,
case when datediff ( day,a.[Дата отправки требования] , b.d ) between 0 and 30 then '[1]'
when datediff ( day, a.[Дата отправки требования] , b.d ) between 31 and 60 then '[2]'
when datediff ( day, a.[Дата отправки требования] , b.d  ) between 61 and 90 then '[3]'
when datediff ( day, a.[Дата отправки требования] , b.d ) between 91 and 120 then '[4]'
when datediff ( day, a.[Дата отправки требования] , b.d ) between 121 and 150 then '[5]'
when datediff ( day, a.[Дата отправки требования] , b.d ) between 151 and 180 then '[6]'
when datediff ( day, a.[Дата отправки требования] , b.d ) between 181 and 210 then '[7]'
when datediff ( day, a.[Дата отправки требования] , b.d ) between 211 and 240 then '[8]'
when datediff ( day, a.[Дата отправки требования] , b.d  ) between 241 and 270 then '[9]'
when datediff ( day, a.[Дата отправки требования] , b.d) between 271 and 300 then '[10]'
when datediff ( day, a.[Дата отправки требования] , b.d ) between 301 and 330 then '[11]'
when datediff ( day, a.[Дата отправки требования] , b.d  ) between 331 and 360 then '[12]'
when datediff ( day, a.[Дата отправки требования] , b.d ) between 361 and 390 then '[13]'
when datediff ( day, a.[Дата отправки требования] , b.d  ) between 391 and 420 then '[14]'
when datediff ( day, a.[Дата отправки требования] , b.d ) between 421 and 450 then '[15]'
when datediff ( day, a.[Дата отправки требования] , b.d ) between 451 and 480 then '[16]'
when datediff ( day, a.[Дата отправки требования] , b.d ) between 481 and 510 then '[17]'
when datediff ( day, a.[Дата отправки требования] , b.d ) between 511 and 540 then '[18]'
when datediff ( day, a.[Дата отправки требования] , b.d ) > 541 then '[19+]' end as mob1,

case when datediff ( day, cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) between 0 and 30 then '[1]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) between 31 and 60 then '[2]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d  ) between 61 and 90 then '[3]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) between 91 and 120 then '[4]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) between 121 and 150 then '[5]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) between 151 and 180 then '[6]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) between 181 and 210 then '[7]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) between 211 and 240 then '[8]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d  ) between 241 and 270 then '[9]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d) between 271 and 300 then '[10]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) between 301 and 330 then '[11]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d  ) between 331 and 360 then '[12]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) between 361 and 390 then '[13]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d  ) between 391 and 420 then '[14]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) between 421 and 450 then '[15]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) between 451 and 480 then '[16]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) between 481 and 510 then '[17]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) between 511 and 540 then '[18]'
when datediff ( day,  cast(isnull(a.[Дата отправки иска в суд],'9999-01-01') as date) , b.d ) > 541 then '[19+]' end as mob2,

case when b.d <= cast(isnull(a.[Дата получения ИЛ],'9999-01-01') as date) 
then 0 else 1 end as from_IL
,a.installment
INTO #db2
from #pilot_inst a
left join #CMR_inst b on a.external_id=b.external_id 
where b.pay_total<>0;


if OBJECT_ID('riskdwh.[cm\a.kurikalov].Legal_pilot_db1') is null
begin
	select  top(0) * into riskdwh.[cm\a.kurikalov].Legal_pilot_db1
	from #db1
end;

if OBJECT_ID('riskdwh.[cm\a.kurikalov].Legal_pilot_db2') is null
begin
	select  top(0) * into riskdwh.[cm\a.kurikalov].Legal_pilot_db2
	from #db2
end;

BEGIN TRANSACTION
		truncate table riskdwh.[cm\a.kurikalov].Legal_pilot_db1;
		INSERT INTO riskdwh.[cm\a.kurikalov].Legal_pilot_db1
		SELECT * FROM #db1;

		truncate table riskdwh.[cm\a.kurikalov].Legal_pilot_db2;
		INSERT INTO riskdwh.[cm\a.kurikalov].Legal_pilot_db2
		SELECT * FROM #db2;
COMMIT TRANSACTION;

drop table #pilot_inst;
drop table #CMR_inst;
drop table #db1;
drop table #db2;

exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'Legal_pilot - FINISH';
END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
		exec LogDb.[dbo].[SendToSlack_risk-reports-notifications] 'Legal_pilot - ERROR';
		SET @msg = 'Ошибка выполнение процедуры Legal_pilot'

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