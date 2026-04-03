CREATE PROCEDURE [riskCollection].[create_collection_datamart] as 
begin
--exec [riskCollection].[create_collection_datamart] 
declare @rdt date; 
set @rdt = 
	(
	select
	case 
		when day(getdate()) > 15 then datefromparts(year(getdate()), month(getdate()), 1)
		else datefromparts(year(getdate()), month(dateadd(mm,-1,getdate())), 1) 
		end rdt
	);
declare @msg nvarchar(255),
@subject nvarchar(255);
set @subject = 'Warning - ошибка выполнения процедуры'

declare @start_date date = '2025-02-17';
declare @end_date date = getdate();

BEGIN TRY

-------------------------------------------Данные по закреплениям по сотрудникам 
drop table if exists #last_sotr; 
---здесь подтягивается последний сотрудник на дню, из-за того что кто-то в течение дня туда-сюда переназначает договоры за сотрудниками
select
distinct(Deals.number) as external_id
,max(cchist.date) over (partition by Deals.number,cast(cchist.date as date) ) as date_from
,first_value(NewClaimantId) over (partition by Deals.number,cast(cchist.date as date) order by cchist.date desc) as ClaimantId
into #last_sotr
from stg._Collection.Deals Deals
left join stg._Collection.ClaimantCustomersHistory cchist
	on Deals.idcustomer = cchist.customerid;

drop table if exists #sotr; -- здесь вормируется "дата с" и "дата до" закрепления
select 
last_sotr.external_id 
,coalesce(cast(last_sotr.date_from as date), '1999-01-01') as date_from
,coalesce(cast(lead(dateadd(dd, -1,last_sotr.date_from)) over (partition by last_sotr.external_id order by last_sotr.date_from) as date),'2099-01-01') as date_to 
,concat_ws(' ', emp.LastName, emp.FirstName, emp.MiddleName) as claimant_fio
into #sotr
from #last_sotr last_sotr
left join stg._Collection.Employee emp
	on last_sotr.ClaimantId = emp.id
;
-------------------------------------------Данные по закреплениям по сотрудникам ИП
drop table if exists #ip_sotr;
select 
distinct(a.number) as external_id
,concat_ws(' ', ee.LastName, ee.FirstName, ee.MiddleName) as claimant_ip_fio
into #ip_sotr
from stg._Collection.Deals a
left join stg._Collection.customers b
	on a.IdCustomer = b.Id
left join stg._Collection.Employee ee
	on b.ClaimantExecutiveProceedingId = ee.Id
;
-------------------------------------------Принтяие на баланс
drop table if exists #ballance;
select 
* 
,row_number() over (partition by external_id order by AdoptionBalanceDate desc) as rn
into #ballance from
(
	----принятия на баланс в процесс ИП
	select b.number as external_id
	,cast(ep.AdoptionBalanceDate as date) as AdoptionBalanceDate
	,cast(ep.AmountDepositToBalance as float) as AmountDepositToBalance
	from stg._Collection.DealPledgeItem a
	left join stg._Collection.Deals b
		on a.DealId = b.Id
	left join stg._Collection.customers c
		on b.IdCustomer = c.id
	inner join stg._Collection.EnforcementProceedingMonitoring m
		on a.PledgeItemId = m.PledgeItemId
	inner join stg._Collection.EnforcementProceedingMonitoringImplementation ep
		on m.Id = ep.EnforcementProceedingMonitoringId
	where ep.DecisionDepositToBalance = 1

	union

	----принятия на баланс в процесс банкротства
	select
	Deals.number
	,cast(bunk.AdoptionBalanceDate as date)
	,bunk.balancevehiclecost
	from stg._Collection.CustomerBankruptcy bunk
	left join stg._Collection.customers c
		on bunk.CustomerId = c.id
	left join stg._Collection.Deals Deals
		on Deals.IdCustomer = c.id
	where bunk.AdoptionBalanceDate is not null
) t
;
-------------------------------------------Платежи от ФССП
drop table if exists #fssp_pays;
select 
Deals.Number as external_id
,cast(pays.PaymentDt as date) as PaymentDt
,sum(pays.Amount) as Amount
,pays.payer
into #fssp_pays
from stg._Collection.Payment pays
inner join stg._Collection.Deals Deals
	on pays.IdDeal = Deals.Id
where pays.Payer = 'ФССП'
and Deals.Number is not null
and pays.IsActive = 1
and cast(pays.PaymentDt as date) >= @rdt
group by Deals.Number,cast(pays.PaymentDt as date), pays.payer
;
-------------------------------------------Признак безнадежного взыскания И МЕРТВЫХ
drop table if exists #beznadega_dead;
select 
t.customerid
,t.customerstateid
,cast(t.createdate as date) as createdate
,tt.number as external_id
,case when t.customerstateid=22 then 'Безнадёжное взыскание подтверждено' else 'other' end beznadega_status
,case when t.customerstateid=3  then 1 else 0 end death_flag
,row_number() over (partition by tt.number,t.customerstateid order by t.createdate) rn
into #beznadega_dead
from Stg._Collection.CustomerStatus t
left join stg._collection.deals tt 
	on t.customerid=tt.IdCustomer
where t.CustomerStateId in (22, 3)
;
-------------------------------------------Признак банкротов
drop table if exists #Bankrupts;
select 
tt.number as external_id
,cast(ChangeDate as date) as ChangeDate
,1 as BankruptConfirmed
,row_number() over (partition by tt.number,NewValue order by ChangeDate) rn
into #Bankrupts
from stg._collection.CustomerBankruptcyHistory h
left join stg._collection.CustomerBankruptcy t
	on h.ObjectId = t.id
left join stg._collection.deals tt 
	on t.customerid=tt.IdCustomer
where NewValue = 'Признан банкротом'
and tt.number is not null
;
-------------------------------------------Кредитные каникулы и реструктуризация
drop table if exists #kk;
select 
number as external_id
,period_start
,period_end
,case when operation_type = 'Кредитные каникулы' then 1 else 0 end kk_status
,case when operation_type = 'Реструктуризация' then 1 else 0 end restr
into #kk
from reports.dbo.dm_restructurings
where operation_type in ('Кредитные каникулы', 'Реструктуризация')
and period_end is not null
;
-------------------------------------------Балансы входа в бакет
drop table if exists #balls;
select
stbal.d
,stbal.external_id
,stbal.bucket_p_coll
,stbal.bucket_last_coll
,case when day(stbal.d) = 1 then stbal.prev_od --балансы входа в бакет на первое число
	when day(stbal.d) > 1  and [dbo].[GetCollectionBucketName] (stbal.prev_dpd_p_coll) <> stbal.[bucket_p_coll] then stbal.prev_od 
	else 0 --балансы входа в бакет в течение месяца
	end ball_in_p
into #balls
from dbo.dm_CMRStatBalance stbal
where stbal.d >= @rdt
;
-------------------------------------------Фиксируем балансы входа в бакет на даты. нужно, чтобы учитывать весь сохраненный балас при множественных платежах
drop table if exists #balls_sb;
select 
balls.d
,coalesce( dateadd(dd,-1, coalesce( lead(balls.d) over (partition by balls.external_id order by balls.d, balls.bucket_p_coll)
,lead(balls.d) over (partition by balls.external_id order by balls.d)) ),'2099-01-01') as to_d
,balls.external_id
,balls.ball_in_p
into #balls_sb
from #balls balls 
where balls.ball_in_p > 0
;
-------------------------------------------Исполнительные листы
drop table if exists #ispol_lists;
select
distinct(a.number) as external_id
,1 as flag_IL
,cast(min(coalesce(eo.[Date], eo.ReceiptDate, eo.CreateDate)) as date) as dt_from
into #ispol_lists
from Stg._Collection.EnforcementOrders eo
left join Stg._Collection.JudicialClaims jc
	on jc.Id = eo.JudicialClaimId
left join Stg._Collection.JudicialProceeding jp
	on jp.Id = jc.JudicialProceedingId
left join stg._Collection.deals a 
	on a.Id = jp.DealId
where a.Number is not null
group by a.Number
-------------------------------------------Филер стадий на дни их отсутствия
drop table if exists #missed_stages;
select 
* 
,@end_date as end_date
into #missed_stages
from stg._loginom.Collection_External_Stage_history
where call_dt = @start_date
;
-------------------------------------------Наименование продукта
drop table if exists #product_types;
select 
a.Код as external_id
,product_types.[Наименование продукта]
into #product_types
from stg._1cCMR.Справочник_Договоры a
left join Stg._1cCMR.Справочник_Заявка cmr_Заявка 
	on cmr_Заявка.Ссылка = a.Заявка
left join riskcollection.v_product_types product_types
	on cmr_Заявка.ПодтипПродукта = product_types.ПодтипПродукта
;
-------------------------------------------раздубливание Client_stage
drop table if exists #cstage;
select
dstage.external_id
,ccsh.CRMClientGUID
,ccsh.call_dt
,ccsh.Client_stage
,row_number () over (partition by ccsh.CRMClientGUID order by ccsh.call_dt desc) as rn
into #cstage
from Stg._loginom.Collection_Client_Stage_history ccsh
left join stg._loginom.Collection_External_Stage_history dstage
	on ccsh.CRMClientGUID = dstage.CRMClientGUID 
	and ccsh.call_dt = dstage.call_dt
where ccsh.call_dt >= @rdt
;
-------------------------------------------External_Stage_history
drop table if exists #External_Stage_history;
select 
external_id
,call_dt
,external_stage
,CRMClientGUID
,fio
,ClaimantStage
,row_number() over (partition by external_id, call_dt order by call_date desc) as rn
into #External_Stage_history
from stg._loginom.Collection_External_Stage_history cstage
where call_dt >= @rdt
;
-------------------------------------------КА
drop table if exists #ka;
select 
Deals.number as external_id
,cast(cat.TransferDate as date) as st_date
,coalesce(cast(cat.ReturnDate as date), '2099-01-01') as end_date
,ags.AgentName as agent_name
,row_number() over (partition by cat.DealId, cat.TransferDate order by coalesce(cast(cat.ReturnDate as date), '2099-01-01') desc) as rn
into #ka
from stg._collection.CollectingAgencyTransfer cat
left join Stg._Collection.Deals Deals
	on Deals.id = cat.DealId
left join stg._Collection.CollectorAgencies ags
	on cat.CollectorAgencyId = ags.Id
;
-------------------------------------------Итог
drop table if exists #final;
select
stbal.d
,stbal.external_id
--,stbal.[Тип продукта]
, case when d.[ТипПродукта] = 'PDL' then 'PDL' else d.[ГруппаПродуктов_Наименование] end [Тип продукта]
,stbal.dpd_coll
,stbal.dpd_p_coll
,stbal.dpd_last_coll
,stbal.bucket_coll
,substring(bucket_coll, 2,1) as bucket_coll_num
,stbal.bucket_p_coll
,substring(bucket_p_coll, 2,1) as bucket_p_coll_num
,stbal.bucket_last_coll
,substring(bucket_last_coll, 2,1) as bucket_last_coll_num
,bucket_last_p_coll
,substring(bucket_last_p_coll, 2,1) as bucket_last_p_coll_num
,stbal.[остаток од]
,stbal.prev_od
,stbal.prev_dpd_coll
,stbal.prev_dpd_p_coll
,stbal.pay_total
,case 
	when day(stbal.d)=1 then stbal.prev_od
	when day(stbal.d)>1 and [dbo].[GetCollectionBucketName] (stbal.prev_dpd_p_coll) != stbal.bucket_p_coll then stbal.prev_od
	else 0 
	end ball_in_p1
,case 
	when [dbo].[GetCollectionBucketName] (stbal.prev_dpd_p_coll) = '(1)_0' and stbal.bucket_p_coll = '(2)_1_30' 
	then stbal.prev_od 
	else 0 
	end inflow
,case when stbal.bucket_last_coll = '(1)_0' and stbal.bucket_coll = '(2)_1_30' then stbal.prev_od else 0 end inflow_old
,case when substring(stbal.bucket_p_coll, 2,1) > substring(stbal.bucket_coll, 2,1) 
	and stbal.dpd_p_coll < 91
	and (stbal.pay_total > 0 or restr.restr = 1)
	then balls_sb.ball_in_p else 0 end Saved_ballance
,case when substring(stbal.bucket_p_coll, 2,1) > substring(stbal.bucket_coll, 2,1) 
	and stbal.dpd_p_coll < 91
	and (stbal.pay_total > 0 or restr.restr = 1)
	then balls_sb.ball_in_p*(ac.k1-ac.k2)/nullif(ac.k1,0) end reduced_balance

,balls_sb.ball_in_p

,coalesce(dstage.external_stage, hi.external_stage, missed_stages.external_stage) as external_stage
,coalesce(dstage.ClaimantStage, hi.ClaimantStage, missed_stages.ClaimantStage) as ClaimantStage
,coalesce(dstage.fio, hi.fio, missed_stages.fio) as fio

,cstage.Client_stage as crmclientstage 

,ag.agent_name

,sotr.claimant_fio

,case when ballance.external_id is not null then 1 else 0 end ballance_flag
,ballance.AmountDepositToBalance as [Сумма принятия на баланс]

,dead.death_flag

,fssp_pays.Amount as fssp_pays

,beznadega.beznadega_status
,Bankrupts.BankruptConfirmed

,kk.kk_status

,ispol_lists.flag_IL

,ipsotr.claimant_ip_fio

,restr.restr

,[riskcollection].GetCollectionPortfBucketName (stbal.dpd_p_coll) as bucket_p_portf
,stbal.[остаток %]

,pt.[Наименование продукта]

into #final
from dbo.dm_CMRStatBalance stbal
left join dwh2.hub.ДоговорЗайма d on d.[КодДоговораЗайма] = stbal.external_id
left join reports.risk.coll_bucket_migr_adj_coef ac
on (case when stbal.[Тип продукта] in ('PDL') then 'PDL' 
	when stbal.[Тип продукта] in ('ПТС', 'ПТС31','ПТС (Автокред)','T-Банк','ПТС Займ для Самозанятых','ПТС Лайт для самозанятых') then 'PTS' 
	else 'Installment' end) = ac.product
	and stbal.bucket_p_coll = ac.bucket_from
	and stbal.bucket_coll = ac.bucket_to
	and stbal.d >= ac.d
left join #balls_sb balls_sb
	on stbal.external_id = balls_sb.external_id and (stbal.d between balls_sb.d and balls_sb.to_d)
--
left join #External_Stage_history dstage --нормальный случай
	on stbal.external_id = dstage.external_id 
	and stbal.d = cast(dstage.call_dt as date) 
	and dstage.call_dt != '2025-03-17' --дата пробной страт., исключить
	and dstage.rn = 1
left join #External_Stage_history hi --на случай пропуска одного дня
	on hi.external_id = stbal.external_id 
	and stbal.d = dateadd(dd, 1, hi.call_dt) 
	and dateadd(dd, 1, hi.call_dt) != '2025-03-17' --дата пробной страт., исключить
	and hi.rn = 1
left join #missed_stages missed_stages --на время кебер-инцидента
	on missed_stages.external_id = stbal.external_id 
	and stbal.d between missed_stages.call_dt and missed_stages.end_date
--
left join #cstage cstage
	on cstage.CRMClientGUID = dstage.CRMClientGUID 
	and cstage.call_dt = dstage.call_dt
	and cstage.rn = 1
left join #ka ag --dwh_new.dbo.v_agent_credits
	on stbal.external_id = ag.external_id 
	and (stbal.d between ag.st_date and ag.end_date)
	and ag.rn = 1
left join #sotr sotr
	on stbal.external_id = sotr.external_id 
	and (stbal.d between sotr.date_from and sotr.date_to)
left join #ip_sotr ipsotr
	on stbal.external_id = ipsotr.external_id
left join #ballance ballance
	on stbal.external_id = ballance.external_id 
	and stbal.d >= cast(ballance.AdoptionBalanceDate as date) and ballance.rn = 1
left join #beznadega_dead dead
	on stbal.external_id = dead.external_id 
	and stbal.d >= cast(dead.createdate as date) 
	and dead.rn = 1 and death_flag = 1
left join #fssp_pays fssp_pays
	on stbal.external_id = fssp_pays.external_id 
	and stbal.d = cast(fssp_pays.PaymentDt as date)
left join #Bankrupts Bankrupts
	on stbal.external_id = Bankrupts.external_id 
	and stbal.d >= cast(Bankrupts.ChangeDate as date) 
	and Bankrupts.rn = 1 
left join #beznadega_dead beznadega
	on stbal.external_id = beznadega.external_id and stbal.d >= cast(beznadega.createdate as date) 
	and beznadega.rn = 1 and beznadega.beznadega_status = 'Безнадёжное взыскание подтверждено'
left join #kk kk
	on stbal.external_id = kk.external_id 
	and stbal.d >= kk.period_start 
	and stbal.d < kk.period_end
	and kk_status = 1
left join #kk restr
	on stbal.external_id = restr.external_id 
	and stbal.d >= restr.period_start 
	and stbal.d < restr.period_end
	and restr.restr = 1
left join #ispol_lists ispol_lists
	on stbal.external_id = ispol_lists.external_id and stbal.d >= cast(ispol_lists.dt_from as date) 
left join #product_types pt
	on stbal.external_id = pt.external_id
where stbal.d >= @rdt
;

if OBJECT_ID('riskcollection.collection_datamart') is null
begin
	select top(0) * into riskcollection.collection_datamart
	from #final
end;

BEGIN TRANSACTION
	delete from riskcollection.collection_datamart
	where d >= @rdt

	insert into riskcollection.collection_datamart 
	select * from #final;
COMMIT TRANSACTION;

drop table if exists #last_sotr;
drop table if exists #sotr;
drop table if exists #ip_sotr;
drop table if exists #ballance;
drop table if exists #fssp_pays;
drop table if exists #beznadega_dead;
drop table if exists #Bankrupts;
drop table if exists #kk;
drop table if exists #balls;
drop table if exists #balls_sb;
drop table if exists #ispol_lists;
drop table if exists #missed_stages;
drop table if exists #product_types;
drop table if exists #cstage;
drop table if exists #External_Stage_history;
drop table if exists #ka;
drop table if exists #final;

END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'riskcollection@carmoney.ru'
			--,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH

END;