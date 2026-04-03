CREATE procedure [Risk].[v_portfolio_for_under]
as
begin
SET XACT_ABORT  ON;
DECLARE @Date_rep date = '20240801';
begin try

drop table if exists #table;
select distinct c.number, c.stage, o.client_type_1,
c.RequiredChecks, o.IsDocumentalVerification, o.IsSimplifiedVerification, isFullAutoApprove, o.uw_segment, w.decision,
format(call_date, 'yyyy-MM') as STAGE_DATE_AGG,
call_date,
--, case when call_date between '20240801' and '20240901' then '1-31.08.'
-- when call_date >= '20240901' and call_date < '20240906' then '1-5.09'
-- when call_date >= '20240906' then 'c 06.09.'
-- else 'wtf'
-- end as fl_date,
case
when isFullAutoApprove = 1 then 'Автоодобрение'
when o.IsDocumentalVerification = 1 and (isFullAutoApprove = 0 or isFullAutoApprove is null) then 'Проверка документов'
when w.decision = 'Decline' then 'Проверка документов'
when o.IsDocumentalVerification = 0 and o.IsSimplifiedVerification = 1 then 'Упрощенная верификация'
else 'Полная верификация' end as fl_check
, case when (RequiredChecks like '%1.201%') then 1 else 0 end as fl_fssp
, case when (RequiredChecks like '%1.217%') then 1 else 0 end as fl_bank
, case when (RequiredChecks like '%1.106%') then 1 else 0 end as fl_cobalt_frod
, case when (RequiredChecks like '%1.107%') then 1 else 0 end as fl_cobalt_check_person
into #table
from [Stg].[_loginom].[Originationlog] c with (nolock)
left join (select number, last_name, IsDocumentalVerification, IsSimplifiedVerification, uw_segment, client_type_1 from 
	stg.[_loginom].[Originationlog] with (nolock) where stage = 'Call 1' ) o
on o.number = c.number
left join (select number, decision from [Stg].[_loginom].[Originationlog] with (nolock) where stage = 'Call 1.5' ) w
on w.number = c.number
left join (select distinct [Номер заявки], fl_kd = 1 from [reports].[dbo].[dm_FedorVerificationRequests_without_coll] where [Статус] = 'Контроль данных') f
on f.[Номер заявки] = c.number
where call_date >=  @Date_rep and is_installment = 1 and stage = 'Call 1.2' and c.decision = 'Accept'
and c.number <> 19061300000088 and upper(o.last_name) not like 'ТЕСТ%' and fl_kd = 1

		begin tran
truncate table dwh2.risk.v_portfolio_for_under;

insert into dwh2.risk.v_portfolio_for_under
(
 [number]
, [stage]
, [client_type_1]
, [RequiredChecks]
, [IsDocumentalVerification]
, [IsSimplifiedVerification]
, [isFullAutoApprove]
, [uw_segment]
, [decision]
, [STAGE_DATE_AGG]
, [fl_check]
, [fl_fssp]
, [fl_bank]
, [fl_cobalt_frod]
, [fl_cobalt_check_person]

)
select  
 [number]
, [stage]
, [client_type_1]
, [RequiredChecks]
, [IsDocumentalVerification]
, [IsSimplifiedVerification]
, [isFullAutoApprove]
, [uw_segment]
, [decision]
, [STAGE_DATE_AGG]
, [fl_check]
, [fl_fssp]
, [fl_bank]
, [fl_cobalt_frod]
, [fl_cobalt_check_person]
from  #table

commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
