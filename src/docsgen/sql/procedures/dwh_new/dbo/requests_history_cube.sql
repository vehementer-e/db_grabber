
CREATE procedure [dbo].[requests_history_cube] as

--drop table if exists dbo.requests_history_fact;
--DWH-1764
TRUNCATE TABLE dbo.requests_history_fact

;with requests_history_lst as
(
SELECT   id, request_id, stage_time, verifier, status, reject_reason, created, is_active, external_link,
stage_date_key = year(  stage_time)*10000+month(stage_time)*100+day(stage_time),
stage_date = cast(stage_time as date),
stage_hour = datepart(hour,stage_time),
stage_min = datepart(MINUTE,stage_time),
stage_sec = datepart(SECOND,stage_time),
rank_over_stage = ROW_NUMBER() over (partition by request_id,status order by stage_time desc)
--into  requests_history_fact
FROM        [dwh_new].dbo.requests_history
),
next_stage as(
select * 
, next_status = lag(status,1,null) over (partition by request_id order by stage_time desc)
, next_status_rr = lag(reject_reason,1,null) over (partition by request_id order by stage_time desc)
, next_verifier = lag(verifier,1,null) over (partition by request_id order by stage_time desc)
from requests_history_lst
--where rank_over_stage = 1
),
cred as (
select distinct c.external_id , c.id from [dwh_new].dbo.credits_history ch
join [dwh_new].dbo.credits c on c.id=ch.credit_id
where isnull(status,0) > 0 and isnull(status,0) <7
),
fedor_request as
(select distinct cr.number from stg.[_fedor].[core_CheckListItem] cl
join stg.[_fedor].[core_ClientRequest] cr on cr.Id = cl.IdClientRequest)
INSERT dbo.requests_history_fact
(
    id,
    request_id,
    stage_time,
    verifier,
    status,
    reject_reason,
    created,
    is_active,
    external_link,
    stage_date_key,
    stage_date,
    stage_hour,
    stage_min,
    stage_sec,
    rank_over_stage,
    next_status,
    next_status_name,
    next_verifier,
    next_status_rr,
    is_canceled,
    is_approved,
    is_rejected,
    is_onhold,
    is_credit,
    is_fpd30,
    is_fpd90,
    risk_visa,
    is_fedor
)
select 
rh.id,
rh.request_id,
rh.stage_time,
rh.verifier,
rh.status,
rh.reject_reason,
rh.created,
rh.is_active,
rh.external_link,
rh.stage_date_key,
rh.stage_date,
rh.stage_hour,
rh.stage_min,
rh.stage_sec,
rh.rank_over_stage,
ns.next_status,
next_status_name = s.name,
ns.next_verifier,
ns.next_status_rr ,
is_canceled = case when ns.next_status in(13,15,18) then 1 else 0 end,
is_approved = case when ns.next_status in(6,8) then 1 else 0 end,
is_rejected = case when ns.next_status in(12,14) then 1 else 0 end,
is_onhold = case when ns.next_status in(1,2,3,4,5,7,9,10,11,16,17) then 1 else 0 end,
is_credit = case when c.external_id is not null then 1 else 0 end,
is_fpd30 =  isnull(fpd3.fpd30,0),
is_fpd90 =  isnull(fpd9.fpd90,0) 
,r.risk_visa
,is_fedor = case when fe.Number is not null then 1 else 0 end
--into   dbo.requests_history_fact
from 
requests_history_lst rh
 join [dwh_new].dbo.tmp_v_requests r on r.id = rh.request_id
left join cred c on c.external_id = r.external_id
left join [dwh_new].dbo.v_fpd_30 fpd3 on fpd3.credit_id = c.id
left join [dwh_new].dbo.v_fpd_90 fpd9 on fpd9.credit_id = c.id
left join next_stage ns on ns.request_id = rh.request_id and
ns.status = rh.status and ns.rank_over_stage = rh.rank_over_stage
left join [dwh_new].dbo.v_statuses s on s.id=ns.next_status
left join fedor_request fe on fe.Number = r.external_id COLLATE SQL_Latin1_General_CP1_CI_AS
--select * from statuses
--select * from v_fpd_30
--drop table requests_history_fact
 